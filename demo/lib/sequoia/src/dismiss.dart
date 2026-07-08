import 'package:flutter/widgets.dart';

/// An inherited widget that provides access to the menu's dismissal state.
class SequoiaMenuDismissHandler extends InheritedWidget {
  const SequoiaMenuDismissHandler({
    super.key,
    required this.state,
    required super.child,
    required this.isInteractive,
    required this.isAnimating,
  });

  final SequoiaMenuDismissCoordinatorState state;
  final bool isInteractive;
  final bool isAnimating;

  static SequoiaMenuDismissCoordinatorState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SequoiaMenuDismissHandler>()!.state;
  }

  @override
  bool updateShouldNotify(SequoiaMenuDismissHandler oldWidget) {
    return state != oldWidget.state ||
        isInteractive != oldWidget.isInteractive ||
        isAnimating != oldWidget.isAnimating;
  }
}

/// A wrapper that coordinates the Sequoia-style "fade out" dismissal
/// and hover interactivity for a menu system.
class SequoiaMenuDismissCoordinator extends StatefulWidget {
  const SequoiaMenuDismissCoordinator({
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
  State<SequoiaMenuDismissCoordinator> createState() => SequoiaMenuDismissCoordinatorState();
}

class SequoiaMenuDismissCoordinatorState extends State<SequoiaMenuDismissCoordinator>
    with SingleTickerProviderStateMixin {
  bool isAnimatingOut = false;
  late bool isInteractive = widget.isInteractive;

  late final AnimationController animation = AnimationController(
    duration: Duration.zero,
    value: 1,
    vsync: this,
  );

  @override
  void didUpdateWidget(covariant SequoiaMenuDismissCoordinator oldWidget) {
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
    if (isAnimatingOut || !mounted || !widget.controller.isOpen) {
      return;
    }

    widget.onFadeOutBegin?.call();
    isAnimatingOut = true;
    animation.duration = const Duration(milliseconds: 125);
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
    return SequoiaMenuDismissHandler(
      state: this,
      isInteractive: isInteractive,
      isAnimating: isAnimatingOut,
      child: widget.child,
    );
  }
}
