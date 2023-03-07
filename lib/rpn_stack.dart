import 'package:statistics/statistics.dart';

import 'operators.dart';
import 'stack_item.dart';

class RpnStack {
  RpnStack() {
    stack.add(EditableItem.blank());
  }

  RpnStack.clone(RpnStack source) {
    for (final o in source.stack) {
      StackItem clone;
      if (o is EditableItem) {
        clone = EditableItem(o);
      } else if (o is RealizedItem) {
        clone = RealizedItem(o.value);
      } else {
        throw StateError('unknown item type for $o');
      }
      stack.add(clone);
    }
    appendNew = source.appendNew;
  }

  final List<StackItem> stack = [];

  // When true, the next append operation should create a new item.
  bool appendNew = false;

  int get length => stack.length;

  StackItem get first => stack[0];

  bool get isEmpty => length == 1 && first.isEmpty;

  StackItem? operator [](int i) => stack[i];

  void _realizeStack() {
    final first = this.first;
    if (first is EditableItem) {
      if (first.isEmpty) {
        _pop();
      } else {
        stack[0] = first.realize();
      }
    }
    assert(stack.every((e) => e is RealizedItem), 'Every element in stack should be realized.');
  }

  void push(StackItem v) {
    stack.insert(0, v);
  }

  StackItem? _pop() {
    if (stack.isNotEmpty) {
      return stack.removeAt(0);
    }
    return null;
  }

  void drop() {
    _pop();
    if (stack.isEmpty) {
      push(EditableItem.blank());
    }
  }

  void advance() {
    final current = stack.first;
    _realizeStack();
    push(EditableItem(current));
  }

  void swap() {
    if (stack.length < 2) {
      return;
    }
    _realizeStack();
    final first = stack[0];
    final second = stack[1];
    stack[0] = second;
    stack[1] = first;
  }

  void rotateDown() {
    if (stack.length < 2) {
      return;
    }
    _realizeStack();
    final first = _pop()!;
    stack.add(first);
  }

  void rotateUp() {
    if (stack.length < 2) {
      return;
    }
    _realizeStack();
    final last = stack.removeAt(stack.length - 1);
    push(last);
  }


  /// Attempts to apply the provided operator to the two top-most items in the
  /// stack. Returns a boolean indicating if the operation was applied
  /// successfully.
  bool applyBinaryOperation(BinaryOperator o) {
    if (stack.length < 2) {
      return false;
    }
    if (o == BinaryOperator.divide && stack.first.value.isZero) {
      // Divide by zero error;
      return false;
    }
    appendNew = true;
    // If the first item is editable and empty, remove and skip the operation.
    if (first.isEmpty) {
      _pop();
      return false;
    }
    _realizeStack();
    final fn = operations[o]!;
    final b = _pop()!.value;
    final a = _pop()!.value;
    final res = fn(a, b);
    push(RealizedItem(res));
    return true;
  }

  void reverseSign() {
    final v = first.value;
    final res = v * DynamicInt.negativeOne;
    if (res is DynamicNumber) {
      stack[0] = RealizedItem(res);
    }
  }

  void percent() {
    DynamicNumber res;
    switch (stack.length) {
      case 0:
        return;
      case 1:
        res = _pop()!.value / DynamicInt.fromInt(100);
        break;
      default:
        res = (_pop()!.value / DynamicInt.fromInt(100)) * _pop()!.value;
        break;
    }
    push(RealizedItem(res));
    appendNew = true;
  }

  void clearCurrent() {
    stack[0] = EditableItem.blank();
  }

  void appendCurrent(String c) {
    final first = this.first;
    EditableItem updated;
    // Append new editable item.
    if (first is EditableItem) {
      // Update existing item.
      first.appendChar(c);
    } else if (appendNew) {
      _realizeStack();
      appendNew = false;
      updated = EditableItem.blank()..appendChar(c);
      push(updated);
    } else if (first is RealizedItem) {
      // Replace realized item with new editable item.
      updated = EditableItem.blank()..appendChar(c);
      stack[0] = updated;
    }
  }

  void backspaceCurrent() {
    final first = this.first;
    if (first is RealizedItem) {
      stack[0] = EditableItem(first)..removeChar();
    } else if (first is EditableItem) {
      first.removeChar();
    }
  }

  void clearAll() {
    stack.clear();
    push(EditableItem.blank());
  }

  void remove(int index) {
    // Ensure that we don't leave an empty stack after removal.
    if (stack.length == 1) {
      return clearAll();
    }
    stack.removeAt(index);
  }

  void replaceAt(int index, DynamicNumber newVal) {
    stack[index] = RealizedItem(newVal);
  }
}
