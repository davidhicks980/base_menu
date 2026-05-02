import 'package:flutter/widgets.dart';

import '../../app_state_manager.dart';
import '../../model/model.dart';
import '../dimension_picker.dart';
import '../menu_divider.dart';
import '../menu_item.dart';
import '../menu_panel.dart';
import '../selectable_menu_item.dart';
import 'menu_entry_submenu.dart';
import 'menu_entry_tile_group.dart';

class MenuEntryPanel extends StatelessWidget {
  const MenuEntryPanel({
    super.key,
    this.constraints,
    this.clipBehavior = Clip.none,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.axis = Axis.vertical,
    required this.menuEntry,
  });

  final BoxConstraints? constraints;
  final BorderRadiusGeometry borderRadius;
  final Clip clipBehavior;
  final SubmenuEntry menuEntry;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    return MenuPanel(
      axis: axis,
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
                return SelectableMenuItem(
                  selected: checked,
                  onPressed: () {
                    Actions.invoke(context, child.intent);
                  },
                  shortcut: child.shortcut,
                  controlAffinity: child.iconConfig?.affinity == .leading ? .trailing : .leading,
                  icon: child.icon != null
                      ? Icon(
                          child.icon,
                          weight: child.iconConfig?.weight,
                          fill: child.iconConfig?.fill,
                          grade: child.iconConfig?.grade,
                          opticalSize: child.iconConfig?.opticalSize,
                          size: child.iconConfig?.size,
                        )
                      : null,
                  child: Text(child.label),
                );
              },
            ),

            MenuEntryWithIntent(
              :final intent,
              :final icon,
              :final shortcut,
              :final label,
              :final iconConfig,
            ) =>
              MenuItem(
                intent: intent,
                leading: icon != null
                    ? Icon(
                        child.icon,
                        weight: iconConfig?.weight,
                        fill: iconConfig?.fill,
                        grade: iconConfig?.grade,
                        opticalSize: iconConfig?.opticalSize,
                        size: iconConfig?.size,
                      )
                    : null,
                shortcut: shortcut,
                child: Text(label),
              ),
            MenuEntry() => MenuItem(
              leading: child.icon != null
                  ? Icon(
                      child.icon,
                      weight: child.iconConfig?.weight,
                      fill: child.iconConfig?.fill,
                      grade: child.iconConfig?.grade,
                      opticalSize: child.iconConfig?.opticalSize,
                      size: child.iconConfig?.size,
                    )
                  : null,
              child: Text(child.label),
            ),
            SeparatorMenuEntry() => const MenuDivider(),
          },
      ],
    );
  }
}
