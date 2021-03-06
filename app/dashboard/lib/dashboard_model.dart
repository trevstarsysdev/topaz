// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fidl_fuchsia_modular/fidl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:lib.app.dart/app.dart';
import 'package:lib.app.dart/logging.dart';
import 'package:lib.module_resolver.dart/intent_builder.dart';
import 'package:lib.widgets.dart/model.dart';
import 'package:lib.module.dart/module.dart';
import 'package:meta/meta.dart';

import 'build_status_model.dart';

/// Manages the framework FIDL services for this module.
class DashboardModel extends Model implements TickerProvider {
  final Future<ModuleControllerClient> Function(Intent intent) launchWebview;

  final DeviceMapProxy _deviceMapProxy = new DeviceMapProxy();

  /// The models that get the various build statuses.
  final List<List<BuildStatusModel>> buildStatusModels;

  final DateTime _startTime = new DateTime.now();
  DateTime _lastRefreshed;
  List<String> _devices;
  ModuleControllerClient _webviewModuleControllerClient;
  Timer _deviceMapTimer;

  /// Constructor.
  DashboardModel({
    @required this.launchWebview,
    this.buildStatusModels,
  }) : assert(launchWebview != null) {
    // ignore: avoid_function_literals_in_foreach_calls
    buildStatusModels.expand((List<BuildStatusModel> models) => models).forEach(
          (BuildStatusModel buildStatusModel) =>
              buildStatusModel.addListener(_updatePassFailTime),
        );
  }

  void onStop() {
    closeWebView();
    _deviceMapProxy.ctrl.close();
    _deviceMapTimer?.cancel();
    _deviceMapTimer = null;
  }

  @override
  Ticker createTicker(TickerCallback onTick) => new Ticker(onTick);

  /// The time the dashboard started.
  DateTime get startTime => _startTime;

  /// The time the dashboard was last refreshed.
  DateTime get lastRefreshed => _lastRefreshed;

  /// The devices for the current user.
  List<String> get devices => _devices;

  /// Starts loading the device map from the environment.
  void loadDeviceMap(StartupContext startupContext) {
    connectToService(
      startupContext.environmentServices,
      _deviceMapProxy.ctrl,
    );
    _deviceMapTimer?.cancel();
    _deviceMapTimer = new Timer.periodic(
        const Duration(seconds: 30), (_) => _queryDeviceMap());
  }

  void _queryDeviceMap() {
    _deviceMapProxy.query((List<DeviceMapEntry> devices) {
      List<String> newDeviceList =
          devices.map((DeviceMapEntry entry) => entry.deviceId).toList();
      if (!const ListEquality<String>().equals(_devices, newDeviceList)) {
        _devices = new List<String>.unmodifiable(newDeviceList);
        notifyListeners();
      }
    });
  }

  /// Starts a web view module pointing to the given [buildName].
  void launchWebView(String buildName) {
    final String url =
        'https://luci-scheduler.appspot.com/jobs/fuchsia/$buildName';

    final intentBuilder = new IntentBuilder.handler(url);

    _webviewModuleControllerClient?.proxy?.ctrl?.close();
    launchWebview(intentBuilder.intent).then((ModuleControllerClient client) {
      _webviewModuleControllerClient = client;
      client.proxy.onStateChange = onStateChange;
    }).catchError((err) => log.warning('Error launching webview: $err'));
  }

  void onStateChange(ModuleState newState) {
    /// If our module was stopped by the framework, notify this.
    if (newState == ModuleState.stopped) {
      onStop();
    }
  }

  /// Closes a previously launched web view.
  void closeWebView() {
    _webviewModuleControllerClient?.proxy?.ctrl?.close();
    _webviewModuleControllerClient = null;
  }

  void _updatePassFailTime() {
    _lastRefreshed = new DateTime.now();
    notifyListeners();
  }

  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static DashboardModel of(BuildContext context) =>
      new ModelFinder<DashboardModel>().of(context);
}
