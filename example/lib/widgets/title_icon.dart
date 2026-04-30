import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

class TitleIconButton extends StatelessWidget {
  const TitleIconButton({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final icon = IconTheme(
      data: const IconThemeData(size: 18, color: Color.fromRGBO(68, 71, 70, 1), grade: 90),
      child: child,
    );
    return CoreTappable(
      mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
      child: SizedBox(
        width: 28,
        height: 28,
        child: Builder(
          builder: (context) {
            final Color color;
            if (CoreTappable.isPressedOf(context)) {
              color = const Color.from(alpha: 1, red: 0.898, green: 0.898, blue: 0.898);
            } else if (CoreTappable.isFocusedOf(context)) {
              color = const Color.from(alpha: 1, red: 0.949, green: 0.949, blue: 0.949);
            } else {
              color = const Color.from(alpha: 0, red: 0, green: 0, blue: 0);
            }
            return DecoratedBox(
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: icon,
            );
          },
        ),
      ),
      onPressed: () {},
    );
  }
}
