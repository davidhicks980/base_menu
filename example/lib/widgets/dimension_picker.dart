import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../model/intents.dart';
import '../utilities/colors.dart';

class DimensionPicker extends StatefulWidget {
  const DimensionPicker({super.key});

  @override
  State<DimensionPicker> createState() => _DimensionPickerState();
}

class _DimensionPickerState extends State<DimensionPicker> {
  int selectedRow = 0;
  int selectedColumn = 0;
  int? highlightedRow;
  int? highlightedColumn;

  void _handleHighlight(int row, int column) {
    if (row != highlightedRow || column != highlightedColumn) {
      setState(() {
        highlightedRow = row.clamp(0, 19);
        highlightedColumn = column.clamp(0, 19);
      });
    }
  }

  void _handleSelect([Object? _]) {
    setState(() {
      selectedRow = highlightedRow ?? selectedRow;
      selectedColumn = highlightedColumn ?? selectedColumn;
      highlightedRow = null;
      highlightedColumn = null;
    });
    Actions.invoke(context, InsertTableIntent(selectedRow + 1, selectedColumn + 1));
    Actions.invoke(context, const DismissIntent());
  }

  @override
  Widget build(BuildContext context) {
    final callbackAction = CallbackAction<Intent>(onInvoke: _handleSelect);
    highlightedRow = highlightedRow ?? selectedRow;
    highlightedColumn = highlightedColumn ?? selectedColumn;
    final int rowCount = clampDouble(highlightedRow! + 2, 5, 20).toInt();
    final int columnCount = clampDouble(highlightedColumn! + 2, 11, 20).toInt();
    final isRtl = Directionality.of(context) == TextDirection.rtl;

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
          shortcuts: <ShortcutActivator, Intent>{
            const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
            const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
            const SingleActivator(LogicalKeyboardKey.arrowUp): const DirectionalFocusIntent(
              TraversalDirection.up,
            ),
            const SingleActivator(LogicalKeyboardKey.arrowDown): const DirectionalFocusIntent(
              TraversalDirection.down,
            ),
            if (isRtl ? highlightedColumn! < columnCount - 1 : highlightedColumn! > 0)
              const SingleActivator(LogicalKeyboardKey.arrowLeft): const DirectionalFocusIntent(
                TraversalDirection.left,
              ),
            if (isRtl ? highlightedColumn! > 0 : highlightedColumn! < columnCount - 1)
              const SingleActivator(LogicalKeyboardKey.arrowRight): const DirectionalFocusIntent(
                TraversalDirection.right,
              ),
          },
          child: Focus(
            canRequestFocus: true,
            child: Column(
              children: [
                Semantics(
                  label: '${highlightedRow ?? 0} by ${highlightedColumn ?? 0}',
                  liveRegion: true,
                  child: Table(
                    defaultColumnWidth: const FixedColumnWidth(18.0),
                    children: <TableRow>[
                      for (int row = 0; row < rowCount; row++)
                        TableRow(
                          key: ValueKey<int>(row),
                          children: <Widget>[
                            for (int column = 0; column < columnCount; column++)
                              Cell(
                                selected: row <= highlightedRow! && column <= highlightedColumn!,
                                onTap: () => _handleSelect(),
                                onPointerEnter: (event) => _handleHighlight(row, column),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8.0),
                Text('${(highlightedRow ?? 0) + 1} x ${(highlightedColumn ?? 0) + 1}'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void onDirectionalFocus(DirectionalFocusIntent intent) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    switch (intent.direction) {
      case TraversalDirection.up:
        _handleHighlight(highlightedRow! - 1, highlightedColumn!);
      case TraversalDirection.down:
        _handleHighlight(highlightedRow! + 1, highlightedColumn!);
      case TraversalDirection.left:
        _handleHighlight(highlightedRow!, isRtl ? highlightedColumn! + 1 : highlightedColumn! - 1);
      case TraversalDirection.right:
        _handleHighlight(highlightedRow!, isRtl ? highlightedColumn! - 1 : highlightedColumn! + 1);
    }
  }
}

class Cell extends StatelessWidget {
  const Cell({
    super.key,
    required this.selected,
    required this.onTap,
    required this.onPointerEnter,
  });

  final bool selected;
  final VoidCallback onTap;
  final PointerEnterEventListener onPointerEnter;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        final color = selected
            ? FloogleColors.selectedButtonBackground
            : FloogleColors.dimensionPickerTileColor;

        final border = selected
            ? const Border.fromBorderSide(
                BorderSide(color: FloogleColors.dimensionPickerTileSelectedBorder),
              )
            : const Border.fromBorderSide(
                BorderSide(color: FloogleColors.dimensionPickerTileBorder),
              );

        return BaseMenuItem(
          onPointerEnter: onPointerEnter,
          onPressed: onTap,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.0),
              child: SizedBox(
                height: 16.0,
                width: 16.0,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: color, border: border),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
