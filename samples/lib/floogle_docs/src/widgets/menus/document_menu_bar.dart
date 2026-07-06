import 'package:base_menu/base_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/src/gestures/events.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../data/menu.dart';
import '../../model/model.dart';
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

  static void disableInteractivityOf(BuildContext context) {
    context.findAncestorStateOfType<_DocumentMenuBarState>()?.disableInteractivity();
  }

  static void enableInteractivityOf(BuildContext context) {
    context.findAncestorStateOfType<_DocumentMenuBarState>()?.enableInteractivity();
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
  bool _isInteractive = false;

  void disableInteractivity() {
    if (_isInteractive) {
      setState(() {
        _isInteractive = false;
      });
      _focusScopeNode.requestScopeFocus();
    }
  }

  void enableInteractivity() {
    if (!_isInteractive) {
      setState(() {
        _isInteractive = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _focusScopeNode.addListener(() {
        if (!_focusScopeNode.hasFocus) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            FocusManager.instance.applyFocusChangesIfNeeded();
            if (mounted && !_focusScopeNode.hasFocus) {
              _menuController.close();
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _focusScopeNode.dispose();
    super.dispose();
  }

  void _handleTapOutside(PointerDownEvent event) {
    disableInteractivity();
    _menuController.close();
  }

  void _handlePointerExit(PointerExitEvent event) {
    if (!_menuController.isOpen) {
      _focusScopeNode.requestScopeFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasOverflow = _cutoff < Menu.main.children.length;
    return _DocumentMenuBarScope(
      isInteractive: _isInteractive,
      child: BaseMenuBar(
        controller: _menuController,
        focusScopeNode: _focusScopeNode,
        child: TapRegion(
          groupId: 'menu_system',
          onTapOutside: _handleTapOutside,
          child: BaseMenuPanel(
            constraints: const BoxConstraints.tightFor(height: 23.5),
            padding: const EdgeInsetsDirectional.only(end: 20.0),
            mainAxisSize: MainAxisSize.min,
            onPointerExit: _handlePointerExit,
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
                    children: [
                      ...Menu.main.children.skip(_cutoff).map((entry) => MenuBarMenu(entry: entry)),
                    ],
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
    );
  }
}
