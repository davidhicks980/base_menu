import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

@optionalTypeArgs
class Pressable<T> extends StatefulWidget {
  const Pressable({
    super.key,
    this.enabled = true,
    this.onPressed,
    this.behavior = HitTestBehavior.deferToChild,
    this.semanticsGestureDelegate,
    this.excludeFromSemantics = false,
    required this.child,
  });

  final bool enabled;
  final VoidCallback? onPressed;
  final HitTestBehavior behavior;
  final SemanticsGestureDelegate? semanticsGestureDelegate;
  final bool excludeFromSemantics;
  final Widget child;

  static bool isPressedOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_PressableScope<T>>()?.pressed ?? false;
  }

  static bool readIsPressedOf<T>(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_PressableScope<T>>()?.pressed ?? false;
  }

  @override
  State<Pressable<T>> createState() => _PressableState<T>();
}

class _PressableState<T> extends State<Pressable<T>> {
  Map<Type, GestureRecognizerFactory>? _gestures;
  DeviceGestureSettings? _gestureSettings;
  bool isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      isPressed = true;
    });
  }

  void _handleTapUp(TapUpDetails? details) {
    setState(() {
      isPressed = false;
    });
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    setState(() {
      isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final DeviceGestureSettings? newGestureSettings = MediaQuery.maybeGestureSettingsOf(context);
    if (_gestureSettings != newGestureSettings) {
      _gestureSettings = newGestureSettings;
      _gestures = null;
    }

    _gestures ??= <Type, GestureRecognizerFactory>{
      TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
        () => TapGestureRecognizer(debugOwner: this),
        (TapGestureRecognizer instance) {
          instance
            ..onTapDown = _handleTapDown
            ..onTapUp = _handleTapUp
            ..onTapCancel = _handleTapCancel
            ..gestureSettings = _gestureSettings;
        },
      ),
    };

    return RawGestureDetector(
      excludeFromSemantics: widget.excludeFromSemantics,
      semantics: widget.semanticsGestureDelegate,
      behavior: widget.behavior,
      gestures: widget.enabled ? _gestures! : const <Type, GestureRecognizerFactory>{},
      child: _PressableScope<T>(pressed: isPressed, child: widget.child),
    );
  }
}

class _PressableScope<T> extends InheritedWidget {
  const _PressableScope({required this.pressed, required super.child});

  final bool pressed;

  @override
  bool updateShouldNotify(_PressableScope<T> oldWidget) {
    return pressed != oldWidget.pressed;
  }
}
