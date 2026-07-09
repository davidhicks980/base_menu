import 'package:base_menu/base_menu.dart';
import 'package:flutter/widgets.dart';

import '../theme/colors.dart';
import 'icon_button.dart';
import 'menu_panel.dart';
import 'tooltip.dart';

class Popup extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final controller = MenuController();
    final body = BaseSubmenu(
      requestFocusOnHover: false,
      enableHoverTraversal: false,
      controller: controller,
      orientation: orientation,
      menu: panel,
      positionDelegate: const DefaultMenuPositioningDelegate(
        offset: Offset(0, 8),
        padding: MenuPanel.defaultPadding,
      ),
      onOpen: onOpen,
      onClose: onClose,
      onPressed: () {
        if (controller.isOpen) {
          controller.close();
        } else {
          controller.open();
          MenuTooltipScope.of(context).hideTooltip(sync: true);
        }
      },
      focusNode: focusNode,
      child: Builder(
        builder: (context) {
          return ToolbarIconLabel(
            decoration:
                buttonDecoration ??
                (MenuController.maybeIsOpenOf(context) == true ? openDecoration : null),
            constraints: buttonConstraints,
            child: child,
          );
        },
      ),
    );
    if (tooltip == null) {
      return body;
    }
    return MenuTooltip(enableSemantics: enableTooltipSemantics, message: tooltip!, child: body);
  }
}
