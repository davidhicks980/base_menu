import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../model/model.dart';
import '../toolbar_icon_button.dart';
import 'menu_entry_popup.dart';

class SegmentedPopupButton extends StatefulWidget {
  const SegmentedPopupButton({super.key, required this.entry, required this.child});

  final MenuEntry child;
  final SubmenuEntry entry;

  @override
  State<SegmentedPopupButton> createState() => _SegmentedPopupButtonState();
}

class _SegmentedPopupButtonState extends State<SegmentedPopupButton> {
  final leftFocusNode = FocusNode();

  @override
  void dispose() {
    leftFocusNode.dispose();
    super.dispose();
  }

  static const pressedColor = Color.from(alpha: 0.098, red: 0, green: 0, blue: 0);
  static const hoveredFocusedColor = Color.from(alpha: 0.059, red: 0, green: 0, blue: 0);

  static const WidgetStateProperty<BoxDecoration> _leftDecoration = WidgetStateProperty.fromMap({
    WidgetState.pressed: BoxDecoration(
      color: pressedColor,
      borderRadius: BorderRadius.only(topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
    ),
    WidgetState.focused: BoxDecoration(
      color: hoveredFocusedColor,
      borderRadius: BorderRadius.only(topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
    ),
    WidgetState.hovered: BoxDecoration(
      color: hoveredFocusedColor,
      borderRadius: BorderRadius.only(topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
    ),
    WidgetState.any: BoxDecoration(),
  });

  static const WidgetStateProperty<BoxDecoration> _rightDecoration = WidgetStateProperty.fromMap({
    WidgetState.pressed: BoxDecoration(
      color: pressedColor,
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(4),
        bottomRight: Radius.circular(4),
      ),
    ),
    WidgetState.focused: BoxDecoration(
      color: hoveredFocusedColor,
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(4),
        bottomRight: Radius.circular(4),
      ),
    ),
    WidgetState.hovered: BoxDecoration(
      color: hoveredFocusedColor,
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(4),
        bottomRight: Radius.circular(4),
      ),
    ),
    WidgetState.any: BoxDecoration(),
  });

  @override
  Widget build(BuildContext context) {
    return IconTheme.merge(
      data: const IconThemeData(size: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ToolbarIconButton(
            focusNode: leftFocusNode,
            tooltip: widget.entry.child.label,
            decoration: _leftDecoration,
            child: widget.child.icon != null ? Icon(widget.child.icon) : const SizedBox(),
          ),

          IconTheme.merge(
            data: const IconThemeData(size: 13),
            child: MenuEntryPopup(
              buttonConstraints: const BoxConstraints.tightFor(width: 13, height: 30),
              buttonDecoration: _rightDecoration,
              model: widget.entry.copyWith(
                child: MenuEntry(widget.entry.child.label, icon: Symbols.arrow_drop_down),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
