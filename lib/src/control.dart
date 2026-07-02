import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'focusable.dart';
import 'hoverable.dart';
import 'interface.dart';

@optionalTypeArgs
class BaseControl<T extends Object?> extends StatefulWidget implements BaseControlInterface {
  const BaseControl({
    super.key,
    this.onPressed,
    this.onActivate,
    this.onPointerHover,
    this.onPointerEnter,
    this.onPointerLeave,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.behavior = HitTestBehavior.deferToChild,
    this.opaque = true,
    this.mouseCursor,
    this.gestureSemanticsEnabled = true,
    this.gestureSemantics,
    this.shortcuts = activateOnEnterAndSpaceUpShortcuts,
    required this.child,
  });

  @override
  final VoidCallback? onPressed;

  @override
  final VoidCallback? onActivate;

  @override
  final PointerEnterEventListener? onPointerEnter;

  @override
  final PointerHoverEventListener? onPointerHover;

  @override
  final PointerExitEventListener? onPointerLeave;

  @override
  final ValueChanged<bool>? onFocusChange;

  @override
  final FocusNode? focusNode;

  @override
  final bool autofocus;

  @override
  final HitTestBehavior behavior;

  @override
  final bool opaque;

  @override
  final WidgetStateProperty<MouseCursor>? mouseCursor;

  @override
  final bool gestureSemanticsEnabled;

  @override
  final SemanticsGestureDelegate? gestureSemantics;

  @override
  bool get enabled => onPressed != null || onActivate != null;

  @override
  final Map<ShortcutActivator, Intent> shortcuts;

  @override
  final Widget child;

  /// Returns the [WidgetState]s of the ancestor [BaseControl] nearest to the
  /// provided `context`.
  ///
  /// {@template BaseControl.statesOf}
  /// Calling this method establishes a dependency that will cause the provided
  /// [BuildContext] to rebuild whenever any of the following states change:
  ///
  /// - [WidgetState.pressed], which indicates whether the ancestor is currently
  ///   pressed.
  /// - [WidgetState.hovered], which indicates whether the ancestor should show
  ///   a hover highlight.
  /// - [WidgetState.focused], which indicates whether the ancestor should show
  ///   a focus highlight.
  /// - [WidgetState.disabled], which indicates whether the ancestor is
  ///   currently disabled.
  ///
  /// To minimize rebuilds, widgets that only react to specific states can use
  /// the following state selectors:
  ///  * [isHoverHighlightShownOf]: matches [WidgetState.hovered]
  ///  * [isFocusHighlightShownOf]: matches [WidgetState.focused]
  ///  * [isPressedOf]: matches [WidgetState.pressed]
  ///  * [isDisabledOf]: matches [WidgetState.disabled]
  ///
  /// The returned set of [WidgetState]s should only be used to determine the
  /// visual state of a widget. For example, a widget might choose to draw a
  /// hover highlight if the returned set contains [WidgetState.hovered].
  ///
  /// Depending on the platform, a focused or hovered widget may not show a
  /// visual highlight. In this case, [isFocusedOf] or [isHoveredOf] can be used
  /// to determine whether the control is focused or hovered, independent of
  /// whether a highlight is shown.
  /// {@endtemplate}
  @optionalTypeArgs
  static Set<WidgetState> statesOf<T extends Object?>(BuildContext context) {
    return {
      if (BaseControl.isPressedOf<T>(context)) WidgetState.pressed,
      if (BaseControl.isHoverHighlightShownOf<T>(context)) WidgetState.hovered,
      if (BaseControl.isFocusHighlightShownOf<T>(context)) WidgetState.focused,
      if (BaseControl.isDisabledOf<T>(context)) WidgetState.disabled,
    };
  }

  ///  Returns whether the ancestor [BaseControl] nearest to the provided
  /// `context` is hovered.
  ///
  /// {@macro BaseHoverable.isHoveredOf}
  ///
  /// See Also:
  ///
  ///   * [isHoverHighlightShownOf], which indicates whether the control should
  ///     visually indicate that it is hovered.
  ///   * [isFocusedOf], which indicates whether the control is focused.
  @optionalTypeArgs
  static bool isHoveredOf<T extends Object?>(BuildContext context) {
    return BaseHoverable.isHoveredOf<T>(context);
  }

  /// Returns whether the ancestor [BaseControl] nearest to the provided
  /// `context` is pressed.
  ///
  /// When true, [statesOf] will also include [WidgetState.pressed].
  @optionalTypeArgs
  static bool isPressedOf<T extends Object?>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_PressableScope<T>>()!.pressed;
  }

  /// Returns whether the ancestor [BaseControl] nearest to the provided
  /// `context` has input focus.
  ///
  /// {@macro BaseFocusable.isFocusedOf}
  @optionalTypeArgs
  static bool isFocusedOf<T extends Object?>(BuildContext context) {
    return BaseFocusable.isFocusedOf<T>(context);
  }

  /// Returns whether the ancestor [BaseControl] nearest to the provided
  /// `context` should show a visual focus highlight.
  ///
  /// {@macro BaseFocusable.isFocusHighlightShownOf}
  ///
  /// If true, [statesOf] will also include [WidgetState.focused].
  ///

  @optionalTypeArgs
  static bool isFocusHighlightShownOf<T extends Object?>(BuildContext context) {
    return BaseFocusable.isFocusHighlightShownOf<T>(context);
  }

  /// Returns whether the ancestor [BaseControl] nearest to the provided
  /// `context` should show a visual hover highlight.
  ///
  /// {@macro BaseHoverable.isHoverHighlightShownOf}
  ///
  /// When true, the set returned by [statesOf] will contain
  /// [WidgetState.hovered].
  @optionalTypeArgs
  static bool isHoverHighlightShownOf<T extends Object?>(BuildContext context) {
    return BaseHoverable.isHoverHighlightShownOf<T>(context);
  }

  /// Returns whether the ancestor [BaseControl] nearest to the provided
  /// `context` is disabled.
  ///
  /// When true, the set returned by [statesOf] will contain
  /// [WidgetState.disabled].
  @optionalTypeArgs
  static bool isDisabledOf<T extends Object?>(BuildContext context) {
    return !context.dependOnInheritedWidgetOfExactType<_EnabledScope<T>>()!.enabled;
  }

  static const activateOnEnterShortcuts = {
    SingleActivator(LogicalKeyboardKey.space): DoNothingAndStopPropagationIntent(),
    SingleActivator(LogicalKeyboardKey.enter): kIsWeb ? ButtonActivateIntent() : ActivateIntent(),
  };

  /// The default shortcuts for [BaseControl]s.
  ///
  /// By default, Space triggers the control's [onPressed] callback on key up,
  /// and Enter triggers it on key down.
  ///
  /// These shortcuts can be overridden by providing a different map to the
  /// [shortcuts] parameter.
  static const activateOnEnterAndSpaceUpShortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.space, includeRepeats: false): _ActivateDownIntent(),
    ...activateOnEnterShortcuts,
    _SingleKeyUpActivator(LogicalKeyboardKey.space): ActivateIntent(),
  };

  static const activateOnEnterAndSpaceDownShortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.enter): kIsWeb ? ButtonActivateIntent() : ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
  };

  @override
  State<BaseControl<T>> createState() => _BaseControlState<T>();
}

class _BaseControlState<T extends Object?> extends State<BaseControl<T>> {
  late final _actions = <Type, Action<Intent>>{
    _ActivateDownIntent: CallbackAction<_ActivateDownIntent>(onInvoke: _handleActivateDown),
    DoNothingAndStopPropagationIntent: DoNothingAction(),
    ActivateIntent: Action<ActivateIntent>.overridable(
      defaultAction: CallbackAction(onInvoke: _handleActivate),
      context: context,
    ),
    if (kIsWeb)
      ButtonActivateIntent: Action<ButtonActivateIntent>.overridable(
        defaultAction: CallbackAction(onInvoke: _handleActivate),
        context: context,
      ),
  };
  Map<Type, GestureRecognizerFactory>? _gestures;
  DeviceGestureSettings? _gestureSettings;

  bool isHovered = false;
  bool _isPressed = false;
  _ActivationSource? _activationSource;

  void _handleTapDown(TapDownDetails details) {
    if (_activationSource == .keyboard) {
      return;
    }

    setState(() {
      _activationSource = .pointer;
      _isPressed = true;
    });
  }

  void _handleTapUp(TapUpDetails? details) {
    if (_activationSource == .keyboard) {
      return;
    }

    setState(() {
      _activationSource = null;
      _isPressed = false;
    });

    widget.onPressed?.call();
  }

  void _handleActivateDown(_ActivateDownIntent intent) {
    if (_activationSource == .pointer) {
      return;
    }

    _activationSource = .keyboard;
    if (!_isPressed) {
      setState(() {
        _isPressed = true;
      });
    }
  }

  void _handleActivate(Intent intent) {
    if (_activationSource == .pointer) {
      return;
    }

    _activationSource = null;
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
    }

    (widget.onActivate ?? widget.onPressed)?.call();
  }

  void _handleTapCancel() {
    if (_activationSource == .keyboard) {
      return;
    }

    _activationSource = null;

    // This guard is necessary to prevent a rebuild when the control is
    // disabled while pressed.
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
    }
  }

  @override
  void didUpdateWidget(BaseControl<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _isPressed) {
      _isPressed = false;
      _activationSource = null;
    }
  }

  Widget _buildHoverable(BuildContext context, void Function(void Function()) setState) {
    final hasMouseCursor = widget.mouseCursor != null;
    return BaseHoverable<T>(
      enabled: widget.enabled,
      behavior: widget.behavior,
      opaque: widget.opaque,
      onEnter: (PointerEnterEvent event) {
        setState(() {
          isHovered = true;
        });
        widget.onPointerEnter?.call(event);
      },
      onHover: widget.onPointerHover,
      onExit: (PointerExitEvent event) {
        widget.onPointerLeave?.call(event);
        setState(() {
          isHovered = false;
        });
      },
      cursor: hasMouseCursor
          ? widget.mouseCursor!.resolve({
              if (isHovered) WidgetState.hovered,
              if (BaseControl.isPressedOf<T>(context)) WidgetState.pressed,
              if (BaseFocusable.isFocusedOf<T>(context)) WidgetState.focused,
              if (!widget.enabled) WidgetState.disabled,
            })
          : MouseCursor.defer,
      child: widget.child,
    );
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
      properties: SemanticsProperties(enabled: widget.enabled),
      child: Actions(
        actions: widget.enabled ? _actions : const <Type, Action<Intent>>{},
        child: Shortcuts(
          shortcuts: widget.enabled ? widget.shortcuts : const <ShortcutActivator, Intent>{},
          child: _EnabledScope<T>(
            enabled: widget.enabled,
            child: BaseFocusable<T>(
              onFocusChange: widget.onFocusChange,
              focusNode: widget.focusNode,
              autofocus: widget.autofocus,
              enabled: widget.enabled,
              child: RawGestureDetector(
                excludeFromSemantics: !widget.gestureSemanticsEnabled,
                semantics: widget.gestureSemantics,
                gestures: widget.enabled ? _gestures! : const <Type, GestureRecognizerFactory>{},
                child: _PressableScope<T>(
                  pressed: _isPressed,
                  child: StatefulBuilder(builder: _buildHoverable),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _ActivationSource { pointer, keyboard }

class _ActivateDownIntent extends Intent {
  const _ActivateDownIntent();
}

class ActivateCompleteIntent extends Intent {
  const ActivateCompleteIntent();
}

class _PressableScope<T extends Object?> extends InheritedWidget {
  const _PressableScope({required this.pressed, required super.child});

  final bool pressed;

  @override
  bool updateShouldNotify(_PressableScope<T> oldWidget) {
    return pressed != oldWidget.pressed;
  }
}

class _EnabledScope<T extends Object?> extends InheritedWidget {
  const _EnabledScope({required this.enabled, required super.child});
  final bool enabled;

  @override
  bool updateShouldNotify(_EnabledScope<T> oldWidget) => enabled != oldWidget.enabled;
}

class _SingleKeyUpActivator extends SingleActivator {
  const _SingleKeyUpActivator(super.triggerKey);

  @override
  bool accepts(KeyEvent event, HardwareKeyboard state) {
    return event is KeyUpEvent &&
        triggers.contains(event.logicalKey) &&
        !state.isControlPressed &&
        !state.isShiftPressed &&
        !state.isAltPressed &&
        !state.isMetaPressed;
  }
}
