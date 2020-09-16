import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'stack_item.dart';

class StackItemWidget extends StatelessWidget {
  const StackItemWidget({
    @required this.onPaste,
    @required this.item,
    @required this.color,
    @required this.onRemove,
    Key key,
  }) : super(key: key);

  final void Function(num newVal) onPaste;
  final void Function() onRemove;
  final StackItem item;
  final Color color;

  @override
  Widget build(BuildContext context) => InkWell(
        onLongPress: () {
          HapticFeedback.lightImpact();
          showMenu<String>(
            context: context,
            // TODO(alexei): position relative to selected item.
            position: const RelativeRect.fromLTRB(100, 100, 100, 100),
            items: [
              PopupMenuItem<String>(
                enabled: !item.isEmpty,
                value: 'copy',
                child: Text(
                  'Copy $item',
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
            switch (value) {
              case 'copy':
                Clipboard.setData(ClipboardData(text: item.toString())).then(
                    // XXX get snackbar to match theme colors
                    (_) => Scaffold.of(context).showSnackBar(const SnackBar(
                          content: Text('Copied to clipboard'),
                          duration: Duration(seconds: 1),
                        )));
                break;
              case 'paste':
                num newVal;
                Clipboard.getData('text/plain').then((value) {
                  final s = value.text;
                  try {
                    if (s.contains('.')) {
                      newVal = double.parse(s);
                    } else {
                      newVal = int.parse(s);
                    }
                  } on FormatException catch (_) {
                    Scaffold.of(context).showSnackBar(const SnackBar(
                      content: Text('Clipboard is not a valid number'),
                      duration: Duration(seconds: 1),
                    ));
                    return 0;
                  }
                  onPaste(newVal);
                });
                break;
              case 'remove':
                onRemove();
                break;
            }
          });
        },
        child: Text('$item',
            textAlign: TextAlign.right,
            style: GoogleFonts.robotoMono(
              textStyle: TextStyle(fontSize: 24, color: color),
            )),
      );
}
