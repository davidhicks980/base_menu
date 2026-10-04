import 'package:base_menu/base_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../../shared/package.dart';
import '../../model/model.dart';
import '../../utilities/exclusive_menu_manager.dart';
import '../menu_bar_button_label.dart';
import '../menus/document_menu_bar.dart';
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

  void _handleOpen() {
    ExclusiveMenuManager.of(context).setActive(MenuController.maybeOf(context)!);
    anchorFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return BaseSubmenu(
      positionDelegate: const DefaultMenuPositioningDelegate(
        overlayPadding: EdgeInsets.only(top: 55, bottom: 8),
      ),
      orientation: widget.overflow ? Axis.horizontal : Axis.vertical,
      controller: controller,
      focusNode: anchorFocusNode,
      onOpen: _handleOpen,
      requestFocusOnHover: DocumentMenuBar.isInteractiveOf(context),
      requestOpenOnPointerEnter:
          DocumentMenuBar.isInteractiveOf(context) && MenuController.maybeIsOpenOf(context) == true,
      requestCloseOnPointerExit: false,
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
            onSurfaceExit: (_) {
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
            isInteractive: DocumentMenuBar.isInteractiveOf(context),
            child: widget.overflow
                ? Icon(widget.entry.child.icon, size: 16)
                : kIsWeb
                ? WebLabel(
                    label: widget.entry.child.label,
                    textStyle: const TextStyle(
                      fontFamily: 'GoogleSansFlex',
                      fontFamilyFallback: ['GoogleSans'],
                      package: kPackage,
                      fontSize: 14.5,
                      fontWeight: FontWeight(460),
                      letterSpacing: 0.1,
                      fontVariations: [FontVariation.width(82.5), FontVariation.opticalSize(14)],
                    ),
                    uppercaseTextStyle: const TextStyle(
                      fontFamily: 'GoogleSans',
                      package: kPackage,
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
