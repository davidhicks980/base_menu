import 'package:flutter/widgets.dart';

import '../../app_state_manager.dart';
import '../../model/intents.dart';
import '../color_grid.dart';
import '../menu_panel.dart';
import '../popup.dart';

class TextColorButton extends StatefulWidget {
  const TextColorButton({super.key});

  @override
  State<TextColorButton> createState() => _TextColorButtonState();
}

class _TextColorButtonState extends State<TextColorButton> {
  @override
  Widget build(BuildContext context) {
    final color =
        AppStateManager.selectedTextStyleOf(context)?.textStyle?.color ?? const Color(0xFF3C4043);
    final button = Semantics(
      label: 'Text color: ${': ${colorLabel(color)}'}',
      child: ExcludeSemantics(
        child: SizedBox(
          width: 20,
          height: 20,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 1.5,
            children: [
              const Text(
                'A',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF3C4043),
                  height: 1.0,
                ),
              ),
              Container(
                height: 4,
                width: 22,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1)),
              ),
            ],
          ),
        ),
      ),
    );
    return Popup(
      panel: MenuPanel(
        children: [
          Builder(
            builder: (context) {
              return ColorPickerPanel(
                selectedColor: color,
                onColorSelected: (Color color) {
                  Actions.invoke(context, FormatTextColorIntent(color));
                  MenuController.maybeOf(context)?.close();
                },
              );
            },
          ),
        ],
      ),
      child: button,
    );
  }
}
