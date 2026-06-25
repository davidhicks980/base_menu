import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../../model/model.dart';
import '../menu_bar_button_label.dart';
import '../web_label.dart';
import 'menu_entry_panel.dart';

class MenuBarMenu extends StatefulWidget {
  const MenuBarMenu({super.key, required this.entry, this.overflow = false, this.panel});

  final SubmenuEntry entry;
  final bool overflow;
  final Widget? panel;

  @override
  State<MenuBarMenu> createState() => _MenuBarMenuState();
}

class _MenuBarMenuState extends State<MenuBarMenu> {
  late final anchorFocusNode = FocusNode(debugLabel: widget.entry.child.label);
  final controller = MenuController();

  @override
  void dispose() {
    anchorFocusNode.dispose();
    super.dispose();
  }

  Widget _buildOverlayWrapper(BuildContext context, Widget child) {
    return BaseHoverable<BaseMenu>(
      onExit: (event) {
        anchorFocusNode.requestFocus();
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseSubmenu(
      overlayChildBuilder: _buildOverlayWrapper,
      positionDelegate: const DefaultBaseMenuPositioningDelegate(
        overlayPadding: EdgeInsets.only(top: 55, bottom: 8),
      ),
      orientation: widget.overflow ? Axis.horizontal : Axis.vertical,
      controller: controller,
      onPressed: () {
        if (controller.isOpen) {
          controller.close();
        } else {
          controller.open();
        }
      },

      menu:
          widget.panel ??
          MenuEntryPanel(
            onSurfaceEnter: (_) {
              if (!anchorFocusNode.hasFocus) {
                anchorFocusNode.requestFocus();
              }
            },
            menuEntry: widget.entry,
            borderRadius: const BorderRadiusDirectional.only(
              bottomStart: Radius.circular(4),
              bottomEnd: Radius.circular(4),
              topEnd: Radius.circular(4),
            ),
            constraints: widget.overflow
                ? const BoxConstraints(minWidth: 200)
                : const BoxConstraints(minWidth: 320),
          ),
      child: Builder(
        builder: (context) {
          return MenuBarButtonLabel(
            widget.overflow
                ? Icon(widget.entry.child.icon, size: 16)
                : kIsWeb
                ? WebLabel(
                    label: widget.entry.child.label,
                    textStyle: const TextStyle(
                      fontFamily: 'GoogleSansFlex',
                      fontFamilyFallback: ['GoogleSans'],
                      fontSize: 14.5,
                      fontWeight: FontWeight(460),
                      letterSpacing: 0.1,
                      fontVariations: [FontVariation.width(82.5), FontVariation.opticalSize(14)],
                    ),
                    uppercaseTextStyle: const TextStyle(
                      fontFamily: 'GoogleSans',
                      fontSize: 14.5,
                      fontWeight: FontWeight(460),
                      letterSpacing: -0.3,
                      fontVariations: [FontVariation.opticalSize(14)],
                    ),
                  )
                : Text(widget.entry.child.label),
          );
        },
      ),
    );
  }
}
