import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

import 'widget_state_decorated_box.dart';

class TitleIconButton extends StatelessWidget {
  const TitleIconButton({super.key, required this.child});
  final Widget child;

  static const _decoration = WidgetStateProperty<BoxDecoration>.fromMap({
    WidgetState.pressed: BoxDecoration(
      color: Color.from(alpha: 0.098, red: 0, green: 0, blue: 0),
      shape: BoxShape.circle,
    ),
    WidgetState.focused: BoxDecoration(
      color: Color.from(alpha: 0.059, red: 0, green: 0, blue: 0),
      shape: BoxShape.circle,
    ),
    WidgetState.hovered: BoxDecoration(
      color: Color.from(alpha: 0.059, red: 0, green: 0, blue: 0),
      shape: BoxShape.circle,
    ),
    WidgetState.any: BoxDecoration(),
  });

  @override
  Widget build(BuildContext context) {
    final icon = IconTheme(
      data: const IconThemeData(
        size: 18,
        color: Color.fromRGBO(68, 71, 70, 1),
        grade: 90,
        weight: kIsWeb ? 500 : 400,
      ),
      child: child,
    );
    return CoreTappable(
      mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
      child: SizedBox(
        width: 28,
        height: 28,
        child: WidgetStateDecoratedBox(decoration: _decoration, child: icon),
      ),
      onPressed: () {},
    );
  }
}
