import 'package:flutter/widgets.dart';

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

  static bool isFocusedOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_FocusableScope<T>>()!.focused;
  }

  static bool isFocusHighlightShownOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_FocusableScope<T>>()!.showFocusHighlight;
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
    return _isFocused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional &&
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
