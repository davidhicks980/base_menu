import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'control.dart';

class BaseMenuItem extends StatefulWidget {
  const BaseMenuItem({
    super.key,
    this.onPointerHover,
    this.onPointerEnter,
    this.onPointerLeave,
    this.onPressed,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.requestFocusOnHover = true,
    this.requestCloseOnActivate = true,
    this.behavior = HitTestBehavior.deferToChild,
    this.mouseCursor,
    this.role = SemanticsRole.menuItem,
    required this.child,
  });

  final PointerHoverEventListener? onPointerHover;
  final PointerHoverEventListener? onPointerEnter;
  final PointerExitEventListener? onPointerLeave;
  final VoidCallback? onPressed;
  final ValueChanged<bool>? onFocusChange;
  final FocusNode? focusNode;
  final bool autofocus;
  final HitTestBehavior behavior;
  final WidgetStateProperty<MouseCursor>? mouseCursor;
  final bool requestFocusOnHover;
  final bool requestCloseOnActivate;
  final SemanticsRole? role;
  final Widget child;

  static Set<WidgetState> statesOf(BuildContext context) {
    return BaseControl.statesOf<BaseMenuItem>(context);
  }

  static bool isHoveredOf(BuildContext context) {
    return BaseControl.isHoveredOf<BaseMenuItem>(context);
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

  void _handleHoverEnter(PointerHoverEvent event) {
    if (widget.requestFocusOnHover && !_focusNode.hasFocus) {
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
          mouseCursor: widget.mouseCursor ?? WidgetStateMouseCursor.adaptiveClickable,
          behavior: widget.behavior,
          onFocusChange: widget.onFocusChange,
          onPointerHover: widget.onPointerHover,
          onPointerEnter: _handleHoverEnter,
          onPointerLeave: widget.onPointerLeave,
          onPressed: _handlePressed,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          child: widget.child,
        ),
      ),
    );
  }
}
