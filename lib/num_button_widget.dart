import 'package:flutter/material.dart';

class NumButtonWidget extends StatelessWidget {
  const NumButtonWidget({
    @required this.onPressed,
    @required this.char,
    Key key,
  }) : super(key: key);

  final void Function(String char) onPressed;
  final String char;

  @override
  Widget build(BuildContext context) => FlatButton(
      height: 85,
      onPressed: () {
        onPressed(char);
      },
      child: Text(char));
}
