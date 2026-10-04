import 'package:flutter/widgets.dart';

/// An inherited widget that provides access to the menu's dismissal state.
class CupertinoMenuDismissHandler extends InheritedWidget {
  const CupertinoMenuDismissHandler({
    super.key,
    required this.state,
    required super.child,
    required this.isInteractive,
    required this.isAnimating,
  });

  final MenuDismissCoordinatorState state;
  final bool isInteractive;
  final bool isAnimating;

  static MenuDismissCoordinatorState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CupertinoMenuDismissHandler>()!.state;
  }

  @override
  bool updateShouldNotify(CupertinoMenuDismissHandler oldWidget) {
    return state != oldWidget.state ||
        isInteractive != oldWidget.isInteractive ||
        isAnimating != oldWidget.isAnimating;
  }
}

/// A wrapper that coordinates the Cupertino-style "fade out" dismissal
/// and hover interactivity for a menu system.
class MenuDismissCoordinator extends StatefulWidget {
  const MenuDismissCoordinator({
    super.key,
    required this.controller,
    this.onFadeOutBegin,
    this.isInteractive = false,
    required this.child,
  });

  final MenuController controller;
  final VoidCallback? onFadeOutBegin;
  final bool isInteractive;
  final Widget child;

  @override
  State<MenuDismissCoordinator> createState() => MenuDismissCoordinatorState();
}

class MenuDismissCoordinatorState extends State<MenuDismissCoordinator>
    with SingleTickerProviderStateMixin {
  bool isAnimatingOut = false;
  late bool isInteractive = widget.isInteractive;

  late final AnimationController animation = AnimationController(
    duration: Duration.zero,
    value: 1,
    vsync: this,
  );

  @override
  void didUpdateWidget(covariant MenuDismissCoordinator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isInteractive != oldWidget.isInteractive) {
      isInteractive = widget.isInteractive;
    }
  }

  void enableInteractivity() {
    if (!isInteractive) {
      setState(() {
        isInteractive = true;
      });
    }
  }

  void fadeMenuOut() {
    if (!mounted) {
      return;
    }

    if (!widget.controller.isOpen) {
      setState(() {
        isInteractive = widget.isInteractive;
      });
      return;
    }

    if (isAnimatingOut) {
      return;
    }

    widget.onFadeOutBegin?.call();
    setState(() {
      isAnimatingOut = true;
    });
    animation.duration = const Duration(milliseconds: 133);
    animation.reverse().whenComplete(() {
      widget.controller.close();
      animation.duration = Duration.zero;
      animation.value = 1;
      isAnimatingOut = false;
      setState(() {
        isInteractive = widget.isInteractive;
      });
    });
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoMenuDismissHandler(
      state: this,
      isInteractive: isInteractive,
      isAnimating: isAnimatingOut,
      child: widget.child,
    );
  }
}
