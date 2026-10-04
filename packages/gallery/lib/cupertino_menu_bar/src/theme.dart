import 'package:flutter/widgets.dart';

class CupertinoMenuTheme extends InheritedWidget {
  const CupertinoMenuTheme({
    super.key,
    required super.child,
    required this.surface,
    this.surfacePadding = EdgeInsets.zero,
  });

  final Widget surface;
  final EdgeInsetsGeometry surfacePadding;

  static CupertinoMenuTheme of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CupertinoMenuTheme>()!;
  }

  @override
  bool updateShouldNotify(CupertinoMenuTheme oldWidget) {
    return surface != oldWidget.surface || surfacePadding != oldWidget.surfacePadding;
  }
}

class CupertinoMenuBarItemTheme extends InheritedWidget {
  const CupertinoMenuBarItemTheme({super.key, required super.child, required this.radius});

  final Radius radius;

  static CupertinoMenuBarItemTheme of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CupertinoMenuBarItemTheme>()!;
  }

  @override
  bool updateShouldNotify(CupertinoMenuBarItemTheme oldWidget) {
    return radius != oldWidget.radius;
  }
}

class CupertinoMenuItemTheme extends InheritedWidget {
  const CupertinoMenuItemTheme({
    super.key,
    required super.child,
    required this.radius,
    required this.padding,
    required this.showIcon,
    required this.highlightColor,
    required this.expandedColor,
    required this.secondaryTextStyle,
    this.secondaryTextHighlight,
  });

  final Radius radius;
  final EdgeInsetsGeometry padding;
  final bool showIcon;
  final Color highlightColor;
  final Color expandedColor;
  final TextStyle secondaryTextStyle;
  final TextStyle? secondaryTextHighlight;

  static CupertinoMenuItemTheme of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CupertinoMenuItemTheme>()!;
  }

  @override
  bool updateShouldNotify(CupertinoMenuItemTheme oldWidget) {
    return radius != oldWidget.radius ||
        padding != oldWidget.padding ||
        showIcon != oldWidget.showIcon ||
        highlightColor != oldWidget.highlightColor ||
        expandedColor != oldWidget.expandedColor ||
        secondaryTextStyle != oldWidget.secondaryTextStyle ||
        secondaryTextHighlight != oldWidget.secondaryTextHighlight;
  }
}
