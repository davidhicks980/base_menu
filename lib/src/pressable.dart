import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

@optionalTypeArgs
class BaseTappable<T> extends StatefulWidget {
  const BaseTappable({
    super.key,
    this.enabled = true,
    this.onTap,
    this.behavior = HitTestBehavior.deferToChild,
    this.semanticsGestureDelegate,
    this.excludeFromSemantics = false,
    required this.child,
  });

  final bool enabled;
  final VoidCallback? onTap;
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
  State<BaseTappable<T>> createState() => _BaseTappableState<T>();
}

class _BaseTappableState<T> extends State<BaseTappable<T>> {
  static const _shortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.space): ButtonActivateIntent(),
  };

  late final _actions = {
    ActivateIntent: Action<ActivateIntent>.overridable(
      defaultAction: CallbackAction(onInvoke: _handleActivate),
      context: context,
    ),
    ButtonActivateIntent: Action<ButtonActivateIntent>.overridable(
      defaultAction: CallbackAction(onInvoke: _handleActivate),
      context: context,
    ),
  };

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
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    setState(() {
      isPressed = false;
    });
  }

  void _handleActivate(Intent intent) {
    widget.onTap?.call();
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

    return Actions(
      actions: _actions,
      child: Shortcuts(
        shortcuts: _shortcuts,
        child: RawGestureDetector(
          excludeFromSemantics: widget.excludeFromSemantics,
          semantics: widget.semanticsGestureDelegate,
          behavior: widget.behavior,
          gestures: widget.enabled ? _gestures! : const <Type, GestureRecognizerFactory>{},
          child: _PressableScope<T>(pressed: isPressed, child: widget.child),
        ),
      ),
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
