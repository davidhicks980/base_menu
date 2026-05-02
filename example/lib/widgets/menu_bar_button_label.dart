import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../utilities/colors.dart';

class MenuBarButtonLabel extends StatelessWidget {
  const MenuBarButtonLabel(this.child, {super.key, this.decoration});
  final Widget child;
  final Decoration? decoration;

  static const _textStyle = TextStyle(
    fontFamily: 'GoogleSans',
    fontSize: 14,
    letterSpacing: 0.2,
    fontWeight: FontWeight.w400,
    decoration: TextDecoration.none,
    inherit: false,
    color: FloogleColors.darkGray,
  );

  static const _openBorderRadius = BorderRadiusDirectional.only(
    topStart: Radius.circular(4),
    topEnd: Radius.circular(4),
  );

  static const WidgetStateProperty<BoxDecoration> _decoration = WidgetStateProperty.fromMap({
    WidgetState.pressed: BoxDecoration(
      color: FloogleColors.menuItemPressedColor,
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    WidgetState.focused: BoxDecoration(
      color: FloogleColors.menuItemFocusColor,
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    WidgetState.hovered: BoxDecoration(
      color: FloogleColors.logoFocusHoverColor,
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    WidgetState.any: BoxDecoration(),
  });

  @override
  Widget build(BuildContext context) {
    final Widget child = Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 2.0, 8.0, 2.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 17.5, minWidth: 22.5),
        child: Center(
          child: DefaultTextStyle(
            style: _textStyle,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            child: this.child,
          ),
        ),
      ),
    );

    if (decoration != null) {
      return DecoratedBox(decoration: decoration!, child: child);
    }

    return Builder(
      builder: (context) {
        final isOpen = MenuController.maybeIsOpenOf(context) ?? false;
        BoxDecoration decoration = _decoration.resolve(CoreTappable.statesOf(context));
        if (isOpen) {
          decoration = decoration.copyWith(
            borderRadius: _openBorderRadius,
            color: FloogleColors.menuItemFocusColor,
          );
        }
        return DecoratedBox(decoration: decoration, child: child);
      },
    );
  }
}
