import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../menu_utilities.dart';

class BaseMenuItem extends StatefulWidget {
  const BaseMenuItem({
    super.key,
    this.onTap,
    this.onPointerHover,
    this.onPointerEnter,
    this.onPointerLeave,
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

  final VoidCallback? onTap;
  final PointerEnterEventListener? onPointerEnter;
  final PointerHoverEventListener? onPointerHover;
  final PointerExitEventListener? onPointerLeave;
  final ValueChanged<bool>? onFocusChange;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool requestFocusOnHover;
  final bool requestCloseOnActivate;
  final HitTestBehavior behavior;
  final WidgetStateProperty<MouseCursor>? mouseCursor;
  final SemanticsRole? role;
  // Custom states to report to descendants instead of using the actual state of
  // the control. Useful for controls that want to report a different state than
  // their internal state.
  final Widget child;

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

    widget.onTap?.call();
  }

  void _handleHoverEnter(PointerEnterEvent event) {
    if (widget.requestFocusOnHover) {
      _focusNode.requestFocus();
    }

    widget.onPointerEnter?.call(event);
  }

  void _handleHoverLeave(PointerExitEvent event) {
    widget.onPointerLeave?.call(event);
  }

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics.fromProperties(
        properties: SemanticsProperties(role: widget.role),
        child: BaseControl<BaseMenuItem>(
          onTap: _handlePressed,
          onPointerEnter: _handleHoverEnter,
          onPointerHover: widget.onPointerHover,
          onPointerLeave: _handleHoverLeave,
          focusNode: _focusNode,
          onFocusChange: widget.onFocusChange,
          autofocus: widget.autofocus,
          mouseCursor: widget.mouseCursor,
          behavior: widget.behavior,
          child: widget.child,
        ),
      ),
    );
  }
}
