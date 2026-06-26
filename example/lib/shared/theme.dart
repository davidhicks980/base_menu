import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

const Color kSeedColor = Color(0xFF4285F4);
const Color kPressedColor = Color(0xFF174EA6);
const Color kHoverBg = Color(0xFFE8F0FE);
const Color kFocusBg = Color(0xFFD2E3FC);
const Color kDefaultText = Color(0xFF3C4043);
const Color kDisabledText = Color(0xFF9AA0A6);
const Color kTransparent = Color(0x00000000);
const Color kBlack = Color(0xFF000000);
const Color kWhite = Color(0xFFFFFFFF);

final WidgetStateProperty<BoxDecoration> demoButtonDecoration = WidgetStateProperty.fromMap({
  WidgetState.disabled: BoxDecoration(
    color: const Color(0xFFF1F3F4),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0xFFE0E0E0), width: 3.5),
  ),
  WidgetState.selected: BoxDecoration(
    color: kHoverBg,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: kSeedColor, width: 3.5),
  ),
  // Combination: Pressed + Focused + Hovered (Maximum prominence)
  WidgetState.pressed & WidgetState.focused & WidgetState.hovered: BoxDecoration(
    color: kPressedColor,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(width: 3.5),
    boxShadow: [BoxShadow(color: kSeedColor.withOpacity(0.4), blurRadius: 4)],
  ),
  WidgetState.pressed: BoxDecoration(
    color: kPressedColor,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: kTransparent, width: 3.5),
  ),
  // Combination: Focus + Hover
  WidgetState.focused & WidgetState.hovered: BoxDecoration(
    color: kFocusBg,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: kSeedColor, width: 3.5),
  ),
  WidgetState.focused: BoxDecoration(
    color: kTransparent,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: kSeedColor, width: 3.5),
  ),
  WidgetState.hovered: BoxDecoration(
    color: kSeedColor,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: kSeedColor.withOpacity(0.5), width: 3.5),
  ),
  WidgetState.any: BoxDecoration(
    color: kTransparent,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0xFFDADCE0), width: 3.5),
  ),
});

final WidgetStateProperty<BoxDecoration> demoMenuItemDecoration = WidgetStateProperty.fromMap({
  WidgetState.disabled: const BoxDecoration(color: kTransparent),
  WidgetState.pressed: BoxDecoration(
    color: kPressedColor,
    borderRadius: BorderRadius.circular(4),

    border: Border.all(color: kSeedColor, width: 3.5),
  ),
  WidgetState.pressed & WidgetState.focused: BoxDecoration(
    color: kPressedColor,
    borderRadius: BorderRadius.circular(4),
    border: Border.all(color: kSeedColor, width: 3.5),
  ),
  WidgetState.focused & WidgetState.hovered: BoxDecoration(
    color: kSeedColor,
    borderRadius: BorderRadius.circular(4),
    border: Border.all(color: kTransparent, width: 3.5),
  ),
  WidgetState.hovered: BoxDecoration(
    color: kSeedColor,
    borderRadius: BorderRadius.circular(4),
    border: Border.all(color: kSeedColor, width: 3.5),
  ),
  WidgetState.focused: BoxDecoration(
    color: kSeedColor.withOpacity(0.12),
    borderRadius: BorderRadius.circular(4),
    border: Border.all(color: kSeedColor, width: 3.5),
  ),
  WidgetState.any: const BoxDecoration(
    color: kTransparent,
    borderRadius: BorderRadius.all(Radius.circular(4)),
    border: Border.fromBorderSide(BorderSide(color: kTransparent, width: 3.5)),
  ),
});

final WidgetStateProperty<TextStyle> demoTextStyle = WidgetStateProperty.fromMap({
  WidgetState.disabled: const TextStyle(color: kDisabledText, fontFamily: 'InterVariable'),
  WidgetState.pressed: const TextStyle(color: kWhite, fontFamily: 'InterVariable'),
  WidgetState.hovered & WidgetState.pressed: const TextStyle(
    color: kBlack,
    fontFamily: 'InterVariable',
  ),
  WidgetState.hovered: const TextStyle(color: kWhite, fontFamily: 'InterVariable'),
  WidgetState.focused: const TextStyle(color: kDefaultText, fontFamily: 'InterVariable'),
  WidgetState.any: const TextStyle(color: kDefaultText, fontFamily: 'InterVariable'),
});

const WidgetStateProperty<TextStyle> demoButtonTextStyle = WidgetStateProperty.fromMap({
  WidgetState.disabled: TextStyle(color: kDisabledText, fontFamily: 'InterVariable'),
  WidgetState.pressed: TextStyle(color: kWhite, fontFamily: 'InterVariable'),
  WidgetState.hovered: TextStyle(color: kDefaultText, fontFamily: 'InterVariable'),
  WidgetState.focused: TextStyle(color: kDefaultText, fontFamily: 'InterVariable'),
  WidgetState.any: TextStyle(color: kDefaultText, fontFamily: 'InterVariable'),
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
              border: Border.fromBorderSide(BorderSide(color: kPressedColor, width: 3.5)),
              borderRadius: BorderRadius.all(Radius.circular(8)),
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
    return Container(
      decoration: MenuController.maybeIsOpenOf(context) ?? false
          ? const BoxDecoration(
              color: kPressedColor,
              border: Border.fromBorderSide(BorderSide(color: kPressedColor, width: 3.5)),
            )
          : demoMenuItemDecoration
                .resolve(BaseMenuItem.statesOf(context))
                .copyWith(borderRadius: BorderRadius.zero),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: IconTheme(
        data: IconThemeData(
          color: demoTextStyle
              .resolve(BaseMenuItem.statesOf(context))
              .copyWith(
                fontWeight: .w500,
                color: MenuController.maybeIsOpenOf(context) ?? false ? kWhite : null,
              )
              .color,
        ),
        child: DefaultTextStyle(
          style: demoTextStyle
              .resolve(BaseMenuItem.statesOf(context))
              .copyWith(
                fontWeight: .w500,
                color: MenuController.maybeIsOpenOf(context) ?? false ? kWhite : null,
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
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
          indent: 4,
          endIndent: 4,
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
      ),
      child: child,
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
    final double dpr = MediaQuery.devicePixelRatioOf(context);
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
          dpr: dpr,
        ),
      ),
    );
  }
}

class _PixelSnapPainter extends CustomPainter {
  _PixelSnapPainter({
    required this.orientation,
    required this.color,
    required this.thickness,
    required this.indent,
    required this.endIndent,
    required this.dpr,
  });

  final Axis orientation;
  final Color color;
  final int thickness;
  final double indent;
  final double endIndent;
  final double dpr;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;

    final double logicalThickness = thickness / dpr;

    if (orientation == Axis.horizontal) {
      // Horizontal line: Indent affects the X axis (left/right)
      final double top = ((size.height * dpr - thickness) / 2.0).round() / dpr;
      canvas.drawRect(
        Rect.fromLTWH(indent, top, size.width - indent - endIndent, logicalThickness),
        paint,
      );
    } else {
      // Vertical line: Indent affects the Y axis (top/bottom)
      final double left = ((size.width * dpr - thickness) / 2.0).round() / dpr;
      canvas.drawRect(
        Rect.fromLTWH(left, indent, logicalThickness, size.height - indent - endIndent),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PixelSnapPainter old) =>
      old.color != color ||
      old.dpr != dpr ||
      old.orientation != orientation ||
      old.indent != indent ||
      old.endIndent != endIndent;
}
