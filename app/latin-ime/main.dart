// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fidl_fuchsia_ui_input/fidl.dart';
import 'package:flutter/material.dart';
import 'package:keyboard/keyboard.dart';
import 'package:lib.app.dart/app.dart';
import 'package:lib.app.dart/logging.dart';

class ImeKeyboard extends StatelessWidget {

  const ImeKeyboard({ImeServiceProxy imeService})
    : _imeService = imeService,
      super();

  final ImeServiceProxy _imeService;

  void _onText(String text) {
    final kbEvent = KeyboardEvent(
      phase: KeyboardEventPhase.pressed,
      codePoint: text.codeUnitAt(0),
      hidUsage: 0,
      eventTime: 0,
      modifiers: 0,
      deviceId: 0,
    );
    var event = InputEvent.withKeyboard(kbEvent);
    _imeService.injectInput(event);
  }

  void _onDelete() {
    final kbEvent = KeyboardEvent(
      phase: KeyboardEventPhase.pressed,
      codePoint: 0,
      hidUsage: 0x2a,
      eventTime: 0,
      modifiers: 0,
      deviceId: 0,
    );
    var event = InputEvent.withKeyboard(kbEvent);
    _imeService.injectInput(event);
  }

  void _onGo() {
    final kbEvent = KeyboardEvent(
      phase: KeyboardEventPhase.pressed,
      codePoint: 0,
      hidUsage: 0x28,
      eventTime: 0,
      modifiers: 0,
      deviceId: 0,
    );
    var event = InputEvent.withKeyboard(kbEvent);
    _imeService.injectInput(event);
  }

  @override
  Widget build(BuildContext context) {
    return Keyboard(onText: _onText, onDelete: _onDelete, onGo: _onGo);
  }
}

void main() {
  final context = StartupContext.fromStartupInfo();
  var imeService = ImeServiceProxy();
  connectToService<ImeService>(context.environmentServices, imeService.ctrl);

  setupLogger();

  runApp(Theme(
    data: ThemeData.light(),
    child: ImeKeyboard(imeService: imeService),
  ));
}
