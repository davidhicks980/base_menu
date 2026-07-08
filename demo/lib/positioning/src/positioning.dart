import 'package:base_menu/base_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../shared/theme.dart';

class Submenu extends StatefulWidget {
  const Submenu({
    super.key,
    required this.orientation,
    required this.controller,
    required this.submenuPositioningDelegate,
  });
  final Axis orientation;
  final MenuController controller;
  final DefaultMenuPositioningDelegate submenuPositioningDelegate;

  @override
  State<Submenu> createState() => _SubmenuState();
}

class _SubmenuState extends State<Submenu> {
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.controller.open();
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  List<Widget> _buildRecursiveMenuItems(List<int> path, int maxDepth, int childCount) {
    if (path.length >= maxDepth) {
      return [
        for (var i = 0; i < childCount; i++) _MenuItem(label: [...path, i].join('.')),
      ];
    }
    final submenuIcon = widget.orientation == Axis.vertical
        ? const Icon(Symbols.arrow_right, size: 16)
        : const Icon(Symbols.arrow_drop_down, size: 16);
    return [
      for (var i = 0; i < childCount; i++)
        if (i == childCount - 1)
          _SubmenuItem(
            isOpen: true,
            label: [...path, i].join('.'),
            submenuIcon: submenuIcon,
            positionDelegate: widget.submenuPositioningDelegate,
            children: _buildRecursiveMenuItems([...path, i], maxDepth, childCount),
          )
        else
          _MenuItem(label: [...path, i].join('.')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BaseMenu(
      orientation: widget.orientation,
      onCloseRequest: (hideOverlay) {},
      positionDelegate: const DefaultMenuPositioningDelegate(offset: Offset(0, 4)),
      controller: widget.controller,
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
        child: BaseMenuPanel(
          onPointerExit: (_) {
            if (!focusNode.hasFocus) {
              focusNode.requestFocus();
            }
          },
          constraints: const BoxConstraints(minWidth: 150),
          orientation: widget.orientation,
          clipBehavior: .hardEdge,
          children: _buildRecursiveMenuItems([], 3, 5),
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
  const _SubmenuItem({
    required this.label,
    required this.isOpen,
    required this.children,
    required this.submenuIcon,
    required this.positionDelegate,
  });

  final String label;
  final List<Widget> children;
  final Icon submenuIcon;
  final DefaultMenuPositioningDelegate positionDelegate;
  final bool isOpen;

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
        onCloseRequest: (hideOverlay) {
          if (widget.isOpen) {
            return;
          }
          hideOverlay();
        },
        onOpenRequest: (position, showOverlay) {
          if (!widget.isOpen) {
            return;
          }
          showOverlay();
        },
        controller: controller,
        focusNode: focusNode,
        hoverOpenDelay: const Duration(milliseconds: 250),
        hoverCloseDelay: const Duration(milliseconds: 250),
        positionDelegate: widget.positionDelegate,
        onPressed: () {
          if (!controller.isOpen) {
            controller.open();
            focusNode.requestFocus();
          }
        },
        menu: StyledMenuPanel(
          child: BaseMenuPanel(
            constraints: const BoxConstraints(minWidth: 150),
            onPointerExit: (event) {
              if (!focusNode.hasFocus) {
                focusNode.requestFocus();
              }
            },
            orientation: Axis.vertical,
            children: widget.children,
          ),
        ),
        child: DecoratedBox(
          decoration: widget.isOpen
              ? const BoxDecoration(
                  border: Border.fromBorderSide(BorderSide(color: kBlack, width: 3.5)),
                )
              : const BoxDecoration(),
          child: StyledSubmenuChild(
            child: Row(children: [Text(widget.label), const Spacer(), widget.submenuIcon]),
          ),
        ),
      ),
    );
  }
}
