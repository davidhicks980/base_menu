import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

import 'tooltip.dart';
import '../utilities/colors.dart';

class TitleIconButton extends StatelessWidget {
  const TitleIconButton({super.key, required this.child, required this.tooltip});
  final Widget child;
  final TextSpan tooltip;

  static const _decoration = WidgetStateProperty<BoxDecoration>.fromMap({
    WidgetState.pressed: BoxDecoration(
      color: FloogleColors.toolbarItemPressed,
      shape: BoxShape.circle,
    ),
    WidgetState.focused: BoxDecoration(
      color: FloogleColors.toolbarItemHoverFocus,
      shape: BoxShape.circle,
    ),
    WidgetState.hovered: BoxDecoration(
      color: FloogleColors.toolbarItemHoverFocus,
      shape: BoxShape.circle,
    ),
    WidgetState.any: BoxDecoration(),
  });

  @override
  Widget build(BuildContext context) {
    final icon = IconTheme(
      data: const IconThemeData(
        size: 18,
        color: FloogleColors.darkGray,
        grade: 90,
        weight: kIsWeb ? 500 : 400,
      ),
      child: child,
    );
    return MenuTooltip(
      message: tooltip,
      child: BaseControl(
        mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Builder(
            builder: (BuildContext context) {
              return DecoratedBox(
                decoration: _decoration.resolve(BaseControl.statesOf(context)),
                child: icon,
              );
            },
          ),
        ),
        onPressed: () {},
      ),
    );
  }
}
