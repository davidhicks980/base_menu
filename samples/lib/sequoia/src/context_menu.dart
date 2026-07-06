import 'dart:async';

import 'package:base_menu/base_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'dismiss.dart';
import 'menu.dart';
import 'model.dart';
import 'surface.dart';

class SequoiaContextMenuRegion extends StatefulWidget {
  const SequoiaContextMenuRegion({super.key, required this.child, required this.item});

  final Widget child;
  final List<MenuItem> item;

  @override
  State<SequoiaContextMenuRegion> createState() => _SequoiaContextMenuRegionState();
}

class _SequoiaContextMenuRegionState extends State<SequoiaContextMenuRegion> {
  final _focusNode = FocusNode();
  bool _wasBrowserContextMenuEnabled = false;
  final MenuController _menuController = MenuController();

  @override
  void initState() {
    super.initState();
    _wasBrowserContextMenuEnabled = kIsWeb && BrowserContextMenu.enabled;
  }

  @override
  void dispose() {
    if (_wasBrowserContextMenuEnabled) {
      _enableContextMenu();
    }
    _focusNode.dispose();
    super.dispose();
  }

  Future<void>? _contextMenuStatus;
  Future<void> _disableContextMenu() async {
    assert(_wasBrowserContextMenuEnabled);

    if (_contextMenuStatus != null) {
      // If a context menu status change is already in progress, wait for it to complete before starting a new one.
      await _contextMenuStatus;
    }

    if (!BrowserContextMenu.enabled) {
      return;
    }

    _contextMenuStatus = BrowserContextMenu.disableContextMenu();
  }

  Future<void> _enableContextMenu() async {
    assert(_wasBrowserContextMenuEnabled);

    if (_contextMenuStatus != null) {
      // If a context menu status change is already in progress, wait for it to complete before starting a new one.
      await _contextMenuStatus;
    }

    if (BrowserContextMenu.enabled) {
      return;
    }

    _contextMenuStatus = BrowserContextMenu.enableContextMenu();
  }

  bool _handleKeyEvent(KeyEvent event) {
    assert(kIsWeb);
    switch (event) {
      case KeyDownEvent(logicalKey: LogicalKeyboardKey.shiftLeft || LogicalKeyboardKey.shiftRight):
        _enableContextMenu();
      case KeyUpEvent(logicalKey: LogicalKeyboardKey.shiftLeft || LogicalKeyboardKey.shiftRight):
        _disableContextMenu();
    }

    return false;
  }

  void _onHoverEnter(PointerEnterEvent event) {
    WidgetsBinding.instance.keyboard.addHandler(_handleKeyEvent);
    _disableContextMenu();
  }

  void _onHoverExit(PointerExitEvent event) {
    _enableContextMenu();
    WidgetsBinding.instance.keyboard.removeHandler(_handleKeyEvent);
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (event.buttons == kSecondaryMouseButton) {
      if (kIsWeb && BrowserContextMenu.enabled) {
        return;
      }

      _menuController.open(position: event.localPosition);
      return;
    }

    if (_menuController.isOpen) {
      _menuController.close();
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
          if (HardwareKeyboard.instance.logicalKeysPressed.contains(
                LogicalKeyboardKey.controlLeft,
              ) ||
              HardwareKeyboard.instance.logicalKeysPressed.contains(
                LogicalKeyboardKey.controlRight,
              )) {
            _menuController.open(position: event.localPosition);
          }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = SequoiaMenuDismissCoordinator(
      controller: _menuController,
      isInteractive: true,
      child: SequoiaContextSubmenu(
        item: widget.item,
        focusNode: _focusNode,
        onOpen: () {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _focusNode.requestFocus();
            }
          });
        },
        controller: _menuController,
        child: Focus(
          focusNode: _focusNode,
          child: Semantics(
            onLongPress: () {
              // Semantic equivalent for right-click / context menu
              _menuController.open();
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

    if (!_wasBrowserContextMenuEnabled) {
      return child;
    }

    return MouseRegion(
      onEnter: _onHoverEnter,
      onExit: _onHoverExit,
      hitTestBehavior: .translucent,
      child: child,
    );
  }
}

class SequoiaContextSubmenu extends StatefulWidget {
  const SequoiaContextSubmenu({
    super.key,
    required this.item,
    required this.child,
    required this.controller,
    required this.onOpen,
    required this.focusNode,
  });

  final List<MenuItem> item;
  final MenuController controller;
  final VoidCallback onOpen;
  final FocusNode focusNode;
  final Widget child;

  @override
  State<SequoiaContextSubmenu> createState() => _SequoiaContextSubmenuState();
}

class _SequoiaContextSubmenuState extends State<SequoiaContextSubmenu> {
  late SequoiaMenuDismissCoordinatorState _dismissHandler;
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
    _dismissHandler = SequoiaMenuDismissHandler.of(context);
  }

  void _handleCloseRequest(VoidCallback hideOverlay) {
    scheduleMicrotask(() {
      if (!_dismissHandler.isAnimating) {
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
                  groupId: 'menu_system',
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
                      child: SequoiaMenuSurface(
                        child: BaseMenuPanel(
                          onPointerExit: (event) {
                            if (!widget.focusNode.hasFocus) {
                              widget.focusNode.requestFocus();
                            }
                          },
                          orientation: Axis.vertical,
                          padding: const EdgeInsets.all(4),
                          children: [
                            for (final child in widget.item) SequoiaMenuBar.buildItem(child, false),
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
        child: widget.child,
      ),
    );
  }
}
