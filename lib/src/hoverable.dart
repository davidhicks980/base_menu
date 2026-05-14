import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class BaseHoverableStateInjector<T> extends StatelessWidget {
  const BaseHoverableStateInjector({super.key, this.showHoverHighlight, required this.child});
  final bool? showHoverHighlight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _HoverableScope<T>(
      hovered: BaseHoverable.isHoveredOf<T>(context),
      showHoverHighlight: showHoverHighlight ?? BaseHoverable.isHoverHighlightShownOf<T>(context),
      child: child,
    );
  }
}

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

  final PointerEnterEventListener? onEnter;
  final PointerHoverEventListener? onHover;
  final PointerExitEventListener? onExit;
  final MouseCursor mouseCursor;
  final HitTestBehavior behavior;
  final bool enabled;
  final bool opaque;
  final Widget child;

  static _HoverableScope<T>? _of<T>(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_HoverableScope<T>>();
    assert(scope != null, 'No BaseHoverable of type $T found in context');
    return scope;
  }

  @optionalTypeArgs
  static bool isHoveredOf<T>(BuildContext context) {
    return _of<T>(context)?.hovered ?? false;
  }

  @optionalTypeArgs
  static bool isHoverHighlightShownOf<T>(BuildContext context) {
    return _of<T>(context)?.showHoverHighlight ?? false;
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

  void _handleEnter(PointerEnterEvent event) {
    setState(() {
      isHovered = true;
    });
    widget.onEnter?.call(event);
  }

  void _handleHover(PointerHoverEvent event) {
    if (!isHovered) {
      setState(() {
        isHovered = true;
      });
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
      onEnter: widget.enabled ? _handleEnter : null,
      onHover: widget.enabled || !isHovered ? _handleHover : null,
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
