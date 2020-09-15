import 'dart:developer';

import 'package:characters/characters.dart';

abstract class StackItem {
  final num value = 0;
  final bool isEmpty = false;
}

class EditableItem implements StackItem {
  EditableItem(StackItem v) {
    _chars = v.toString();
  }
  EditableItem.blank();

  String _chars = '';
  bool isEdited = false;

  num _parseNum(String s) {
    try {
      if (s == '') {
        return 0;
      } else if (s.contains('.')) {
        return double.parse(s);
      } else {
        return int.parse(s);
      }
    } on FormatException catch (e) {
      log('Error parsing number $s - $e');
      return 0;
    }
  }

  @override
  num get value => _parseNum(_chars);

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
  String toString() => _chars;

  RealizedItem realize() {
    final v = value;
    assert(v != null, 'Value should not be null');
    return RealizedItem(v);
  }
}

class RealizedItem implements StackItem {
  const RealizedItem(this._value);

  final num _value;
  @override
  bool get isEmpty => false;
  @override
  num get value => _value;

  @override
  String toString() => _value?.toString() ?? '';
}
