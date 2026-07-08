import 'package:base_menu/base_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../shared/package.dart';
import '../../shared/theme.dart';

class MenuBar extends StatefulWidget {
  const MenuBar({super.key, required this.orientation});
  final Axis orientation;

  @override
  State<MenuBar> createState() => _MenuBarState();
}

class _MenuBarState extends State<MenuBar> {
  final focusScopeNode = FocusScopeNode();
  @override
  void dispose() {
    focusScopeNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submenuIcon = widget.orientation == Axis.vertical
        ? const Icon(Symbols.arrow_right, size: 16)
        : const Icon(Symbols.arrow_drop_down, size: 16);
    return Center(
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: 'InterVariable',
          package: kPackage,
          fontSize: 14,
          color: Color(0xff000000),
        ),
        child: BaseMenuBar(
          focusScopeNode: focusScopeNode,
          orientation: widget.orientation,
          child: StyledMenuPanel(
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              child: BaseMenuPanel(
                onPointerExit: (event) {
                  if (kIsWeb) {
                    if (!focusScopeNode.hasPrimaryFocus) {
                      focusScopeNode.requestScopeFocus();
                    }
                  }
                },
                padding: widget.orientation == Axis.vertical
                    ? const EdgeInsets.symmetric(vertical: 6)
                    : EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 150),
                orientation: widget.orientation,
                children: [
                  _Submenu(
                    label: 'File',
                    submenuIcon: submenuIcon,
                    children: const [
                      _MenuItem(label: 'New'),
                      _MenuItem(label: 'Open'),
                      _MenuItem(label: 'Save'),
                    ],
                  ),
                  _Submenu(
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
                  _Submenu(
                    submenuIcon: submenuIcon,
                    label: 'View',
                    children: const [
                      _MenuItem(label: 'Zoom In'),
                      _MenuItem(label: 'Zoom Out'),
                      _MenuItem(label: 'Reset Zoom'),
                    ],
                  ),
                  _Submenu(
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
        ),
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

class _Submenu extends StatefulWidget {
  const _Submenu({required this.label, required this.children, required this.submenuIcon});

  final String label;
  final List<Widget> children;
  final Icon submenuIcon;

  @override
  State<_Submenu> createState() => _SubmenuState();
}

class _SubmenuState extends State<_Submenu> with SingleTickerProviderStateMixin {
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
        positionDelegate: DefaultMenuPositioningDelegate(
          edgeBehavior: const EdgeBehavior(
            horizontal: EdgeBehaviorStrategy(flip: true),
            vertical: EdgeBehaviorStrategy(constrain: true),
          ),
          padding: const EdgeInsets.symmetric(vertical: 6),
          offset: BaseMenu.maybeOrientationOf(context) == Axis.vertical
              ? const Offset(-4, 0)
              : const Offset(0, 6),
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
              padding: const EdgeInsets.symmetric(vertical: 6),
              clipBehavior: .hardEdge,
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
        child: StyledMenuBarChild(
          child: Row(children: [Text(widget.label), const Spacer(), widget.submenuIcon]),
        ),
      ),
    );
  }
}
