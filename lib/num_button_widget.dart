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
  Widget build(BuildContext context) => ButtonTheme(
      height: 85,
      child: FlatButton(
          onPressed: () {
            onPressed(char);
          },
          child: Text(char)));
}
