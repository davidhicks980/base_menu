import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../menu_utilities.dart';

class BaseMenuItem extends StatefulWidget implements BaseControlInterface {
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

  /// Whether hovering over this menu item should request focus.
  ///
  /// Defaults to true.
  final bool requestFocusOnHover;

  /// Whether activating this menu item should request to close the menu.
  ///
  /// Defaults to true.
  final bool requestCloseOnActivate;

  @override
  final HitTestBehavior behavior;

  @override
  final WidgetStateProperty<MouseCursor>? mouseCursor;

  @override
  final bool gestureSemanticsEnabled;

  @override
  final SemanticsGestureDelegate? gestureSemantics;

  /// The semantic role to assign to this menu item.
  final SemanticsRole? role;

  @override
  final Widget child;

  @override
  bool get enabled => onPressed != null;

  static Set<WidgetState> statesOf(BuildContext context) {
    return BaseControl.statesOf<BaseMenuItem>(context);
  }

  static bool isHoveredOf(BuildContext context) {
    return BaseHoverable.isHoveredOf<BaseMenuItem>(context);
  }

  static bool isPressedOf(BuildContext context) {
    return BaseControl.isPressedOf<BaseMenuItem>(context);
  }

  static bool isFocusedOf(BuildContext context) {
    return BaseControl.isFocusedOf<BaseMenuItem>(context);
  }

  static bool isDisabledOf(BuildContext context) {
    return BaseControl.isDisabledOf<BaseMenuItem>(context);
  }

  @override
  State<BaseMenuItem> createState() => _BaseMenuItemState();
}

class _BaseMenuItemState extends State<BaseMenuItem> {
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
  void didUpdateWidget(BaseMenuItem oldWidget) {
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
        properties: SemanticsProperties(role: widget.role),
        child: BaseControl<BaseMenuItem>(
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
