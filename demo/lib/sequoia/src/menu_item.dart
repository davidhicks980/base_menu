import 'package:base_menu/base_menu.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'menu_action_label.dart';

const Color _kSequoiaHighlightBackground = Color.fromRGBO(21, 99, 185, 1);
const Color _kSequoiaText = Color.fromARGB(255, 244, 244, 244);
const Color _kSequoiaTextFocused = Color(0xFFFFFFFF);

class SequoiaMenuItem extends StatefulWidget {
  const SequoiaMenuItem({
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
  State<SequoiaMenuItem> createState() => _SequoiaMenuItemState();
}

class _SequoiaMenuItemState extends State<SequoiaMenuItem> with SingleTickerProviderStateMixin {
  static const Duration _flashDuration = Duration(milliseconds: 200);
  Ticker? _flashTicker;
  int? _phase;

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
    if (_phase != phase) {
      setState(() {
        _phase = phase;
      });
      if (_phase == 1 && mounted) {
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
        child: SequoiaMenuActionLabel(
          leading: widget.leading,
          shortcut: widget.shortcut,
          backgroundColor: _phase != null
              ? switch (_phase) {
                  0 => const Color(0x00000000),
                  _ => _kSequoiaHighlightBackground,
                }
              : null,
          foregroundColor: _phase != null
              ? switch (_phase) {
                  0 => _kSequoiaText,
                  _ => _kSequoiaTextFocused,
                }
              : null,
          child: widget.child,
        ),
      ),
    );
  }
}
