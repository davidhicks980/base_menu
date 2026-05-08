import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

@optionalTypeArgs
class BaseHoverable<T> extends StatefulWidget {
  const BaseHoverable({
    super.key,
    this.onHover,
    this.onEnter,
    this.onExit,
    this.behavior = HitTestBehavior.deferToChild,
    this.mouseCursor = MouseCursor.defer,
    this.opaque = true,
    this.enabled = true,
    required this.child,
  });

  final PointerHoverEventListener? onHover;
  final PointerHoverEventListener? onEnter;
  final PointerExitEventListener? onExit;
  final MouseCursor mouseCursor;
  final HitTestBehavior behavior;
  final bool enabled;
  final bool opaque;
  final Widget child;

  @optionalTypeArgs
  static bool isHoveredOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_HoverableScope<T>>()!.hovered;
  }

  @optionalTypeArgs
  static bool isHoverHighlightShownOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_HoverableScope<T>>()!.showHoverHighlight;
  }

  @override
  State<BaseHoverable<T>> createState() => _BaseHoverableState<T>();
}

class _BaseHoverableState<T> extends State<BaseHoverable<T>> {
  bool isHovered = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_handleHighlightModeChange);
  }

  @override
  void didUpdateWidget(BaseHoverable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && isHovered) {
      isHovered = false;
    }
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_handleHighlightModeChange);
    super.dispose();
  }

  void _handleHighlightModeChange(FocusHighlightMode _) {
    setState(() {
      // Update the highlight mode to trigger a rebuild, which will update the
      // focus highlight if needed.
    });
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

  bool get _showHoverHighlight {
    // Hover highlights are only shown in traditional highlight modes (e.g. mouse),
    // and not in touch modes.
    return isHovered &&
        widget.enabled &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      opaque: widget.opaque,
      onHover: _hoverCallback,
      onExit: widget.enabled ? _handleLeave : null,
      hitTestBehavior: widget.behavior,
      cursor: widget.mouseCursor,
      child: _HoverableScope<T>(
        hovered: isHovered,
        showHoverHighlight: _showHoverHighlight,
        child: widget.child,
      ),
    );
  }
}

class _HoverableScope<T> extends InheritedWidget {
  const _HoverableScope({
    required this.hovered,
    required super.child,
    required this.showHoverHighlight,
  });

  final bool hovered;
  final bool showHoverHighlight;

  @override
  bool updateShouldNotify(_HoverableScope<T> oldWidget) {
    return hovered != oldWidget.hovered || showHoverHighlight != oldWidget.showHoverHighlight;
  }
}
