import 'package:flutter/scheduler.dart';
import 'package:flutter/src/gestures/events.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../../data/menu.dart';
import '../../model/model.dart';
import '../adapters/menu_entry_menu_bar_submenu.dart';
import '../menu_panel.dart';
import '../overflow_toolbar.dart';

class DocumentMenuBar extends StatefulWidget {
  const DocumentMenuBar({super.key});

  @override
  State<DocumentMenuBar> createState() => _DocumentMenuBarState();
}

class _DocumentMenuBarState extends State<DocumentMenuBar> {
  final FocusScopeNode _focusScopeNode = FocusScopeNode();
  final MenuController _menuController = MenuController();
  int _cutoff = Menu.main.children.length;
  final List<Widget> children = Menu.main.children
      .map((entry) => MenuBarSubmenu(entry: entry))
      .toList(growable: false);
  bool isEntered = false;

  @override
  void dispose() {
    _focusScopeNode.dispose();
    super.dispose();
  }

  void _handlePointerExit(PointerExitEvent _) {
    setState(() {
      isEntered = false;
    });
  }

  void _handlePointerEnter(PointerEnterEvent _) {
    setState(() {
      isEntered = true;
    });
  }

  void _handleMenuClose() {
    _focusScopeNode.unfocus(disposition: UnfocusDisposition.previouslyFocusedChild);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasOverflow = _cutoff < Menu.main.children.length;
    return MouseRegion(
      onEnter: _handlePointerEnter,
      onExit: _handlePointerExit,
      child: BaseMenuBar(
        controller: _menuController,
        focusScopeNode: _focusScopeNode,
        onClose: !isEntered ? _handleMenuClose : null,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(end: 20.0),
          child: SizedBox(
            height: 23.5,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: OverflowRow(
                    onOverflow: (int lastVisibleIndex) {
                      _cutoff = lastVisibleIndex;
                      SchedulerBinding.instance.addPostFrameCallback((timestamp) {
                        if (mounted) {
                          setState(() {});
                        }
                      });
                    },
                    children: children,
                  ),
                ),
                if (hasOverflow)
                  MenuBarSubmenu(
                    overflow: true,
                    panel: MenuPanel(
                      axis: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                      children: [
                        ...Menu.main.children
                            .skip(_cutoff)
                            .map((entry) => MenuBarSubmenu(entry: entry)),
                      ],
                    ),
                    entry: SubmenuEntry(
                      const MenuEntry('More', icon: Symbols.more_horiz),
                      Menu.main.children.take(_cutoff).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
