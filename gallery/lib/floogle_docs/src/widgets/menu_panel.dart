import 'package:base_menu/base_menu.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../theme/colors.dart';

class MenuPanel extends StatelessWidget {
  const MenuPanel({
    super.key,
    this.padding = defaultPadding,
    this.constraints,
    this.orientation = Axis.vertical,
    required this.children,
    this.clipBehavior = Clip.antiAlias,
    this.spacing = 0,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.color = FloogleColors.white,
    this.onSurfaceEnter,
    this.onSurfaceExit,
    this.onSurfaceHover,
    this.scrollable = true,
  });

  static const defaultPadding = EdgeInsets.symmetric(vertical: 7, horizontal: 1);

  final EdgeInsetsGeometry padding;
  final BoxConstraints? constraints;
  final List<Widget> children;
  final BorderRadiusGeometry borderRadius;
  final Clip clipBehavior;
  final Axis orientation;
  final double spacing;
  final Color color;
  final PointerEnterEventListener? onSurfaceEnter;
  final PointerHoverEventListener? onSurfaceHover;
  final PointerExitEventListener? onSurfaceExit;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return MenuPanelDecoration(
      clipBehavior: clipBehavior,
      borderRadius: borderRadius,
      color: color,
      child: BaseMenuPanel(
        padding: padding,
        constraints: constraints,
        orientation: orientation,
        spacing: spacing,
        scrollable: scrollable,
        onPointerEnter: onSurfaceEnter,
        onPointerHover: onSurfaceHover,
        onPointerExit: onSurfaceExit,
        children: children,
      ),
    );
  }
}

class MenuPanelDecoration extends StatelessWidget {
  const MenuPanelDecoration({
    super.key,
    required this.child,
    this.clipBehavior = Clip.none,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.color = FloogleColors.white,
  });

  final BorderRadiusGeometry borderRadius;
  final Clip clipBehavior;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: color,
      borderRadius: borderRadius,
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.15),
          blurRadius: 6,
          spreadRadius: 2,
          offset: Offset(0, 2),
        ),
      ],
    );

    if (clipBehavior == Clip.none) {
      return DecoratedBox(decoration: decoration, child: child);
    }

    return Container(decoration: decoration, clipBehavior: clipBehavior, child: child);
  }
}
