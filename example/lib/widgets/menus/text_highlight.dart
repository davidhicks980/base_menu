import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_state_manager.dart';
import '../../model/intents.dart';
import '../../utilities/colors.dart';
import '../color_grid.dart';
import '../menu_item.dart';
import '../menu_panel.dart';
import '../popup.dart';

class TextHighlightButton extends StatelessWidget {
  const TextHighlightButton({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedColor =
        AppStateManager.selectedTextStyleOf(context)?.textStyle?.backgroundColor ??
        FloogleColors.transparent;
    final button = MergeSemantics(
      child: Semantics(
        label: 'Text highlight color: ${': ${colorLabel(selectedColor)}'}',
        child: ExcludeSemantics(
          child: SizedBox(
            width: 20,
            height: 20,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 1.5,
              children: [
                CustomPaint(
                  painter: _InkHighlighterTopFillPainter(),
                  child: const Icon(
                    Symbols.ink_highlighter,
                    size: 14,
                    color: FloogleColors.darkGray,
                  ),
                ),
                SizedBox(
                  height: 4,
                  width: 22,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: selectedColor,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Popup(
      requestFocusOnHover:
          MenuController.maybeIsOpenOf(context) != true &&  FocusScope.of(context).hasFocus,
      panel: Builder(
        builder: (context) {
          return MenuPanel(
            padding: const EdgeInsets.symmetric(vertical: 6),
            children: [
              ColorPickerPanel(
                leading: const MenuItem(
                  leading: Icon(Symbols.format_color_reset, fill: 1.0),
                  child: Text('None'),
                ),
                selectedColor: selectedColor,
                onColorSelected: (Color color) {
                  Actions.invoke(context, FormatTextHighlightIntent(color));
                  MenuController.maybeOf(context)?.close();
                },
              ),
            ],
          );
        },
      ),
      child: button,
    );
  }
}

class _InkHighlighterTopFillPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FloogleColors.darkGray
      ..style = PaintingStyle.fill;
    final rect = Rect.fromLTWH(0, size.height / 1.75, size.width / 2.5, size.height / 3.5);
    canvas
      ..save()
      ..rotate(-0.75)
      ..drawRect(rect, paint)
      ..restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
