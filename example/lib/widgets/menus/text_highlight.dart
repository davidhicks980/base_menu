import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../model/intents.dart';
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
  Color? _selectedColor;
  @override
  Widget build(BuildContext context) {
    final button = MergeSemantics(
      child: Semantics(
        label:
            'Text highlight color: ${_selectedColor != null ? ': ${colorLabel(_selectedColor!)}' : ''}',
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
                  child: const Icon(Symbols.ink_highlighter, size: 14, color: Color(0xFF3C4043)),
                ),
                Container(
                  height: 4,
                  width: 22,
                  decoration: BoxDecoration(
                    color: _selectedColor ?? const Color(0xFF3C4043),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Popup(
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
                selectedColor: _selectedColor,
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
      ..color = const Color(0xFF3C4043)
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
