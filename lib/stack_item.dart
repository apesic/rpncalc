import 'dart:developer';

import 'package:characters/characters.dart';
import 'package:decimal/decimal.dart';
import 'package:rational/rational.dart';

abstract class StackItem {
  final Rational value = Rational.zero;
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

  Rational _parseNum(String s) {
    final r = Rational.tryParse(s);
    if (r == null) {
      log('Error parsing number $s');
      return Rational.zero;
    }
    return r;
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
  String toRawString() => _value.toDecimal(scaleOnInfinitePrecision: StackItem.maxPrecision).toString();

  @override
  String toString() {
    String s;
    if (!_value.hasFinitePrecision) {
      s = toRawString();
      if (s.length <= StackItem.maxDisplayLength) {
        return s;
      }
      return '${s.substring(0, StackItem.maxDisplayLength)}…';
    }
    final d = _value.toDecimal();
    s = d.toString();
    if (s.length <= StackItem.maxDisplayLength) {
      return s;
    }
    // XXX keep this?
    // - remove trailing zeros
    return d.toStringAsExponential(StackItem.minPrecision);
  }
}
