import 'package:flutter/widgets.dart';

import '../../data/menu.dart';
import '../../model/model.dart';
import '../submenu.dart';
import 'menu_entry_panel.dart';

class MenuEntrySubmenu extends StatefulWidget {
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
  State<MenuEntrySubmenu> createState() => _MenuEntrySubmenuState();
}

class _MenuEntrySubmenuState extends State<MenuEntrySubmenu> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _focusNode.debugLabel = 'MenuEntrySubmenu(${widget.entry.child.label}) FocusNode';
    return Submenu(
      alignment: widget.alignment,
      menuAlignment: widget.menuAlignment,
      hoverOpenDelay: widget.hoverDelay,
      focusNode: _focusNode,
      panel: MenuEntryPanel(
        menuEntry: widget.entry,
        constraints: widget.entry == Menu.table ? null : widget.constraints,
        onSurfaceEnter: (event) {
          if (!_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
        },
      ),
      leading: widget.entry.child.icon != null ? Icon(widget.entry.child.icon) : null,
      child: Text(widget.entry.child.label),
    );
  }
}
