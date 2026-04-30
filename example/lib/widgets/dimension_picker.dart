import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class DimensionPicker extends StatefulWidget {
  const DimensionPicker({super.key});

  @override
  State<DimensionPicker> createState() => _DimensionPickerState();
}

class _DimensionPickerState extends State<DimensionPicker> {
  int selectedRow = 0;
  int selectedColumn = 0;
  int? hoveredRow;
  int? hoveredColumn;

  void _handleHighlight(int row, int column) {
    if (row != hoveredRow || column != hoveredColumn) {
      if (row < 0 || column < 0) {
        FocusScope.of(context).previousFocus();
      } else {
        setState(() {
          hoveredRow = row.clamp(0, 20);
          hoveredColumn = column.clamp(0, 20);
        });
      }
    }
  }

  void _handleSelect() {
    setState(() {
      selectedRow = hoveredRow ?? selectedRow;
      selectedColumn = hoveredColumn ?? selectedColumn;
      hoveredRow = null;
      hoveredColumn = null;
    });
    Actions.invoke(context, const DismissIntent());
  }

  @override
  Widget build(BuildContext context) {
    final callbackAction = CallbackAction<Intent>(
      onInvoke: (Object? intent) {
        _handleSelect();
        return null;
      },
    );
    hoveredRow = hoveredRow ?? selectedRow;
    hoveredColumn = hoveredColumn ?? selectedColumn;
    final int rowCount = clampDouble(hoveredRow! + 2, 5, 20).toInt();
    final int columnCount = clampDouble(hoveredColumn! + 2, 11, 20).toInt();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Actions(
        actions: <Type, Action<Intent>>{
          ButtonActivateIntent: callbackAction,
          ActivateIntent: callbackAction,
          DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
            onInvoke: onDirectionalFocus,
          ),
          NextFocusIntent: CallbackAction<NextFocusIntent>(
            onInvoke: (NextFocusIntent intent) {
              Actions.invoke(context, intent);
              return null;
            },
          ),
          PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(
            onInvoke: (PreviousFocusIntent intent) {
              Actions.invoke(context, intent);
              return null;
            },
          ),
        },
        child: Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(
              TraversalDirection.up,
            ),
            SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(
              TraversalDirection.down,
            ),
            SingleActivator(LogicalKeyboardKey.arrowLeft): DirectionalFocusIntent(
              TraversalDirection.left,
            ),
            SingleActivator(LogicalKeyboardKey.arrowRight): DirectionalFocusIntent(
              TraversalDirection.right,
            ),
          },
          child: Focus(
            canRequestFocus: true,
            child: Column(
              children: [
                Semantics(
                  label: '${hoveredRow ?? 0} by ${hoveredColumn ?? 0}',
                  liveRegion: true,
                  child: Table(
                    defaultColumnWidth: const FixedColumnWidth(18.0),
                    children: <TableRow>[
                      for (int row = 0; row < rowCount; row++)
                        TableRow(
                          key: ValueKey<int>(row),
                          children: <Widget>[
                            for (int column = 0; column < columnCount; column++)
                              Builder(
                                builder: (BuildContext context) {
                                  final bool selected =
                                      row <= hoveredRow! && column <= hoveredColumn!;
                                  final color = selected
                                      ? const Color.fromARGB(255, 211, 227, 253)
                                      : const Color.fromARGB(255, 248, 248, 248);

                                  final border = selected
                                      ? Border.all(color: const Color.fromARGB(255, 112, 162, 249))
                                      : Border.all(color: const Color.fromARGB(255, 230, 230, 230));

                                  return MouseRegion(
                                    onEnter: (PointerEnterEvent event) {
                                      _handleHighlight(row, column);
                                    },
                                    child: GestureDetector(
                                      onTap: _handleSelect,
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 1.0),
                                          child: SizedBox(
                                            height: 16.0,
                                            width: 16.0,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: color,
                                                border: border,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8.0),
                Text('${(hoveredRow ?? 0) + 1} x ${(hoveredColumn ?? 0) + 1}'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void onDirectionalFocus(DirectionalFocusIntent intent) {
    setState(() {
      switch (intent.direction) {
        case TraversalDirection.up:
          if (hoveredRow == 0) {
            Actions.invoke(context, intent);
            return;
          }
          _handleHighlight(hoveredRow! - 1, hoveredColumn!);
        case TraversalDirection.down:
          if (hoveredRow == 20) {
            Actions.invoke(context, intent);
            return;
          }
          _handleHighlight(hoveredRow! + 1, hoveredColumn!);
        case TraversalDirection.left:
          if (hoveredColumn == 0) {
            Actions.invoke(context, intent);
            break;
          }
          _handleHighlight(hoveredRow!, hoveredColumn! - 1);
        case TraversalDirection.right:
          if (hoveredColumn == 20) {
            MenuController.maybeOf(context)?.close();
            break;
          }
          _handleHighlight(hoveredRow!, hoveredColumn! + 1);
      }
    });
  }
}
