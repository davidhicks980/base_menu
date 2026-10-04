import 'package:base_menu/base_menu.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'menu_action_label.dart';
import 'theme.dart';

const Color _kCupertinoText = Color.fromARGB(255, 244, 244, 244);
const Color _kCupertinoTextFocused = Color(0xFFFFFFFF);

class CupertinoMenuItem extends StatefulWidget {
  const CupertinoMenuItem({
    super.key,
    this.onTap = emptyCallback,
    required this.child,
    this.leading,
    this.shortcut,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Widget? leading;
  final MenuSerializableShortcut? shortcut;

  static void emptyCallback() {}

  @override
  State<CupertinoMenuItem> createState() => _CupertinoMenuItemState();
}

class _CupertinoMenuItemState extends State<CupertinoMenuItem> with SingleTickerProviderStateMixin {
  static const Duration _flashDuration = Duration(milliseconds: 200);
  Ticker? _flashTicker;
  int? _flashPhase;

  @override
  void dispose() {
    _flashTicker?.dispose();
    _flashTicker = null;
    super.dispose();
  }

  void _handleTap() {
    widget.onTap?.call();
    _flashTicker ??= createTicker(_handleTick)..start();
  }

  void _handleTick(Duration elapsed) {
    if (elapsed >= _flashDuration) {
      _flashTicker?.stop();
      _flashTicker?.dispose();
      _flashTicker = null;
      return;
    }

    final int phase = (elapsed.inMicroseconds * 3) ~/ _flashDuration.inMicroseconds;
    if (_flashPhase != phase) {
      setState(() {
        _flashPhase = phase;
      });
      if (_flashPhase == 1 && mounted) {
        if (MenuController.maybeOf(context)?.isOpen ?? false) {
          Actions.invoke(context, const DismissIntent());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseMenuItem(
      requestCloseOnActivate: false,
      onPressed: widget.onTap != null ? _handleTap : null,
      child: RepaintBoundary(
        child: CupertinoMenuActionLabel(
          leading: widget.leading,
          shortcut: widget.shortcut,
          backgroundColor: _flashPhase != null
              ? switch (_flashPhase) {
                  0 => const Color(0x00000000),
                  _ => CupertinoMenuItemTheme.of(context).highlightColor,
                }
              : null,
          foregroundColor: _flashPhase != null
              ? switch (_flashPhase) {
                  0 => _kCupertinoText,
                  _ => _kCupertinoTextFocused,
                }
              : null,
          child: widget.child,
        ),
      ),
    );
  }
}
