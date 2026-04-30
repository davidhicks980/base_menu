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
  static const panel = MenuEntryPanel(
    menuEntry: Menu.context,
    constraints: BoxConstraints(minWidth: 320),
  );
  final TextEditingController _controller = TextEditingController(
    text: 'Click here to start editing...',
  );

  final FocusNode _buttonFocusNode = FocusNode(debugLabel: 'Menu Button');
  late final gestures = {
    TapGestureRecognizer: GestureRecognizerFactoryWithHandlers(
      () => TapGestureRecognizer(debugOwner: this),
      (instance) {
        instance
          ..onTapDown = _handleTapDown
          ..onSecondaryTapDown = _handleSecondaryTapDown;
      },
    ),
  };

  bool _menuWasEnabled = false;

  @override
  void initState() {
    super.initState();
    _disableContextMenu();
  }

  @override
  void dispose() {
    _controller.dispose();
    _buttonFocusNode.dispose();
    _reenableContextMenu();
    super.dispose();
  }

  Future<void> _disableContextMenu() async {
    if (!kIsWeb) {
      // Does nothing on non-web platforms.
      return;
    }
    _menuWasEnabled = BrowserContextMenu.enabled;
    if (_menuWasEnabled) {
      await BrowserContextMenu.disableContextMenu();
    }
  }

  void _reenableContextMenu() {
    if (!kIsWeb) {
      // Does nothing on non-web platforms.
      return;
    }
    if (_menuWasEnabled && !BrowserContextMenu.enabled) {
      BrowserContextMenu.enableContextMenu();
    }
  }

  void _handleSecondaryTapDown(TapDownDetails details) {
    widget.menuController.open(position: details.localPosition);
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.menuController.isOpen) {
      widget.menuController.close();
      return;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        // Don't open the menu on these platforms with a Ctrl-tap (or a
        // tap).
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        // Only open the menu on these platforms if the control button is down
        // when the tap occurs.
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
    return CoreMenu(
      padding: const EdgeInsets.symmetric(vertical: 6),
      panel: panel,
      controller: widget.menuController,
      child: RawGestureDetector(
        gestures: gestures,
        excludeFromSemantics: true,
        child: widget.child,
      ),
    );
  }
}
