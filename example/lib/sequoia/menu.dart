import 'dart:async';

import 'package:flutter/material.dart';
import 'package:menu_utilities/menu_utilities.dart';

import 'menu_action_label.dart';
import 'menu_divider.dart';
import 'menu_item.dart';
import 'model.dart';
import 'surface.dart';

class _MenuSystemDismissHandler extends InheritedWidget {
  const _MenuSystemDismissHandler({
    required this.state,
    required super.child,
    required this.isInteractive,
  });

  final _SequoiaMenuState state;
  final bool isInteractive;

  static _MenuSystemDismissHandler of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_MenuSystemDismissHandler>()!;
  }

  @override
  bool updateShouldNotify(_MenuSystemDismissHandler oldWidget) {
    return state != oldWidget.state || isInteractive != oldWidget.isInteractive;
  }
}

class SequoiaMenu extends StatefulWidget {
  const SequoiaMenu({super.key, required this.items});

  final List<MenuItem> items;

  @override
  State<SequoiaMenu> createState() => _SequoiaMenuState();

  static Widget _buildItem(MenuItem item, bool isTopLevel) {
    if (item case MenuDividerItem()) {
      return const SequoiaMenuDivider();
    }

    if (item.children.isEmpty) {
      return SequoiaMenuItem(shortcut: item.shortcut, child: Text(item.label));
    }

    return _SequoiaModelBarSubmenu(item: item, isTopLevel: isTopLevel);
  }
}

class _SequoiaMenuState extends State<SequoiaMenu> with SingleTickerProviderStateMixin {
  final controller = MenuController();
  bool isAnimating = false;
  bool isInteractive = false;
  final FocusScopeNode focusScopeNode = FocusScopeNode();

  late final AnimationController animation = AnimationController(
    duration: Duration.zero,
    value: 1,
    vsync: this,
  );

  void enableInteractivity() {
    if (!isInteractive) {
      setState(() {
        isInteractive = true;
      });
    }
  }

  void fadeMenuOut() {
    if (isAnimating) {
      return;
    }
    focusScopeNode.requestScopeFocus();
    isAnimating = true;
    animation.duration = const Duration(milliseconds: 125);
    animation.reverse().whenComplete(() {
      controller.close();
      animation.duration = Duration.zero;
      animation.value = 1;
      isAnimating = false;
      setState(() {
        isInteractive = false;
      });
    });
  }

  @override
  void dispose() {
    focusScopeNode.dispose();
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MenuSystemDismissHandler(
      isInteractive: isInteractive,
      state: this,
      child: TapRegion(
        groupId: 'menu_system',
        onTapOutside: (event) {
          fadeMenuOut();
        },
        child: MouseRegion(
          onExit: (event) {
            if (!controller.isOpen) {
              focusScopeNode.requestScopeFocus();
            }
          },
          child: BaseMenuBar(
            controller: controller,
            focusScopeNode: focusScopeNode,
            child: BaseMenuPanel(
              orientation: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: widget.items.map((item) => SequoiaMenu._buildItem(item, true)).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _SequoiaModelBarSubmenu extends StatefulWidget {
  const _SequoiaModelBarSubmenu({required this.item, required this.isTopLevel});

  final MenuItem item;
  final bool isTopLevel;

  @override
  State<_SequoiaModelBarSubmenu> createState() => _SequoiaModelBarSubmenuState();
}

class _SequoiaModelBarSubmenuState extends State<_SequoiaModelBarSubmenu>
    with SingleTickerProviderStateMixin {
  final controller = MenuController();
  final focusNode = FocusNode();
  late _SequoiaMenuState _menuState;
  bool _isClosing = false;
  late final Map<Type, Action<Intent>> actions = {
    DismissIntent: CallbackAction<DismissIntent>(
      onInvoke: (intent) {
        _menuState.fadeMenuOut();
        return null;
      },
    ),
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _menuState = _MenuSystemDismissHandler.of(context).state;
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  void _handleCloseRequest(VoidCallback hideOverlay) {
    scheduleMicrotask(() {
      if (!_menuState.isAnimating) {
        hideOverlay();
      } else {
        setState(() {
          _isClosing = true;
        });
        void listener(AnimationStatus status) {
          if (status == AnimationStatus.dismissed) {
            _menuState.animation.removeStatusListener(listener);
            hideOverlay();
            if (mounted) {
              setState(() {
                _isClosing = false;
              });
            }
          }
        }

        _menuState.animation.addStatusListener(listener);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: BaseSubmenu(
        controller: controller,
        // Top level opens down, nested submenus open to the side
        positionDelegate: DefaultBaseMenuPositioningDelegate(
          padding: const EdgeInsets.symmetric(vertical: 4),
          offset: widget.isTopLevel ? const Offset(1, 0) : const Offset(0, -1.5),
        ),
        onCloseRequest: _handleCloseRequest,
        hoverOpenDelay: widget.isTopLevel ? Duration.zero : const Duration(milliseconds: 250),
        anchorActions: actions,
        focusNode: focusNode,
        requestFocusOnHover: _menuState.isInteractive,
        onPressed: () {
          if (controller.isOpen) {
            if (widget.isTopLevel) {
              _menuState.fadeMenuOut();
              focusNode.unfocus();
            }
          } else {
            controller.open();
            focusNode.requestFocus();
            _menuState.enableInteractivity();
          }
        },
        menu: Actions(
          actions: actions,
          child: ExcludeSemantics(
            excluding: _isClosing,
            child: ExcludeFocus(
              excluding: _isClosing,
              child: IgnorePointer(
                ignoring: _isClosing,
                child: TapRegion(
                  groupId: 'menu_system',
                  onTapOutside: (event) {
                    _menuState.fadeMenuOut();
                  },
                  child: FadeTransition(
                    opacity: _menuState.animation,
                    child: ColoredBox(
                      color: const Color(0x00000000),
                      child: Padding(
                        padding: widget.isTopLevel
                            ? const EdgeInsets.symmetric(vertical: 8)
                            : EdgeInsets.zero,
                        child: SequoiaMenuSurface(
                          child: BaseMenuPanel(
                            onEnter: (event) {
                              if (!focusNode.hasFocus) {
                                focusNode.requestFocus();
                              }
                            },
                            orientation: Axis.vertical,
                            padding: const EdgeInsets.all(4),
                            children: [
                              for (final child in widget.item.children)
                                SequoiaMenu._buildItem(child, false),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        child: widget.isTopLevel
            ? SequoiaMenuBarActionLabel(child: Text(widget.item.label))
            : SequoiaSubmenuActionLabel(child: Text(widget.item.label)),
      ),
    );
  }
}
