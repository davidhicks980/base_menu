import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'interface.dart';

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

/// A widget that manages focus state for type [T] and propagates it
/// to descendants in the widget tree.
///
/// Descendants can subscribe to changes in focus or focus highlight visibility
/// using [BaseFocusable.isFocusedOf] and [BaseFocusable.isFocusHighlightShownOf].
@optionalTypeArgs
class BaseFocusable<T extends Object?> extends StatefulWidget implements BaseFocusableInterface {
  /// Creates a [BaseFocusable] widget.
  const BaseFocusable({
    super.key,
    this.autofocus = false,
    this.enabled = true,
    this.onFocusChange,
    this.focusNode,
    required this.child,
  });

  @override
  final FocusNode? focusNode;

  @override
  final bool autofocus;

  @override
  final ValueChanged<bool>? onFocusChange;

  /// Whether this widget is interactive.
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
  /// When this widget is focused, a focus highlight is requested on web and on
  /// platforms where the [FocusHighlightMode] is
  /// [FocusHighlightMode.traditional].
  final bool enabled;

  /// The child widget of this [BaseFocusable].
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  static _FocusableScope<T>? _of<T extends Object?>(BuildContext context) {
    final _FocusableScope<T>? scope = context
        .dependOnInheritedWidgetOfExactType<_FocusableScope<T>>();
    assert(scope != null, 'No BaseFocusable of type $T found in context');
    return scope;
  }

  /// Returns whether the ancestor [BaseFocusable] nearest to the provided
  /// [context] has input focus.
  ///
  /// {@template BaseFocusable.isFocusedOf}
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
  /// [context] should have a focus highlight.
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
  /// This method will only return true when [isFocusedOf] is true, but
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
