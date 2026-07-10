import 'dart:async';

import 'package:base_menu/base_menu.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/src/gestures/events.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../data/menu.dart';
import '../../model/model.dart';
import '../../utilities/exclusive_menu_manager.dart';
import '../adapters/menu_entry_menu_bar_menu.dart';
import '../menu_panel.dart';
import '../overflow_toolbar.dart';

/// An inherited widget that provides access to the menu's dismissal state.
class _DocumentMenuBarScope extends InheritedWidget {
  const _DocumentMenuBarScope({required super.child, required this.isInteractive});

  final bool isInteractive;

  @override
  bool updateShouldNotify(_DocumentMenuBarScope oldWidget) {
    return isInteractive != oldWidget.isInteractive;
  }
}

class DocumentMenuBar extends StatefulWidget {
  const DocumentMenuBar({super.key});

  static bool isInteractiveOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_DocumentMenuBarScope>();
    return scope?.isInteractive ?? false;
  }

  static bool hasAncestor(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_DocumentMenuBarScope>() != null;
  }

  @override
  State<DocumentMenuBar> createState() => _DocumentMenuBarState();
}

class _DocumentMenuBarState extends State<DocumentMenuBar> {
  final FocusScopeNode _focusScopeNode = FocusScopeNode();
  final MenuController _menuController = MenuController();
  int _cutoff = Menu.main.children.length;
  final List<Widget> children = Menu.main.children
      .map((entry) => MenuBarMenu(entry: entry))
      .toList(growable: false);

  @override
  void dispose() {
    _focusScopeNode.dispose();
    super.dispose();
  }

  void _handlePointerExit(PointerExitEvent event) {
    if (!_menuController.isOpen && _focusScopeNode.hasFocus) {
      _focusScopeNode.requestScopeFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasOverflow = _cutoff < Menu.main.children.length;
    return _DocumentMenuBarScope(
      isInteractive: ExclusiveMenuManager.controllerOf(context) == _menuController,
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: TapRegion(
          onTapOutside: (event) {
            scheduleMicrotask(() {
              if (mounted && ExclusiveMenuManager.controllerOf(context) == _menuController) {
                _focusScopeNode.unfocus();
              }
            });
          },
          child: BaseMenuBar(
            controller: _menuController,
            focusScopeNode: _focusScopeNode,
            child: BaseMenuPanel(
              constraints: const BoxConstraints.tightFor(height: 23.5),
              padding: const EdgeInsetsDirectional.only(end: 20.0),
              mainAxisSize: MainAxisSize.min,
              onPointerExit: _handlePointerExit,
              clipBehavior: .hardEdge,
              children: [
                Flexible(
                  child: OverflowRow(
                    onOverflow: (int lastVisibleIndex) {
                      _cutoff = lastVisibleIndex;
                      SchedulerBinding.instance.addPostFrameCallback((timestamp) {
                        if (mounted) {
                          setState(() {});
                        }
                      });
                    },
                    children: children,
                  ),
                ),
                if (hasOverflow)
                  MenuBarMenu(
                    overflow: true,
                    panel: MenuPanel(
                      onSurfaceExit: _handlePointerExit,
                      orientation: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                      children: Menu.main.children
                          .skip(_cutoff)
                          .map((entry) => MenuBarMenu(entry: entry))
                          .toList(),
                    ),
                    entry: SubmenuEntry(
                      const MenuEntry('More', icon: Symbols.more_horiz),
                      Menu.main.children.take(_cutoff).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
