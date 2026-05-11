import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../utilities/colors.dart';

class MenuPanel extends StatelessWidget {
  const MenuPanel({
    super.key,
    this.padding = defaultPadding,
    this.constraints,
    this.axis = Axis.vertical,
    required this.children,
    this.clipBehavior = Clip.none,
    this.spacing = 0,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.color = FloogleColors.white,
  });

  static const defaultPadding = EdgeInsets.symmetric(vertical: 7, horizontal: 1);

  final EdgeInsetsGeometry padding;
  final BoxConstraints? constraints;
  final List<Widget> children;
  final BorderRadiusGeometry borderRadius;
  final Clip clipBehavior;
  final Axis axis;
  final double spacing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomMenuPanel(
      clipBehavior: clipBehavior,
      borderRadius: borderRadius,
      color: color,
      child: BaseMenuPanel(
        padding: padding,
        constraints: constraints,
        axis: axis,
        menuChildren: children,
        spacing: spacing,
      ),
    );
  }
}

class CustomMenuPanel extends StatelessWidget {
  const CustomMenuPanel({
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
