import 'package:base_menu/base_menu.dart';
import 'package:flutter/widgets.dart';

import '../../../shared/package.dart';
import '../theme/colors.dart';

class MenuBarButtonLabel extends StatelessWidget {
  const MenuBarButtonLabel({super.key, required this.child, required this.isInteractive});
  final Widget child;
  final bool isInteractive;

  static const _textStyle = TextStyle(
    fontFamily: 'GoogleSans',
    package: kPackage,
    fontSize: 14,
    letterSpacing: 0.2,
    fontWeight: FontWeight.w400,
    decoration: TextDecoration.none,
    inherit: false,
    color: FloogleColors.darkGray,
  );

  static const _decorationMap = {
    WidgetState.pressed: BoxDecoration(
      color: FloogleColors.menuItemPressedColor,
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    WidgetState.focused: BoxDecoration(
      color: FloogleColors.menuItemFocusColor,
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
  };

  static const WidgetStateProperty<BoxDecoration> _decoration = WidgetStateProperty.fromMap({
    ..._decorationMap,
    WidgetState.hovered: BoxDecoration(
      color: FloogleColors.onDarkGray,
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    WidgetState.any: BoxDecoration(),
  });

  static const _interactiveDecoration = WidgetStateProperty.fromMap({
    ..._decorationMap,
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

    if (isInteractive) {
      return DecoratedBox(
        decoration: _interactiveDecoration.resolve(BaseMenuItem.statesOf(context)),
        child: child,
      );
    } else {
      return DecoratedBox(
        decoration: _decoration.resolve(BaseMenuItem.statesOf(context)),
        child: child,
      );
    }
  }
}
