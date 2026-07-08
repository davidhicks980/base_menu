import 'package:base_menu/base_menu.dart';
import 'package:flutter/widgets.dart';

import 'package.dart';

// Updated Constants
const Color kSeedColor = Color(0xFF445E91); // Primary
const Color kPressedColor = Color(0xFF2B4678); // onPrimaryContainer
const Color kDarkPressedColor = Color(0xFF1B2E55); // Darker version of primary
const Color kHoverBg = Color(0xFFD8E2FF); // primaryContainer
const Color kFocusBg = Color(0xFFDBE2F9); // secondaryContainer
const Color kDefaultText = Color(0xFF1A1B20); // onSurface
const Color kDisabledText = Color(0xFF74777F); // outline
const Color kTransparent = Color(0x00000000);
const Color kTransparentLight = Color(0x00FFFFFF);
const Color kBlack = Color(0xFF000000);
const Color kWhite = Color(0xFFFFFFFF);

const WidgetStateProperty<BoxDecoration> demoButtonDecoration = WidgetStateProperty.fromMap({
  WidgetState.disabled: BoxDecoration(
    color: const Color(0xFFEDEDF4), // surfaceContainer
    borderRadius: BorderRadius.all(Radius.circular(4)),
    border: Border.fromBorderSide(
      BorderSide(color: const Color(0xFFC4C6D0), width: 2),
    ), // outlineVariant
  ),
  WidgetState.pressed: BoxDecoration(
    color: kDarkPressedColor,
    borderRadius: BorderRadius.all(Radius.circular(4)),
    border: Border.fromBorderSide(BorderSide(color: kDarkPressedColor, width: 2)),
  ),
  WidgetState.focused: BoxDecoration(
    color: kTransparent,
    borderRadius: BorderRadius.all(Radius.circular(4)),
    border: Border.fromBorderSide(BorderSide(color: kSeedColor, width: 2)),
  ),
  WidgetState.hovered: BoxDecoration(
    color: kSeedColor,
    borderRadius: BorderRadius.all(Radius.circular(4)),
    border: Border.fromBorderSide(BorderSide(color: kSeedColor, width: 2)),
  ),
  WidgetState.any: BoxDecoration(
    color: kTransparent,
    borderRadius: BorderRadius.all(Radius.circular(4)),
    border: Border.fromBorderSide(
      BorderSide(color: const Color(0xFFC4C6D0), width: 2),
    ), // outlineVariant
  ),
});

final WidgetStateProperty<BoxDecoration> demoMenuItemDecoration = WidgetStateProperty.fromMap({
  WidgetState.disabled: const BoxDecoration(color: kTransparent),
  WidgetState.pressed: BoxDecoration(
    color: kPressedColor,
    border: Border.all(color: kPressedColor, width: 1.5),
  ),
  WidgetState.focused: BoxDecoration(
    color: kSeedColor,
    border: Border.all(color: kSeedColor, width: 1.5),
  ),
  WidgetState.any: const BoxDecoration(
    color: kTransparent,
    border: Border.fromBorderSide(BorderSide(color: kTransparent, width: 1.5)),
  ),
});

const WidgetStateProperty<TextStyle> demoTextStyle = WidgetStateProperty.fromMap({
  WidgetState.disabled: TextStyle(
    color: kDisabledText,
    fontFamily: 'InterVariable',
    package: kPackage,
  ),
  WidgetState.pressed: TextStyle(color: kWhite, fontFamily: 'InterVariable', package: kPackage),
  WidgetState.focused: TextStyle(color: kWhite, fontFamily: 'InterVariable', package: kPackage),
  WidgetState.any: TextStyle(color: kDefaultText, fontFamily: 'InterVariable', package: kPackage),
});

final WidgetStateProperty<TextStyle> demoButtonTextStyle = WidgetStateProperty.fromMap({
  WidgetState.disabled: const TextStyle(
    color: kDisabledText,
    fontFamily: 'InterVariable',
    package: kPackage,
  ),
  WidgetState.pressed: const TextStyle(
    color: kWhite,
    fontFamily: 'InterVariable',
    package: kPackage,
  ),
  (WidgetState.hovered & WidgetState.focused): const TextStyle(
    color: kDefaultText,
    fontFamily: 'InterVariable',
    package: kPackage,
  ),
  WidgetState.hovered: const TextStyle(
    color: kWhite,
    fontFamily: 'InterVariable',
    package: kPackage,
  ),
  WidgetState.focused: const TextStyle(
    color: kDefaultText,
    fontFamily: 'InterVariable',
    package: kPackage,
  ),
  WidgetState.any: const TextStyle(
    color: kDefaultText,
    fontFamily: 'InterVariable',
    package: kPackage,
  ),
});

class StyledMenuButtonChild extends StatelessWidget {
  const StyledMenuButtonChild({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: MenuController.maybeIsOpenOf(context) ?? false
          ? const BoxDecoration(
              color: kPressedColor,
              border: Border.fromBorderSide(BorderSide(color: kPressedColor, width: 1.5)),
              borderRadius: BorderRadius.all(Radius.circular(4)),
            )
          : demoButtonDecoration.resolve(BaseControl.statesOf(context)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: DefaultTextStyle(
        style: demoButtonTextStyle
            .resolve(BaseControl.statesOf(context))
            .copyWith(
              fontWeight: .w500,
              color: MenuController.maybeIsOpenOf(context) ?? false ? kWhite : null,
            ),
        child: child,
      ),
    );
  }
}

class StyledMenuBarChild extends StatelessWidget {
  const StyledMenuBarChild({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final states = BaseMenuItem.statesOf(context);
    return Container(
      decoration: demoMenuItemDecoration.resolve(states).copyWith(borderRadius: BorderRadius.zero),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: IconTheme(
        data: IconThemeData(color: demoTextStyle.resolve(states).copyWith(fontWeight: .w500).color),
        child: DefaultTextStyle(
          style: demoTextStyle.resolve(states).copyWith(fontWeight: .w500),
          child: child,
        ),
      ),
    );
  }
}

class StyledSubmenuChild extends StatelessWidget {
  const StyledSubmenuChild({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final states = BaseMenuItem.statesOf(context);
    return Container(
      decoration: (demoMenuItemDecoration)
          .resolve(states)
          .copyWith(borderRadius: BorderRadius.zero),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: IconTheme(
        data: IconThemeData(color: demoTextStyle.resolve(states).copyWith(fontWeight: .w500).color),
        child: DefaultTextStyle(
          style: demoTextStyle.resolve(states).copyWith(fontWeight: .w500),
          child: child,
        ),
      ),
    );
  }
}

class StyledMenuItemChild extends StatelessWidget {
  const StyledMenuItemChild({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final states = BaseMenuItem.statesOf(context);
    return Container(
      decoration: demoMenuItemDecoration.resolve(states),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: DefaultTextStyle(
        style: demoTextStyle.resolve(states).copyWith(fontWeight: FontWeight.w500),
        child: child,
      ),
    );
  }
}

class MenuDivider extends StatelessWidget {
  const MenuDivider.horizontal({super.key}) : orientation = Axis.horizontal;
  const MenuDivider.vertical({super.key}) : orientation = Axis.vertical;
  final Axis orientation;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: switch (orientation) {
        Axis.vertical => const PhysicalPixelDivider(
          orientation: Axis.vertical,
          color: Color(0xFFE0E0E0),
          thickness: 2,
          crossAxisExtent: 4,
          indent: 8,
          endIndent: 8,
        ),
        Axis.horizontal => const PhysicalPixelDivider(
          orientation: Axis.horizontal,
          color: Color(0xFFE0E0E0),
          thickness: 2,
          crossAxisExtent: 8,
          indent: 14,
          endIndent: 14,
        ),
      },
    );
  }
}

class StyledMenuBar extends StatelessWidget {
  const StyledMenuBar({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
  });
  final Widget child;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xffffffff),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: borderRadius.resolve(Directionality.of(context)),
      ),
      child: child,
    );
  }
}

class StyledMenuPanel extends StatelessWidget {
  const StyledMenuPanel({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
  });
  final Widget child;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xffffffff),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: borderRadius.resolve(Directionality.of(context)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class Separator extends StatelessWidget {
  const Separator.horizontal({super.key, required this.color, required this.thickness})
    : orientation = Axis.horizontal;
  const Separator.vertical({super.key, required this.color, required this.thickness})
    : orientation = Axis.vertical;
  final Axis orientation;
  final Color color;
  final int thickness;

  @override
  Widget build(BuildContext context) {
    return PhysicalPixelDivider(
      orientation: orientation,
      color: color,
      thickness: thickness,
      crossAxisExtent: thickness.toDouble(),
      indent: 0,
      endIndent: 0,
    );
  }
}

class PhysicalPixelDivider extends StatelessWidget {
  const PhysicalPixelDivider({
    super.key,
    required this.orientation,
    required this.color,
    required this.thickness,
    required this.crossAxisExtent,
    required this.indent,
    required this.endIndent,
  });

  final Axis orientation;
  final Color color;
  final int thickness;
  final double crossAxisExtent;
  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    final double pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return SizedBox(
      width: orientation == Axis.vertical ? crossAxisExtent : double.infinity,
      height: orientation == Axis.horizontal ? crossAxisExtent : double.infinity,
      child: CustomPaint(
        painter: _PixelSnapPainter(
          orientation: orientation,
          color: color,
          thickness: thickness,
          indent: indent,
          endIndent: endIndent,
          pixelRatio: pixelRatio,
        ),
      ),
    );
  }
}

class _PixelSnapPainter extends CustomPainter {
  const _PixelSnapPainter({
    required this.orientation,
    required this.color,
    required this.thickness,
    required this.indent,
    required this.endIndent,
    required this.pixelRatio,
  });

  final Axis orientation;
  final Color color;
  final int thickness;
  final double indent;
  final double endIndent;
  final double pixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;

    final double logicalThickness = thickness / pixelRatio;

    if (orientation == Axis.horizontal) {
      // Horizontal line: Indent affects the X axis (left/right)
      final double top = ((size.height * pixelRatio - thickness) / 2.0).round() / pixelRatio;
      canvas.drawRect(
        Rect.fromLTWH(indent, top, size.width - indent - endIndent, logicalThickness),
        paint,
      );
    } else {
      // Vertical line: Indent affects the Y axis (top/bottom)
      final double left = ((size.width * pixelRatio - thickness) / 2.0).round() / pixelRatio;
      canvas.drawRect(
        Rect.fromLTWH(left, indent, logicalThickness, size.height - indent - endIndent),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PixelSnapPainter old) =>
      old.color != color ||
      old.pixelRatio != pixelRatio ||
      old.orientation != orientation ||
      old.indent != indent ||
      old.endIndent != endIndent;
}
