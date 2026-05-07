import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'focusable.dart';
import 'hoverable.dart';
import 'pressable.dart';

class _ControlScope<T> extends InheritedModel<WidgetState> {
  const _ControlScope({required this.states, required super.child});

  final Set<WidgetState> states;

  @override
  bool updateShouldNotify(_ControlScope<T> oldWidget) {
    return !setEquals(states, oldWidget.states);
  }

  @override
  bool updateShouldNotifyDependent(_ControlScope<T> oldWidget, Set<WidgetState> dependencies) {
    for (final state in dependencies) {
      if (states.contains(state) != oldWidget.states.contains(state)) {
        return true;
      }
    }
    return false;
  }
}

@optionalTypeArgs
class BaseControl<T> extends StatefulWidget {
  const BaseControl({
    super.key,
    this.onPointerHover,
    this.onPointerEnter,
    this.onPointerLeave,
    this.onPressed,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.behavior = HitTestBehavior.deferToChild,
    this.mouseCursor,
    this.enabled = true,
    required this.child,
  });

  final PointerHoverEventListener? onPointerHover;
  final PointerHoverEventListener? onPointerEnter;
  final PointerExitEventListener? onPointerLeave;
  final VoidCallback? onPressed;
  final ValueChanged<bool>? onFocusChange;
  final FocusNode? focusNode;
  final bool autofocus;
  final HitTestBehavior behavior;
  final WidgetStateProperty<MouseCursor>? mouseCursor;
  final bool enabled;
  final Widget child;

  @optionalTypeArgs
  static Set<WidgetState> statesOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ControlScope<T>>()!.states;
  }

  @optionalTypeArgs
  static bool isHoveredOf<T>(BuildContext context) {
    return Hoverable.isHoveredOf<BaseControl<T>>(context);
  }

  @optionalTypeArgs
  static bool isPressedOf<T>(BuildContext context) {
    return Pressable.isPressedOf<BaseControl<T>>(context);
  }

  @optionalTypeArgs
  static bool isFocusedOf<T>(BuildContext context) {
    return Focusable.isFocusedOf<BaseControl<T>>(context);
  }

  @optionalTypeArgs
  static bool isDisabledOf<T>(BuildContext context) {
    return InheritedModel.inheritFrom<_ControlScope<BaseControl<T>>>(
      context,
      aspect: WidgetState.disabled,
    )!.states.contains(WidgetState.disabled);
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

  Widget _buildHoverable(BuildContext context) {
    return Hoverable<BaseControl<T>>(
      behavior: widget.behavior,
      enabled: widget.enabled,
      onHover: widget.onPointerHover,
      onEnter: widget.onPointerEnter,
      onExit: widget.onPointerLeave,
      states: widget.mouseCursor != null
          ? {
              if (Pressable.isPressedOf<BaseControl<T>>(context)) WidgetState.pressed,
              if (Focusable.isFocusedOf<BaseControl<T>>(context)) WidgetState.focused,
            }
          : null,
      mouseCursor: widget.mouseCursor,
      child: Builder(
        builder: (BuildContext context) {
          return _ControlScope<T>(
            states: {
              if (Hoverable.isHoveredOf<BaseControl<T>>(context)) WidgetState.hovered,
              if (Pressable.isPressedOf<BaseControl<T>>(context)) WidgetState.pressed,
              if (Focusable.isFocusedOf<BaseControl<T>>(context)) WidgetState.focused,
              if (!widget.enabled) WidgetState.disabled,
            },
            child: widget.child,
          );
        },
      ),
    );
  }

  void _handleActivate(Intent intent) {
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics.fromProperties(
      properties: SemanticsProperties(enabled: widget.enabled),
      child: Actions(
        actions: _actions,
        child: Shortcuts(
          shortcuts: _shortcuts,
          child: Focusable<BaseControl<T>>(
            onFocusChange: widget.onFocusChange,
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            enabled: widget.enabled,
            child: Pressable<BaseControl<T>>(
              enabled: widget.enabled,
              onPressed: widget.onPressed,
              child: Builder(builder: _buildHoverable),
            ),
          ),
        ),
      ),
    );
  }
}
