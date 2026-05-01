import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_state_manager.dart';
import '../../data/menu.dart';
import '../../model/intents.dart';
import '../menu_panel.dart';
import '../popup.dart';
import '../toolbar_icon_button.dart';

class AlignIndentMenu extends StatefulWidget {
  const AlignIndentMenu({super.key});

  @override
  State<AlignIndentMenu> createState() => _AlignIndentMenuState();
}

class _AlignIndentMenuState extends State<AlignIndentMenu> {
  @override
  Widget build(BuildContext context) {
    final align = AppStateManager.selectedTextStyleOf(context)?.textAlign ?? TextAlign.left;
    return Popup(
      focusFirstOnOpen: false,
      buttonConstraints: const BoxConstraints(),
      panel: MenuPanel(
        spacing: 4,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        borderRadius: BorderRadius.circular(6),
        axis: Axis.horizontal,
        children: [
          for (final entry in Menu.align.children)
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 232, 237, 246),
                borderRadius: BorderRadius.circular(6),
              ),
              child: ToolbarIconButton(
                autofocus: align == entry.intent.value,
                decoration: align == entry.intent.value
                    ? WidgetStatePropertyAll(
                        BoxDecoration(
                          color: const Color.fromRGBO(211, 226, 253, 1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                    : null,
                onPressed: () {
                  Actions.invoke<SetBlockAlignIntent>(context, entry.intent as SetBlockAlignIntent);
                  FocusScope.of(
                    context,
                    createDependency: false,
                  ).unfocus(disposition: UnfocusDisposition.previouslyFocusedChild);
                },
                shortcut: entry.shortcut,
                tooltip: entry.label[0].toUpperCase() + entry.label.substring(1),
                child: Icon(
                  entry.icon,
                  color: align == entry.intent.value
                      ? const Color.fromARGB(255, 5, 30, 73)
                      : const Color.fromARGB(255, 70, 70, 70),
                ),
              ),
            ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 40, minHeight: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(switch ((align, Directionality.of(context))) {
              (TextAlign.left, TextDirection.ltr) ||
              (TextAlign.start, TextDirection.ltr) => Symbols.format_align_left,
              (TextAlign.right, TextDirection.rtl) ||
              (TextAlign.end, TextDirection.rtl) => Symbols.format_align_left,
              (TextAlign.right, TextDirection.ltr) ||
              (TextAlign.end, TextDirection.ltr) => Symbols.format_align_right,
              (TextAlign.left, TextDirection.rtl) ||
              (TextAlign.start, TextDirection.rtl) => Symbols.format_align_right,
              (TextAlign.center, _) => Symbols.format_align_center,
              (TextAlign.justify, _) => Symbols.format_align_justify,
            }, size: 18),
            const Icon(Symbols.arrow_drop_down),
          ],
        ),
      ),
      // ),
    );
  }
}
