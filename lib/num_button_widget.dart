import 'package:flutter/material.dart';

class NumButtonWidget extends StatelessWidget {
  const NumButtonWidget({
    required this.onPressed,
    required this.char,
    this.fontSize = 22,
    Key? key,
  }) : super(key: key);

  final void Function(String char) onPressed;
  final String char;
  final double fontSize;

  @override
  Widget build(BuildContext context) => TextButton(
      onPressed: () {
        onPressed(char);
      },
      child: Text(
        char,
        style: TextStyle(fontSize: fontSize),
      ));
}
