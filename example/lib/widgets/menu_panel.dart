import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../utilities/colors.dart';

class MenuPanel extends StatelessWidget {
  const MenuPanel({
    super.key,
    this.padding = EdgeInsets.zero,
    this.constraints,
    this.axis = Axis.vertical,
    required this.children,
    this.clipBehavior = Clip.none,
    this.spacing = 0,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
  });

  final EdgeInsetsGeometry padding;
  final BoxConstraints? constraints;
  final List<Widget> children;
  final BorderRadiusGeometry borderRadius;
  final Clip clipBehavior;
  final Axis axis;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final panel = CoreMenuPanel(
      padding: padding,
      constraints: constraints,
      axis: axis,
      menuChildren: children,
      spacing: spacing,
    );
    final decoration = BoxDecoration(
      color: FloogleColors.white,
      borderRadius: borderRadius,
      boxShadow: const <BoxShadow>[
        BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.2), blurRadius: 4, offset: Offset(0, 2)),
      ],
    );
    if (clipBehavior == Clip.none) {
      return DecoratedBox(decoration: decoration, child: panel);
    }

    return Container(decoration: decoration, clipBehavior: clipBehavior, child: panel);
  }
}
