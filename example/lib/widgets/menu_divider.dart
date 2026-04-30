import 'package:flutter/widgets.dart';

class MenuDivider extends StatelessWidget {
  const MenuDivider({
    super.key,
    this.padding = const EdgeInsets.symmetric(vertical: 7.5),
    this.color = _color,
  });

  final EdgeInsets padding;
  final Color color;

  static const _color = Color(0xFFdadce0);

  @override
  Widget build(BuildContext context) {
    // This should be a SemanticsRole.separator, but this is currently not
    // supported by Flutter's semantics system.
    return Padding(
      padding: padding,
      child: const ColoredBox(
        color: _color,
        isAntiAlias: false,
        child: SizedBox(height: 1, width: double.infinity),
      ),
    );
  }
}

class VerticalMenuDivider extends StatelessWidget {
  const VerticalMenuDivider({super.key});

  static const _color = Color(0xFFc4c7c5);

  @override
  Widget build(BuildContext context) {
    // This should be a SemanticsRole.separator, but this is currently not
    // supported by Flutter's semantics system.
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 10),
      child: ColoredBox(color: _color, isAntiAlias: false, child: SizedBox(width: 1, height: 20)),
    );
  }
}
