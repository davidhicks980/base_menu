import 'package:base_menu/base_menu.dart';
import 'package:flutter/widgets.dart';

import '../theme/colors.dart';
import 'icon_button.dart';
import 'menu_panel.dart';

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
    return BaseMenu(
      controller: controller,
      orientation: orientation,
      menu: panel,
      positionDelegate: const DefaultMenuPositioningDelegate(
        offset: Offset(0, 8),
        padding: MenuPanel.defaultPadding,
      ),
      onOpen: onOpen,
      onClose: onClose,
      onFocusChange: (bool value) {
        if (!value && (focusNode != null && !focusNode!.hasFocus)) {
          controller.close();
        }
      },
      child: Builder(
        builder: (context) {
          return ToolbarIconButton(
            enableTooltipSemantics: enableTooltipSemantics,
            focusNode: focusNode,
            decoration:
                buttonDecoration ??
                (MenuController.maybeIsOpenOf(context) == true ? openDecoration : null),
            constraints: buttonConstraints,
            tooltip: tooltip?.toPlainText(includePlaceholders: false),
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            child: child,
          );
        },
      ),
      builder: (context, controller, button) {
        final isOpen = MenuController.maybeIsOpenOf(context);
        return MergeSemantics(
          child: Semantics(expanded: isOpen, child: button),
        );
      },
    );
  }
}
