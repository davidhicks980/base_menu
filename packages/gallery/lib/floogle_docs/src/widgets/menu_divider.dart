import 'package:flutter/widgets.dart';

import '../theme/colors.dart';

class MenuDivider extends StatelessWidget {
  const MenuDivider({
    super.key,
    this.padding = const EdgeInsets.symmetric(vertical: 7.5),
    this.color = FloogleColors.separatorColor,
  });

  final EdgeInsets padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // This should be a SemanticsRole.separator, but this is currently not
    // supported by Flutter's semantics system.
    return IgnorePointer(
      child: Padding(
        padding: padding,
        child: ColoredBox(
          color: color,
          isAntiAlias: false,
          child: const SizedBox(height: 1, width: double.infinity),
        ),
      ),
    );
  }
}

class VerticalMenuDivider extends StatelessWidget {
  const VerticalMenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    // This should be a SemanticsRole.separator, but this is currently not
    // supported by Flutter's semantics system.
    return const IgnorePointer(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2, vertical: 5),
        child: ColoredBox(
          color: Color.from(alpha: 1, red: 0.769, green: 0.78, blue: 0.773),
          isAntiAlias: false,
          child: SizedBox(width: 1, height: 20),
        ),
      ),
    );
  }
}
