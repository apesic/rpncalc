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
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: () => onPressed(char),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.grey[900],
    ),
    child: Text( char, style: const TextStyle(
      color: Colors.white,
    )),
  );
}
