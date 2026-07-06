import 'package:flutter/widgets.dart';

import '../../model/model.dart';
import '../popup.dart';
import 'menu_entry_panel.dart';

class MenuEntryPopup extends StatefulWidget {
  const MenuEntryPopup({
    super.key,
    required this.model,
    this.constraints,
    this.tooltip,
    this.buttonConstraints = const BoxConstraints(minWidth: 30, minHeight: 30),
    this.buttonDecoration,
    this.onOpen,
    this.onClose,
  });
  final SubmenuEntry model;
  final BoxConstraints? constraints;
  final WidgetStateProperty<BoxDecoration>? buttonDecoration;
  final BoxConstraints buttonConstraints;
  final InlineSpan? tooltip;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  @override
  State<MenuEntryPopup> createState() => _MenuEntryPopupState();
}

class _MenuEntryPopupState extends State<MenuEntryPopup> {
  final focusNode = FocusNode();

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Popup(
      focusNode: focusNode,
      buttonConstraints: widget.buttonConstraints,
      buttonDecoration: widget.buttonDecoration,
      tooltip: widget.tooltip,
      onOpen: () {
        focusNode.requestFocus();
        widget.onOpen?.call();
      },
      onClose: widget.onClose,
      panel: Builder(
        builder: (context) {
          return MenuEntryPanel(
            constraints: widget.constraints,
            menuEntry: widget.model,
            onSurfaceExit: (_) {
              focusNode.requestFocus();
              MenuController.maybeOf(context)?.open();
            },
          );
        },
      ),
      child: Icon(widget.model.child.icon),
    );
  }
}
