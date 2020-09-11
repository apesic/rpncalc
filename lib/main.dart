import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  runApp(RPNCalc());
}

class RPNCalc extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RPN Calc',
      theme: ThemeData(
        buttonTheme: ButtonThemeData(
          height: 60,
        ),
        textTheme: TextTheme(
          button: TextStyle(
            fontSize: 24,
          ),
        ),
        primarySwatch: Colors.orange,
        brightness: Brightness.dark,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AppHome(),
    );
  }
}

class AppHome extends StatefulWidget {
  AppHome({Key key}) : super(key: key);

  @override
  _AppHomeState createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> {
  String _current = "";
  bool _newItem = true;
  List<num> _stack = [];

  num _parseNum(s) {
    if (s == "") {
      return null;
    } else if (_current.contains(".")) {
      return double.parse(s);
    } else {
      return int.parse(s);
    }
  }

  void _pushStack(num n) {
    setState(() {
      _stack.insert(0, n);
      _newItem = true;
    });
  }

  void _applyOperator(Operator o) {
    if (_stack.length == 0) return;
    var fn = operations[o];
    var b = _parseNum(_current);
    if (b == null) {
      b = _stack.removeAt(0);
    }
    setState(() {
      var a = _stack.removeAt(0);
      var res = fn(a, b);
      _pushStack(res);
      _current = "";
    });
  }

  void _appendCurrent(String c) {
    setState(() {
      if (_newItem) {
        _current = c;
        _newItem = false;
      } else if (c != "." || !_current.contains(".")) {
        _current += c;
      }
    });
  }

  void _backspaceCurrent() {
    setState(() {
      if (_current != "") {
        _current = _current.substring(0, _current.length - 1);
      }
    });
  }

  void _reverseSign() {
    setState(() {
      if (_current != "") {
        if (_current.startsWith("-")) {
          _current = _current.substring(1, _current.length);
        } else {
          _current = "-" + _current;
        }
      } else if (_stack.length > 0) {
        _stack[0] = -1 * _stack[0];
      }
    });
  }

  void _inverse() {
    setState(() {
      num n;
      if (_current != "") {
        n = _parseNum(_current);
        if (n != 0) {
          _current = (1 / n).toString();
        }
      } else if (_stack.length > 0) {
        n = _stack[0];
        if (n != 0) {
          _stack[0] = 1 / n;
        }
      }
    });
  }

  void _percent() {
    num a = 1, b, res;
    setState(() {
      if (_current != "") {
        b = _parseNum(_current);
      } else if (_stack.length > 0) {
        b = _stack.removeAt(0);
      }
      if (_stack.length > 0) {
        a = _stack[0];
      }
      res = (b / 100) * a;
      _pushStack(res);
      _current = "";
    });
  }

  void _clearCurrent() {
    setState(() {
      _newItem = true;
      if (_current == "") {
        _clearStack();
      }
      _current = "";
    });
  }

  void _clearStack() {
    setState(() {
      _stack = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          // Stack
          Container(
            color: Colors.grey[500],
            height: 150,
            padding: const EdgeInsets.all(5),
            margin: MediaQuery.of(context).padding,
            child: ListView.builder(
                shrinkWrap: true,
                reverse: true,
                itemCount: _stack.length,
                itemBuilder: (context, index) {
                  var n = _stack[index];
                  return Text('$n',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.robotoMono(
                        textStyle: TextStyle(
                          fontSize: 24,
                        ),
                      ));
                }),
          ),
          // Current item
          Container(
            color: Colors.grey[800],
            constraints:
                BoxConstraints.expand(width: double.infinity, height: 40),
            padding: const EdgeInsets.all(5),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$_current',
                textAlign: TextAlign.right,
                style: GoogleFonts.robotoMono(
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: "Roboto Mono",
                    fontSize: 24,
                    color: (_newItem ? Colors.orangeAccent : Colors.white),
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: Table(
                  defaultColumnWidth: FlexColumnWidth(0.5),
                  children: [
                    TableRow(children: [
                      FlatButton(
                        onPressed: _reverseSign,
                        child: Text("±"),
                      ),
                      FlatButton(
                        onPressed: _inverse,
                        child: Text("1/X"),
                      ),
                      FlatButton(
                        onPressed: _percent,
                        child: Text("％"),
                      ),
                    ]),
                    TableRow(children: [
                      FlatButton(
                        onPressed: () {
                          _appendCurrent("7");
                        },
                        child: Text("7"),
                      ),
                      FlatButton(
                        onPressed: () {
                          _appendCurrent("8");
                        },
                        child: Text("8"),
                      ),
                      FlatButton(
                        onPressed: () {
                          _appendCurrent("9");
                        },
                        child: Text("9"),
                      ),
                    ]),
                    TableRow(children: [
                      FlatButton(
                        onPressed: () {
                          _appendCurrent("4");
                        },
                        child: Text("4"),
                      ),
                      FlatButton(
                        onPressed: () {
                          _appendCurrent("5");
                        },
                        child: Text("5"),
                      ),
                      FlatButton(
                        onPressed: () {
                          _appendCurrent("6");
                        },
                        child: Text("6"),
                      ),
                    ]),
                    TableRow(children: [
                      FlatButton(
                        onPressed: () {
                          _appendCurrent("1");
                        },
                        child: Text("1"),
                      ),
                      FlatButton(
                        onPressed: () {
                          _appendCurrent("2");
                        },
                        child: Text("2"),
                      ),
                      FlatButton(
                        onPressed: () {
                          _appendCurrent("3");
                        },
                        child: Text("3"),
                      ),
                    ]),
                    TableRow(children: [
                      FlatButton(
                        onPressed: () {
                          _appendCurrent("0");
                        },
                        child: Text("0"),
                      ),
                      FlatButton(
                        onPressed: () {
                          _appendCurrent(".");
                        },
                        child: Text("."),
                      ),
                      FlatButton.icon(
                        onPressed: _backspaceCurrent,
                        icon: Icon(Icons.backspace),
                        label: Text(""),
                      ),
                    ]),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  FlatButton(
                    child: Text(_current == "" ? "AC" : "C"),
                    onPressed: _current == "" ? _clearStack : _clearCurrent,
                    onLongPress: () {
                      _clearCurrent();
                      _clearStack();
                    },
                  ),
                  FlatButton(
                    child: Text("÷"),
                    onPressed: () {
                      _applyOperator(Operator.divide);
                    },
                  ),
                  FlatButton(
                    child: Text("×"),
                    onPressed: () {
                      _applyOperator(Operator.multiply);
                    },
                  ),
                  FlatButton(
                    child: Text("−"),
                    onPressed: () {
                      _applyOperator(Operator.subtract);
                    },
                  ),
                  FlatButton(
                    child: Text("+"),
                    onPressed: () {
                      _applyOperator(Operator.add);
                    },
                  ),
                  FlatButton.icon(
                    color: Colors.orangeAccent,
                    icon: Icon(Icons.keyboard_return),
                    label: Text(""),
                    onPressed: () {
                      var n = _parseNum(_current);
                      if (n != null) {
                        _pushStack(n);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

typedef Operation = num Function(num a, num b);

enum Operator { add, subtract, multiply, divide }

var operations = <Operator, Operation>{
  Operator.add: (num a, b) {
    return a + b;
  },
  Operator.subtract: (num a, b) {
    return a - b;
  },
  Operator.multiply: (num a, b) {
    return a * b;
  },
  Operator.divide: (num a, b) {
    return a / b;
  },
};
