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

  StackItem operator [](int i) => stack[i];

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

  StackItem _pop() {
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
    final first = _pop();
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

  void applyBinaryOperation(BinaryOperator o) {
    if (stack.length < 2) {
      return;
    }
    appendNew = true;
    // If the first item is editable and empty, remove and skip the operation.
    if (first.isEmpty) {
      _pop();
      return;
    }
    _realizeStack();
    final fn = operations[o];
    final b = _pop().value;
    final a = _pop().value;
    final res = fn(a, b);
    push(RealizedItem(res));
  }

  void inverse() {
    final v = first.value;
    if (v != null && v != 0) {
      stack[0] = RealizedItem(1 / v);
    }
  }

  void reverseSign() {
    final v = first.value;
    stack[0] = RealizedItem(v * -1);
  }

  void percent() {
    num res;
    switch (stack.length) {
      case 0:
        return;
      case 1:
        res = _pop().value / 100;
        break;
      default:
        res = (_pop().value / 100) * _pop().value;
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
    stack.removeAt(index);
  }

  void replaceAt(int index, num newVal) {
    stack[index] = RealizedItem(newVal);
  }
}
