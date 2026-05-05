import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
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
    this.onHover,
    this.onTap,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.behavior = HitTestBehavior.deferToChild,
    this.mouseCursor,
    this.enabled = true,
    required this.child,
  });

  final ValueChanged<bool>? onHover;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onFocusChange;
  final FocusNode? focusNode;
  final bool autofocus;
  final HitTestBehavior behavior;
  final WidgetStateProperty<MouseCursor>? mouseCursor;
  final bool enabled;
  final Widget child;

  @optionalTypeArgs
  static Set<WidgetState> statesOf<T>(BuildContext context) {
    final _ControlScope<T>? scope = context.dependOnInheritedWidgetOfExactType<_ControlScope<T>>();
    return scope!.states;
  }

  @optionalTypeArgs
  static bool isHoveredOf<T>(BuildContext context) {
    return BaseHoverable.isHoveredOf<BaseControl<T>>(context);
  }

  @optionalTypeArgs
  static bool isPressedOf<T>(BuildContext context) {
    return BaseTappable.isPressedOf<BaseControl<T>>(context);
  }

  @optionalTypeArgs
  static bool isFocusedOf<T>(BuildContext context) {
    return BaseFocusable.isFocusedOf<BaseControl<T>>(context);
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
  FocusNode? _internalFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;
  bool isHovered = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }
  }

  @override
  void didUpdateWidget(BaseControl<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      if (widget.focusNode == null) {
        _internalFocusNode = FocusNode();
      } else {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      }
    }
  }

  void _handleHover(bool hovered) {
    isHovered = hovered;
    widget.onHover?.call(hovered);
  }

  Widget _buildHoverable(BuildContext context) {
    return BaseHoverable<BaseControl<T>>(
      behavior: widget.behavior,
      enabled: widget.enabled,
      onHover: _handleHover,
      mouseCursor: widget.mouseCursor != null
          ? widget.mouseCursor!.resolve({
              if (isHovered) WidgetState.hovered,
              if (BaseTappable.isPressedOf<BaseControl<T>>(context)) WidgetState.pressed,
              if (BaseFocusable.isFocusedOf<BaseControl<T>>(context)) WidgetState.focused,
              if (!widget.enabled) WidgetState.disabled,
            })
          : MouseCursor.defer,
      child: Builder(
        builder: (BuildContext context) {
          return _ControlScope<T>(
            states: {
              if (BaseHoverable.isHoveredOf<BaseControl<T>>(context)) WidgetState.hovered,
              if (BaseTappable.isPressedOf<BaseControl<T>>(context)) WidgetState.pressed,
              if (BaseFocusable.isFocusedOf<BaseControl<T>>(context)) WidgetState.focused,
              if (!widget.enabled) WidgetState.disabled,
            },
            child: widget.child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics.fromProperties(
      properties: SemanticsProperties(enabled: widget.enabled),
      child: BaseTappable<BaseControl<T>>(
        enabled: widget.enabled,
        onTap: widget.onTap,
        child: BaseFocusable<BaseControl<T>>(
          onFocusChange: widget.onFocusChange,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          enabled: widget.enabled,
          child: Builder(builder: _buildHoverable),
        ),
      ),
    );
  }
}
