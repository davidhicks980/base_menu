import 'package:base_menu/base_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../data/menu.dart';
import '../../model/enum.dart';
import '../../model/intents.dart';
import '../../theme/colors.dart';
import '../app_state_manager.dart';
import '../menu_action_label.dart';
import '../menu_divider.dart';
import '../menu_item.dart';
import '../menu_item_radio_semantics.dart';
import '../menu_panel.dart';
import '../select.dart';
import '../tooltip.dart';

import '../web_label.dart';

class ParagraphStylesMenu extends StatefulWidget {
  const ParagraphStylesMenu({super.key});

  @override
  State<ParagraphStylesMenu> createState() => _ParagraphStylesMenuState();
}

class _ParagraphStylesMenuState extends State<ParagraphStylesMenu> {
  final FocusNode _focusNode = FocusNode();
  final MenuController controller = MenuController();
  final MenuController optionsController = MenuController();
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleOptionPointerLeave(PointerExitEvent event) {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  void _handleSurfacePointerExit(PointerExitEvent event) {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints.tightFor(width: 122),
      child: MenuTooltip(
        enableSemantics: false,
        message: const TextSpan(text: 'Styles'),
        child: Select(
          menuController: controller,
          focusNode: _focusNode,
          panel: MenuPanel(
            onSurfaceExit: _handleSurfacePointerExit,
            padding: const EdgeInsets.only(bottom: 6, top: 1, left: 1, right: 1),
            constraints: const BoxConstraints(minWidth: 221).normalize(),
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final option in Menu.paragraphStyles.children)
                    DecoratedBox(
                      position: DecorationPosition.foreground,
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFdadce0))),
                      ),
                      child: _Option(
                        onPointerLeave: _handleOptionPointerLeave,
                        label: option.label,
                        shortcut: option.shortcut,
                        style: option.intent.value,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 7.5),
              BaseSubmenu(
                controller: optionsController,
                positionDelegate: const DefaultMenuPositioningDelegate(
                  padding: EdgeInsets.symmetric(vertical: 6),
                ),
                menu: const MenuPanel(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  constraints: BoxConstraints(minWidth: 260),
                  children: [
                    MenuItem(child: Text('Save as my default styles')),
                    MenuItem(child: Text('Use my default styles')),
                    MenuItem(child: Text('Reset styles')),
                  ],
                ),
                onPressed: () {},
                child: const SubmenuActionLabel(
                  axis: Axis.vertical,
                  leading: Icon(Symbols.tune, size: 16),
                  child: Text('Options'),
                ),
              ),
            ],
          ),
          child: Builder(
            builder: (context) {
              final selectedStyle = AppStateManager.selectedParagraphStyleOf(context).label;
              return MergeSemantics(
                child: Semantics.fromProperties(
                  properties: SemanticsProperties(
                    label: 'Paragraph styles. $selectedStyle is selected.',
                    button: true,
                  ),
                  child: ExcludeSemantics(
                    child: kIsWeb
                        ? WebLabel(
                            label: selectedStyle,
                            textStyle: const TextStyle(
                              color: FloogleColors.selectTextColor,
                              fontSize: 14.2,
                              fontWeight: FontWeight(550),
                              overflow: TextOverflow.ellipsis,
                              letterSpacing: -0.1,

                              fontVariations: [
                                FontVariation.width(95),
                                FontVariation.opticalSize(14.2),
                              ],
                            ),
                            uppercaseTextStyle: const TextStyle(
                              color: FloogleColors.selectTextColor,
                              fontSize: 14.5,
                              fontWeight: FontWeight(550),
                              letterSpacing: -0.1,

                              overflow: TextOverflow.ellipsis,
                              fontVariations: [FontVariation.opticalSize(14)],
                            ),
                          )
                        : Text(
                            selectedStyle,
                            style: const TextStyle(color: FloogleColors.selectTextColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Option extends StatefulWidget {
  const _Option({
    required this.label,
    required this.style,
    this.shortcut,
    required this.onPointerLeave,
  });

  final String label;
  final MenuSerializableShortcut? shortcut;
  final DocumentParagraphStyle style;
  final PointerExitEventListener? onPointerLeave;

  @override
  State<_Option> createState() => _OptionState();
}

class _OptionState extends State<_Option> {
  final FocusNode _focusNode = FocusNode();
  final MenuController controller = MenuController();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paragraphStyles = AppStateManager.paragraphStylesOf(context);
    final selectedParagraphStyle = AppStateManager.selectedParagraphStyleOf(context);
    final isSelected = selectedParagraphStyle == widget.style;
    return MenuItemRadioSemantics(
      checked: isSelected,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: BaseSubmenu(
          controller: controller,
          focusNode: _focusNode,
          autofocus: isSelected,
          onPressed: () {
            MenuController.maybeOf(context)?.close();
            Actions.invoke(context, ApplyParagraphStyleIntent(widget.style));
          },
          onPointerExit: widget.onPointerLeave,
          menu: MenuPanel(
            onSurfaceExit: (event) {
              if (!_focusNode.hasFocus) {
                _focusNode.requestFocus();
              }
            },
            padding: const EdgeInsets.symmetric(vertical: 6),
            children: [
              MenuItem(
                onTap: () {
                  MenuController.maybeOf(context)?.close();
                  Actions.invoke(context, ApplyParagraphStyleIntent(widget.style));
                },
                shortcut: widget.shortcut,
                child: Text("Apply '${widget.label}'", textDirection: TextDirection.ltr),
              ),
              const MenuDivider(padding: EdgeInsets.fromLTRB(30, 7.5, 0, 7.5)),
              MenuItem(
                onTap: () {
                  MenuController.maybeOf(context)?.close();
                  Actions.invoke(context, UpdateParagraphStyleToMatchIntent(widget.style));
                },
                child: Text("Update '${widget.label}' to match", textDirection: TextDirection.ltr),
              ),
            ],
          ),
          child: SubmenuActionLabel(
            leading: isSelected ? const Icon(Symbols.check, size: 16) : null,
            axis: Axis.vertical,
            child: Text(widget.label, style: paragraphStyles[widget.style]?.textStyle),
          ),
        ),
      ),
    );
  }
}
