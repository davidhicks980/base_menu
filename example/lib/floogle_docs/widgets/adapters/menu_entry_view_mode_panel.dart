import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../app_state_manager.dart';
import '../../data/menu.dart';
import '../../model/enum.dart';
import '../../utilities/colors.dart';
import '../menu_item_radio_semantics.dart';
import '../menu_panel.dart';
import '../selectable_menu_item.dart';

class ViewModePanel extends StatelessWidget {
  const ViewModePanel({super.key, this.onSurfaceEnter});
  final PointerEnterEventListener? onSurfaceEnter;

  @override
  Widget build(BuildContext context) {
    final selected = AppStateManager.documentStateOf(context)[SelectionKey.viewMode]!;
    return MenuPanel(
      constraints: const BoxConstraints(minWidth: 260),
      padding: const EdgeInsetsGeometry.symmetric(vertical: 6),
      onSurfaceEnter: onSurfaceEnter,
      children: [
        for (final option in Menu.viewMode.children)
          MenuItemRadioSemantics(
            checked: selected == option.intent.value,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: SelectableMenuItem(
                key: ValueKey(option),
                controlAffinity: .trailing,
                shortcut: option.shortcut,
                selected: selected == option.intent.value,
                control: const Icon(Symbols.check, size: 24),
                icon: Icon(option.icon, size: 20),
                onPressed: () {
                  Actions.invoke(context, option.intent);
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        option.label,
                        style: const TextStyle(
                          fontWeight: .w500,
                          color: FloogleColors.darkGray,
                          fontSize: 14,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (option.subtitle != null)
                        Text(
                          option.subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: FloogleColors.grey,
                            height: 1,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
