import 'package:flutter/material.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../shared/theme.dart';

const focusColor = Color(0xFFF2F2F7); // Light grey for hover/focus
const pressedColor = Color(0xFFE5E5EA);
const anyColor = Color(0xFFFFFFFF);

class MenuBarApp extends StatelessWidget {
  const MenuBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(child: _MenuBar(orientation: Axis.vertical)),
        Container(height: 1, color: ColorScheme.of(context).outlineVariant),
        const Expanded(child: _MenuBar(orientation: Axis.horizontal)),
      ],
    );
  }
}

class _MenuBar extends StatefulWidget {
  const _MenuBar({required this.orientation});
  final Axis orientation;

  @override
  State<_MenuBar> createState() => _MenuBarState();
}

class _MenuBarState extends State<_MenuBar> {
  final focusNode = FocusNode();
  @override
  void dispose() {
    super.dispose();
    focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submenuIcon = widget.orientation == Axis.vertical
        ? const Icon(Icons.arrow_right, size: 16)
        : const Icon(Icons.arrow_drop_down, size: 16);
    return Center(
      child: DefaultTextStyle(
        style: const TextStyle(fontFamily: 'InterVariable', fontSize: 14, color: Color(0xff000000)),
        child: BaseMenuBar(
          axis: widget.orientation,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: StyledMenuPanel(
              child: BaseMenuPanel(
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
      onPressed: () {
        print('Pressed $label');
      },
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
        positionDelegate: const DefaultBaseMenuPositioningDelegate(
          flipEdges: {AxisDirection.left, AxisDirection.right},
          padding: EdgeInsets.all(4.0),
        ),
        onPressed: () {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
            focusNode.requestFocus();
          }
        },
        menu: StyledMenuPanel(
          child: BaseMenuPanel(
            padding: const EdgeInsets.all(4.0),
            onEnter: (event) {
              if (!focusNode.hasFocus) {
                focusNode.requestFocus();
              }
            },
            orientation: Axis.vertical,
            children: widget.children,
          ),
        ),
        child: StyledMenuBarChild(
          child: Row(children: [Text(widget.label), const Spacer(), widget.submenuIcon]),
        ),
      ),
    );
  }
}
