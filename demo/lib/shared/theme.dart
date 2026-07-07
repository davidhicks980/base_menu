import 'package:base_menu/base_menu.dart';
import 'package:flutter/widgets.dart';

import '../floogle_docs/src/theme/colors.dart';
import 'package.dart';

const Color kSeedColor = Color(0xFF4285F4);
const Color kPressedColor = Color(0xFF174EA6);
const Color kDarkPressedColor = Color.fromARGB(255, 10, 48, 109);
const Color kHoverBg = Color(0xFFE8F0FE);
const Color kFocusBg = Color(0xFFD2E3FC);
const Color kDefaultText = Color(0xFF3C4043);
const Color kDisabledText = Color(0xFF9AA0A6);
const Color kTransparent = Color(0x00000000);
const Color kTransparentLight = Color(0x00FFFFFF);
const Color kBlack = Color(0xFF000000);
const Color kWhite = Color(0xFFFFFFFF);

@immutable
class AppTheme {
  const AppTheme({
    required this.brightness,
    required this.surface,
    required this.elevatedSurface,
    required this.separator,
    required this.text,
    required this.mutedText,
    required this.selection,
    required this.focus,
    required this.hover,
    required this.highlight,
    required this.transparent,
  });

  final Brightness brightness;
  final Color surface;
  final Color elevatedSurface;
  final Color separator;
  final Color text;
  final Color mutedText;
  final Color selection;
  final Color focus;
  final Color hover;
  final Color highlight;
  final Color transparent;

  Color get shade => brightness == Brightness.light ? kWhite : kBlack;

  // Light theme based on FloogleColors
  static const AppTheme light = AppTheme(
    brightness: Brightness.light,
    surface: FloogleColors.surfaceColor,
    elevatedSurface: FloogleColors.elevatedSurfaceColor,
    separator: FloogleColors.lightSeparatorColor,
    text: FloogleColors.black,
    mutedText: FloogleColors.grey,
    selection: FloogleColors.selectedButtonBackground,
    focus: FloogleColors.toolbarItemHoverFocus, // Add to FloogleColors if missing
    hover: FloogleColors.toolbarItemHoverFocus,
    highlight: Color.fromARGB(255, 66, 133, 244),
    transparent: kTransparentLight,
  );

  // Dark theme based on Sequoia (macOS dark-mode inspired)
  static const AppTheme dark = AppTheme(
    brightness: Brightness.dark,
    surface: Color(0xA82F3133), // From Sequoia surface
    elevatedSurface: Color(0xFF1F1F1F),
    separator: Color(0x38FFFFFF), // From Sequoia divider
    text: Color(0xFFFFFFFF),
    mutedText: Color(0xB3FFFFFF), // White with 70% opacity
    selection: Color.fromARGB(255, 0, 119, 255),
    focus: Color(0x1AFFFFFF),
    hover: Color(0x0AFFFFFF),
    highlight: Color.fromARGB(255, 0, 119, 255),
    transparent: Color(0x00000000),
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is AppTheme &&
        other.brightness == brightness &&
        other.surface == surface &&
        other.elevatedSurface == elevatedSurface &&
        other.separator == separator &&
        other.text == text &&
        other.mutedText == mutedText &&
        other.selection == selection &&
        other.focus == focus &&
        other.hover == hover &&
        other.highlight == highlight &&
        other.transparent == transparent;
  }

  @override
  int get hashCode {
    return brightness.hashCode ^
        surface.hashCode ^
        elevatedSurface.hashCode ^
        separator.hashCode ^
        text.hashCode ^
        mutedText.hashCode ^
        selection.hashCode ^
        focus.hashCode ^
        hover.hashCode ^
        highlight.hashCode ^
        transparent.hashCode;
  }
}

final WidgetStateProperty<BoxDecoration> demoButtonDecoration = WidgetStateProperty.fromMap({
  WidgetState.disabled: BoxDecoration(
    color: const Color(0xFFF1F3F4),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0xFFE0E0E0), width: 3.5),
  ),

  WidgetState.pressed: BoxDecoration(
    color: kDarkPressedColor,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: kDarkPressedColor, width: 3.5),
  ),
  WidgetState.focused: BoxDecoration(
    color: kTransparent,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: kSeedColor, width: 3.5),
  ),
  WidgetState.hovered: BoxDecoration(
    color: kSeedColor,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: kSeedColor, width: 3.5),
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
    border: Border.all(color: kPressedColor, width: 3.5),
  ),
  WidgetState.focused: BoxDecoration(
    color: kSeedColor,
    borderRadius: BorderRadius.circular(4),
    border: Border.all(color: kSeedColor, width: 3.5),
  ),
  WidgetState.any: const BoxDecoration(
    color: kTransparent,
    borderRadius: BorderRadius.all(Radius.circular(4)),
    border: Border.fromBorderSide(BorderSide(color: kTransparent, width: 3.5)),
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
  const StyledSubmenuChild({super.key, required this.child, this.decoration});
  final Widget child;
  final WidgetStateProperty<BoxDecoration>? decoration;

  @override
  Widget build(BuildContext context) {
    final states = BaseMenuItem.statesOf(context);
    return Container(
      decoration: (decoration ?? demoMenuItemDecoration)
          .resolve(states)
          .copyWith(borderRadius: BorderRadius.zero),
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
  const _PixelSnapPainter({
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
