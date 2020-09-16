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
import 'rpn_stack.dart';
import 'stack_item.dart';
import 'stack_item_widget.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/LICENSE.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  runApp(const RpnCalc());
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

class _AppHomeState extends State<AppHome> {
  RpnStack _stack = RpnStack();
  // TODO(alexei): improve undo implementation.
  final List<RpnStack> _undoBuffer = [];
  static const maxUndoBuffer = 5;

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
      HapticFeedback.selectionClick();
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
