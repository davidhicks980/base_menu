import 'package:base_menu/base_menu.dart';
import 'package:flutter/widgets.dart';

import 'package.dart';
import 'separator.dart';

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
    color: Color(0xFFEDEDF4), // surfaceContainer
    borderRadius: BorderRadius.all(Radius.circular(4)),
    border: Border.fromBorderSide(
      BorderSide(color: Color(0xFFC4C6D0), width: 1.5),
    ), // outlineVariant
  ),
  WidgetState.pressed: BoxDecoration(
    color: kDarkPressedColor,
    borderRadius: BorderRadius.all(Radius.circular(4)),
    border: Border.fromBorderSide(BorderSide(color: kDarkPressedColor, width: 1.5)),
  ),
  WidgetState.focused: BoxDecoration(
    color: kTransparent,
    borderRadius: BorderRadius.all(Radius.circular(4)),
    border: Border.fromBorderSide(BorderSide(color: kSeedColor, width: 1.5)),
  ),
  WidgetState.hovered: BoxDecoration(
    color: kSeedColor,
    borderRadius: BorderRadius.all(Radius.circular(4)),
    border: Border.fromBorderSide(BorderSide(color: kSeedColor, width: 1.5)),
  ),
  WidgetState.any: BoxDecoration(
    color: kTransparent,
    borderRadius: BorderRadius.all(Radius.circular(4)),
    border: Border.fromBorderSide(BorderSide(color: Color(0xFFC4C6D0), width: 1.5)),
  ),
});

const WidgetStateProperty<BoxDecoration> demoMenuItemDecoration = WidgetStateProperty.fromMap({
  WidgetState.disabled: BoxDecoration(color: kTransparent),
  WidgetState.pressed: BoxDecoration(
    color: kPressedColor,
    border: Border.fromBorderSide(BorderSide(color: kPressedColor, width: 1.5)),
  ),
  WidgetState.focused: BoxDecoration(
    color: kSeedColor,
    border: Border.fromBorderSide(BorderSide(color: kSeedColor, width: 1.5)),
  ),
  WidgetState.any: BoxDecoration(
    color: kTransparent,
    border: Border.fromBorderSide(BorderSide(color: kTransparent, width: 1.5)),
  ),
});

const WidgetStateProperty<TextStyle> demoTextStyle = WidgetStateProperty.fromMap({
  WidgetState.disabled: TextStyle(
    color: kDisabledText,
    fontFamily: 'InterVariable',
    fontWeight: .w500,
    package: kPackage,
  ),
  WidgetState.pressed: TextStyle(
    color: kWhite,
    fontWeight: .w500,
    fontFamily: 'InterVariable',
    package: kPackage,
  ),
  WidgetState.focused: TextStyle(
    color: kWhite,
    fontWeight: .w500,
    fontFamily: 'InterVariable',
    package: kPackage,
  ),
  WidgetState.any: TextStyle(
    color: kDefaultText,
    fontWeight: .w500,
    fontFamily: 'InterVariable',
    package: kPackage,
  ),
});

const WidgetStateProperty<TextStyle> demoButtonTextStyle = WidgetStateProperty.fromMap({
  WidgetState.disabled: TextStyle(
    color: kDisabledText,
    fontWeight: .w500,
    fontFamily: 'InterVariable',
    package: kPackage,
  ),
  WidgetState.pressed: TextStyle(
    color: kWhite,
    fontWeight: .w500,
    fontFamily: 'InterVariable',
    package: kPackage,
  ),
  WidgetState.focused: TextStyle(
    color: kDefaultText,
    fontWeight: .w500,
    fontFamily: 'InterVariable',
    package: kPackage,
  ),
  WidgetState.hovered: TextStyle(
    color: kWhite,
    fontWeight: .w500,
    fontFamily: 'InterVariable',
    package: kPackage,
  ),

  WidgetState.any: TextStyle(
    color: kDefaultText,
    fontWeight: .w500,
    fontFamily: 'InterVariable',
    package: kPackage,
  ),
});

class StyledMenuButtonChild extends StatelessWidget {
  const StyledMenuButtonChild({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final states = BaseControl.statesOf(context);
    return Container(
      decoration: MenuController.maybeIsOpenOf(context) ?? false
          ? const BoxDecoration(
              color: kPressedColor,
              border: Border.fromBorderSide(BorderSide(color: kPressedColor, width: 1.5)),
              borderRadius: BorderRadius.all(Radius.circular(4)),
            )
          : demoButtonDecoration.resolve(states),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: DefaultTextStyle(
        style: demoButtonTextStyle
            .resolve(states)
            .copyWith(color: MenuController.maybeIsOpenOf(context) ?? false ? kWhite : null),
        child: child,
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
    final textStyle = demoTextStyle.resolve(states);
    return Container(
      decoration: demoMenuItemDecoration.resolve(states),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: IconTheme(
        data: IconThemeData(color: textStyle.color),
        child: DefaultTextStyle(style: textStyle, child: child),
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
        border: Border.all(color: const Color(0xFFFFFFFF)),
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
