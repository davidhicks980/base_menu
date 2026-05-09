import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

import 'icon_button.dart';
import 'menu_panel.dart';

class Popup extends StatelessWidget {
  const Popup({
    super.key,
    this.buttonConstraints = const BoxConstraints(minWidth: 30, minHeight: 30),
    this.tooltip,
    required this.panel,
    required this.child,
    this.axis = Axis.vertical,
    this.buttonDecoration,
    this.focusFirstOnOpen = true,
  });

  final Widget panel;
  final Widget child;
  final InlineSpan? tooltip;
  final Axis axis;
  final BoxConstraints buttonConstraints;
  final WidgetStateProperty<BoxDecoration>? buttonDecoration;
  final bool focusFirstOnOpen;

  @override
  Widget build(BuildContext context) {
    final controller = MenuController();
    return BaseMenu(
      orientation: axis,
      padding: MenuPanel.defaultPadding,
      menu: panel,
      onFocusChange: (value) {
        if (!value) {
          controller.close();
        }
      },
      alignmentOffset: const Offset(0, 8),
      controller: controller,
      child: Builder(
        builder: (context) {
          return IconButton(
            decoration: buttonDecoration,
            constraints: buttonConstraints,
            tooltip: tooltip?.toPlainText(includePlaceholders: false),
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                if (focusFirstOnOpen) {
                  Actions.invoke(context, const MenuEnterIntent.focusFirst());
                } else {
                  controller.open();
                }
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
