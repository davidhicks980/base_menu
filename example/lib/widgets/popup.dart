import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../utilities/colors.dart';
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
      orientation: orientation,
      menu: panel,
      positioningDelegate: const DefaultBaseMenuPositioningDelegate(
        alignmentOffset: Offset(0, 8),
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
