import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../../shared/localized_shortcut_labeler.dart';

// Sequoia 15 Style Constants
const double _kSequoiaMenuFontSize = 13.0;
const double _kSequoiaMenuIconSize = 14.0;
const EdgeInsets _kSequoiaMenuItemPadding = EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.5);
const BorderRadius _kSequoiaMenuBorderRadius = BorderRadius.all(Radius.circular(4.0));

// Colors
const Color _kSequoiaHighlightBackground = Color.fromRGBO(21, 99, 185, 1); // Sequoia Accent Blue
const Color _kSequoiaForegroundHighlighted = Colors.white;

const Color _kSequoiaTextDark = Color(0xFFFFFFFF);
const Color _kSequoiaShortcutDark = Color.fromARGB(90, 255, 255, 255);

const _webFontStyle = TextStyle(
  fontFamily: 'Main',
  decoration: .none,
  fontVariations: [FontVariation.opticalSize(16), FontVariation.weight(450)],
);

const _cupertinoFontStyle = TextStyle(
  fontFamily: 'CupertinoSystemText',
  letterSpacing: -0.1, // SF Pro standard tight tracking
  height: 1.2,
  decoration: TextDecoration.none,
);

TextStyle get textStyle => switch (defaultTargetPlatform) {
  .iOS || .macOS when !kIsWeb => _cupertinoFontStyle,
  _ => _webFontStyle,
};

class SequoiaSubmenuActionLabel extends StatelessWidget {
  const SequoiaSubmenuActionLabel({
    super.key,
    required this.child,
    this.leadingContentWidth = 20,
    this.leading,
    this.trailing,
    this.shortcut,
  });

  final Widget? leading;
  final double leadingContentWidth;
  final Widget? trailing;
  final MenuSerializableShortcut? shortcut;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SequoiaMenuActionLabel(
      leading: leading,
      leadingContentWidth: leadingContentWidth,
      trailing: const _SequoiaSubmenuChevron(),
      shortcut: shortcut,
      child: child,
    );
  }
}

class SequoiaMenuActionLabel extends StatelessWidget {
  const SequoiaMenuActionLabel({
    super.key,
    required this.child,
    this.leading,
    this.leadingContentWidth = 20,
    this.trailing,
    this.shortcut,
  });

  final Widget? leading;
  final double leadingContentWidth;
  final Widget? trailing;
  final MenuSerializableShortcut? shortcut;
  final Widget child;

  static const WidgetStateProperty<Color> _kSequoiaTextColorDark = WidgetStateProperty.fromMap({
    WidgetState.focused: _kSequoiaForegroundHighlighted,
    WidgetState.any: _kSequoiaTextDark,
  });

  static const WidgetStateProperty<Color> _kSequoiaSecondaryColorDark = WidgetStateProperty.fromMap(
    {WidgetState.focused: _kSequoiaForegroundHighlighted, WidgetState.any: _kSequoiaShortcutDark},
  );

  static const WidgetStateProperty<Color> _kSequoiaBackgroundColor = WidgetStateProperty.fromMap({
    WidgetState.focused: _kSequoiaHighlightBackground,
    WidgetState.any: Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    // Rely on your framework's state methods to check if highlighted
    final states = BaseMenuItem.statesOf(context);

    // Swap all foreground colors to white when highlighted
    // final textColor = states ? _kSequoiaForegroundHighlighted :
    // _kSequoiaTextDefault;
    final textColor = _kSequoiaTextColorDark.resolve(states);
    final secondaryColor = _kSequoiaSecondaryColorDark.resolve(states);

    final backgroundColor = _kSequoiaBackgroundColor.resolve(states);

    return DecoratedBox(
      decoration: BoxDecoration(color: backgroundColor, borderRadius: _kSequoiaMenuBorderRadius),
      child: Padding(
        padding: _kSequoiaMenuItemPadding,
        child: IconTheme.merge(
          data: IconThemeData(size: _kSequoiaMenuIconSize, color: textColor),
          child: DefaultTextStyle.merge(
            style: textStyle.copyWith(
              fontSize: _kSequoiaMenuFontSize,
              color: textColor,
              fontWeight: FontWeight.w400,
              decoration: TextDecoration.none,
            ),
            child: Row(
              children: [
                if (leading != null)
                  SizedBox(
                    width: leadingContentWidth,
                    child: Align(child: leading),
                  ),
                const SizedBox(width: 4),

                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400, minWidth: 100),
                    child: Align(alignment: AlignmentDirectional.centerStart, child: child),
                  ),
                ),

                const SizedBox(width: 24),
                if (shortcut != null)
                  _SequoiaShortcutLabel(shortcut: shortcut!, color: secondaryColor),

                if (trailing != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: IconTheme.merge(
                      data: IconThemeData(color: textColor),
                      child: trailing!,
                    ),
                  ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SequoiaShortcutLabel extends StatelessWidget {
  const _SequoiaShortcutLabel({required this.shortcut, required this.color});

  final MenuSerializableShortcut shortcut;
  final Color color;

  @override
  Widget build(BuildContext context) {
    var label = LocalizedShortcutLabeler.instance.getShortcutLabel(
      shortcut,
      MaterialLocalizations.of(context),
    );

    // Sequoia symbols usually sit densely next to each other
    label = label.replaceAll(RegExp(r'\s'), ' ');

    return Text(
      label,
      style: textStyle.copyWith(fontSize: _kSequoiaMenuFontSize, color: color),
    );
  }
}

class _SequoiaSubmenuChevron extends StatelessWidget {
  const _SequoiaSubmenuChevron();

  @override
  Widget build(BuildContext context) {
    const color = _kSequoiaTextDark;

    final flipX = Directionality.of(context) == TextDirection.rtl;
    final scaleFactor = MediaQuery.textScalerOf(context).scale(1);
    return Padding(
      padding: const EdgeInsets.only(top: 1.0),
      child: Transform(
        alignment: .center,
        transform: Matrix4.diagonal3Values(
          flipX ? -scaleFactor : scaleFactor,
          scaleFactor,
          scaleFactor,
        ),
        child: const CustomPaint(
          size: Size(6, 10), // Precise geometry for Sequoia SF Symbol chevron
          painter: _SequoiaChevronPainter(color: color),
        ),
      ),
    );
  }
}

class _SequoiaChevronPainter extends CustomPainter {
  const _SequoiaChevronPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          1.5 // Finer weight to match SF Pro Regular at 13pt
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // Geometry adjusted to better reflect the 'chevron.right' SF Symbol
    final path = Path()
      ..moveTo(1.0, 1.0)
      ..lineTo(size.width - 1.0, size.height / 2)
      ..lineTo(1.0, size.height - 1.0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SequoiaChevronPainter oldDelegate) => color != oldDelegate.color;
}

class SequoiaMenuBarActionLabel extends StatelessWidget {
  const SequoiaMenuBarActionLabel({
    super.key,
    required this.child,
    this.radius = const BorderRadius.all(Radius.circular(5.0)),
    this.padding = const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 5.0),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry radius;

  @override
  Widget build(BuildContext context) {
    final isFocused = BaseMenuItem.isFocusHighlightShownOf(context);

    // Sequoia Menu Bar Specific Colors
    const textColor = Color(0xFFFFFFFF);

    return CustomPaint(
      painter: MenuBarHighlightPainter(
        enabled: isFocused,
        radius: radius.resolve(Directionality.of(context)),
      ),
      child: Padding(
        padding: padding,
        child: DefaultTextStyle.merge(
          style: textStyle.copyWith(fontSize: 13.5, color: textColor, fontWeight: FontWeight.w400),
          child: child,
        ),
      ),
    );
  }
}

class MenuBarHighlightPainter extends CustomPainter {
  const MenuBarHighlightPainter({required this.enabled, required this.radius});

  final bool enabled;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (!enabled) {
      return;
    }

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final rect = Rect.fromLTWH(-4, 0, size.width + 8, size.height);
    final rrect = RSuperellipse.fromRectAndCorners(
      rect,
      bottomLeft: radius.bottomLeft,
      bottomRight: radius.bottomRight,
      topLeft: radius.topLeft,
      topRight: radius.topRight,
    );
    canvas.drawRSuperellipse(rrect, paint);
  }

  @override
  bool shouldRepaint(MenuBarHighlightPainter oldDelegate) =>
      enabled != oldDelegate.enabled || radius != oldDelegate.radius;

  @override
  bool shouldRebuildSemantics(MenuBarHighlightPainter oldDelegate) => false;
}
