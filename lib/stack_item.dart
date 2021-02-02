import 'dart:developer';

import 'package:characters/characters.dart';
import 'package:rational/rational.dart';

abstract class StackItem {
  final Rational value = Rational.zero;
  final bool isEmpty = false;
  static const int maxLength = 18;

  // The unformatted characters that represent the value.
  String toRawString();
}

class EditableItem implements StackItem {
  EditableItem(StackItem v) {
    _chars = v.toString();
  }
  EditableItem.blank();

  String _chars = '';
  bool isEdited = false;

  Rational _parseNum(String s) {
    try {
      if (s == '') {
        return Rational.zero;
      }
      return Rational.parse(s);
    } on FormatException catch (e) {
      log('Error parsing number $s: $e');
      return Rational.zero;
    }
  }

  @override
  Rational get value => _parseNum(_chars);

  @override
  bool get isEmpty => _chars.isEmpty;

  void appendChar(String c) {
    if (!isEdited) {
      _chars = c;
      isEdited = true;
      return;
    }
    if (c == '.' && _chars.contains('.')) {
      return;
    }
    _chars += c;
  }

  void removeChar() {
    isEdited = true;
    _chars = _chars.characters.skipLast(1).toString();
  }

  @override
  String toRawString() => _chars;

  @override
  String toString() => _chars;

  RealizedItem realize() {
    final v = value;
    assert(v != null, 'Value should not be null');
    return RealizedItem(v);
  }
}

class RealizedItem implements StackItem {
  const RealizedItem(this._value);

  final Rational _value;

  @override
  bool get isEmpty => false;

  @override
  Rational get value => _value;

  @override
  String toRawString() => _value?.toDecimalString() ?? '';

  @override
  String toString() {
    if (_value == null) {
      return '';
    }

    final s = _value.toDecimalString();
    if (s.length <= StackItem.maxLength) {
      return s;
    }
    return _value.toStringAsExponential(StackItem.maxLength - 10);
  }
}
