import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'focusable.dart';
import 'hoverable.dart';
import 'interface.dart';

class _EnabledScope<T> extends InheritedWidget {
  const _EnabledScope({required this.enabled, required super.child});
  final bool enabled;

  @override
  bool updateShouldNotify(_EnabledScope<T> oldWidget) => enabled != oldWidget.enabled;
}

@optionalTypeArgs
class BaseControl<T> extends StatefulWidget implements BaseControlInterface {
  const BaseControl({
    super.key,
    this.onPressed,
    this.onPointerHover,
    this.onPointerEnter,
    this.onPointerLeave,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.behavior = HitTestBehavior.deferToChild,
    this.opaque = true,
    this.mouseCursor,
    this.gestureSemanticsEnabled = true,
    this.gestureSemantics,
    required this.child,
  });

  @override
  final VoidCallback? onPressed;

  @override
  final PointerEnterEventListener? onPointerEnter;

  @override
  final PointerHoverEventListener? onPointerHover;

  @override
  final PointerExitEventListener? onPointerLeave;

  @override
  final ValueChanged<bool>? onFocusChange;

  @override
  final FocusNode? focusNode;

  @override
  final bool autofocus;

  @override
  final HitTestBehavior behavior;

  final bool opaque;

  @override
  final WidgetStateProperty<MouseCursor>? mouseCursor;

  @override
  final bool gestureSemanticsEnabled;

  @override
  final SemanticsGestureDelegate? gestureSemantics;

  @override
  bool get enabled => onPressed != null;

  @override
  final Widget child;

  @optionalTypeArgs
  static Set<WidgetState> statesOf<T>(BuildContext context) {
    return {
      if (BaseControl.isPressedOf<T>(context)) WidgetState.pressed,
      if (BaseControl.isHoverHighlightShownOf<T>(context)) WidgetState.hovered,
      if (BaseControl.isFocusHighlightShownOf<T>(context)) WidgetState.focused,
      if (BaseControl.isDisabledOf<T>(context)) WidgetState.disabled,
    };
  }

  @optionalTypeArgs
  static bool isHoveredOf<T>(BuildContext context) {
    return BaseHoverable.isHoveredOf<T>(context);
  }

  @optionalTypeArgs
  static bool isPressedOf<T>(BuildContext context) {
    return _Pressable.isPressedOf<T>(context);
  }

  @optionalTypeArgs
  static bool isFocusedOf<T>(BuildContext context) {
    return BaseFocusable.isFocusedOf<T>(context);
  }

  @optionalTypeArgs
  static bool isFocusHighlightShownOf<T>(BuildContext context) {
    return BaseFocusable.isFocusHighlightShownOf<T>(context);
  }

  @optionalTypeArgs
  static bool isHoverHighlightShownOf<T>(BuildContext context) {
    return BaseHoverable.isHoverHighlightShownOf<T>(context);
  }

  @optionalTypeArgs
  static bool isDisabledOf<T>(BuildContext context) {
    return !context.dependOnInheritedWidgetOfExactType<_EnabledScope<T>>()!.enabled;
  }

  @override
  State<BaseControl<T>> createState() => _BaseControlState<T>();
}

class _BaseControlState<T> extends State<BaseControl<T>> {
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

  bool isHovered = false;
  void _handleActivate(Intent intent) {
    widget.onPressed?.call();
  }

  Widget _buildHoverable(BuildContext context, void Function(void Function()) setState) {
    final hasMouseCursor = widget.mouseCursor != null;
    return BaseHoverable<T>(
      enabled: widget.enabled,
      behavior: widget.behavior,
      opaque: widget.opaque,
      onEnter: (PointerEnterEvent event) {
        widget.onPointerEnter?.call(event);
        setState(() {
          isHovered = true;
        });
      },
      onHover: widget.onPointerHover,
      onExit: (PointerExitEvent event) {
        setState(() {
          isHovered = false;
        });
        widget.onPointerLeave?.call(event);
      },
      cursor: hasMouseCursor
          ? widget.mouseCursor!.resolve({
              if (isHovered) WidgetState.hovered,
              if (_Pressable.isPressedOf<T>(context)) WidgetState.pressed,
              if (BaseFocusable.isFocusedOf<T>(context)) WidgetState.focused,
              if (!widget.enabled) WidgetState.disabled,
            })
          : MouseCursor.defer,
      child: widget.child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics.fromProperties(
      properties: SemanticsProperties(enabled: widget.enabled),
      child: Actions(
        actions: _actions,
        child: Shortcuts(
          shortcuts: _shortcuts,
          child: _EnabledScope<T>(
            enabled: widget.enabled,
            child: BaseFocusable<T>(
              onFocusChange: widget.onFocusChange,
              focusNode: widget.focusNode,
              autofocus: widget.autofocus,
              enabled: widget.enabled,
              child: _Pressable<T>(
                enabled: widget.enabled,
                onPressed: widget.onPressed,
                enableGestureSemantics: widget.gestureSemanticsEnabled,
                semanticsGestureDelegate: widget.gestureSemantics,
                child: StatefulBuilder(builder: _buildHoverable),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@optionalTypeArgs
class _Pressable<T> extends StatefulWidget {
  const _Pressable({
    super.key,
    this.enabled = true,
    this.onPressed,
    this.semanticsGestureDelegate,
    this.enableGestureSemantics = true,
    required this.child,
  });

  final bool enabled;
  final VoidCallback? onPressed;
  final SemanticsGestureDelegate? semanticsGestureDelegate;
  final bool enableGestureSemantics;
  final Widget child;

  static bool isPressedOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_PressableScope<T>>()?.pressed ?? false;
  }

  @override
  State<_Pressable<T>> createState() => _PressableState<T>();
}

class _PressableState<T> extends State<_Pressable<T>> {
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
    // This guard is necessary to prevent a rebuild when the control is
    // disabled while pressed.
    if (isPressed) {
      setState(() {
        isPressed = false;
      });
    }
  }

  @override
  void didUpdateWidget(_Pressable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && isPressed) {
      isPressed = false;
    }
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
      excludeFromSemantics: !widget.enableGestureSemantics,
      semantics: widget.semanticsGestureDelegate,
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
