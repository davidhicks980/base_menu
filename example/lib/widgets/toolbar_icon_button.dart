import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

import 'widget_state_decorated_box.dart';

class ToolbarIconButton extends StatelessWidget {
  const ToolbarIconButton({
    super.key,
    required this.child,
    this.onPressed,
    this.onHover,
    this.focusNode,
    this.tooltip,
    this.shortcut,
    this.showShortcutInTooltip = true,
    this.autofocus = false,
    this.intent,
    this.decoration,
    this.constraints = const BoxConstraints.tightFor(width: 30, height: 30),
    this.requestFocusOnHover = false,
    this.requestCloseOnActivate = true,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final String? tooltip;
  final void Function(bool)? onHover;
  final MenuSerializableShortcut? shortcut;
  final bool showShortcutInTooltip;
  final WidgetStateProperty<BoxDecoration>? decoration;
  final BoxConstraints constraints;
  final bool requestFocusOnHover;
  final bool requestCloseOnActivate;
  final bool autofocus;
  final Intent? intent;

  static const _decoration = WidgetStateProperty<BoxDecoration>.fromMap({
    WidgetState.pressed: BoxDecoration(
      color: Color.from(alpha: 0.098, red: 0, green: 0, blue: 0),
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    WidgetState.focused: BoxDecoration(
      color: Color.from(alpha: 0.059, red: 0, green: 0, blue: 0),
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    WidgetState.hovered: BoxDecoration(
      color: Color.from(alpha: 0.059, red: 0, green: 0, blue: 0),
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    WidgetState.any: BoxDecoration(),
  });

  @override
  Widget build(BuildContext context) {
    return CoreMenuItem(
      autofocus: autofocus,
      onPressed: onPressed,
      onHover: onHover,
      mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
      requestFocusOnHover: false,
      requestCloseOnActivate: requestCloseOnActivate,
      role: null,
      child: ConstrainedBox(
        constraints: constraints,
        child: WidgetStateDecoratedBox(decoration: decoration ?? _decoration, child: child),
      ),
    );
  }
}
