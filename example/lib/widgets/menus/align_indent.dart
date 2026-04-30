import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../../data/menu.dart';
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
    return Popup(
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
                // decoration: false
                //     ? BoxDecoration(
                //         color: const Color.fromRGBO(211, 226, 253, 1),
                //         borderRadius: BorderRadius.circular(4),
                //       )
                //     : BoxDecoration(
                //         color: const Color.fromARGB(255, 240, 244, 250),
                //         borderRadius: BorderRadius.circular(4),
                //       ),
                onPressed: () {
                  Actions.invoke<Intent>(context, entry.intent);
                  FocusScope.of(
                    context,
                    createDependency: false,
                  ).unfocus(disposition: UnfocusDisposition.previouslyFocusedChild);
                },
                shortcut: entry.shortcut,
                tooltip: entry.label[0].toUpperCase() + entry.label.substring(1),
                child: Builder(
                  builder: (context) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: CoreTappable.isFocusedOf(context)
                            ? const Color.fromARGB(255, 220, 224, 232)
                            : null,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: Icon(
                          entry.icon,
                          color: false
                              // ignore: dead_code
                              ? const Color.fromARGB(255, 5, 30, 73)
                              : const Color.fromARGB(255, 70, 70, 70),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 40, minHeight: 30),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Symbols.format_align_left, size: 18), Icon(Symbols.arrow_drop_down)],
        ),
      ),
      // ),
    );
  }
}
