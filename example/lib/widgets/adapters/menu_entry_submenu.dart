import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../../data/menu.dart';
import '../../model/model.dart';
import '../menu_action_label.dart';
import '../menu_panel.dart';
import 'menu_entry_panel.dart';

class MenuEntrySubmenu extends StatefulWidget {
  const MenuEntrySubmenu({
    super.key,
    required this.entry,
    this.hoverDelay = Duration.zero,
    this.constraints = const BoxConstraints(minWidth: 260),
  });

  final SubmenuEntry entry;
  final Duration hoverDelay;
  final BoxConstraints constraints;

  @override
  State<MenuEntrySubmenu> createState() => _MenuEntrySubmenuState();
}

class _MenuEntrySubmenuState extends State<MenuEntrySubmenu> {
  final FocusNode _focusNode = FocusNode();
  final MenuController _menuController = MenuController();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handlePressed() {
    if (_menuController.isOpen) {
      _menuController.close();
    } else {
      _menuController.open();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseSubmenu(
      focusNode: _focusNode,
      positioningDelegate: const DefaultBaseMenuPositioningDelegate(
        padding: MenuPanel.defaultPadding,
      ),
      hoverOpenDelay: widget.hoverDelay,
      hoverCloseDelay: widget.hoverDelay,
      menu: MenuEntryPanel(
        menuEntry: widget.entry,
        constraints: widget.entry == Menu.table ? null : widget.constraints,
        onSurfaceEnter: (event) {
          if (!_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
        },
      ),
      onPressed: _handlePressed,
      child: SubmenuActionLabel(
        axis: Axis.vertical,
        leading: widget.entry.child.icon != null ? Icon(widget.entry.child.icon) : null,
        child: Text(widget.entry.child.label),
      ),
    );
  }
}
