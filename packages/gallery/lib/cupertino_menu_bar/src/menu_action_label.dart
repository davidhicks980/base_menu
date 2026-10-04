import 'package:base_menu/base_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../shared/localized_shortcut_labeler.dart';
import '../../shared/package.dart';
import 'theme.dart';

const double _kCupertinoMenuFontSize = 13.0;
const double _kCupertinoMenuIconSize = 14.0;

const Color _kCupertinoText = Color.fromARGB(255, 244, 244, 244);
const Color _kCupertinoTextFocused = Color(0xFFFFFFFF);
const Color _kCupertinoShortcutDark = Color.fromARGB(70, 255, 255, 255);

const _webFontStyle = TextStyle(
  fontFamily: 'InterVariable',
  package: kPackage,
  decoration: .none,
  fontVariations: [FontVariation.opticalSize(16), FontVariation.weight(450)],
);

const _cupertinoFontStyle = TextStyle(
  fontFamily: 'CupertinoSystemText',
  package: kPackage,
  letterSpacing: -0.1, // SF Pro standard tight tracking
  height: 1.2,
  decoration: TextDecoration.none,
);

TextStyle textStyle = switch (defaultTargetPlatform) {
  .iOS || .macOS when !kIsWeb => _cupertinoFontStyle,
  _ => _webFontStyle,
};

class CupertinoSubmenuActionLabel extends StatelessWidget {
  const CupertinoSubmenuActionLabel({
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
    final theme = CupertinoMenuItemTheme.of(context);
    final decoration = BoxDecoration(
      color: MenuController.maybeIsOpenOf(context) ?? false
          ? CupertinoMenuItemTheme.of(context).expandedColor
          : const Color(0x00000000),
      backgroundBlendMode: BlendMode.overlay,
      borderRadius: BorderRadius.all(theme.radius),
    );
    return DecoratedBox(
      decoration: decoration,
      child: CupertinoMenuActionLabel(
        leading: leading,
        leadingContentWidth: leadingContentWidth,
        trailing: const _CupertinoSubmenuChevron(),
        shortcut: shortcut,
        backgroundColor: MenuController.maybeIsOpenOf(context) ?? false
            ? const Color.from(alpha: 0.05, red: 1, green: 1, blue: 1)
            : null,
        child: child,
      ),
    );
  }
}

class CupertinoMenuActionLabel extends StatelessWidget {
  const CupertinoMenuActionLabel({
    super.key,
    required this.child,
    this.leading,
    this.leadingContentWidth = 20,
    this.trailing,
    this.shortcut,
    this.backgroundColor,
    this.foregroundColor,
  });

  final Widget? leading;
  final double leadingContentWidth;
  final Widget? trailing;
  final MenuSerializableShortcut? shortcut;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;

  static const WidgetStateProperty<Color> _kCupertinoTextColorDark = WidgetStateProperty.fromMap({
    WidgetState.focused: _kCupertinoTextFocused,
    WidgetState.any: _kCupertinoText,
  });

  static const WidgetStateProperty<Color> _kCupertinoShortcutColorDark =
      WidgetStateProperty.fromMap({
        WidgetState.focused: _kCupertinoTextFocused,
        WidgetState.any: _kCupertinoShortcutDark,
      });

  @override
  Widget build(BuildContext context) {
    final states = BaseMenuItem.statesOf(context);
    final textColor = foregroundColor ?? _kCupertinoTextColorDark.resolve(states);
    final secondaryColor = foregroundColor ?? _kCupertinoShortcutColorDark.resolve(states);
    final background =
        backgroundColor ??
        (BaseMenuItem.isFocusHighlightShownOf(context)
            ? CupertinoMenuItemTheme.of(context).highlightColor
            : const Color(0x00000000));
    final theme = CupertinoMenuItemTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.all(theme.radius)),
      child: Padding(
        padding: theme.padding.resolve(Directionality.maybeOf(context) ?? .ltr),
        child: IconTheme.merge(
          data: IconThemeData(size: _kCupertinoMenuIconSize, color: textColor),
          child: DefaultTextStyle.merge(
            style: textStyle.copyWith(
              fontSize: _kCupertinoMenuFontSize,
              color: textColor,
              package: kPackage,
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
                  _CupertinoShortcutLabel(
                    shortcut: shortcut!,
                    color: secondaryColor,
                    highlight: !BaseMenuItem.isFocusHighlightShownOf(context),
                  ),

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

class _CupertinoShortcutLabel extends StatelessWidget {
  const _CupertinoShortcutLabel({
    required this.shortcut,
    required this.color,
    required this.highlight,
  });

  final MenuSerializableShortcut shortcut;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    var label = LocalizedShortcutLabeler.instance.getShortcutLabel(
      shortcut,
      MaterialLocalizations.of(context),
    );

    label = label.replaceAll(RegExp(r'\s'), ' ');

    return _SecondaryText(label: label, color: color, highlight: highlight);
  }
}

class _SecondaryText extends StatelessWidget {
  const _SecondaryText({required this.label, required this.color, required this.highlight});

  final String label;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoMenuItemTheme.of(context);
    final text = Text(label, style: textStyle.apply(color: color).merge(theme.secondaryTextStyle));

    if (!highlight || theme.secondaryTextHighlight == null) {
      return text;
    }

    return Stack(
      children: [
        text,
        ExcludeSemantics(
          child: Text(
            label,
            style: textStyle.merge(CupertinoMenuItemTheme.of(context).secondaryTextHighlight),
          ),
        ),
      ],
    );
  }
}

class _CupertinoSubmenuChevron extends StatelessWidget {
  const _CupertinoSubmenuChevron();

  @override
  Widget build(BuildContext context) {
    const color = _kCupertinoTextFocused;
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
          size: Size(6, 10),
          painter: _ChevronPainter(color: color),
        ),
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final path = Path()
      ..moveTo(1.0, 1.0)
      ..lineTo(size.width - 1.0, size.height / 2)
      ..lineTo(1.0, size.height - 1.0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ChevronPainter oldDelegate) => color != oldDelegate.color;
}

class CupertinoMenuBarActionLabel extends StatelessWidget {
  const CupertinoMenuBarActionLabel({
    super.key,
    required this.child,
    this.screenRadius,
    this.padding = const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 4.0),
  });
  final Widget child;
  final Radius? screenRadius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFFFFFFFF);
    final isFocused = BaseMenuItem.isFocusHighlightShownOf(context);
    final radius = CupertinoMenuBarItemTheme.of(context).radius;
    Radius topStartRadius;
    if (screenRadius != null) {
      topStartRadius = screenRadius!.x > radius.x ? screenRadius! : radius;
    } else {
      topStartRadius = radius;
    }

    return ColoredBox(
      color: const Color(0x00000000),
      child: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: CustomPaint(
          painter: _MenuBarHighlightPainter(
            enabled: isFocused,
            radius: BorderRadiusDirectional.only(
              topStart: topStartRadius,
              topEnd: radius,
              bottomStart: radius,
              bottomEnd: radius,
            ).resolve(Directionality.maybeOf(context) ?? .ltr),
          ),
          child: Padding(
            padding: padding,
            child: DefaultTextStyle.merge(
              style: textStyle.copyWith(
                fontSize: 13.5,
                color: textColor,
                fontWeight: FontWeight.w400,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuBarHighlightPainter extends CustomPainter {
  const _MenuBarHighlightPainter({required this.enabled, required this.radius});

  final bool enabled;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (!enabled) {
      return;
    }

    final paint = Paint()
      ..color = const Color.fromRGBO(255, 255, 255, 0.1)
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
  bool shouldRepaint(_MenuBarHighlightPainter oldDelegate) =>
      enabled != oldDelegate.enabled || radius != oldDelegate.radius;

  @override
  bool shouldRebuildSemantics(_MenuBarHighlightPainter oldDelegate) => false;
}
