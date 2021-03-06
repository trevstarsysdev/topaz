// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vulkan_surface_pool.h"

#include <algorithm>
#include <string>

#include <trace/event.h>

#include "flutter/fml/trace_event.h"
#include "third_party/skia/include/gpu/GrContext.h"

namespace flutter {

namespace {

std::string ToString(const SkISize& size) {
  return "{height: " + std::to_string(size.height()) +
         ", width: " + std::to_string(size.width()) + "}";
}

}  // namespace

VulkanSurfacePool::VulkanSurfacePool(vulkan::VulkanProvider& vulkan_provider,
                                     sk_sp<GrContext> context,
                                     scenic::Session* scenic_session)
    : vulkan_provider_(vulkan_provider),
      context_(std::move(context)),
      scenic_session_(scenic_session) {}

VulkanSurfacePool::~VulkanSurfacePool() {}

std::unique_ptr<flow::SceneUpdateContext::SurfaceProducerSurface>
VulkanSurfacePool::AcquireSurface(const SkISize& size) {
  auto surface = GetCachedOrCreateSurface(size);

  if (surface == nullptr) {
    FML_DLOG(ERROR) << "Could not acquire surface";
    return nullptr;
  }

  if (!surface->FlushSessionAcquireAndReleaseEvents()) {
    FML_DLOG(ERROR) << "Could not flush acquire/release events for buffer.";
    return nullptr;
  }

  return surface;
}

std::unique_ptr<flow::SceneUpdateContext::SurfaceProducerSurface>
VulkanSurfacePool::GetCachedOrCreateSurface(const SkISize& size) {
  // First try to find a surface that exactly matches |size|.
  {
    auto exact_match_it =
        std::find_if(available_surfaces_.begin(), available_surfaces_.end(),
                     [&size](const auto& surface) {
                       return surface->IsValid() && surface->GetSize() == size;
                     });
    if (exact_match_it != available_surfaces_.end()) {
      auto acquired_surface = std::move(*exact_match_it);
      available_surfaces_.erase(exact_match_it);
      return acquired_surface;
    }
  }

  // Then, look for a surface that has enough |VkDeviceMemory| to hold a
  // |VkImage| of size |size|, but is currently holding a |VkImage| of a
  // different size.
  VulkanImage vulkan_image;
  if (!CreateVulkanImage(vulkan_provider_, size, &vulkan_image)) {
    FML_DLOG(ERROR) << "Failed to create a VkImage of size: " << ToString(size);
    return nullptr;
  }

  auto best_it = available_surfaces_.end();
  for (auto it = available_surfaces_.begin(); it != available_surfaces_.end();
       ++it) {
    const auto& surface = *it;
    if (!surface->IsValid() || surface->GetAllocationSize() <
                                   vulkan_image.vk_memory_requirements.size) {
      continue;
    }
    if (best_it == available_surfaces_.end() ||
        surface->GetAllocationSize() < (*best_it)->GetAllocationSize()) {
      best_it = it;
    }
  }

  // If no such surface exists, then create a new one.
  if (best_it == available_surfaces_.end()) {
    return CreateSurface(size);
  }

  auto acquired_surface = std::move(*best_it);
  available_surfaces_.erase(best_it);
  bool swap_succeeded =
      acquired_surface->BindToImage(context_, std::move(vulkan_image));
  if (!swap_succeeded) {
    FML_DLOG(ERROR) << "Failed to swap VulkanSurface to new VkImage of size: "
                    << ToString(size);
    return CreateSurface(size);
  }
  FML_DCHECK(acquired_surface->IsValid());
  trace_surfaces_reused_++;
  return acquired_surface;
}

void VulkanSurfacePool::SubmitSurface(
    std::unique_ptr<flow::SceneUpdateContext::SurfaceProducerSurface>
        p_surface) {
  TRACE_EVENT0("flutter", "VulkanSurfacePool::SubmitSurface");

  // This cast is safe because |VulkanSurface| is the only implementation of
  // |SurfaceProducerSurface| for Flutter on Fuchsia.  Additionally, it is
  // required, because we need to access |VulkanSurface| specific information
  // of the surface (such as the amount of VkDeviceMemory it contains).
  auto vulkan_surface = std::unique_ptr<VulkanSurface>(
      static_cast<VulkanSurface*>(p_surface.release()));
  if (!vulkan_surface) {
    return;
  }

  uintptr_t surface_key = reinterpret_cast<uintptr_t>(vulkan_surface.get());

  auto insert_iterator = pending_surfaces_.insert(std::make_pair(
      surface_key,               // key
      std::move(vulkan_surface)  // value
      ));

  if (insert_iterator.second) {
    insert_iterator.first->second->SignalWritesFinished(
        std::bind(&VulkanSurfacePool::RecycleSurface, this, surface_key));
  }
}

std::unique_ptr<VulkanSurface> VulkanSurfacePool::CreateSurface(
    const SkISize& size) {
  TRACE_EVENT0("flutter", "VulkanSurfacePool::CreateSurface");
  auto surface = std::make_unique<VulkanSurface>(vulkan_provider_, context_,
                                                 scenic_session_, size);
  if (!surface->IsValid()) {
    return nullptr;
  }
  trace_surfaces_created_++;
  return surface;
}

void VulkanSurfacePool::RecycleSurface(uintptr_t surface_key) {
  // Before we do anything, we must clear the surface from the collection of
  // pending surfaces.
  auto found_in_pending = pending_surfaces_.find(surface_key);
  if (found_in_pending == pending_surfaces_.end()) {
    return;
  }

  // Grab a hold of the surface to recycle and clear the entry in the pending
  // surfaces collection.
  auto surface_to_recycle = std::move(found_in_pending->second);
  pending_surfaces_.erase(found_in_pending);

  // The surface may have become invalid (for example it the fences could
  // not be reset).
  if (!surface_to_recycle->IsValid()) {
    return;
  }

  // Recycle the buffer by putting it in the list of available surfaces if we
  // have not reached the maximum amount of cached surfaces.
  if (available_surfaces_.size() < kMaxSurfaces) {
    available_surfaces_.push_back(std::move(surface_to_recycle));
  }
}

void VulkanSurfacePool::AgeAndCollectOldBuffers() {
  TRACE_EVENT0("flutter", "VulkanSurfacePool::AgeAndCollectOldBuffers");

  // Remove all surfaces that are no longer valid or are too old.
  available_surfaces_.erase(
      std::remove_if(available_surfaces_.begin(), available_surfaces_.end(),
                     [&](auto& surface) {
                       return !surface->IsValid() ||
                              surface->AdvanceAndGetAge() >= kMaxSurfaceAge;
                     }),
      available_surfaces_.end());

  // Look for a surface that has both a larger |VkDeviceMemory| allocation
  // than is necessary for its |VkImage|, and has a stable size history.
  auto surface_to_remove_it = std::find_if(
      available_surfaces_.begin(), available_surfaces_.end(),
      [](const auto& surface) {
        return surface->IsOversized() && surface->HasStableSizeHistory();
      });
  // If we found such a surface, then destroy it and cache a new one that only
  // uses a necessary amount of memory.
  if (surface_to_remove_it != available_surfaces_.end()) {
    auto size = (*surface_to_remove_it)->GetSize();
    available_surfaces_.erase(surface_to_remove_it);
    auto new_surface = CreateSurface(size);
    if (new_surface != nullptr) {
      available_surfaces_.push_back(std::move(new_surface));
    } else {
      FML_DLOG(ERROR) << "Failed to create a new shrunk surface";
    }
  }

  TraceStats();
}

void VulkanSurfacePool::ShrinkToFit() {
  for (auto& surface : available_surfaces_) {
    if (surface->IsOversized()) {
      auto size = surface->GetSize();
      // Reset |surface| first so that the old surface and new surface don't
      // exist at the same time at any point, reducing our peak memory
      // footprint.
      surface.reset();
      surface = CreateSurface(size);
    }
  }

  TraceStats();
}

void VulkanSurfacePool::TraceStats() {
  // Resources held in cached buffers.
  size_t cached_surfaces = 0;
  size_t cached_surfaces_bytes = 0;

  for (const auto& surface : available_surfaces_) {
    cached_surfaces++;
    cached_surfaces_bytes += surface->GetAllocationSize();
  }

  // Resources held by Skia.
  int skia_resources = 0;
  size_t skia_bytes = 0;
  context_->getResourceCacheUsage(&skia_resources, &skia_bytes);
  const size_t skia_cache_purgeable =
      context_->getResourceCachePurgeableBytes();

  TRACE_COUNTER("flutter", "SurfacePool", 0u,                     //
                "CachedCount", cached_surfaces,                   //
                "CachedBytes", cached_surfaces_bytes,             //
                "Created", trace_surfaces_created_,               //
                "Reused", trace_surfaces_reused_,                 //
                "PendingInCompositor", pending_surfaces_.size(),  //
                "SkiaCacheResources", skia_resources,             //
                "SkiaCacheBytes", skia_bytes,                     //
                "SkiaCachePurgeable", skia_cache_purgeable        //
  );

  // Reset per present/frame stats.
  trace_surfaces_created_ = 0;
  trace_surfaces_reused_ = 0;
}

}  // namespace flutter
