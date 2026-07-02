import 'package:flutter/material.dart';
import 'package:menu_utilities/menu_utilities.dart';

/// A menu item that changes color when hovered, focused, or pressed.
class MenuItem extends StatelessWidget {
  const MenuItem({super.key, required this.child, required this.onPressed, this.suffix});
  final Widget child;
  final Widget? suffix;
  final VoidCallback? onPressed;

  static const WidgetStateProperty<BoxDecoration> decoration = WidgetStateProperty.fromMap({
    WidgetState.pressed: BoxDecoration(color: Color(0xFFE9E9E9)),
    WidgetState.hovered: BoxDecoration(color: Color(0xFFEDEDED)),
    WidgetState.focused: BoxDecoration(color: Color(0xFFEDEDED)),
    WidgetState.any: BoxDecoration(color: Color(0x00000000)),
  });

  @override
  Widget build(BuildContext context) {
    final Widget body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: suffix != null
          ? Row(spacing: 12, mainAxisAlignment: .spaceBetween, children: [child, suffix!])
          : child,
    );

    return BaseMenuItem(
      onPressed: () {},
      child: Builder(
        builder: (context) {
          // Rebuilds any time the menu item is hovered, focused, pressed, or
          // disabled.
          return DecoratedBox(
            decoration: decoration.resolve(BaseMenuItem.statesOf(context)),
            child: body,
          );
        },
      ),
    );
  }
}

/// A suffix that changes color when its parent menu item is hovered.
class Suffix extends StatelessWidget {
  const Suffix({super.key});

  @override
  Widget build(BuildContext context) {
    const box = SizedBox.square(dimension: 20);
    // Rebuilds only when the parent menu item is hovered.
    if (BaseMenuItem.isHoveredOf(context)) {
      return const ColoredBox(color: Color(0xFFFF0000), child: box);
    } else {
      return const ColoredBox(color: Color(0xFF000000), child: box);
    }
  }
}

/// A suffix that changes color it is hovered, but not when its parent menu item
/// is hovered.
class HoverableSuffix extends StatelessWidget {
  const HoverableSuffix({super.key});

  @override
  Widget build(BuildContext context) {
    const box = SizedBox.square(dimension: 20);
    return BaseHoverable(
      child: Builder(
        builder: (context) {
          // Rebuilds only when this widget is hovered.
          if (BaseHoverable.isHoveredOf(context)) {
            return const ColoredBox(color: Color(0xFFFF0000), child: box);
          } else {
            return const ColoredBox(color: Color(0xFF000000), child: box);
          }
        },
      ),
    );
  }
}

/// A suffix that passes its hover state to its child.
class SpecializedSuffix extends StatelessWidget {
  const SpecializedSuffix({super.key, required this.child});
  final Widget child;

  static bool isHovered(BuildContext context) {
    return BaseHoverable.isHoveredOf<SpecializedSuffix>(context);
  }

  @override
  Widget build(BuildContext context) {
    return BaseHoverable<SpecializedSuffix>(
      child: ConstrainedBox(
        constraints: const BoxConstraints.tightFor(width: 20, height: 20),
        child: child,
      ),
    );
  }
}

class SpecializedSuffixChild extends StatelessWidget {
  const SpecializedSuffixChild({super.key});

  @override
  Widget build(BuildContext context) {
    return SpecializedSuffix(
      child: Builder(
        builder: (context) {
          // The child can now use SpecializedSuffix.isHovered(context) to determine
          // if it is hovered.
          if (SpecializedSuffix.isHovered(context)) {
            return const ColoredBox(color: Color(0xFFFF0000));
          } else {
            return const ColoredBox(color: Color(0xFF000000));
          }
        },
      ),
    );
  }
}
