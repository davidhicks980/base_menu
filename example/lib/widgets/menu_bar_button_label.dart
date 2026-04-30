import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

class MenuBarButtonLabel extends StatelessWidget {
  const MenuBarButtonLabel(this.child, {super.key, this.decoration});
  final Widget child;
  final Decoration? decoration;

  static const _textStyleWeb = TextStyle(
    fontFamily: 'RobotoFlex',
    fontSize: 14,
    fontWeight: FontWeight(490),
    decoration: TextDecoration.none,
    inherit: false,
    fontVariations: [FontVariation.opticalSize(15)],
    color: Color.from(alpha: 1, red: 0.122, green: 0.122, blue: 0.122),
  );

  static const _textStyle = TextStyle(
    fontFamily: 'GoogleSans',
    fontSize: 14,
    letterSpacing: 0.2,
    fontWeight: FontWeight.w400,
    decoration: TextDecoration.none,
    inherit: false,
    color: Color.from(alpha: 1, red: 0.122, green: 0.122, blue: 0.122),
  );

  static const _openBorderRadius = BorderRadiusDirectional.only(
    topStart: Radius.circular(4),
    topEnd: Radius.circular(4),
  );

  static const WidgetStateProperty<BoxDecoration> _decoration = WidgetStateProperty.fromMap({
    WidgetState.pressed: BoxDecoration(
      color: Color.from(alpha: 1, red: 0.912156, blue: 0.912156, green: 0.912156),
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    WidgetState.focused: BoxDecoration(
      color: Color.from(alpha: 1, red: 0.929726, blue: 0.929726, green: 0.929726),
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    WidgetState.hovered: BoxDecoration(
      color: Color.from(alpha: 1, red: 0.929726, blue: 0.929726, green: 0.929726),
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    WidgetState.any: BoxDecoration(),
  });

  @override
  Widget build(BuildContext context) {
    const textStyle = kIsWeb ? _textStyleWeb : _textStyle;
    final Widget child = Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 2.0, 8.0, 2.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 17.5, minWidth: 22.5),
        child: Center(
          child: DefaultTextStyle(
            style: textStyle,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
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
            color: const Color.from(alpha: 1, red: 0.929726, blue: 0.929726, green: 0.929726),
          );
        }
        return DecoratedBox(decoration: decoration, child: child);
      },
    );
  }
}
