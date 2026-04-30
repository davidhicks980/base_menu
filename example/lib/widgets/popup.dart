import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

import 'toolbar_icon_button.dart';

class Popup extends StatefulWidget {
  const Popup({
    super.key,
    this.buttonConstraints = const BoxConstraints(minWidth: 30, minHeight: 30),
    this.tooltip,
    required this.panel,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 6.0),
    this.axis = Axis.vertical,
    this.buttonDecoration,
  });

  final Widget panel;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final InlineSpan? tooltip;
  final Axis axis;
  final BoxConstraints buttonConstraints;
  final WidgetStateProperty<BoxDecoration>? buttonDecoration;

  @override
  State<Popup> createState() => _PopupState();
}

class _PopupState extends State<Popup> {
  late final FocusNode focusNode = FocusNode();
  final controller = MenuController();

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  static const WidgetStateProperty<BoxDecoration> _decoration = WidgetStateProperty.fromMap({
    WidgetState.pressed: BoxDecoration(
      color: Color.from(alpha: 0.098, red: 0, green: 0, blue: 0),
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    WidgetState.focused: BoxDecoration(
      color: Color.from(alpha: 0.059, red: 0, green: 0, blue: 0),
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    WidgetState.hovered: BoxDecoration(
      color: Color.from(alpha: 0.059, red: 0, green: 0, blue: 0),
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),

    // Use selected state to match the open state of the menu
    WidgetState.selected: BoxDecoration(
      color: Color.from(alpha: 0.059, red: 0, green: 0, blue: 0),
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    WidgetState.any: BoxDecoration(),
  });

  @override
  Widget build(BuildContext context) {
    return CoreMenu(
      axis: widget.axis,
      padding: widget.padding,
      panel: widget.panel,
      onFocusChange: (value) {
        if (!value) {
          controller.close();
        }
      },
      alignmentOffset: const Offset(0, 8),
      controller: controller,
      child: widget.child,
      builder: (context, controller, child) {
        final isOpen = MenuController.maybeIsOpenOf(context);
        final button = ToolbarIconButton(
          decoration: widget.buttonDecoration ?? _decoration,
          requestCloseOnActivate: false,
          focusNode: focusNode,
          constraints: widget.buttonConstraints,
          tooltip: widget.tooltip?.toPlainText(includePlaceholders: false),
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              focusNode.requestFocus();
              Actions.invoke(context, const CoreMenuEnterIntent.focusFirst());
            }
          },
          child: widget.child,
        );

        return MergeSemantics(
          child: Semantics(expanded: isOpen, child: button),
        );
      },
    );
  }
}
