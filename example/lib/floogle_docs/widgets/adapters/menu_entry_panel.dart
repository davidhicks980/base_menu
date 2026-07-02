import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../app_state_manager.dart';
import '../../data/menu.dart';
import '../../model/model.dart';
import '../dimension_picker.dart';
import '../menu_divider.dart';
import '../menu_item.dart';
import '../menu_panel.dart';
import '../selectable_menu_item.dart';
import 'menu_entry_submenu.dart';
import 'menu_entry_tile_group.dart';
import 'menu_entry_view_mode_panel.dart';

class MenuEntryPanel extends StatelessWidget {
  const MenuEntryPanel({
    super.key,
    this.constraints,
    this.clipBehavior = Clip.none,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.axis = Axis.vertical,
    required this.menuEntry,
    this.onSurfaceEnter,
    this.onSurfaceHover,
    this.onSurfaceExit,
  });

  final BoxConstraints? constraints;
  final BorderRadiusGeometry borderRadius;
  final Clip clipBehavior;
  final SubmenuEntry menuEntry;
  final Axis axis;
  final void Function(PointerEnterEvent)? onSurfaceEnter;
  final void Function(PointerHoverEvent)? onSurfaceHover;
  final void Function(PointerExitEvent)? onSurfaceExit;

  @override
  Widget build(BuildContext context) {
    if (menuEntry == Menu.viewMode) {
      return const ViewModePanel();
    }

    return MenuPanel(
      orientation: axis,
      constraints: constraints,
      clipBehavior: clipBehavior,
      borderRadius: borderRadius,
      onSurfaceEnter: onSurfaceEnter,
      onSurfaceExit: onSurfaceExit,
      onSurfaceHover: onSurfaceHover,
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
                    AppStateManager.documentStateOf(context)[child.intent.key] ==
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

            MenuEntryWithIntent() => MenuItem(
              intent: child.intent,
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
              shortcut: child.shortcut,
              child: Text(child.label),
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
