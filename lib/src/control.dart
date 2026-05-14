import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'focusable.dart';
import 'hoverable.dart';
import 'tappable.dart';

class _EnabledScope<T> extends InheritedWidget {
  const _EnabledScope({required this.enabled, required super.child});
  final bool enabled;

  @override
  bool updateShouldNotify(_EnabledScope<T> oldWidget) => enabled != oldWidget.enabled;
}

@optionalTypeArgs
class BaseControl<T> extends StatefulWidget {
  const BaseControl({
    super.key,
    this.onPointerHover,
    this.onPointerEnter,
    this.onPointerLeave,
    this.onTap,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.behavior = HitTestBehavior.deferToChild,
    this.mouseCursor,
    this.enabled = true,
    required this.child,
  });

  final PointerHoverEventListener? onPointerHover;
  final PointerEnterEventListener? onPointerEnter;
  final PointerExitEventListener? onPointerLeave;
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
    return BaseTappable.isPressedOf<T>(context);
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
    widget.onTap?.call();
  }

  Widget _buildHoverable(BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, setState) {
        final hasMouseCursor = widget.mouseCursor != null;
        return BaseHoverable<T>(
          behavior: widget.behavior,
          enabled: widget.enabled,
          onHover: widget.onPointerHover,
          onEnter: hasMouseCursor
              ? widget.onPointerEnter
              : (PointerEnterEvent event) {
                  widget.onPointerEnter?.call(event);
                  setState(() {
                    isHovered = true;
                  });
                },
          onExit: !isHovered
              ? widget.onPointerLeave
              : (PointerExitEvent event) {
                  setState(() {
                    isHovered = false;
                  });
                  widget.onPointerLeave?.call(event);
                },
          mouseCursor: hasMouseCursor
              ? widget.mouseCursor!.resolve({
                  if (isHovered) WidgetState.hovered,
                  if (BaseTappable.isPressedOf<T>(context)) WidgetState.pressed,
                  if (BaseFocusable.isFocusedOf<T>(context)) WidgetState.focused,
                  if (!widget.enabled) WidgetState.disabled,
                })
              : MouseCursor.defer,
          child: widget.child,
        );
      },
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
              child: BaseTappable<T>(
                enabled: widget.enabled,
                onTap: widget.onTap,
                child: Builder(builder: _buildHoverable),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
