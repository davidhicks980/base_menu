import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../utilities/colors.dart';
import 'menu_panel.dart';
import 'toolbar_icon_button.dart';

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

  static const WidgetStateProperty<BoxDecoration> _decoration = WidgetStateProperty.fromMap({
    WidgetState.pressed: BoxDecoration(
      color: FloogleColors.toolbarItemPressed,
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    WidgetState.focused: BoxDecoration(
      color: FloogleColors.toolbarItemHoverFocus,
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    WidgetState.hovered: BoxDecoration(
      color: FloogleColors.toolbarItemHoverFocus,
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),

    WidgetState.any: BoxDecoration(),
  });

  @override
  Widget build(BuildContext context) {
    final controller = MenuController();
    return CoreMenu(
      axis: axis,
      padding: MenuPanel.defaultPadding,
      panel: panel,
      onFocusChange: (value) {
        if (!value) {
          controller.close();
        }
      },
      alignmentOffset: const Offset(0, 8),
      controller: controller,
      child: Builder(
        builder: (context) {
          return ToolbarIconButton(
            decoration: buttonDecoration ?? _decoration,
            requestCloseOnActivate: false,
            constraints: buttonConstraints,
            tooltip: tooltip?.toPlainText(includePlaceholders: false),
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                if (focusFirstOnOpen) {
                  Actions.invoke(context, const CoreMenuEnterIntent.focusFirst());
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
