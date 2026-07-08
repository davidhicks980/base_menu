import 'package:base_menu/base_menu.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../shared/theme.dart';

class Submenu extends StatefulWidget {
  const Submenu({super.key, required this.orientation});
  final Axis orientation;

  @override
  State<Submenu> createState() => _SubmenuState();
}

class _SubmenuState extends State<Submenu> {
  final focusNode = FocusNode();

  @override
  void dispose() {
    super.dispose();
    focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submenuIcon = widget.orientation == Axis.vertical
        ? const Icon(Symbols.arrow_right, size: 16)
        : const Icon(Symbols.arrow_drop_down, size: 16);
    return BaseMenu(
      orientation: widget.orientation,
      positionDelegate: const DefaultMenuPositioningDelegate(offset: Offset(0, 2)),
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
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          child: BaseMenuPanel(
            onPointerExit: (_) {
              if (!focusNode.hasFocus) {
                focusNode.requestFocus();
              }
            },
            constraints: const BoxConstraints(minWidth: 150),
            orientation: widget.orientation,
            clipBehavior: .hardEdge,
            children: [
              _SubmenuItem(
                label: 'File',
                submenuIcon: submenuIcon,
                children: const [
                  _MenuItem(label: 'New'),
                  _MenuItem(label: 'Open'),
                  _MenuItem(label: 'Save'),
                ],
              ),
              _SubmenuItem(
                label: 'Edit',
                submenuIcon: submenuIcon,
                children: const [
                  _MenuItem(label: 'Undo'),
                  _MenuItem(label: 'Redo'),
                  MenuDivider.horizontal(),
                  _MenuItem(label: 'Cut'),
                  _MenuItem(label: 'Copy'),
                  _MenuItem(label: 'Paste'),
                  _MenuItem(label: 'Select All'),
                  _MenuItem(label: 'Delete'),
                ],
              ),
              _SubmenuItem(
                submenuIcon: submenuIcon,
                label: 'View',
                children: const [
                  _MenuItem(label: 'Zoom In'),
                  _MenuItem(label: 'Zoom Out'),
                  _MenuItem(label: 'Reset Zoom'),
                ],
              ),
              _SubmenuItem(
                submenuIcon: submenuIcon,
                label: 'Help',
                children: const [
                  _MenuItem(label: 'Documentation'),
                  _MenuItem(label: 'About'),
                ],
              ),
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

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return BaseMenuItem(
      onPressed: () {},
      child: StyledMenuItemChild(child: Text(label)),
    );
  }
}

class _SubmenuItem extends StatefulWidget {
  const _SubmenuItem({required this.label, required this.children, required this.submenuIcon});

  final String label;
  final List<Widget> children;
  final Icon submenuIcon;

  @override
  State<_SubmenuItem> createState() => _SubmenuItemState();
}

class _SubmenuItemState extends State<_SubmenuItem> with SingleTickerProviderStateMixin {
  final controller = MenuController();
  final focusNode = FocusNode();

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: BaseSubmenu(
        controller: controller,
        focusNode: focusNode,
        hoverOpenDelay: const Duration(milliseconds: 250),
        hoverCloseDelay: const Duration(milliseconds: 250),
        positionDelegate: DefaultMenuPositioningDelegate(
          edgeBehavior: const EdgeBehavior(
            horizontal: EdgeBehaviorStrategy(flip: true),
            vertical: EdgeBehaviorStrategy(constrain: true),
          ),
          offset: BaseMenuScope.maybeOf(context)?.orientation == Axis.vertical
              ? const Offset(-4, 0)
              : Offset.zero,
        ),
        onPressed: () {
          if (!controller.isOpen) {
            controller.open();
            focusNode.requestFocus();
          }
        },
        menu: StyledMenuPanel(
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            child: BaseMenuPanel(
              onPointerExit: (event) {
                if (!focusNode.hasFocus) {
                  focusNode.requestFocus();
                }
              },
              orientation: Axis.vertical,
              children: widget.children,
            ),
          ),
        ),
        child: StyledSubmenuChild(
          child: Row(children: [Text(widget.label), const Spacer(), widget.submenuIcon]),
        ),
      ),
    );
  }
}
