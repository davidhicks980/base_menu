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
    this.orientation = Axis.vertical,
    this.buttonDecoration,
    this.focusFirstOnOpen = true,
  });

  final Widget panel;
  final Widget child;
  final InlineSpan? tooltip;
  final Axis orientation;
  final BoxConstraints buttonConstraints;
  final WidgetStateProperty<BoxDecoration>? buttonDecoration;
  final bool focusFirstOnOpen;

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
                  Actions.invoke(context, const BaseMenuEnterIntent.focusFirst());
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
