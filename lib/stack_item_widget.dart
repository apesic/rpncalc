import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:statistics/statistics.dart';

import 'stack_item.dart';

class StackItemWidget extends StatefulWidget {
  const StackItemWidget({
    required this.onPaste,
    required this.item,
    required this.color,
    required this.onRemove,
    Key? key,
  }) : super(key: key);

  final void Function(DynamicNumber newVal) onPaste;
  final void Function() onRemove;
  final StackItem item;
  final Color color;

  @override
  StackItemWidgetState createState() => StackItemWidgetState();
}

class StackItemWidgetState extends State<StackItemWidget> {
  var _highlighted = false;

  @override
  Widget build(BuildContext context) => Material(
        color: _highlighted ? Colors.grey[600] : Colors.transparent,
        child: InkWell(
          onLongPress: () {
            setState(() {
              _highlighted = true;
            });
            HapticFeedback.lightImpact();
            showMenu<String>(
              context: context,
              // TODO(alexei): position relative to selected item.
              position: const RelativeRect.fromLTRB(100, 100, 100, 100),
              items: [
                PopupMenuItem<String>(
                  enabled: !widget.item.isEmpty,
                  value: 'copy',
                  child: Text(
                    'Copy ${widget.item.toRawString()}',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'paste',
                  child: Text('Paste'),
                ),
                const PopupMenuItem<String>(
                  value: 'remove',
                  child: Text('Remove'),
                ),
              ],
            ).then((value) {
              setState(() {
                _highlighted = false;
              });
              switch (value) {
                case 'copy':
                  Clipboard.setData(ClipboardData(text: widget.item.toRawString())).then(
                    (_) => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    ),
                  );
                  break;
                case 'paste':
                  Clipboard.getData('text/plain').then((value) {
                    final s = value!.text!;
                    final newVal = DynamicNumber.tryParse(s);
                    if (newVal is DynamicNumber) {
                      widget.onPaste(newVal);
                      return 1;
                    }
                    // TODO(alexei): Refactor this to shared error handling.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Clipboard is not a valid number'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    return 0;
                  });
                  break;
                case 'remove':
                  widget.onRemove();
                  break;
              }
            });
          },
          child: IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(widget.item.toString(),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: GoogleFonts.robotoMono(
                        textStyle: TextStyle(fontSize: 32, color: widget.color),
                      )),
                ),
                if (widget.item is EditableItem)
                  const Carat()
                else
                  const Padding(padding: EdgeInsets.only(right: 2)),
              ],
            ),
          ),
        ),
      );
}

class Carat extends StatefulWidget {
  @override
  const Carat({Key? key}) : super(key: key);

  @override
  CaratState createState() => CaratState();
}

class CaratState extends State<Carat> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final duration = const Duration(milliseconds: 500);

  @override
  void initState() {
    _controller = AnimationController(
      duration: duration,
      reverseDuration: duration,
      vsync: this,
    )..repeat(reverse: true);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _controller,
        child: const VerticalDivider(
          indent: 2,
          endIndent: 2,
          thickness: 2,
          width: 2,
          color: Colors.white,
        ),
      );
}
