import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../shared/localized_shortcut_labeler.dart';
import '../../model/model.dart';
import '../icon_button.dart';
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
  bool _isOpen = false;

  @override
  void dispose() {
    leftFocusNode.dispose();
    super.dispose();
  }

  void _handleClose() {
    setState(() {
      _isOpen = false;
    });
  }

  void _handleOpen() {
    setState(() {
      _isOpen = true;
    });
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
    String? shortcutLabel;
    Intent? menuIntent;
    if (widget.entry.child case MenuEntryWithIntent(
      :final MenuSerializableShortcut? shortcut,
      :final Intent? intent,
    )) {
      if (shortcut != null) {
        shortcutLabel = LocalizedShortcutLabeler.instance.getShortcutLabel(
          shortcut,
          MaterialLocalizations.of(context),
        );

        if (shortcutLabel.length <= 3) {
          shortcutLabel = shortcutLabel.replaceAll(RegExp(r'\s'), '');
        } else {
          shortcutLabel = shortcutLabel.replaceAll(RegExp(r'\s'), '+');
        }
      }
      menuIntent = intent;
    }

    return IconTheme.merge(
      data: const IconThemeData(size: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MergeSemantics(
            child: ToolbarIconButton(
              onPressed: () {
                if (menuIntent != null) {
                  Actions.invoke(context, menuIntent);
                }
              },
              focusNode: leftFocusNode,
              tooltip:
                  widget.entry.child.label + (shortcutLabel != null ? ' ($shortcutLabel)' : ''),
              decoration: _leftDecoration,
              child: widget.child.icon != null ? Icon(widget.child.icon) : const SizedBox(),
            ),
          ),
          IconTheme.merge(
            data: const IconThemeData(size: 13),
            child: MenuEntryPopup(
              onOpen: _handleOpen,
              onClose: _handleClose,
              tooltip: TextSpan(text: '${widget.entry.child.label} menu'),
              buttonConstraints: const BoxConstraints.tightFor(width: 13, height: 30),
              buttonDecoration: _isOpen
                  ? const WidgetStatePropertyAll(
                      BoxDecoration(
                        color: hoveredFocusedColor,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                    )
                  : _rightDecoration,
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
