import 'dart:async';

import 'package:base_menu/base_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../shared/browser_context_menu_blocker.dart';
import 'dismiss.dart';
import 'menu.dart';
import 'model.dart';
import 'theme.dart';

class CupertinoContextMenu extends StatefulWidget {
  const CupertinoContextMenu({
    super.key,
    required this.child,
    required this.item,
    required this.controller,
  });

  final Widget child;
  final List<MenuItem> item;
  final MenuController controller;

  @override
  State<CupertinoContextMenu> createState() => _CupertinoContextMenuState();
}

class _CupertinoContextMenuState extends State<CupertinoContextMenu> {
  final _focusNode = FocusNode();
  bool _deferClose = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.controller.isOpen && event.buttons == kPrimaryMouseButton) {
      widget.controller.close();
      return;
    }

    if (kIsWeb && ContextMenuBlocker.isEnabledOf(context)) {
      return;
    }

    if (event.buttons == kSecondaryMouseButton) {
      _deferClose = true;
      widget.controller.open(position: event.localPosition);
      scheduleMicrotask(() {
        _deferClose = false;
      });
      return;
    }

    if (event.buttons == kPrimaryMouseButton) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          break;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          if (HardwareKeyboard.instance.isControlPressed) {
            widget.controller.open(position: event.localPosition);
          }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MenuDismissCoordinator(
      controller: widget.controller,
      isInteractive: true,
      child: CupertinoContextSubmenu(
        item: widget.item,
        allowCloseRequest: () {
          return !_deferClose;
        },
        focusNode: _focusNode,
        onOpen: () {
          setState(() {});
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _focusNode.requestFocus();
            }
          });
        },
        controller: widget.controller,
        child: Focus(
          canRequestFocus: widget.controller.isOpen,
          focusNode: _focusNode,
          child: Semantics(
            onLongPress: () {
              // Semantic equivalent for right-click / context menu
              widget.controller.open();
            },
            child: Listener(
              onPointerDown: _handlePointerDown,
              behavior: .opaque,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class CupertinoContextSubmenu extends StatefulWidget {
  const CupertinoContextSubmenu({
    super.key,
    required this.item,
    required this.child,
    required this.controller,
    required this.onOpen,
    required this.focusNode,
    required this.allowCloseRequest,
  });

  final List<MenuItem> item;
  final MenuController controller;
  final VoidCallback onOpen;
  final FocusNode focusNode;
  final bool Function() allowCloseRequest;
  final Widget child;

  @override
  State<CupertinoContextSubmenu> createState() => _CupertinoContextSubmenuState();
}

class _CupertinoContextSubmenuState extends State<CupertinoContextSubmenu> {
  late MenuDismissCoordinatorState _dismissHandler;
  bool _isClosing = false;
  late final Map<Type, Action<Intent>> actions = {
    DismissIntent: CallbackAction<DismissIntent>(
      onInvoke: (intent) {
        _dismissHandler.fadeMenuOut();
        return null;
      },
    ),
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dismissHandler = CupertinoMenuDismissHandler.of(context);
  }

  void _handleCloseRequest(VoidCallback hideOverlay) {
    if (!widget.allowCloseRequest()) {
      return;
    }
    scheduleMicrotask(() {
      if (!_dismissHandler.isAnimatingOut) {
        hideOverlay();
      } else {
        setState(() {
          _isClosing = true;
        });
        void listener(AnimationStatus status) {
          if (status == AnimationStatus.dismissed) {
            _dismissHandler.animation.removeStatusListener(listener);
            hideOverlay();
            if (mounted) {
              setState(() {
                _isClosing = false;
              });
            }
          }
        }

        _dismissHandler.animation.addStatusListener(listener);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoMenuTheme.of(context);
    return IntrinsicWidth(
      child: BaseMenu(
        controller: widget.controller,
        // Top level opens down, nested submenus open to the side
        positionDelegate: const DefaultMenuPositioningDelegate(
          padding: EdgeInsets.symmetric(vertical: 4),
          offset: Offset(0, -1.5),
        ),
        onOpen: widget.onOpen,
        onCloseRequest: _handleCloseRequest,
        menu: Actions(
          actions: actions,
          child: ExcludeSemantics(
            excluding: _isClosing,
            child: ExcludeFocus(
              excluding: _isClosing,
              child: IgnorePointer(
                ignoring: _isClosing,
                child: TapRegion(
                  groupId: widget.controller,
                  onTapOutside: (event) {
                    if (event.buttons == kSecondaryMouseButton) {
                      return;
                    }
                    _dismissHandler.fadeMenuOut();
                  },
                  child: FadeTransition(
                    opacity: _dismissHandler.animation,
                    child: ColoredBox(
                      color: const Color(0x00000000),
                      child: Stack(
                        children: [
                          Positioned.fill(child: theme.surface),
                          BaseMenuPanel(
                            onPointerExit: (event) {
                              if (!widget.focusNode.hasFocus) {
                                widget.focusNode.requestFocus();
                              }
                            },
                            orientation: Axis.vertical,
                            padding: theme.surfacePadding,
                            children: [
                              for (final child in widget.item)
                                CupertinoSubmenu.buildItem(
                                  child,
                                  false,
                                  groupId: widget.controller,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        child: widget.child,
      ),
    );
  }
}
