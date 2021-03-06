// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fidl_fuchsia_timezone/fidl.dart';
import 'package:flutter/foundation.dart';
import 'package:lib.app.dart/app.dart';
import 'package:lib.device_shell/netstack_model.dart';
import 'package:lib.widgets/model.dart';

import 'authentication_overlay_model.dart';

/// Enum of the possible stages that are displayed during user setup.
///
/// The enum order is not equal to the order of steps.
enum SetupStage {
  /// When the setup has not yet started.
  notStarted,

  /// When logging in to a new user.
  userAuth,

  /// The first screen shown, including a timezone picker.
  welcome,

  /// When connecting to wireless internet.
  wifi,

  /// When the setup is complete.
  complete,
}

const List<SetupStage> _stages = const <SetupStage>[
  SetupStage.notStarted,
  SetupStage.welcome,
  SetupStage.wifi,
  SetupStage.userAuth,
  SetupStage.complete
];

/// Model that contains all the state needed to set up a new user
class UserSetupModel extends Model {
  final AuthenticationOverlayModel _authModel;
  final TimezoneProxy _timeZoneProxy;
  VoidCallback _loginAsGuest;
  bool _userPresent;
  final NetstackModel _netstackModel;

  /// StartupContext to allow setup to launch apps
  final StartupContext startupContext;

  /// Callback to cancel adding a new user.
  final VoidCallback cancelAuthenticationFlow;

  /// Callback to add a new user.
  VoidCallback addNewUser;

  int _currentIndex;

  /// Whether or not the user has connected to wifi and moved
  /// to the next step automatically.
  bool _connectedToWifi;

  /// Create a new [UserSetupModel]
  UserSetupModel(
      this.startupContext, this._netstackModel, this.cancelAuthenticationFlow)
      : _currentIndex = _stages.indexOf(SetupStage.notStarted),
        _authModel = new AuthenticationOverlayModel(),
        _timeZoneProxy = new TimezoneProxy(),
        _connectedToWifi = false {
    /// todo: change lifespan of proxies
    connectToService(startupContext.environmentServices, _timeZoneProxy.ctrl);

    _timeZoneProxy.getTimezoneId((String tz) {
      _currentTimezone = tz;
      notifyListeners();
    });

    addListener(_onStepChanged);
  }

  /// The overlay model for the authentication flow
  AuthenticationOverlayModel get authModel => _authModel;

  /// The current stage that the setup flow is in.
  SetupStage get currentStage => _stages[_currentIndex];

  /// Cancels the setup flow, moving back to the beginning.
  void reset() {
    _currentIndex = _stages.indexOf(SetupStage.notStarted);
    notifyListeners();
  }

  /// Begin setup phase
  void start({
    @required VoidCallback addNewUser,
    @required VoidCallback loginAsGuest,
    @required bool userPresent,
  }) {
    // This should be refactored into the model
    this.addNewUser = addNewUser;
    _loginAsGuest = loginAsGuest;
    _userPresent = userPresent;
    _currentIndex = _stages.indexOf(SetupStage.notStarted);
    nextStep();
  }

  /// Moves to the next stage in the setup flow.
  void nextStep() {
    do {
      assert(currentStage != SetupStage.complete);
      _currentIndex++;
    } while (_shouldSkipStage);

    notifyListeners();
  }

  /// Moves to the previous step in the setup flow
  void previousStep() {
    do {
      assert(currentStage != SetupStage.notStarted);
      _currentIndex--;
    } while (_shouldSkipStage);

    notifyListeners();
  }

  void _onStepChanged() {
    _netstackModel.removeListener(_wifiListener);

    // This will be refactored into the model, and then called when
    // building the userAuth widget.
    if (currentStage == SetupStage.userAuth) {
      addNewUser();
    } else if (currentStage == SetupStage.wifi && !_connectedToWifi) {
      _netstackModel.addListener(_wifiListener);
    }
  }

  void _wifiListener() {
    if (_netstackModel.networkReachable.value) {
      _connectedToWifi = true;
      nextStep();
    }
  }

  /// Function called with the authentication flow is completed.
  void endAuthFlow() {
    authModel.onStopOverlay();
    nextStep();
  }

  String _currentTimezone;

  /// Returns the current timezone.
  String get currentTimezone => _currentTimezone;

  /// Sets the current timezone
  set currentTimezone(String newTimezone) {
    _timeZoneProxy.setTimezone(newTimezone, (bool succeeded) {
      assert(succeeded);
      _currentTimezone = newTimezone;
      notifyListeners();
    });
  }

  /// Next step button should only be shown if the user has
  /// connected to wifi but gone back
  bool get shouldShowNextStep =>
      currentStage == SetupStage.wifi && _connectedToWifi;

  /// If the stage isn't needed due to current conditions.
  ///
  /// Does not apply to going backwards, as a user may
  /// need to connect to a different wifi network
  bool get _shouldSkipStage =>
      (currentStage == SetupStage.welcome && _userPresent) ||
      (currentStage == SetupStage.wifi &&
          !_connectedToWifi &&
          _netstackModel.networkReachable.value);

  /// Ends the setup flow and immediately logs in as guest
  void loginAsGuest() {
    _currentIndex = _stages.indexOf(SetupStage.complete);
    notifyListeners();
    _loginAsGuest();
  }
}
