import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

@optionalTypeArgs
class BaseHoverable<T> extends StatefulWidget {
  const BaseHoverable({
    super.key,
    this.onHover,
    this.behavior = HitTestBehavior.deferToChild,
    this.mouseCursor = MouseCursor.defer,
    this.opaque = false,
    required this.child,
    required this.enabled,
  });

  final ValueChanged<bool>? onHover;
  final MouseCursor mouseCursor;
  final HitTestBehavior behavior;
  final bool enabled;
  final bool opaque;
  final Widget child;

  static bool isHoveredOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_HoverableScope<T>>()?.hovered ?? false;
  }

  static bool readIsHoveredOf<T>(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_HoverableScope<T>>()?.hovered ?? false;
  }

  @override
  State<BaseHoverable<T>> createState() => _BaseHoverableState<T>();
}

class _BaseHoverableState<T> extends State<BaseHoverable<T>> {
  bool isHovered = false;

  void _handleEnter(PointerHoverEvent event) {
    if (!isHovered) {
      setState(() {
        isHovered = true;
      });
      widget.onHover?.call(true);
    }
  }

  void _handleLeave(PointerExitEvent event) {
    if (isHovered) {
      setState(() {
        isHovered = false;
      });
      widget.onHover?.call(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      opaque: widget.opaque,
      onHover: widget.enabled && !isHovered ? _handleEnter : null,
      onExit: widget.enabled && isHovered ? _handleLeave : null,
      hitTestBehavior: widget.behavior,
      cursor: widget.mouseCursor,
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
