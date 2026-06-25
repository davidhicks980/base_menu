import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// Injects [BaseFocusable] state for type [T] into the widget tree.
///
/// Use this widget to:
///  * Propagate the focus state of a specific [BaseFocusable] type to a
///    subtree.
///  * Override the value of [BaseFocusable.isFocusHighlightShownOf] for a
///    specific subtree using the [showFocusHighlight] property.
@internal
class BaseFocusableStateInjector<T extends Object?> extends StatelessWidget {
  const BaseFocusableStateInjector({super.key, this.showFocusHighlight, required this.child});

  /// A value used to override the value of
  /// [BaseFocusable.isFocusHighlightShownOf] for descendant widgets.
  ///
  /// To stop overriding the value and revert to the default behavior, set
  /// [showFocusHighlight] to null.
  ///
  /// Defaults to null.
  final bool? showFocusHighlight;

  /// The child widget of this [BaseFocusableStateInjector].
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _FocusableScope<T>(
      focused: BaseFocusable.isFocusedOf<T>(context),
      showFocusHighlight: showFocusHighlight ?? BaseFocusable.isFocusHighlightShownOf<T>(context),
      child: child,
    );
  }
}

@optionalTypeArgs
class BaseFocusable<T extends Object?> extends StatefulWidget {
  const BaseFocusable({
    super.key,
    this.autofocus = false,
    this.enabled = true,
    this.onFocusChange,
    this.focusNode,
    required this.child,
  });

  /// An optional focus node to use as the focus node for this widget.
  ///
  /// If a focus node is provided, it is the responsibility of the parent widget
  /// to manage the lifecycle of the focus node, including disposing it when it
  /// is no longer needed.
  final FocusNode? focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// Whether the parent of this widget is interactive.
  ///
  /// When true, this widget is always focusable.
  ///
  /// When false, this widget is:
  ///  * Not focusable when [MediaQueryData.navigationMode] is
  ///    [NavigationMode.traditional] or null.
  ///  * Focusable when [MediaQueryData.navigationMode] is
  ///    [NavigationMode.directional].
  ///    * This is common on television interfaces, where focusing disabled
  ///      controls provides additional information.
  ///
  /// When this widget is focused, focus highlight is requested on web and on
  /// platforms where the [FocusHighlightMode] is
  /// [FocusHighlightMode.traditional].
  final bool enabled;

  /// Handler called when the focus changes.
  ///
  /// Called with true if this widget's node gains focus, and false if it loses
  /// focus.
  ///
  /// See also:
  ///
  ///  * [isFocusedOf], which will rebuild the provided [BuildContext] whenever
  ///    the focus state of the nearest ancestor [BaseFocusable] changes.
  ///  * [isFocusHighlightShownOf], which will rebuild the provided
  ///    [BuildContext] whenever the focus highlight state of the nearest
  ///    ancestor [BaseFocusable] changes.
  final ValueChanged<bool>? onFocusChange;

  /// The child widget of this [BaseFocusable].
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  static _FocusableScope<T>? _of<T extends Object?>(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_FocusableScope<T>>();
    assert(scope != null, 'No BaseFocusable of type $T found in context');
    return scope;
  }

  /// Returns whether the ancestor [BaseFocusable] nearest to the provided
  /// `context` has input focus.
  ///
  /// {@template BaseFocusable.isFocusedOf}
  ///
  /// Calling this method establishes a dependency that rebuilds the provided
  /// [BuildContext] whenever the ancestor gains or loses focus input.
  ///
  /// On most platforms, only enabled ancestors are focusable. However, on
  /// platforms that primarily use directional input (for example, television
  /// interfaces), disabled ancestors may be focusable. See
  /// [MediaQueryData.navigationMode] for more details.
  ///
  /// The value of [isFocusedOf] may be true when [isFocusHighlightShownOf] is
  /// false. In this case, the ancestor has input focus but has indicated that a
  /// focus highlight should not be shown.
  ///
  /// {@endtemplate}
  @optionalTypeArgs
  static bool isFocusedOf<T extends Object?>(BuildContext context) {
    return _of<T>(context)?.focused ?? false;
  }

  /// Returns whether the ancestor [BaseFocusable] nearest to the provided
  /// `context` should have a focus highlight.
  ///
  /// {@template BaseFocusable.isFocusHighlightShownOf}
  ///
  /// Calling this method establishes a dependency that will cause the provided
  /// [BuildContext] to rebuild whenever the ancestor gains or loses focus
  /// highlight.
  ///
  /// On most platforms, focus highlight is only shown when using a keyboard.
  /// This corresponds to [FocusHighlightMode.traditional]. The exception is
  /// web, where Flutter defaults to [FocusHighlightMode.touch] on first
  /// interaction. To account for this, web platforms always use
  /// [FocusHighlightMode.traditional] when determining whether to show a focus
  /// highlight.
  ///
  /// This method will always return true when [isFocusedOf] is true, but
  /// [isFocusedOf] may return true when this method returns false. In this
  /// case, the ancestor is focused but the platform has indicated that a focus
  /// highlight is not appropriate for the current input method.
  ///
  /// {@endtemplate}
  @optionalTypeArgs
  static bool isFocusHighlightShownOf<T extends Object?>(BuildContext context) {
    return _of<T>(context)?.showFocusHighlight ?? false;
  }

  @override
  State<BaseFocusable<T>> createState() => _BaseFocusableState<T>();
}

class _BaseFocusableState<T extends Object?> extends State<BaseFocusable<T>> {
  bool _isFocused = false;

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
      // Rebuild to update the focus highlight when the highlight mode changes.
    });
  }

  void _handleFocusChange(bool focused) {
    setState(() {
      _isFocused = focused;
    });
    widget.onFocusChange?.call(_isFocused);
  }

  bool get _canRequestFocus => switch (MediaQuery.maybeNavigationModeOf(context)) {
    NavigationMode.traditional || null => widget.enabled,
    NavigationMode.directional => true,
  };

  bool get _showFocusHighlight {
    // Web often defaults to 'touch' mode on first interaction
    return _isFocused &&
        (FocusManager.instance.highlightMode == FocusHighlightMode.traditional || kIsWeb);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      canRequestFocus: _canRequestFocus,
      onFocusChange: _handleFocusChange,
      child: _FocusableScope<T>(
        focused: _isFocused,
        showFocusHighlight: _showFocusHighlight,
        child: widget.child,
      ),
    );
  }
}

class _FocusableScope<T> extends InheritedWidget {
  const _FocusableScope({
    required this.focused,
    required this.showFocusHighlight,
    required super.child,
  });

  final bool focused;
  final bool showFocusHighlight;

  @override
  bool updateShouldNotify(_FocusableScope<T> oldWidget) {
    return focused != oldWidget.focused || showFocusHighlight != oldWidget.showFocusHighlight;
  }
}
