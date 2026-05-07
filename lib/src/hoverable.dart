import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

@optionalTypeArgs
class Hoverable<T> extends StatefulWidget {
  const Hoverable({
    super.key,
    this.onHover,
    this.onEnter,
    this.onExit,
    this.behavior = HitTestBehavior.deferToChild,
    this.mouseCursor,
    this.opaque = true,
    this.enabled = true,
    this.states,
    required this.child,
  });

  final PointerHoverEventListener? onHover;
  final PointerHoverEventListener? onEnter;
  final PointerExitEventListener? onExit;
  final WidgetStateProperty<MouseCursor>? mouseCursor;
  final HitTestBehavior behavior;
  final bool enabled;
  final bool opaque;
  final Set<WidgetState>? states;
  final Widget child;

  @optionalTypeArgs
  static bool isHoveredOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_HoverableScope<T>>()?.hovered ?? false;
  }

  @optionalTypeArgs
  static bool readIsHoveredOf<T>(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_HoverableScope<T>>()?.hovered ?? false;
  }

  @override
  State<Hoverable<T>> createState() => _HoverableState<T>();
}

class _HoverableState<T> extends State<Hoverable<T>> {
  bool isHovered = false;

  @override
  void didUpdateWidget(Hoverable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && isHovered) {
      isHovered = false;
    }
  }

  void _handleEnter(PointerHoverEvent event) {
    setState(() {
      isHovered = true;
    });
    widget.onEnter?.call(event);
  }

  void _handleHover(PointerHoverEvent event) {
    if (!isHovered) {
      _handleEnter(event);
    }
    widget.onHover?.call(event);
  }

  void _handleLeave(PointerExitEvent event) {
    if (isHovered) {
      setState(() {
        isHovered = false;
      });
      widget.onExit?.call(event);
    }
  }

  PointerHoverEventListener? get _hoverCallback {
    if (!widget.enabled) {
      return null;
    } else if (widget.onHover != null) {
      return _handleHover;
    } else if (!isHovered) {
      return _handleEnter;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      opaque: widget.opaque,
      onHover: _hoverCallback,
      onExit: widget.enabled ? _handleLeave : null,
      hitTestBehavior: widget.behavior,
      cursor: widget.mouseCursor != null
          ? widget.mouseCursor!.resolve({
              if (!widget.enabled) WidgetState.disabled,
              if (isHovered) WidgetState.hovered,
              ...?widget.states,
            })
          : MouseCursor.defer,
      child: _HoverableScope<T>(hovered: isHovered, child: widget.child),
    );
  }
}

class _HoverableScope<T> extends InheritedWidget {
  const _HoverableScope({required this.hovered, required super.child});

  final bool hovered;

  @override
  bool updateShouldNotify(_HoverableScope<T> oldWidget) {
    return hovered != oldWidget.hovered;
  }
}
