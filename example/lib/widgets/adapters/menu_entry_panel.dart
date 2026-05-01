import 'package:flutter/widgets.dart';

import '../../app_state_manager.dart';
import '../../model/model.dart';
import '../checkbox_menu_item.dart';
import '../dimension_picker.dart';
import '../menu_divider.dart';
import '../menu_item.dart';
import '../menu_panel.dart';
import 'menu_entry_submenu.dart';
import 'menu_entry_tile_group.dart';

class MenuEntryPanel extends StatelessWidget {
  const MenuEntryPanel({
    super.key,
    this.padding = const EdgeInsets.symmetric(vertical: 6.0),
    this.constraints,
    this.clipBehavior = Clip.none,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.axis = Axis.vertical,
    required this.menuEntry,
  });

  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;
  final BorderRadiusGeometry borderRadius;
  final Clip clipBehavior;
  final SubmenuEntry menuEntry;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    return MenuPanel(
      axis: axis,
      padding: padding ?? EdgeInsets.zero,
      constraints: constraints,
      clipBehavior: clipBehavior,
      borderRadius: borderRadius,
      children: [
        for (final child in menuEntry.children)
          switch (child) {
            TileGroupMenuEntry() => MenuEntryTileGroup(group: child),
            DimensionalPickerMenuEntry() => const DimensionPicker(),
            final SubmenuEntry entry => MenuEntrySubmenu(
              entry: entry,
              hoverDelay: const Duration(milliseconds: 260),
            ),
            SelectableMenuEntry() => Builder(
              builder: (context) {
                final checked =
                    AppStateManager.documentFlagsOf(context)[child.intent.key] ==
                    child.intent.value;
                return CheckboxMenuItem(
                  checked: checked,
                  onPressed: () {
                    Actions.invoke(context, child.intent);
                  },
                  controlAffinity: .trailing,
                  shortcut: child.shortcut,
                  icon: child.icon != null ? Icon(child.icon) : null,
                  child: Text(child.label),
                );
              },
            ),

            MenuEntryWithIntent(:final intent, :final icon, :final shortcut, :final label) =>
              MenuItem(
                intent: intent,
                leading: icon != null ? Icon(icon) : null,
                shortcut: shortcut,
                child: Text(label),
              ),
            MenuEntry() => MenuItem(
              leading: child.icon != null ? Icon(child.icon) : null,
              child: Text(child.label),
            ),
            SeparatorMenuEntry() => const MenuDivider(),
          },
      ],
    );
  }
}
