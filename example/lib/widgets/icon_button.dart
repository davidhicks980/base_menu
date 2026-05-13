import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../utilities/colors.dart';

class IconLabel extends StatelessWidget {
  const IconLabel({
    super.key,
    this.decoration,
    this.constraints = const BoxConstraints.tightFor(width: 30, height: 30),
    required this.child,
  });
  final WidgetStateProperty<BoxDecoration>? decoration;
  final BoxConstraints constraints;
  final Widget child;

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
    return DecoratedBox(
      decoration: (decoration ?? _decoration).resolve(BaseMenuItem.statesOf(context)),
      child: ConstrainedBox(constraints: constraints, child: child),
    );
  }
}

class IconButton extends StatelessWidget {
  const IconButton({
    super.key,
    required this.child,
    this.onPressed,
    this.onFocusChange,
    this.focusNode,
    this.tooltip,
    this.requestFocusOnHover = false,
    this.autofocus = false,
    this.decoration,
    this.constraints = const BoxConstraints.tightFor(width: 30, height: 30),
  });

  final Widget child;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final String? tooltip;
  final void Function(bool)? onFocusChange;
  final WidgetStateProperty<BoxDecoration>? decoration;
  final BoxConstraints constraints;
  final bool autofocus;
  final bool requestFocusOnHover;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tooltip,
      child: BaseMenuItem(
        autofocus: autofocus,
        onTap: onPressed,
        onFocusChange: onFocusChange,
        mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
        focusNode: focusNode,
        role: null,
        requestCloseOnActivate: false,
        requestFocusOnHover: requestFocusOnHover,
        child: IconLabel(decoration: decoration, constraints: constraints, child: child),
      ),
    );
  }
}
