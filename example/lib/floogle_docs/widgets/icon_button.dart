import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../utilities/colors.dart';
import 'tooltip.dart';

class ToolbarIconButton extends StatelessWidget {
  const ToolbarIconButton({
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
    this.enableTooltipSemantics = true,
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
  final bool enableTooltipSemantics;

  @override
  Widget build(BuildContext context) {
    final item = BaseMenuItem(
      autofocus: autofocus,
      onPressed: onPressed,
      onFocusChange: onFocusChange,
      mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
      focusNode: focusNode,
      role: null,
      requestCloseOnActivate: false,
      requestFocusOnHover: requestFocusOnHover,
      child: _IconLabel(decoration: decoration, constraints: constraints, child: child),
    );

    if (tooltip == null) {
      return item;
    }

    return MenuTooltip(
      enableSemantics: enableTooltipSemantics,
      message: TextSpan(text: tooltip),
      child: item,
    );
  }
}

class _IconLabel extends StatelessWidget {
  const _IconLabel({
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
