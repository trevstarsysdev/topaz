// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:lib.widgets/model.dart';

import '../modular/module_model.dart';
import '../widgets.dart';

const double _kZoomTimeInMicroseconds = 3000000.0;

/// Duration to animate play controls showing/hiding
const Duration kAnimationTime = const Duration(milliseconds: 200);

/// The time slider/scrubber for the video player
class Scrubber extends StatelessWidget {
  /// Constructor for the time slider/scrubber for the video player
  Scrubber({
    Key key,
  })
      : super(key: key);

  /// Converts a duration to a string indicating seconds, such as '1:15:00' or
  /// '2:40'
  static String _convertDurationToString(Duration duration) {
    int seconds = duration.inSeconds;
    int minutes = seconds ~/ 60;
    seconds %= 60;
    int hours = minutes ~/ 60;
    minutes %= 60;

    String hoursString = hours == 0 ? '' : '$hours:';
    String minutesString =
        (hours == 0 || minutes > 9) ? '$minutes:' : '0$minutes:';
    String secondsString = seconds > 9 ? '$seconds' : '0$seconds';

    return '$hoursString$minutesString$secondsString';
  }

  Widget _buildProgressBar(VideoModuleModel model) {
    return new Container(
      child: new Slider(
        min: 0.0,
        max: 1.0,
        activeColor: Colors.grey[50],
        inactiveColor: Colors.grey[600],
        value: model.normalizedProgress,
        onChanged: model.normalizedSeek,
      ),
    );
  }

  Widget _buildTimestamp(Duration timestamp, DisplayMode displayMode) {
    return new Center(
      child: new Container(
        padding: new EdgeInsets.symmetric(horizontal: 24.0),
        child: new Text(
          _convertDurationToString(timestamp),
          style: new TextStyle(
            color: Colors.grey[50],
            fontSize: displayMode == DisplayMode.localLarge ? 20.0 : 14.0,
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(VideoModuleModel model) {
    return new Positioned(
      height: 80.0,
      left: 0.0,
      top: 0.0,
      child: _buildTimestamp(model.progress, DisplayMode.localLarge),
    );
  }

  Widget _buildDuration(VideoModuleModel model) {
    return new Positioned(
      height: 80.0,
      right: 0.0,
      top: 0.0,
      child: _buildTimestamp(model.duration, DisplayMode.localLarge),
    );
  }

  Widget _buildScrubberMode(VideoModuleModel model) {
    switch (model.displayMode) {
      case DisplayMode.remoteControl:
        return new Container(
          padding: new EdgeInsets.only(top: 40.0),
          child: new Stack(
            children: <Widget>[
              new PlayControls(
                primaryIconSize: 48.0,
                secondaryIconSize: 48.0,
                padding: 36.0,
              ),
              _buildProgress(model),
              _buildDuration(model),
              new Positioned(
                left: 0.0,
                right: 0.0,
                top: 0.0,
                child: _buildProgressBar(model),
              ),
            ],
          ),
        );
      case DisplayMode.localSmall:
        return new AnimatedCrossFade(
          duration: kAnimationTime,
          firstChild: new Row(
            children: <Widget>[
              _buildTimestamp(model.progress, DisplayMode.localSmall),
              new Expanded(
                child: _buildProgressBar(model),
              ),
              _buildTimestamp(model.duration, DisplayMode.localSmall),
            ],
          ),
          secondChild: new Container(),
          crossFadeState: model.showControlOverlay
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
        );
      case DisplayMode.localLarge:
      default:
        return new AnimatedCrossFade(
          duration: kAnimationTime,
          firstChild: new Stack(
            children: <Widget>[
              _buildProgress(model),
              _buildDuration(model),
              new PlayControls(
                primaryIconSize: 36.0,
                secondaryIconSize: 36.0,
                padding: 20.0,
              ),
              new Positioned(
                left: 0.0,
                right: 0.0,
                top: 0.0,
                child: _buildProgressBar(model),
              ),
            ],
          ),
          secondChild: new Container(),
          crossFadeState: model.showControlOverlay
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return new ScopedModelDescendant<VideoModuleModel>(
      builder: (
        BuildContext context,
        Widget child,
        VideoModuleModel model,
      ) {
        return _buildScrubberMode(model);
      },
    );
  }
}
