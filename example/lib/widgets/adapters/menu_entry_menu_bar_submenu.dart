import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
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
  final anchorFocusNode = FocusNode();
  bool _hasAnchorFocus = false;
  bool _isAnchorHovered = false;
  bool _blockDecoration = false;

  @override
  void dispose() {
    anchorFocusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange(bool value) {
    if (value) {
      if (_blockDecoration) {
        setState(() {
          _blockDecoration = false;
        });
      }
    } else {
      if (_isAnchorHovered && !_blockDecoration) {
        setState(() {
          _blockDecoration = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRootOpen = MenuController.maybeIsOpenOf(context) ?? false;
    return BaseMenu(
      onFocusChange: _handleFocusChange,
      overlayPadding: const EdgeInsets.only(top: 55, bottom: 8),
      orientation: widget.overflow ? Axis.horizontal : Axis.vertical,
      menu:
          widget.panel ??
          MenuEntryPanel(
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
          final isOpen = MenuController.maybeIsOpenOf(context) ?? false;
          return MergeSemantics(
            child: Semantics.fromProperties(
              properties: SemanticsProperties(expanded: isOpen),
              child: BaseMenuItem(
                enableHoverTraversal: isRootOpen,
                focusNode: anchorFocusNode,
                onFocusChange: (value) {
                  final hasAnchorFocus = anchorFocusNode.hasFocus;
                  if (hasAnchorFocus != _hasAnchorFocus) {
                    _hasAnchorFocus = hasAnchorFocus;
                    if (_hasAnchorFocus && !isOpen && isRootOpen) {
                      final controller = MenuController.maybeOf(context);
                      controller?.open();
                    }
                  }
                },
                onPointerEnter: (_) {
                  _isAnchorHovered = true;
                  if (_blockDecoration) {
                    setState(() {
                      _blockDecoration = false;
                    });
                  }
                },
                onPointerLeave: (_) {
                  _isAnchorHovered = false;
                },
                onTap: () {
                  final controller = MenuController.maybeOf(context);
                  if (isOpen) {
                    controller?.close();
                  } else {
                    controller?.open();
                    if (!anchorFocusNode.hasFocus) {
                      anchorFocusNode.requestFocus();
                    }
                  }
                },
                child: MenuBarButtonLabel(
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
                            fontVariations: [
                              FontVariation.width(82.5),
                              FontVariation.opticalSize(14),
                            ],
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
                  decoration: _blockDecoration ? const BoxDecoration() : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
