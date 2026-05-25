import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_state_manager.dart';
import '../../model/intents.dart';
import '../../utilities/colors.dart';
import '../color_grid.dart';
import '../menu_item.dart';
import '../menu_panel.dart';
import '../popup.dart';

class TextHighlightButton extends StatefulWidget {
  const TextHighlightButton({super.key});

  @override
  State<TextHighlightButton> createState() => _TextHighlightButtonState();
}

class _TextHighlightButtonState extends State<TextHighlightButton> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor =
        AppStateManager.selectedTextStyleOf(context)?.textStyle?.backgroundColor ??
        FloogleColors.transparent;
    final button = ExcludeSemantics(
      child: SizedBox(
        width: 20,
        height: 20,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 1.5,
          children: [
            CustomPaint(
              painter: _InkHighlighterTopFillPainter(),
              child: const Icon(Symbols.ink_highlighter, size: 14, color: FloogleColors.darkGray),
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
    );
    return MergeSemantics(
      child: Semantics(
        label: 'Highlight color: ${colorLabel(selectedColor)}',
        child: Popup(
          focusNode: _focusNode,
          tooltip: const TextSpan(text: 'Highlight color', semanticsLabel: ''),
          panel: Builder(
            builder: (context) {
              return MenuPanel(
                padding: const EdgeInsets.symmetric(vertical: 6),
                onSurfaceEnter: (event) {
                  if (!_focusNode.hasFocus) {
                    _focusNode.requestFocus();
                  }
                },
                children: [
                  ColorPickerPanel(
                    leading: MenuItem(
                      leading: const Icon(Symbols.format_color_reset, fill: 1.0),
                      child: const Text('None'),
                      onTap: () {
                        Actions.invoke(
                          context,
                          const FormatTextHighlightIntent(FloogleColors.transparent),
                        );
                        MenuController.maybeOf(context)?.close();
                      },
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
        ),
      ),
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
