import 'package:flutter/widgets.dart';

import '../../model/model.dart';
import '../submenu.dart';
import 'menu_entry_panel.dart';

class MenuEntrySubmenu extends StatelessWidget {
  const MenuEntrySubmenu({
    super.key,
    required this.entry,
    this.alignment,
    this.menuAlignment,
    this.hoverDelay = Duration.zero,
    this.constraints = const BoxConstraints(minWidth: 260),
  });

  final SubmenuEntry entry;
  final AlignmentGeometry? alignment;
  final AlignmentGeometry? menuAlignment;
  final Duration hoverDelay;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    return Submenu(
      alignment: alignment,
      menuAlignment: menuAlignment,
      hoverDelay: hoverDelay,
      panel: MenuEntryPanel(menuEntry: entry, constraints: constraints),
      leading: entry.child.icon != null ? Icon(entry.child.icon) : null,
      child: Text(entry.child.label),
    );
  }
}
