import 'package:flutter/material.dart';

import 'operators.dart';

class BinaryOperatorWidget extends StatelessWidget {
  const BinaryOperatorWidget({
    @required this.label,
    @required this.onPressed,
    @required this.op,
    Key key,
  }) : super(key: key);

  final String label;
  final BinaryOperator op;
  final Function(BinaryOperator op) onPressed;

  @override
  Widget build(BuildContext context) => FlatButton(
        shape: const ContinuousRectangleBorder(),
        color: Colors.grey[800],
        onPressed: () {
          onPressed(op);
        },
        child: Text(
          label,
          style: const TextStyle(color: Colors.lightBlueAccent),
        ),
      );
}
