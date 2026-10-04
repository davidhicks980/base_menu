import 'package:base_menu/base_menu.dart';
import 'package:flutter/widgets.dart';

import '../../shared/theme.dart';

class Popup extends StatefulWidget {
  const Popup({super.key, required this.orientation});
  final Axis orientation;

  @override
  State<Popup> createState() => _PopupState();
}

class _PopupState extends State<Popup> {
  final focusNode = FocusNode();

  @override
  void dispose() {
    super.dispose();
    focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseMenu(
      orientation: widget.orientation,
      positionDelegate: const DefaultMenuPositioningDelegate(offset: Offset(0, 4)),

      // The builder provides the anchor button and access to the menu
      // controller
      builder: (context, controller, child) {
        return MergeSemantics(
          child: Semantics(
            expanded: controller.isOpen,
            button: true,
            child: BaseControl(
              focusNode: focusNode,
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                  focusNode.requestFocus();
                }
              },
              child: child!,
            ),
          ),
        );
      },
      menu: StyledMenuPanel(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: BaseMenuPanel(
            onPointerExit: (_) {
              if (!focusNode.hasFocus) {
                focusNode.requestFocus();
              }
            },
            padding: widget.orientation == .horizontal
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(vertical: 6.0),
            constraints: const BoxConstraints(minWidth: 150),
            orientation: widget.orientation,
            children: [
              const MenuItem(label: 'Undo'),
              const MenuItem(label: 'Redo'),
              switch (widget.orientation) {
                Axis.vertical => const MenuDivider.horizontal(),
                Axis.horizontal => const MenuDivider.vertical(),
              },
              const MenuItem(label: 'Cut'),
              const MenuItem(label: 'Copy'),
              const MenuItem(label: 'Paste'),
              const MenuItem(label: 'Select All'),
              const MenuItem(label: 'Delete'),
            ],
          ),
        ),
      ),
      child: StyledMenuButtonChild(
        child: Text(widget.orientation == Axis.vertical ? 'Vertical Menu' : 'Horizontal Menu'),
      ),
    );
  }
}

class MenuItem extends StatelessWidget {
  const MenuItem({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return BaseMenuItem(
      onPressed: () {},
      child: StyledMenuItemChild(child: Text(label)),
    );
  }
}
