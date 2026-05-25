import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// Use BaseFocusableStateInjector to inject visual focus state into the widget
/// tree
class BaseFocusableStateInjector<T> extends StatelessWidget {
  const BaseFocusableStateInjector({super.key, this.showFocusHighlight, required this.child});
  final bool? showFocusHighlight;
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
class BaseFocusable<T> extends StatefulWidget {
  const BaseFocusable({
    super.key,
    this.autofocus = false,
    this.enabled = true,
    this.onFocusChange,
    this.focusNode,
    required this.child,
  });

  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;
  final ValueChanged<bool>? onFocusChange;
  final Widget child;

  static _FocusableScope<T>? _of<T>(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_FocusableScope<T>>();
    assert(scope != null, 'No BaseFocusable of type $T found in context');
    return scope;
  }

  @optionalTypeArgs
  static bool isFocusedOf<T>(BuildContext context) {
    return _of<T>(context)?.focused ?? false;
  }

  @optionalTypeArgs
  static bool isFocusHighlightShownOf<T>(BuildContext context) {
    return _of<T>(context)?.showFocusHighlight ?? false;
  }

  @override
  State<BaseFocusable<T>> createState() => _BaseFocusableState<T>();
}

class _BaseFocusableState<T> extends State<BaseFocusable<T>> {
  bool _isFocused = false;
  NavigationMode? _navigationMode;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_handleHighlightModeChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navigationMode = MediaQuery.maybeNavigationModeOf(context);
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
    if (_isFocused != focused) {
      setState(() {
        _isFocused = focused;
      });
      widget.onFocusChange?.call(_isFocused);
    }
  }

  bool get _canRequestFocus => switch (_navigationMode) {
    NavigationMode.traditional || null => widget.enabled,
    NavigationMode.directional => true,
  };

  bool get _showFocusHighlight {
    // Web often defaults to 'touch' mode on first interaction
    return _isFocused &&
        (FocusManager.instance.highlightMode == FocusHighlightMode.traditional || kIsWeb) &&
        _canRequestFocus;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      debugLabel: 'Focusable ${widget.child}',
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
