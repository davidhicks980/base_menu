import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

class WidgetStateDecoratedBox extends StatelessWidget {
  const WidgetStateDecoratedBox({
    super.key,
    required this.child,
    required this.decoration,
    this.position = DecorationPosition.background,
  });

  final Widget child;
  final DecorationPosition position;
  final WidgetStateProperty<Decoration> decoration;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      position: position,
      decoration: decoration.resolve(CoreButton.statesOf(context)),
      child: child,
    );
  }
}
