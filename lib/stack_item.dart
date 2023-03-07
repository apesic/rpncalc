import 'dart:developer';

import 'package:characters/characters.dart';
import 'package:statistics/statistics.dart';

abstract class StackItem {
  final DynamicNumber value = DynamicInt.zero;
  final bool isEmpty = false;
  static const int maxPrecision = 8;
  static const int minPrecision = 3;
  static const int maxDisplayLength = 10;

  // The unformatted characters that represent the value.
  String toRawString();
}

class EditableItem implements StackItem {
  EditableItem(StackItem? v) {
    _chars = v.toString();
  }
  EditableItem.blank();

  String _chars = '';
  bool isEdited = false;

  DynamicNumber _parseNum(String s) {
    final r = DynamicNumber.tryParse(s);
    if (r is DynamicNumber) {
      return r;
    }
    log('Error parsing number $s');
    return DynamicInt.zero;
  }

  @override
  DynamicNumber get value => _parseNum(_chars);

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

  RealizedItem realize() => RealizedItem(value);
}

class RealizedItem implements StackItem {
  const RealizedItem(this._value);

  final DynamicNumber _value;

  @override
  bool get isEmpty => false;

  @override
  DynamicNumber get value => _value;

  @override
  String toRawString() => _value.toStringStandard();

  // XXX improve formatting
  @override
  String toString() => _value.toString();
}
