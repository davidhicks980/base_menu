import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../utilities/colors.dart';

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
      color: FloogleColors.toolbarItemPressed,
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    WidgetState.focused: BoxDecoration(
      color: FloogleColors.toolbarItemHoverFocus,
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    WidgetState.hovered: BoxDecoration(
      color: FloogleColors.toolbarItemHoverFocus,
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    WidgetState.any: BoxDecoration(),
  });

  @override
  Widget build(BuildContext context) {
    return BaseMenuItem(
      autofocus: autofocus,
      onPressed: onPressed,
      onHover: onHover,
      mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
      requestFocusOnHover: false,
      requestCloseOnActivate: requestCloseOnActivate,
      role: null,
      child: ConstrainedBox(
        constraints: constraints,
        child: Builder(
          builder: (context) {
            return DecoratedBox(
              decoration: (decoration ?? _decoration).resolve(BaseMenuItem.statesOf(context)),
              child: child,
            );
          },
        ),
      ),
    );
  }
}
