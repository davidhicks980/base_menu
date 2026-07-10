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

  void _handleOpen() {
    ExclusiveMenuManager.of(context).setActive(controller);
    widget.onOpen?.call();
    MenuTooltipScope.of(context).hideTooltip(sync: true);
    widget.focusNode?.requestFocus();
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
      onOpen: _handleOpen,
      onClose: _handleClose,
      onPressed: () {
        if (controller.isOpen) {
          controller.close();
        } else {
          controller.open();
        }
      },
      focusNode: widget.focusNode,
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
