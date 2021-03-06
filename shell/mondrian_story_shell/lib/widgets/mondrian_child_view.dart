// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.app.dart/logging.dart';
import 'package:lib.ui.flutter/child_view.dart';
import '../models/surface/surface.dart';

/// Frame for child views
class MondrianChildView extends StatelessWidget {
  /// Constructor
  const MondrianChildView({this.surface, this.interactable = true});

  /// If true then ChildView hit tests will go through
  final bool interactable;

  final Surface surface;

  @override
  Widget build(BuildContext context) => new AnimatedBuilder(
        animation: surface,
        builder: (BuildContext context, Widget child) =>
            surface.transitionModel.opacity != 1.0
                ? new Stack(
                    children: <Widget>[
                      new ChildView(
                        connection: surface.connection,
                        hitTestable: interactable,
                      ),
                      new Container(
                        color: getColor(surface.placeholderColor),
                      )
                    ],
                  )
                : new ChildView(
                    connection: surface.connection,
                    hitTestable: interactable,
                  ),
      );

// Convert from HTML color code format to 0xAARRGGBB.
// Placeholder colors are specified as and checked for conformance as HTML to
// HTML color codes format (see: peridot/build/module_manifest_schema.json)
//
// Defaults to white in cases where no hexColorString or an invalid
// hexColorString are presented.
  Color getColor(String hexColorString) {
    Color placeholderColor = Colors.white;
    int colorInt;
    String parseString = hexColorString.replaceAll('#', '');
    try {
      colorInt = int.parse(parseString, radix: 16);
      placeholderColor = new Color(colorInt).withOpacity(1.0);
    } on FormatException {
      log.fine('hexColorString conversion error for string $parseString');
    }
    return placeholderColor;
  }
}
