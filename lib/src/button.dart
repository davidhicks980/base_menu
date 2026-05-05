import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class _TappableStateScope extends InheritedModel<WidgetState> {
  const _TappableStateScope({required this.states, required super.child});

  final Set<WidgetState> states;

  @override
  bool updateShouldNotify(_TappableStateScope oldWidget) {
    return !setEquals(states, oldWidget.states);
  }

  @override
  bool updateShouldNotifyDependent(_TappableStateScope oldWidget, Set<WidgetState> dependencies) {
    for (final state in dependencies) {
      if (states.contains(state) != oldWidget.states.contains(state)) {
        return true;
      }
    }
    return false;
  }
}

class BaseButton extends StatefulWidget {
  const BaseButton({
    super.key,
    this.onHover,
    this.onPressed,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.behavior = HitTestBehavior.deferToChild,
    this.mouseCursor,
    required this.child,
  });

  final ValueChanged<bool>? onHover;
  final VoidCallback? onPressed;
  final ValueChanged<bool>? onFocusChange;
  final FocusNode? focusNode;
  final bool autofocus;
  final HitTestBehavior behavior;
  final WidgetStateProperty<MouseCursor>? mouseCursor;
  final Widget child;

  static Set<WidgetState> statesOf(BuildContext context) {
    final _TappableStateScope? scope = context
        .dependOnInheritedWidgetOfExactType<_TappableStateScope>();
    return scope!.states;
  }

  static bool _aspectOf(BuildContext context, WidgetState aspect) {
    return InheritedModel.inheritFrom<_TappableStateScope>(
      context,
      aspect: aspect,
    )!.states.contains(aspect);
  }

  static bool isHoveredOf(BuildContext context) {
    return _aspectOf(context, WidgetState.hovered);
  }

  static bool isPressedOf(BuildContext context) {
    return _aspectOf(context, WidgetState.pressed);
  }

  static bool isFocusedOf(BuildContext context) {
    return _aspectOf(context, WidgetState.focused);
  }

  static bool isDisabledOf(BuildContext context) {
    return _aspectOf(context, WidgetState.disabled);
  }

  @override
  State<BaseButton> createState() => _BaseButtonState();
}

class _BaseButtonState extends State<BaseButton> {
  static const _shortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.space): ButtonActivateIntent(),
  };
  late final _actions = {
    ActivateIntent: Action<ActivateIntent>.overridable(
      defaultAction: CallbackAction(onInvoke: _handleActivate),
      context: context,
    ),
    ButtonActivateIntent: Action<ButtonActivateIntent>.overridable(
      defaultAction: CallbackAction(onInvoke: _handleActivate),
      context: context,
    ),
  };

  final WidgetStatesController _statesController = WidgetStatesController();
  Map<Type, GestureRecognizerFactory>? _gestures;
  DeviceGestureSettings? _gestureSettings;

  FocusNode? _internalFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;

  bool get isHovered => _statesController.value.contains(WidgetState.hovered);
  set isHovered(bool value) {
    _statesController.update(WidgetState.hovered, value);
  }

  bool get isPressed => _statesController.value.contains(WidgetState.pressed);
  set isPressed(bool value) {
    _statesController.update(WidgetState.pressed, value);
  }

  bool get isFocused => _statesController.value.contains(WidgetState.focused);
  set isFocused(bool value) {
    _statesController.update(WidgetState.focused, value);
  }

  bool get isEnabled => !_statesController.value.contains(WidgetState.disabled);
  set isEnabled(bool value) {
    _statesController.update(WidgetState.disabled, !value);
  }

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }
    isEnabled = widget.onPressed != null;
    isFocused = _focusNode.hasPrimaryFocus;
  }

  @override
  void didUpdateWidget(BaseButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      if (widget.focusNode == null) {
        _internalFocusNode = FocusNode();
      } else {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      }
      isFocused = _focusNode.hasFocus;
    }

    if (widget.onPressed != oldWidget.onPressed) {
      if (widget.onPressed == null) {
        isEnabled = isHovered = isPressed = isFocused = false;
      } else {
        isEnabled = true;
      }
    }
  }

  @override
  void dispose() {
    _statesController.dispose();
    super.dispose();
  }

  void _handleFocusChange([bool? focused]) {
    isFocused = _focusNode.hasFocus;
    widget.onFocusChange?.call(isFocused);
  }

  void _handleTapDown(TapDownDetails details) {
    isPressed = true;
  }

  void _handleTapUp(TapUpDetails? details) {
    isPressed = false;
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    isPressed = false;
  }

  void _handlePointerExit(PointerExitEvent event) {
    if (isHovered) {
      isHovered = false;
      widget.onHover?.call(false);
    }
  }

  void _handlePointerEnter(PointerHoverEvent event) {
    if (!isHovered) {
      isHovered = true;
      widget.onHover?.call(true);
    }
  }

  void _handleActivate(Intent intent) {
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final DeviceGestureSettings? newGestureSettings = MediaQuery.maybeGestureSettingsOf(context);
    if (_gestureSettings != newGestureSettings) {
      _gestureSettings = newGestureSettings;
      _gestures = null;
    }

    _gestures ??= <Type, GestureRecognizerFactory>{
      TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
        () => TapGestureRecognizer(debugOwner: this),
        (TapGestureRecognizer instance) {
          instance
            ..onTapDown = _handleTapDown
            ..onTapUp = _handleTapUp
            ..onTapCancel = _handleTapCancel
            ..gestureSettings = _gestureSettings;
        },
      ),
    };

    return Semantics.fromProperties(
      properties: SemanticsProperties(enabled: isEnabled),
      child: Actions(
        actions: _actions,
        child: Shortcuts(
          shortcuts: _shortcuts,
          child: Focus(
            autofocus: isEnabled && widget.autofocus,
            focusNode: _focusNode,
            canRequestFocus: isEnabled,
            skipTraversal: !isEnabled,
            onFocusChange: _handleFocusChange,
            child: ValueListenableBuilder(
              valueListenable: _statesController,
              builder: _buildStatefulScope,
              child: RawGestureDetector(
                behavior: widget.behavior,
                gestures: isEnabled ? _gestures! : const <Type, GestureRecognizerFactory>{},
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatefulScope(BuildContext context, Set<WidgetState> value, Widget? child) {
    final MouseCursor cursor =
        widget.mouseCursor?.resolve(value) ?? WidgetStateMouseCursor.clickable.resolve(value);
    return _TappableStateScope(
      states: Set.from(value),
      child: MouseRegion(
        onHover: isEnabled ? _handlePointerEnter : null,
        onExit: isEnabled ? _handlePointerExit : null,
        hitTestBehavior: HitTestBehavior.deferToChild,
        cursor: cursor,
        child: child,
      ),
    );
  }
}
