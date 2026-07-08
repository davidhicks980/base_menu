import 'dart:async';

import 'package:base_menu/base_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../../shared/browser_context_menu_blocker.dart';
import '../../data/menu.dart';
import '../adapters/menu_entry_panel.dart';

class EditorContextMenu extends StatefulWidget {
  const EditorContextMenu({super.key, required this.child, required this.menuController});

  final Widget child;
  final MenuController menuController;
  static void showMenuAtPointer(BuildContext context, PointerDownEvent event) {
    context.findAncestorStateOfType<_EditorContextMenuState>()!._handlePointerDown(event);
  }

  @override
  State<EditorContextMenu> createState() => _EditorContextMenuState();
}

class _EditorContextMenuState extends State<EditorContextMenu> {
  final TextEditingController _controller = TextEditingController(
    text: 'Click here to start editing...',
  );
  final _focusNode = FocusNode();
  bool _deferClose = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.menuController.isOpen && event.buttons == kPrimaryMouseButton) {
      widget.menuController.close();
      return;
    }

    if (kIsWeb && ContextMenuBlocker.isEnabledOf(context)) {
      return;
    }

    if (event.buttons == kSecondaryMouseButton) {
      _deferClose = true;
      widget.menuController.open(position: event.localPosition);
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
            widget.menuController.open(position: event.localPosition);
          }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseMenu(
      positionDelegate: const DefaultMenuPositioningDelegate(
        padding: EdgeInsets.symmetric(vertical: 6),
      ),
      onCloseRequest: (hideOverlay) {
        if (!_deferClose) {
          hideOverlay();
        }
      },
      onOpen: () {
        _focusNode.requestFocus();
      },
      menu: MenuEntryPanel(
        menuEntry: Menu.context,
        constraints: const BoxConstraints(minWidth: 320),
        onSurfaceExit: (_) {
          if (!_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
        },
      ),
      controller: widget.menuController,
      child: Focus(
        focusNode: _focusNode,
        child: Semantics(
          onLongPress: () {
            // Semantic equivalent for right-click / context menu
            widget.menuController.open();
          },
          child: widget.child,
        ),
      ),
    );
  }
}
