import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../menu_utilities.dart';
import 'interface.dart';

@optionalTypeArgs
class BaseMenuItem<T> extends StatefulWidget implements BaseMenuItemInterface {
  const BaseMenuItem({
    super.key,
    this.onPressed,
    this.onPointerHover,
    this.onPointerEnter,
    this.onPointerLeave,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.requestFocusOnHover = true,
    this.requestCloseOnActivate = true,
    this.behavior = .deferToChild,
    this.mouseCursor,
    this.role = .menuItem,
    this.gestureSemanticsEnabled = true,
    this.gestureSemantics,
    required this.child,
  }) : assert(
         gestureSemanticsEnabled || gestureSemantics == null,
         'If excludeGestureSemantics is true, semanticsGestureDelegate must not be provided.',
       );

  @override
  final VoidCallback? onPressed;

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
  final bool requestFocusOnHover;

  @override
  final bool requestCloseOnActivate;

  @override
  final HitTestBehavior behavior;

  @override
  final WidgetStateProperty<MouseCursor>? mouseCursor;

  @override
  final bool gestureSemanticsEnabled;

  @override
  final SemanticsGestureDelegate? gestureSemantics;

  @override
  final SemanticsRole? role;

  @override
  final Widget child;

  @override
  bool get enabled => onPressed != null;

  @optionalTypeArgs
  static Set<WidgetState> statesOf<T>(BuildContext context) {
    return BaseControl.statesOf<BaseMenuItem<T>>(context);
  }

  @optionalTypeArgs
  static bool isHoveredOf<T>(BuildContext context) {
    return BaseHoverable.isHoveredOf<BaseMenuItem<T>>(context);
  }

  @optionalTypeArgs
  static bool isPressedOf<T>(BuildContext context) {
    return BaseControl.isPressedOf<BaseMenuItem<T>>(context);
  }

  @optionalTypeArgs
  static bool isFocusedOf<T>(BuildContext context) {
    return BaseControl.isFocusedOf<BaseMenuItem<T>>(context);
  }

  @optionalTypeArgs
  static bool isDisabledOf<T>(BuildContext context) {
    return BaseControl.isDisabledOf<BaseMenuItem<T>>(context);
  }

  @override
  State<BaseMenuItem<T>> createState() => _BaseMenuItemState<T>();
}

class _BaseMenuItemState<T> extends State<BaseMenuItem<T>> {
  FocusNode? _internalFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }
  }

  @override
  void didUpdateWidget(BaseMenuItem<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      if (widget.focusNode == null) {
        _internalFocusNode = FocusNode();
      } else {
        _internalFocusNode!.dispose();
        _internalFocusNode = null;
      }
    }
  }

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _handlePressed() {
    if (widget.requestCloseOnActivate) {
      if (MenuController.maybeIsOpenOf(context) ?? false) {
        Actions.invoke(context, const DismissIntent());
      }
    }

    widget.onPressed?.call();
  }

  void _handleHoverEnter(PointerEnterEvent event) {
    if (widget.requestFocusOnHover) {
      _focusNode.requestFocus();
    }

    widget.onPointerEnter?.call(event);
  }

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics.fromProperties(
        properties: SemanticsProperties(role: widget.role, button: true, enabled: widget.enabled),
        child: BaseControl<BaseMenuItem<T>>(
          onPressed: widget.requestCloseOnActivate && widget.enabled
              ? _handlePressed
              : widget.onPressed,
          onPointerEnter: widget.requestFocusOnHover && widget.enabled
              ? _handleHoverEnter
              : widget.onPointerEnter,
          onPointerHover: widget.onPointerHover,
          onPointerLeave: widget.onPointerLeave,
          focusNode: _focusNode,
          onFocusChange: widget.onFocusChange,
          autofocus: widget.autofocus,
          mouseCursor: widget.mouseCursor,
          behavior: widget.behavior,
          gestureSemanticsEnabled: widget.gestureSemanticsEnabled,
          gestureSemantics: widget.gestureSemantics,
          child: widget.child,
        ),
      ),
    );
  }
}
