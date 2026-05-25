import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../../data/menu.dart';
import '../adapters/menu_entry_panel.dart';

class EditorContextMenuWrapper extends StatefulWidget {
  const EditorContextMenuWrapper({super.key, required this.child, required this.menuController});

  final Widget child;
  final MenuController menuController;

  @override
  State<EditorContextMenuWrapper> createState() => _EditorContextMenuWrapperState();
}

class _EditorContextMenuWrapperState extends State<EditorContextMenuWrapper> {
  final TextEditingController _controller = TextEditingController(
    text: 'Click here to start editing...',
  );
  final _focusNode = FocusNode();

  late final gestures = {
    TapGestureRecognizer: GestureRecognizerFactoryWithHandlers(
      () => TapGestureRecognizer(
        debugOwner: this,
        allowedButtonsFilter: (int buttons) =>
            buttons == kSecondaryButton || buttons == kPrimaryButton,
      ),
      (instance) {
        instance
          ..onTapDown = _handleTapDown
          ..onSecondaryTapDown = _handleSecondaryTapDown;
      },
    ),
  };

  bool _wasBrowserContextMenuEnabled = false;
  bool _deferClose = false;

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
    _controller.dispose();
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

  void _handleSecondaryTapDown(TapDownDetails details) {
    if (kIsWeb && BrowserContextMenu.enabled) {
      return;
    }

    _deferClose = true;
    widget.menuController.open(position: details.localPosition);
    scheduleMicrotask(() {
      _deferClose = false;
    });
  }

  void _handleTapDown(TapDownDetails details) {
    // 2. Left Click - Close the menu if open
    if (widget.menuController.isOpen) {
      widget.menuController.close();
      return;
    }

    // 3. Left Click (Ctrl+Click context menu on macOS/iOS)
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        if (HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft) ||
            HardwareKeyboard.instance.logicalKeysPressed.contains(
              LogicalKeyboardKey.controlRight,
            )) {
          widget.menuController.open(position: details.localPosition);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = BaseMenu(
      positioningDelegate: const DefaultBaseMenuPositioningDelegate(
        padding: EdgeInsets.symmetric(vertical: 6),
      ),
      useRootOverlay: true,
      onCloseRequest: (hideOverlay) {
        if (_deferClose) {
          return;
        }
        hideOverlay();
        return;
      },
      menu: MouseRegion(
        onEnter: _onHoverEnter,
        onExit: (event) {
          if (!_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
        },
        child: MenuEntryPanel(
          menuEntry: Menu.context,
          constraints: const BoxConstraints(minWidth: 320),
          onSurfaceEnter: (event) {
            if (!_focusNode.hasFocus) {
              _focusNode.requestFocus();
            }
          },
        ),
      ),
      controller: widget.menuController,
      child: BaseFocusable(
        focusNode: _focusNode,
        child: Semantics(
          child: RawGestureDetector(
            gestures: gestures,
            behavior: HitTestBehavior.translucent,
            child: widget.child,
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
      hitTestBehavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
