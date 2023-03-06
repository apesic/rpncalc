import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rational/rational.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'binary_operator_widget.dart';
import 'num_button_widget.dart';
import 'operators.dart';
import 'rpn_stack.dart';
import 'stack_item.dart';
import 'stack_item_widget.dart';

const appName = 'RPNcalc';

void main() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/LICENSE.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  runApp(const RpnCalc());
}

class RpnCalc extends StatelessWidget {
  const RpnCalc({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              shape: const ContinuousRectangleBorder(),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 24),
            ),
          ),
          primarySwatch: Colors.purple,
          brightness: Brightness.dark,
          snackBarTheme: SnackBarThemeData(
            backgroundColor: Colors.grey[800],
            contentTextStyle: const TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity),
      home: const AppHome());
}

class AppHome extends StatefulWidget {
  const AppHome({Key? key}) : super(key: key);

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

  void _handleDrop() {
    _setStateWithUndo(() {
      HapticFeedback.lightImpact();
      _stack.drop();
    });
  }

  void _applyBinaryOperation(BinaryOperator op) {
    _setStateWithUndo(() {
      HapticFeedback.lightImpact();
      _stack.applyBinaryOperation(op);
    });
  }

  void _onPaste(int index, Rational newVal) {
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
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 2,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        // Stack
                        Expanded(
                          child: ClipRect(
                            child: Container(
                              color: Colors.grey[500],
                              padding: const EdgeInsets.all(5),
                              child: ListView.builder(
                                shrinkWrap: true,
                                reverse: true,
                                itemCount: _stack.length,
                                itemBuilder: (context, index) {
                                  final item = _stack[index];
                                  Color? color = Colors.white;
                                  if (index == 0) {
                                    if (!_stack.appendNew && item is RealizedItem ||
                                        (item is EditableItem && !item.isEdited)) {
                                      color = Colors.grey[800];
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
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showAboutPage(context),
                    )
                  ],
                ),
              ),
              // Buttons
              Flexible(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.grey[700],
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              _setStateWithUndo(_stack.swap);
                            },
                            child: const Icon(
                              Icons.swap_vert_sharp,
                              size: 22,
                              semanticLabel: 'Swap',
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.grey[700],
                              textStyle: const TextStyle(fontSize: 18),
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              _setStateWithUndo(_stack.rotateUp);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text('R'),
                                Icon(
                                  Icons.arrow_upward_sharp,
                                  size: 16,
                                )
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                                backgroundColor: Colors.grey[700],
                                textStyle: const TextStyle(fontSize: 18)),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              _setStateWithUndo(_stack.rotateDown);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text('R'),
                                Icon(
                                  Icons.arrow_downward_sharp,
                                  size: 16,
                                )
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                (states) {
                                  if (states.contains(MaterialState.disabled)) {
                                    return Colors.blueGrey[700]!;
                                  }
                                  return Colors.grey[600]!;
                                },
                              ),
                            ),
                            onPressed: _undoBuffer.isEmpty ? null : _undo,
                            child: const Icon(Icons.undo),
                          ),
                        ),
                      ]),
                    ),
                    // Numpad
                    Expanded(
                      flex: 10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                              flex: 3,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border:
                                            Border(bottom: BorderSide(color: Colors.grey[700]!)),
                                      ),
                                      child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Expanded(
                                              child: TextButton(
                                                onPressed: () {
                                                  HapticFeedback.selectionClick();
                                                  _setStateWithUndo(_stack.reverseSign);
                                                },
                                                child: const Text(
                                                  '±',
                                                  style: TextStyle(fontSize: 20),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: TextButton(
                                                onPressed: () {
                                                  _applyBinaryOperation(BinaryOperator.exponent);
                                                },
                                                child: const Text(
                                                  'yˣ',
                                                  style: TextStyle(fontSize: 20),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: TextButton(
                                                onPressed: () {
                                                  HapticFeedback.selectionClick();
                                                  _setStateWithUndo(_stack.percent);
                                                },
                                                child: const Text(
                                                  '％',
                                                  style: TextStyle(fontSize: 20),
                                                ),
                                              ),
                                            ),
                                          ]),
                                    ),
                                  ),
                                  for (final row in [
                                    [7, 8, 9],
                                    [4, 5, 6],
                                    [1, 2, 3]
                                  ])
                                    Expanded(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          for (final n in row)
                                            Expanded(
                                              child: NumButtonWidget(
                                                char: n.toString(),
                                                onPressed: _handleAppend,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  Expanded(
                                    child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                              child: NumButtonWidget(
                                                  char: '0', onPressed: _handleAppend)),
                                          Expanded(
                                            child: NumButtonWidget(
                                              char: '.',
                                              onPressed: _handleAppend,
                                              fontSize: 30,
                                            ),
                                          ),
                                          Expanded(
                                            child: TextButton(
                                              onPressed: () {
                                                HapticFeedback.selectionClick();
                                                _setStateWithUndo(_stack.backspaceCurrent);
                                              },
                                              onLongPress: _handleDrop,
                                              child: const Icon(
                                                Icons.backspace,
                                                semanticLabel: 'Backspace',
                                              ),
                                            ),
                                          ),
                                        ]),
                                  )
                                ],
                              )),
                          // Operators
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.blueGrey[800],
                                    ),
                                    onPressed: (_stack.isEmpty || _stack.first!.isEmpty)
                                        ? _handleClearAll
                                        : _handleClear,
                                    onLongPress: _handleClearAll,
                                    child:
                                        Text(_stack.isEmpty || _stack.first!.isEmpty ? 'AC' : 'C'),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: BinaryOperatorWidget(
                                      label: '÷',
                                      op: BinaryOperator.divide,
                                      onPressed: _applyBinaryOperation),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: BinaryOperatorWidget(
                                      label: '×',
                                      op: BinaryOperator.multiply,
                                      onPressed: _applyBinaryOperation),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: BinaryOperatorWidget(
                                      label: '−',
                                      op: BinaryOperator.subtract,
                                      onPressed: _applyBinaryOperation),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: BinaryOperatorWidget(
                                      label: '+',
                                      op: BinaryOperator.add,
                                      onPressed: _applyBinaryOperation),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.orangeAccent,
                                      foregroundColor: Colors.black,
                                    ),
                                    onPressed: _handleAdvance,
                                    child: const Icon(
                                      Icons.keyboard_return,
                                      size: 35,
                                      semanticLabel: 'Enter',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
    applicationName: appName,
    applicationVersion: packageInfo.version,
    applicationLegalese: '© 2020 Alexei Pesic',
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 20),
        child: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: '$appName is a free, open-source calculator using ',
              ),
              TextSpan(
                text: 'Reverse Polish Notation',
                style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                recognizer: TapGestureRecognizer()
                  ..onTap = () async {
                    const url = 'https://en.wikipedia.org/wiki/Reverse_Polish_notation';
                    if (await canLaunchUrlString(url)) {
                      await launchUrlString(url);
                    }
                  },
              ),
              const TextSpan(
                text:
                    '.\n\nTo leave feedback, submit a bug report, or view the source-code, see:\n',
              ),
              TextSpan(
                text: 'https://github.com/apesic/rpncalc',
                style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                recognizer: TapGestureRecognizer()
                  ..onTap = () async {
                    const url = 'https://github.com/apesic/rpncalc';
                    if (await canLaunchUrlString(url)) {
                      await launchUrlString(url);
                    }
                  },
              ),
              const TextSpan(
                text: '\n\n$appName is distributed under the GPL-3.0 License.',
              ),
            ],
          ),
        ),
      )
    ],
  );
}
