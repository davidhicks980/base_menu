import 'package:base_menu/base_menu.dart';
import 'package:flutter/widgets.dart';

import '../theme/colors.dart';
import '../utilities/exclusive_menu_manager.dart';
import 'icon_button.dart';
import 'menu_panel.dart';
import 'tooltip.dart';

class Popup extends StatefulWidget {
  const Popup({
    super.key,
    this.buttonConstraints = const BoxConstraints(minWidth: 30, minHeight: 30),
    this.tooltip,
    required this.panel,
    required this.child,
    this.focusNode,
    this.orientation = Axis.vertical,
    this.buttonDecoration,
    this.onOpen,
    this.onClose,
    this.enableTooltipSemantics = true,
  });

  final Widget panel;
  final Widget child;
  final FocusNode? focusNode;
  final InlineSpan? tooltip;
  final Axis orientation;
  final BoxConstraints buttonConstraints;
  final WidgetStateProperty<BoxDecoration>? buttonDecoration;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;
  final bool enableTooltipSemantics;

  static const openDecoration = WidgetStatePropertyAll(
    BoxDecoration(
      color: FloogleColors.toolbarItemHoverFocus,
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
  );

  @override
  State<Popup> createState() => _PopupState();
}

class _PopupState extends State<Popup> {
  final controller = MenuController();
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
  void didUpdateWidget(Popup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      if (widget.focusNode == null) {
        _internalFocusNode = FocusNode();
      } else {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      }
    }
  }

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    _internalFocusNode = null;
    super.dispose();
  }

  void _handleOverlayFocusChange(bool value) {
    if (!value && !_focusNode.hasFocus && controller.isOpen) {
      controller.close();
    }
  }

  void _handleOpen() {
    ExclusiveMenuManager.of(context).setActive(controller);
    widget.onOpen?.call();
    MenuTooltipScope.of(context).hideTooltip(sync: true);
    _focusNode.requestFocus();
  }

  void _handleClose() {
    widget.onClose?.call();
    ExclusiveMenuManager.of(context).setInactive(controller);
  }

  @override
  Widget build(BuildContext context) {
    final body = BaseSubmenu(
      requestFocusOnHover: false,
      requestOpenOnPointerEnter: false,
      requestCloseOnPointerExit: false,
      controller: controller,
      orientation: widget.orientation,
      menu: widget.panel,
      positionDelegate: const DefaultMenuPositioningDelegate(
        offset: Offset(0, 8),
        padding: MenuPanel.defaultPadding,
      ),
      onFocusChange: _handleOverlayFocusChange,
      onOpen: _handleOpen,
      onClose: _handleClose,
      onPressed: () {
        if (controller.isOpen) {
          controller.close();
        } else {
          controller.open();
        }
      },

      focusNode: _focusNode,
      child: Builder(
        builder: (context) {
          return ToolbarIconLabel(
            decoration:
                widget.buttonDecoration ??
                (MenuController.maybeIsOpenOf(context) == true ? Popup.openDecoration : null),
            constraints: widget.buttonConstraints,
            child: widget.child,
          );
        },
      ),
    );
    if (widget.tooltip == null) {
      return body;
    }
    return MenuTooltip(
      enableSemantics: widget.enableTooltipSemantics,
      message: widget.tooltip!,
      child: body,
    );
  }
}
