import 'package:flutter/widgets.dart';

@optionalTypeArgs
class Focusable<T> extends StatefulWidget {
  const Focusable({
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
    return context.dependOnInheritedWidgetOfExactType<_FocusableScope<T>>()?.focused ?? false;
  }

  static bool readIsFocusedOf<T>(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_FocusableScope<T>>()?.focused ?? false;
  }

  @override
  State<Focusable<T>> createState() => _FocusableState<T>();
}

class _FocusableState<T> extends State<Focusable<T>> {
  bool _isFocused = false;

  void _handleFocusChange(bool focused) {
    if (_isFocused != focused) {
      setState(() {
        _isFocused = focused;
      });
      widget.onFocusChange?.call(_isFocused);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.enabled && widget.autofocus,
      focusNode: widget.focusNode,
      canRequestFocus: widget.enabled,
      skipTraversal: !widget.enabled,
      onFocusChange: _handleFocusChange,
      child: _FocusableScope<T>(focused: _isFocused, child: widget.child),
    );
  }
}

class _FocusableScope<T> extends InheritedWidget {
  const _FocusableScope({required this.focused, required super.child});

  final bool focused;

  @override
  bool updateShouldNotify(_FocusableScope<T> oldWidget) {
    return focused != oldWidget.focused;
  }
}
