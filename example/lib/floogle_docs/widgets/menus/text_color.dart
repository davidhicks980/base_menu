import 'package:flutter/widgets.dart';

import '../../model/intents.dart';
import '../../utilities/colors.dart';
import '../app_state_manager.dart';
import '../color_grid.dart';
import '../menu_panel.dart';
import '../popup.dart';

class TextColorButton extends StatefulWidget {
  const TextColorButton({super.key});

  @override
  State<TextColorButton> createState() => _TextColorButtonState();
}

class _TextColorButtonState extends State<TextColorButton> {
  final FocusNode _focusNode = FocusNode();
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        AppStateManager.selectedTextStyleOf(context)?.textStyle?.color ?? FloogleColors.darkGray;
    final button = ExcludeSemantics(
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
                fontFamily: 'RobotoFlex',
                fontWeight: FontWeight.w500,
                color: FloogleColors.darkGray,
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
    );
    return MergeSemantics(
      child: Semantics(
        label: 'Text color: ${colorLabel(color)}',
        child: Popup(
          onOpen: _handleOpen,
          focusNode: _focusNode,
          enableTooltipSemantics: false,
          tooltip: const TextSpan(text: 'Text color'),
          panel: MenuPanel(
            onSurfaceExit: (event) {
              if (!_focusNode.hasFocus) {
                _focusNode.requestFocus();
              }
            },
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
        ),
      ),
    );
  }

  void _handleOpen() {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }
}
