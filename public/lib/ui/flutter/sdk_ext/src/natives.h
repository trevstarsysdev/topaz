// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LIB_UI_FLUTTER_SDK_EXT_SRC_NATIVES_H_
#define LIB_UI_FLUTTER_SDK_EXT_SRC_NATIVES_H_

#include "third_party/dart/runtime/include/dart_api.h"

#include <fuchsia/sys/cpp/fidl.h>

namespace mozart {

class NativesDelegate {
 public:
  virtual void OfferServiceProvider(
      fidl::InterfaceHandle<fuchsia::sys::ServiceProvider>,
      fidl::VectorPtr<fidl::StringPtr> services) = 0;

 protected:
  virtual ~NativesDelegate();
};

Dart_NativeFunction NativeLookup(Dart_Handle name,
                                 int argument_count,
                                 bool* auto_setup_scope);

const uint8_t* NativeSymbol(Dart_NativeFunction nf);

}  // namespace mozart

#endif  // LIB_UI_FLUTTER_SDK_EXT_SRC_NATIVES_H_
