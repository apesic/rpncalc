import 'dart:developer';

import 'package:intl/intl.dart';
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
  EditableItem(StackItem v) {
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

  // Attempts to append the provided character to the
  // current value, and returns a boolean indicating
  // success.
  bool appendChar(String c) {
    if (!isEdited) {
      _chars = c;
      isEdited = true;
      return true;
    }
    if (c == '.' && _chars.contains('.')) {
      return false;
    }
    // Prevent leading zeros.
    if (c == '0' && _chars.length == 1 && _chars[0] == '0' ) {
      return false;
    }
    _chars += c;
    return true;
  }

  void removeChar() {
    if (isEmpty) {
      return;
    }
    isEdited = true;
    _chars = _chars.substring(0,_chars.length-1);
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

  @override
  String toString() => _formatStackItem(_value);
}

final NumberFormat sciNotationFormatter = NumberFormat('0.##########E0');
final Decimal maxDisplaySize = Decimal.fromNum(1e10);
final Decimal minDisplaySize = Decimal.fromNum(1e-8);

/// Returns a human-friendly format of the value. Values
/// are formatted in scientific notation if they are
/// extremely large or small.
String _formatStackItem(DynamicNumber v) {
  if (!v.isZero && (v <= minDisplaySize || v >= maxDisplaySize)) {
    return sciNotationFormatter.format(v.toNum());
  }
  return v.toStringStandard();
}
