import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'interface.dart';

/// Injects [BaseHoverable] state for type [T] into the widget tree.
///
/// Use this widget to:
///  * Propagate the hover state of a specific [BaseHoverable] type to a
///    subtree.
///  * Override the value of [BaseHoverable.isHoverHighlightShownOf] for a
///    specific subtree using the [showHoverHighlight] property.
@internal
class BaseHoverableStateInjector<T extends Object?> extends StatelessWidget {
  const BaseHoverableStateInjector({super.key, this.showHoverHighlight, required this.child});

  /// A property used to override the hover highlight visibility of descendant
  /// widgets.
  ///
  /// To stop overriding the value and revert to the default behavior, set
  /// [showHoverHighlight] to null.
  ///
  /// Defaults to null.
  final bool? showHoverHighlight;

  /// The child widget of this [BaseHoverableStateInjector].
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
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

/// A widget that manages hover state for type [T] and propagates it
/// to descendants in the widget tree.
///
/// Descendants can subscribe to changes in hover or hover highlight visibility
/// using [BaseHoverable.isHoveredOf] and [BaseHoverable.isHoverHighlightShownOf].
@optionalTypeArgs
class BaseHoverable<T extends Object?> extends StatefulWidget implements BaseHoverableInterface {
  /// Creates a widget that forwards mouse events to callbacks.
  const BaseHoverable({
    super.key,
    this.onPointerHover,
    this.onPointerEnter,
    this.onPointerExit,
    this.behavior = HitTestBehavior.deferToChild,
    this.mouseCursor = MouseCursor.defer,
    this.opaque = true,
    this.enabled = true,
    required this.child,
  });

  @override
  final PointerEnterEventListener? onPointerEnter;

  @override
  final PointerHoverEventListener? onPointerHover;

  @override
  final PointerExitEventListener? onPointerExit;

  /// The mouse cursor to display when a pointer is hovering over this region.
  ///
  /// Defaults to [MouseCursor.defer], which defers the choice of cursor to the
  /// nearest underlying region that specifies a cursor.
  final MouseCursor mouseCursor;

  @override
  final HitTestBehavior behavior;

  @override
  final bool opaque;

  /// Whether this widget should trigger hover callbacks and show hover highlights.
  ///
  /// If false, this widget will not trigger hover callbacks, but it will still
  /// communicate its hover state to descendants.
  final bool enabled;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  static _HoverableScope<T>? _of<T extends Object?>(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_HoverableScope<T>>();
    assert(scope != null, 'No BaseHoverable of type $T found in context. \n');
    return scope;
  }

  /// Returns whether the ancestor [BaseHoverable] nearest to the provided
  /// `context` is being hovered by a pointer.
  ///
  /// {@template BaseHoverable.isHoveredOf}
  /// Calling this method establishes a dependency that will cause the provided
  /// [BuildContext] to rebuild whenever the ancestor gains or loses hover.
  ///
  /// Unlike [isHoverHighlightShownOf], this method is not affected by whether
  /// the widget is [enabled] or the [FocusHighlightMode]. As a result,
  /// [isHoverHighlightShownOf] should be used instead of [isHoveredOf] to
  /// determine the visual appearance of downstream widgets.
  /// {@endtemplate}
  @optionalTypeArgs
  static bool isHoveredOf<T extends Object?>(BuildContext context) {
    return _of<T>(context)?.hovered ?? false;
  }

  /// Returns whether the ancestor [BaseHoverable] nearest to the provided
  /// `context` should show a visual hover highlight.
  ///
  /// {@template BaseHoverable.isHoverHighlightShownOf}
  /// Calling this method establishes a dependency that will cause the provided
  /// [BuildContext] to rebuild whenever the ancestor gains or loses highlight
  /// hover.
  ///
  /// On most platforms, hover highlights are only shown when using a mouse
  /// ([FocusHighlightMode.traditional]). The exception is web, where Flutter
  /// often defaults to [FocusHighlightMode.touch] mode on first interaction,
  /// even when a mouse is being used. To account for this, web platforms always
  /// use [FocusHighlightMode.traditional] when determining whether to show a
  /// hover highlight.
  ///
  /// This method will only return true when [isHoveredOf] is true, but
  /// [isHoveredOf] may return true when this method returns false. In this
  /// case, the widget is hovered but the platform has indicated that a hover
  /// highlight is not appropriate for the current input method.
  ///
  /// {@endtemplate}
  @optionalTypeArgs
  static bool isHoverHighlightShownOf<T extends Object?>(BuildContext context) {
    return _of<T>(context)?.showHoverHighlight ?? false;
  }

  @override
  State<BaseHoverable<T>> createState() => _BaseHoverableState<T>();
}

class _BaseHoverableState<T extends Object?> extends State<BaseHoverable<T>> {
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_handleHighlightModeChange);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_handleHighlightModeChange);
    super.dispose();
  }

  void _handleHighlightModeChange(FocusHighlightMode _) {
    setState(() {
      // Update the highlight mode to trigger a rebuild, which will update the
      // hover highlight if needed.
    });
  }

  void _handleEnter(PointerEnterEvent event) {
    setState(() {
      _isHovered = true;
    });

    if (widget.enabled) {
      widget.onPointerEnter?.call(event);
    }
  }

  void _handleLeave(PointerExitEvent event) {
    setState(() {
      _isHovered = false;
    });

    if (widget.enabled) {
      widget.onPointerExit?.call(event);
    }
  }

  /// Most platforms only show hover highlights when using a mouse, which
  /// corresponds to [FocusHighlightMode.traditional]. The exception is web,
  /// where Flutter often defaults to [FocusHighlightMode.touch] on first
  /// interaction, even when the user is using a mouse. To account for this, web
  /// platforms always use [FocusHighlightMode.traditional] when determining
  /// whether to show a hover highlight.
  bool get _showHoverHighlight {
    return _isHovered &&
        widget.enabled &&
        (FocusManager.instance.highlightMode == FocusHighlightMode.traditional || kIsWeb);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      opaque: widget.opaque,
      onEnter: _handleEnter,
      onHover: widget.enabled ? widget.onPointerHover : null,
      onExit: _handleLeave,
      hitTestBehavior: widget.behavior,
      cursor: widget.mouseCursor,
      child: _HoverableScope<T>(
        hovered: _isHovered,
        showHoverHighlight: _showHoverHighlight,
        child: widget.child,
      ),
    );
  }
}

class _HoverableScope<T extends Object?> extends InheritedWidget {
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
