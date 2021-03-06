// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'constants.dart' as constants;
import 'keys.dart';
import 'word_suggestion_service.dart';

const double _kSuggestionRowHeight = 0.0;
const Color _kAccentColor = const Color(0xFF68EFAD);

const Color _kBorderColor = const Color(0xFFD8D9DA);
const Color _kBackgroundColor = const Color(0xFFF8F9FA);
const Color _kContentColor = const Color(0xFF202124);
const TextStyle _kDefaultTextStyle = const TextStyle(
  color: _kContentColor,
  fontFamily: 'Roboto-Light',
  fontSize: 16.0,
);

const String _kKeyType = 'type'; // defaults to kKeyTypeNormal
const String _kKeyTypeSuggestion = 'suggestion';
const String _kKeyTypeNormal = 'normal';
const String _kKeyTypeSpecial = 'special';

const String _kKeyVisualType = 'visualtype'; // defaults to kKeyVisualTypeText
const String _kKeyVisualTypeText = 'text';
const String _kKeyVisualTypeImage = 'image';
const String _kKeyVisualTypeSpacer = 'spacer';
const String _kKeyVisualTypeActionText = 'actiontext';

const String _kKeyAction =
    'action'; // defaults to kKeyActionEmitText, a number indicates an index into the kayboard layouts array.
const String _kKeyActionEmitText = 'emittext';
const String _kKeyActionDelete = 'delete';
const String _kKeyActionSpace = 'space';
const String _kKeyActionGo = 'go';

const String _kKeyImage = 'image'; // defaults to null
const String _kKeyText = 'text'; // defaults to null
const String _kKeyWidth = 'width'; // defaults to 1
const String _kKeyAlign = 'align'; // defaults to 0.5

const int _kKeyboardLayoutIndexLowerCase = 0;
const int _kKeyboardLayoutIndexUpperCase = 1;
const int _kKeyboardLayoutIndexSymbolsOne = 2;
const int _kKeyboardLayoutIndexSymbolsTwo = 3;

const String _kKeyboardLayoutsJson = '['
// Lower Case Layout
    '['
    '['
    '{\"$_kKeyText\":\"q\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"w\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"e\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"r\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"t\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"y\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"u\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"i\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"o\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"p\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyImage\":\"packages/keyboard/res/Delete.png\", \"$_kKeyAction\":\"$_kKeyActionDelete\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeImage\", \"$_kKeyWidth\":\"2\"}'
    '],'
    '['
    '{\"$_kKeyVisualType\":\"$_kKeyVisualTypeSpacer\", \"$_kKeyWidth\":\"1\"},'
    '{\"$_kKeyText\":\"a\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"s\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"d\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"f\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"g\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"h\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"j\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"k\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"l\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"Go\", \"$_kKeyAction\":\"$_kKeyActionGo\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeActionText\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyVisualType\":\"$_kKeyVisualTypeSpacer\", \"$_kKeyWidth\":\"1\"}'
    '],'
    '['
    '{\"$_kKeyImage\":\"packages/keyboard/res/ArrowUp.png\", \"$_kKeyAction\":\"$_kKeyboardLayoutIndexUpperCase\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeImage\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"z\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"x\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"c\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"v\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"b\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"n\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"m\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"!\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"?\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyImage\":\"packages/keyboard/res/ArrowUp.png\", \"$_kKeyAction\":\"$_kKeyboardLayoutIndexUpperCase\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeImage\", \"$_kKeyWidth\":\"2\"}'
    '],'
    '['
    '{\"$_kKeyText\":\"?123\", \"$_kKeyAction\":\"$_kKeyboardLayoutIndexSymbolsOne\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeActionText\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"_\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"-\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyImage\":\"packages/keyboard/res/Space.png\", \"$_kKeyAction\":\"$_kKeyActionSpace\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeImage\", \"$_kKeyWidth\":\"10\"},'
    '{\"$_kKeyText\":\",\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\".\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"?123\", \"$_kKeyAction\":\"$_kKeyboardLayoutIndexSymbolsOne\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeActionText\", \"$_kKeyWidth\":\"2\"}'
    ']'
    '],'
// Upper Case Layout
    '['
    '['
    '{\"$_kKeyText\":\"Q\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"W\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"E\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"R\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"T\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"Y\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"U\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"I\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"O\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"P\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyImage\":\"packages/keyboard/res/Delete.png\", \"$_kKeyAction\":\"$_kKeyActionDelete\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeImage\", \"$_kKeyWidth\":\"2\"}'
    '],'
    '['
    '{\"$_kKeyVisualType\":\"$_kKeyVisualTypeSpacer\", \"$_kKeyWidth\":\"1\"},'
    '{\"$_kKeyText\":\"A\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"S\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"D\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"F\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"G\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"H\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"J\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"K\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"L\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"Go\", \"$_kKeyAction\":\"$_kKeyActionGo\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeActionText\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyVisualType\":\"$_kKeyVisualTypeSpacer\", \"$_kKeyWidth\":\"1\"}'
    '],'
    '['
    '{\"$_kKeyImage\":\"packages/keyboard/res/ArrowDown.png\", \"$_kKeyAction\":\"$_kKeyboardLayoutIndexLowerCase\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeImage\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"Z\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"X\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"C\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"V\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"B\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"N\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"M\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"!\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"?\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyImage\":\"packages/keyboard/res/ArrowDown.png\", \"$_kKeyAction\":\"$_kKeyboardLayoutIndexLowerCase\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeImage\", \"$_kKeyWidth\":\"2\"}'
    '],'
    '['
    '{\"$_kKeyText\":\"?123\", \"$_kKeyAction\":\"$_kKeyboardLayoutIndexSymbolsOne\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeActionText\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"_\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"-\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyImage\":\"packages/keyboard/res/Space.png\", \"$_kKeyAction\":\"$_kKeyActionSpace\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeImage\", \"$_kKeyWidth\":\"10\"},'
    '{\"$_kKeyText\":\",\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\".\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"?123\", \"$_kKeyAction\":\"$_kKeyboardLayoutIndexSymbolsOne\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeActionText\", \"$_kKeyWidth\":\"2\"}'
    ']'
    '],'
// Symbols One Layout
    '['
    '['
    '{\"$_kKeyText\":\"1\"},'
    '{\"$_kKeyText\":\"2\"},'
    '{\"$_kKeyText\":\"3\"},'
    '{\"$_kKeyText\":\"4\"},'
    '{\"$_kKeyText\":\"5\"},'
    '{\"$_kKeyText\":\"6\"},'
    '{\"$_kKeyText\":\"7\"},'
    '{\"$_kKeyText\":\"8\"},'
    '{\"$_kKeyText\":\"9\"},'
    '{\"$_kKeyText\":\"0\"}'
    '],'
    '['
    '{\"$_kKeyText\":\"@\", \"$_kKeyWidth\":\"3\", \"$_kKeyAlign\":\"0.66666666\"},'
    '{\"$_kKeyText\":\"#\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"\$\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"%\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"&\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"-\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"+\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"(\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\")\", \"$_kKeyWidth\":\"3\", \"$_kKeyAlign\":\"0.33333333\"}'
    '],'
    '['
    '{\"$_kKeyText\":\"=\\\\<\", \"$_kKeyAction\":\"$_kKeyboardLayoutIndexSymbolsTwo\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeActionText\", \"$_kKeyWidth\":\"3\"},'
    '{\"$_kKeyText\":\"*\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"\\\\\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"\'\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\":\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\";\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"!\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"?\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyImage\":\"packages/keyboard/res/Delete.png\", \"$_kKeyAction\":\"$_kKeyActionDelete\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeImage\", \"$_kKeyWidth\":\"3\"}'
    '],'
    '['
    '{\"$_kKeyText\":\"ABC\", \"$_kKeyAction\":\"$_kKeyboardLayoutIndexLowerCase\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeActionText\", \"$_kKeyWidth\":\"3\"},'
    '{\"$_kKeyText\":\",\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"_\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyImage\":\"packages/keyboard/res/Space.png\", \"$_kKeyAction\":\"$_kKeyActionSpace\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeImage\", \"$_kKeyWidth\":\"6\"},'
    '{\"$_kKeyText\":\"/\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\".\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"Go\", \"$_kKeyAction\":\"$_kKeyActionGo\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeActionText\", \"$_kKeyWidth\":\"3\"}'
    ']'
    '],'
// Symbols Two Layout
    '['
    '['
    '{\"$_kKeyText\":\"~\"},'
    '{\"$_kKeyText\":\"`\"},'
    '{\"$_kKeyText\":\"|\"},'
    '{\"$_kKeyText\":\"\u{2022}\"},'
    '{\"$_kKeyText\":\"\u{221A}\"},'
    '{\"$_kKeyText\":\"\u{03C0}\"},'
    '{\"$_kKeyText\":\"\u{00F7}\"},'
    '{\"$_kKeyText\":\"\u{00D7}\"},'
    '{\"$_kKeyText\":\"\u{00B6}\"},'
    '{\"$_kKeyText\":\"\u{2206}\"}'
    '],'
    '['
    '{\"$_kKeyText\":\"\u{00A3}\", \"$_kKeyWidth\":\"3\", \"$_kKeyAlign\":\"0.66666666\"},'
    '{\"$_kKeyText\":\"\u{00A2}\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"\u{20AC}\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"\u{00A5}\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"^\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"\u{00B0}\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"=\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"{\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"}\", \"$_kKeyWidth\":\"3\", \"$_kKeyAlign\":\"0.33333333\"}'
    '],'
    '['
    '{\"$_kKeyText\":\"?123\", \"$_kKeyAction\":\"$_kKeyboardLayoutIndexSymbolsOne\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeActionText\", \"$_kKeyWidth\":\"3\"},'
    '{\"$_kKeyText\":\"\\\\\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"\u{00A9}\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"\u{00AE}\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"\u{2122}\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"\u{2105}\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"[\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"]\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyImage\":\"packages/keyboard/res/Delete.png\", \"$_kKeyAction\":\"$_kKeyActionDelete\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeImage\", \"$_kKeyWidth\":\"3\"}'
    '],'
    '['
    '{\"$_kKeyText\":\"ABC\", \"$_kKeyAction\":\"$_kKeyboardLayoutIndexLowerCase\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeActionText\", \"$_kKeyWidth\":\"3\"},'
    '{\"$_kKeyText\":\",\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"<\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyImage\":\"packages/keyboard/res/Space.png\", \"$_kKeyAction\":\"$_kKeyActionSpace\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeImage\", \"$_kKeyWidth\":\"6\"},'
    '{\"$_kKeyText\":\">\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\".\", \"$_kKeyWidth\":\"2\"},'
    '{\"$_kKeyText\":\"Go\", \"$_kKeyAction\":\"$_kKeyActionGo\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeActionText\", \"$_kKeyWidth\":\"3\"}'
    ']'
    ']'
    ']';

final List<List<dynamic>> _kKeyboardLayouts =
    json.decode(_kKeyboardLayoutsJson).cast<List<dynamic>>();

/// Displays a keyboard.
class Keyboard extends StatefulWidget {
  /// Called when a key is tapped on the keyboard.
  final OnText onText;

  /// Called when a suggestion is tapped on the keyboard.
  final OnText onSuggestion;

  /// Called when 'Delete' is tapped on the keyboard.
  final VoidCallback onDelete;

  /// Called when 'Go' is tapped on the keyboard.
  final VoidCallback onGo;

  /// Constructor.
  const Keyboard(
      {Key key, this.onText, this.onSuggestion, this.onDelete, this.onGo})
      : super(key: key);

  @override
  KeyboardState createState() => KeyboardState();
}

/// Displays the current keyboard for [Keyboard].
/// [_keyboards] is the list of available keyboards created from
/// [_kKeyboardLayouts] while [_keyboardWidget] is the one currently being
/// displayed.
class KeyboardState extends State<Keyboard> {
  static const double _kGoKeyTextSize = 12.0;
  static const double _kSuggestionTextSize = 16.0;
  static const TextStyle _kSuggestionTextStyle = const TextStyle(
    color: _kAccentColor,
    fontSize: _kSuggestionTextSize,
    letterSpacing: 2.0,
  );

  final List<GlobalKey<TextKeyState>> _suggestionKeys =
      <GlobalKey<TextKeyState>>[];
  Widget _keyboardWidget;
  List<Widget> _keyboards;

  @override
  void initState() {
    super.initState();
    _keyboards = <Widget>[];
    for (List<dynamic> keyboard in _kKeyboardLayouts) {
      _keyboards.add(Directionality(
        textDirection: TextDirection.ltr,
        child: IntrinsicHeight(
          child: Container(
            decoration: BoxDecoration(
              color: _kBorderColor,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(constants.cornerRadius),
              ),
            ),
            padding: EdgeInsets.only(
              left: constants.borderWidth,
              right: constants.borderWidth,
              top: constants.borderWidth,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: _kBackgroundColor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(constants.cornerRadius),
                ),
              ),
              child: Column(children: keyboard.map(_makeRow).toList()),
            ),
          ),
        ),
      ));
    }
    _keyboardWidget = _keyboards[0];
  }

  @override
  Widget build(BuildContext context) => _keyboardWidget;

  /// Updates the suggestions to be related to [text].
  void updateSuggestions(String text) {
    // If we have no text, clear the suggestions.  If the text ends in
    // whitespace also clear the suggestions (as there is no current word to
    // create suggestions from).
    if (text == null || text == '' || text.endsWith(' ')) {
      _clearSuggestions();
      return;
    }

    final List<String> stringList = text.split(' ');

    // If we have no words at all, clear the suggestions.
    if (stringList.isEmpty) {
      _clearSuggestions();
      return;
    }

    final String currentWord = stringList.removeLast();

    final WordSuggestionService wordSuggestionService = WordSuggestionService();
    List<String> suggestedWords =
        wordSuggestionService.suggestWords(currentWord);
    _clearSuggestions();
    for (int i = 0;
        i < min(_suggestionKeys.length, suggestedWords.length);
        i++) {
      _suggestionKeys[i].currentState?.text = suggestedWords[i];
    }
  }

  void _clearSuggestions() {
    for (GlobalKey<TextKeyState> suggestionKey in _suggestionKeys) {
      suggestionKey.currentState?.text = '';
    }
  }

  Row _makeRow(dynamic jsonRow) {
    List<dynamic> row = jsonRow;
    return Row(
      children: row.map(_makeKey).toList(),
      mainAxisAlignment: MainAxisAlignment.center,
    );
  }

  Widget _makeKey(dynamic jsonKey) {
    Map<String, dynamic> keyMap = jsonKey;
    Map<String, String> key = keyMap.cast();
    String visualType = key[_kKeyVisualType] ?? _kKeyVisualTypeText;
    String action = key[_kKeyAction] ?? _kKeyActionEmitText;
    int width = int.parse(key[_kKeyWidth] ?? '1');

    switch (visualType) {
      case _kKeyVisualTypeImage:
        String image = key[_kKeyImage];
        return _createImageKey(image, width, action);
      case _kKeyVisualTypeSpacer:
        return _createSpacerKey(width);
      case _kKeyVisualTypeText:
      case _kKeyVisualTypeActionText:
      default:
        String type = key[_kKeyType] ?? _kKeyTypeNormal;
        String text = key[_kKeyText];
        double align = double.parse(key[_kKeyAlign] ?? '0.5');
        return _createTextKey(text, width, action, align, type, visualType);
    }
  }

  Widget _createSpacerKey(int width) => SpacerKey(flex: width);

  Widget _createTextKey(String text, int width, String action, double align,
      String type, String visualType) {
    TextStyle style = (type == _kKeyTypeSuggestion)
        ? _kSuggestionTextStyle
        : (visualType == _kKeyVisualTypeActionText)
            ? _kDefaultTextStyle.copyWith(
                fontSize: _kGoKeyTextSize,
                fontWeight: FontWeight.bold,
              )
            : _kDefaultTextStyle;
    bool isSuggestion = type == _kKeyTypeSuggestion;
    GlobalKey<TextKeyState> key = isSuggestion ? GlobalKey() : null;
    TextKey textKey = TextKey(
      isSuggestion ? '' : text,
      style: style,
      height: isSuggestion ? _kSuggestionRowHeight : constants.keyHeight,
      horizontalAlign: align,
      verticalAlign: 0.5,
      key: key,
      flex: width,
      onText: (String text) {
        VoidCallback actionCallback = _getAction(action);
        if (actionCallback != null) {
          actionCallback();
        } else if (isSuggestion) {
          _onSuggestion(text);
        } else {
          _onText(text);
        }
      },
    );

    if (isSuggestion) {
      _suggestionKeys.add(key);
    }
    return textKey;
  }

  Widget _createImageKey(String imageUrl, int width, String action) => ImageKey(
        imageUrl: imageUrl,
        onKeyPressed: _getAction(action),
        height: constants.keyHeight,
        imageColor: _kContentColor,
        flex: width,
      );

  VoidCallback _getAction(String action) {
    switch (action) {
      case _kKeyActionEmitText:
        return null;
      case _kKeyActionDelete:
        return _onDeletePressed;
      case _kKeyActionSpace:
        return _onSpacePressed;
      case _kKeyActionGo:
        return _onGoPressed;
      default:
        return () => setState(() {
              _keyboardWidget = _keyboards[int.parse(action)];
            });
    }
  }

  void _onText(String text) {
    widget.onText?.call(text);
  }

  void _onSuggestion(String suggestion) {
    widget.onSuggestion?.call(suggestion);
  }

  void _onSpacePressed() {
    widget.onText?.call(' ');
  }

  void _onGoPressed() {
    widget.onGo?.call();
  }

  void _onDeletePressed() {
    widget.onDelete?.call();
  }
}
