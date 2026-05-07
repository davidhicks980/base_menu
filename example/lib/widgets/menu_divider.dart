import 'package:flutter/widgets.dart';

import '../utilities/colors.dart';

class MenuDivider extends StatelessWidget {
  const MenuDivider({
    super.key,
    this.padding = const EdgeInsets.symmetric(vertical: 7.5),
    this.color = FloogleColors.lightSeparatorColor,
  });

  final EdgeInsets padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // This should be a SemanticsRole.separator, but this is currently not
    // supported by Flutter's semantics system.
    return Padding(
      padding: padding,
      child: ColoredBox(
        color: color,
        isAntiAlias: false,
        child: const SizedBox(height: 1, width: double.infinity),
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
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 5),
      child: ColoredBox(
        color: FloogleColors.separatorColor,
        isAntiAlias: false,
        child: SizedBox(width: 1, height: 20),
      ),
    );
  }
}
