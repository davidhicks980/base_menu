import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_state_manager.dart';
import '../../data/menu.dart';
import '../../model/intents.dart';
import '../../utilities/colors.dart';
import '../icon_button.dart';
import '../menu_panel.dart';
import '../popup.dart';

class AlignIndentMenu extends StatelessWidget {
  const AlignIndentMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final align = AppStateManager.selectedTextStyleOf(context)?.textAlign ?? TextAlign.left;
    return Popup(
      buttonConstraints: const BoxConstraints(),
      panel: MenuPanel(
        spacing: 4,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        borderRadius: BorderRadius.circular(6),
        color: FloogleColors.alignSurfaceColor,
        orientation: Axis.horizontal,
        children: [
          for (final entry in Menu.align.children)
            DecoratedBox(
              decoration: BoxDecoration(
                color: FloogleColors.alignUnselectedColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: IconButton(
                autofocus: align == entry.intent.value,
                decoration: align == entry.intent.value
                    ? WidgetStatePropertyAll(
                        BoxDecoration(
                          color: FloogleColors.selectedButtonBackground,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                    : null,
                onPressed: () {
                  Actions.invoke<SetBlockAlignIntent>(context, entry.intent);
                  FocusScope.of(
                    context,
                    createDependency: false,
                  ).unfocus(disposition: UnfocusDisposition.previouslyFocusedChild);
                },
                tooltip: entry.label[0].toUpperCase() + entry.label.substring(1),
                child: Icon(
                  entry.icon,
                  color: align == entry.intent.value
                      ? FloogleColors.selectedButton
                      : FloogleColors.grey,
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
