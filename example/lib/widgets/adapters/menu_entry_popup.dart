import 'package:flutter/widgets.dart';

import '../../model/model.dart';
import '../popup.dart';
import 'menu_entry_panel.dart';

class MenuEntryPopup extends StatelessWidget {
  const MenuEntryPopup({
    super.key,
    required this.model,
    this.constraints,
    this.tooltip,
    this.buttonConstraints = const BoxConstraints(minWidth: 30, minHeight: 30),
    this.buttonDecoration,
  });
  final SubmenuEntry model;
  final BoxConstraints? constraints;
  final WidgetStateProperty<BoxDecoration>? buttonDecoration;
  final BoxConstraints buttonConstraints;
  final InlineSpan? tooltip;

  @override
  Widget build(BuildContext context) {
    return Popup(
      buttonConstraints: buttonConstraints,
      buttonDecoration: buttonDecoration,
      requestFocusOnHover:
          MenuController.maybeIsOpenOf(context) != true && FocusScope.of(context).hasFocus,
      tooltip: tooltip,
      panel: MenuEntryPanel(constraints: constraints, menuEntry: model),
      child: Icon(model.child.icon),
    );
  }
}
