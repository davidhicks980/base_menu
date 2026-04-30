import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_state_manager.dart';
import '../../data/menu.dart';
import '../../model/enum.dart';
import '../../model/intents.dart';
import '../menu_divider.dart';
import '../menu_item.dart';
import '../menu_item_radio_semantics.dart';
import '../menu_panel.dart';
import '../select.dart';
import '../submenu.dart';

class ParagraphStylesMenu extends StatefulWidget {
  const ParagraphStylesMenu({super.key});

  @override
  State<ParagraphStylesMenu> createState() => _ParagraphStylesMenuState();
}

class _ParagraphStylesMenuState extends State<ParagraphStylesMenu> {
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 122, maxWidth: 122),
      child: Select(
        panel: MenuPanel(
          padding: const EdgeInsets.only(bottom: 6),
          constraints: const BoxConstraints(minWidth: 221).normalize(),
          children: [
            Semantics.fromProperties(
              container: true,
              explicitChildNodes: true,
              properties: const SemanticsProperties(role: SemanticsRole.radioGroup),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final option in Menu.paragraphStyles.children)
                    Builder(
                      builder: (context) {
                        return DecoratedBox(
                          position: DecorationPosition.foreground,
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFFdadce0))),
                          ),
                          child: _Option(
                            label: option.label,
                            shortcut: option.shortcut,
                            style: option.intent.value,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 7.5),
            const Submenu(
              panel: MenuPanel(
                padding: EdgeInsets.symmetric(vertical: 6),
                constraints: BoxConstraints(minWidth: 260),
                children: [
                  MenuItem(child: Text('Save as my default styles')),
                  MenuItem(child: Text('Use my default styles')),
                  MenuItem(child: Text('Reset styles')),
                ],
              ),
              leading: Icon(Symbols.tune),
              child: Text('Options'),
            ),
          ],
        ),
        child: Builder(
          builder: (context) {
            return Text(AppStateManager.selectedParagraphStyleOf(context).label);
          },
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.label, required this.style, this.shortcut});

  final String label;
  final MenuSerializableShortcut? shortcut;
  final DocumentParagraphStyle style;

  @override
  Widget build(BuildContext context) {
    final paragraphStyles = AppStateManager.paragraphStylesOf(context);
    final selectedParagraphStyle = AppStateManager.selectedParagraphStyleOf(context);
    final isSelected = selectedParagraphStyle == style;
    return MenuItemRadioSemantics(
      checked: isSelected,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),

        child: Submenu(
          onPressed: () {
            MenuController.maybeOf(context)?.close();
            Actions.invoke(context, ApplyParagraphStyleIntent(style));
          },
          leading: isSelected ? const Icon(Symbols.check, size: 16) : null,
          panel: MenuPanel(
            padding: const EdgeInsets.symmetric(vertical: 6),

            children: [
              MenuItem(
                onPressed: () {
                  MenuController.maybeOf(context)?.close();
                  Actions.invoke(context, ApplyParagraphStyleIntent(style));
                },
                shortcut: shortcut,
                child: Text('Apply "$label"'),
              ),
              const MenuDivider(padding: EdgeInsets.fromLTRB(30, 7.5, 0, 7.5)),
              MenuItem(
                onPressed: () {
                  print('Update "$label" to match');
                  MenuController.maybeOf(context)?.close();
                  Actions.invoke(context, UpdateParagraphStyleToMatchIntent(style));
                },
                child: Text('Update "$label" to match'),
              ),
            ],
          ),
          child: Text(label, style: paragraphStyles[style]),
        ),
      ),
    );
  }
}
