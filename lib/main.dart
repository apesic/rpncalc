import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';

import 'binary_operator_widget.dart';
import 'num_button_widget.dart';
import 'operators.dart';
import 'stack_item.dart';
import 'stack_item_widget.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/LICENSE.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  runApp(const RpnCalc());
}

class RpnStack {
  RpnStack() {
    stack.add(EditableItem.blank());
  }
  RpnStack.clone(RpnStack source) {
    // XXX need to deep copy items
    stack.addAll(source.stack);
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
    assert(stack.every((element) => element is RealizedItem),
        'Every element in stack should be realized.');
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

  void advance() {
    _realizeStack();
    push(EditableItem(stack[0]));
  }

  void drop() {
    if (stack.length == 1) {
      stack[0] = EditableItem.blank();
    } else {
      _pop();
    }
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
    // If the first item is editable and empty , remove and skip the operation.
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

class RpnCalc extends StatelessWidget {
  const RpnCalc({Key key}) : super(key: key);
  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'RPN Calc',
      theme: ThemeData(
          buttonTheme: const ButtonThemeData(height: 60),
          textTheme: const TextTheme(button: TextStyle(fontSize: 24)),
          primarySwatch: Colors.orange,
          brightness: Brightness.dark,
          visualDensity: VisualDensity.adaptivePlatformDensity),
      home: const AppHome());
}

class AppHome extends StatefulWidget {
  const AppHome({Key key}) : super(key: key);

  @override
  _AppHomeState createState() => _AppHomeState();
}

const maxUndoBuffer = 5;

class _AppHomeState extends State<AppHome> {
  RpnStack _stack = RpnStack();
  // TODO improve undo implementation.
  final List<RpnStack> _undoBuffer = [];

//  void _onReorder(int oldIndex, newIndex) {
//    setState(() {
//      if (newIndex > oldIndex) {
//        newIndex -= 1;
//      }
//      final num item = _stack.removeAt(oldIndex);
//      _stack.insert(newIndex, item);
//    });
//  }

  void _setStateWithUndo(Function f) {
    setState(() {
      final currentState = RpnStack.clone(_stack);
      if (_undoBuffer.length > maxUndoBuffer) {
        _undoBuffer.removeLast();
      }
      _undoBuffer.insert(0, currentState);
      f();
    });
  }

  void _undo() {
    setState(() {
      if (_undoBuffer.isEmpty) {
        return;
      }
      final prevState = _undoBuffer.removeAt(0);
      _stack = prevState;
    });
  }

  void _handleAppend(String c) {
    setState(() {
      HapticFeedback.selectionClick();
      _stack.appendCurrent(c);
    });
  }

  void _handleAdvance() {
    _setStateWithUndo(() {
      HapticFeedback.heavyImpact();
      _stack.advance();
    });
  }

  void _handleClearAll() {
    _setStateWithUndo(() {
      HapticFeedback.mediumImpact();
      _stack.clearAll();
    });
  }

  void _handleClear() {
    _setStateWithUndo(() {
      HapticFeedback.selectionClick();
      _stack.clearCurrent();
    });
  }

  void _applyBinaryOperation(BinaryOperator op) {
    _setStateWithUndo(() {
      HapticFeedback.lightImpact();
      _stack.applyBinaryOperation(op);
    });
  }

  void _onPaste(int index, num newVal) {
    _setStateWithUndo(() {
      _stack.replaceAt(index, newVal);
    });
  }

  void _onRemove(int index) {
    _setStateWithUndo(() {
      _stack.remove(index);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Stack(
                children: [
                  Column(
                    children: [
                      // Stack
                      Ink(
                        color: Colors.grey[500],
                        height: 240,
                        padding: const EdgeInsets.all(5),
                        child: ListView.builder(
                          shrinkWrap: true,
                          reverse: true,
                          itemCount: _stack.length,
                          itemBuilder: (context, index) {
                            final item = _stack[index];
                            // XXX improve use of colors; pull this logic out to method
                            var color = Colors.white;
                            if (index == 0) {
                              if (!_stack.appendNew && item is RealizedItem ||
                                  (item is EditableItem && !item.isEdited)) {
                                color = Colors.grey[600];
                              } else if (!_stack.appendNew) {
                                color = Colors.orangeAccent;
                              }
                            }
                            return StackItemWidget(
                              onPaste: (newVal) => _onPaste(index, newVal),
                              onRemove: () => _onRemove(index),
                              item: item,
                              color: color,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert_sharp),
                    onPressed: () => _showAboutPage(context),
                  )
                ],
              ),
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Numpad
                  Expanded(
                    flex: 4,
                    child: Table(
                      defaultColumnWidth: const FlexColumnWidth(0.5),
                      children: [
                        TableRow(
                          children: [
                            FlatButton(
                              shape: const ContinuousRectangleBorder(),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                _setStateWithUndo(_stack.swap);
                              },
                              height: 40,
                              color: Colors.grey[700],
                              child: const Text(
                                '⇅',
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                            FlatButton(
                              shape: const ContinuousRectangleBorder(),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                _setStateWithUndo(_stack.rotateUp);
                              },
                              color: Colors.grey[700],
                              height: 40,
                              child: const Text(
                                'R↑',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                            FlatButton(
                              shape: const ContinuousRectangleBorder(),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                _setStateWithUndo(_stack.rotateDown);
                              },
                              color: Colors.grey[700],
                              height: 40,
                              child: const Text(
                                'R↓',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ],
                        ),
                        TableRow(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[800]),
                            ),
                          ),
                          children: [
                            FlatButton(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                _setStateWithUndo(_stack.reverseSign);
                              },
                              child: const Text(
                                '±',
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                            FlatButton(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                _setStateWithUndo(_stack.inverse);
                              },
                              child: const Text(
                                '1/X',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                            FlatButton(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                _setStateWithUndo(_stack.percent);
                              },
                              child: const Text(
                                '％',
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                          ],
                        ),
                        TableRow(children: [
                          NumButtonWidget(char: '7', onPressed: _handleAppend),
                          NumButtonWidget(char: '8', onPressed: _handleAppend),
                          NumButtonWidget(char: '9', onPressed: _handleAppend),
                        ]),
                        TableRow(children: [
                          NumButtonWidget(char: '4', onPressed: _handleAppend),
                          NumButtonWidget(char: '5', onPressed: _handleAppend),
                          NumButtonWidget(char: '6', onPressed: _handleAppend),
                        ]),
                        TableRow(children: [
                          NumButtonWidget(char: '1', onPressed: _handleAppend),
                          NumButtonWidget(char: '2', onPressed: _handleAppend),
                          NumButtonWidget(char: '3', onPressed: _handleAppend),
                        ]),
                        TableRow(children: [
                          NumButtonWidget(char: '0', onPressed: _handleAppend),
                          NumButtonWidget(char: '.', onPressed: _handleAppend),
                          FlatButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              _setStateWithUndo(_stack.backspaceCurrent);
                            },
                            onLongPress: _handleClear,
                            child: const Icon(
                              Icons.backspace,
                              semanticLabel: 'Backspace',
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  // Operators
                  Expanded(
                    flex: 0,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 40,
                          child: FlatButton(
                            shape: const ContinuousRectangleBorder(),
                            color: Colors.blueGrey[600],
                            onPressed: _undoBuffer.isEmpty ? null : _undo,
                            height: 30,
                            disabledColor: Colors.blueGrey[700],
                            child: const Icon(Icons.undo),
                          ),
                        ),
                        FlatButton(
                          shape: const ContinuousRectangleBorder(),
                          color: Colors.blueGrey[800],
                          height: 64,
                          onPressed: (_stack.isEmpty || _stack.first.isEmpty)
                              ? _handleClearAll
                              : _handleClear,
                          onLongPress: _handleClearAll,
                          child: Text(_stack.isEmpty || _stack.first.isEmpty
                              ? 'AC'
                              : 'C'),
                        ),
                        BinaryOperatorWidget(
                            label: '÷',
                            op: BinaryOperator.divide,
                            onPressed: _applyBinaryOperation),
                        BinaryOperatorWidget(
                            label: '×',
                            op: BinaryOperator.multiply,
                            onPressed: _applyBinaryOperation),
                        BinaryOperatorWidget(
                            label: '−',
                            op: BinaryOperator.subtract,
                            onPressed: _applyBinaryOperation),
                        BinaryOperatorWidget(
                            label: '+',
                            op: BinaryOperator.add,
                            onPressed: _applyBinaryOperation),
                        FlatButton(
                          shape: const ContinuousRectangleBorder(),
                          height: 100,
                          color: Colors.orangeAccent,
                          onPressed: _handleAdvance,
                          child: const Icon(
                            Icons.keyboard_return,
                            size: 34,
                            semanticLabel: 'Enter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

Future<void> _showAboutPage(BuildContext context) async {
  final packageInfo = await PackageInfo.fromPlatform();
  return showAboutDialog(
    context: context,
    applicationIcon: const Image(
      image: AssetImage('assets/icon/icon.png'),
      height: 75,
    ),
    applicationName: packageInfo.appName,
    applicationVersion: packageInfo.version,
    applicationLegalese: '© 2020 Alexei Pesic',
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 20),
        child: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'RPNcalc is a free, open-source calculator using ',
              ),
              TextSpan(
                text: 'Reverse Polish Notation',
                style: TextStyle(color: Theme.of(context).accentColor),
                recognizer: TapGestureRecognizer()
                  ..onTap = () async {
                    const url =
                        'https://en.wikipedia.org/wiki/Reverse_Polish_notation';
                    if (await canLaunch(url)) {
                      await launch(url);
                    }
                  },
              ),
              const TextSpan(
                text:
                    '.\n\nTo leave feedback, submit a bug report, or view the '
                    'source-code, see:\n',
              ),
              TextSpan(
                text: 'https://github.com/apesic/rpncalc',
                style: TextStyle(color: Theme.of(context).accentColor),
                recognizer: TapGestureRecognizer()
                  ..onTap = () async {
                    const url = 'https://github.com/apesic/rpncalc';
                    if (await canLaunch(url)) {
                      await launch(url);
                    }
                  },
              ),
              const TextSpan(
                text: '\n\nRPNcalc is distributed under the GPL-3.0 License.',
              ),
            ],
          ),
        ),
      )
    ],
  );
}
