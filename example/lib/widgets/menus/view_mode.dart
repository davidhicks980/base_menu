import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_state_manager.dart';
import '../../data/menu.dart';
import '../../model/enum.dart';
import '../../utilities/colors.dart';
import '../menu_item_radio_semantics.dart';
import '../menu_panel.dart';
import '../select.dart';
import '../selectable_menu_item.dart';

class _ViewMode extends StatelessWidget {
  const _ViewMode({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final selected =
        (AppStateManager.documentStateOf(context)[SelectionKey.viewMode] ??
                Menu.viewMode.children.first.intent.value)
            as ViewModeOption;
    return Select(
      panel: MenuPanel(
        constraints: const BoxConstraints(minWidth: 260),
        padding: const EdgeInsetsGeometry.symmetric(vertical: 6),
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
      ),
      buttonRadius: const BorderRadiusGeometry.all(Radius.circular(100)),
      buttonPadding: const EdgeInsetsGeometry.symmetric(vertical: 4, horizontal: 12),
      child: Semantics(
        label: '${selected.label} mode',
        child: ExcludeSemantics(
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 3, right: 8, bottom: 2),
                child: Icon(selected.icon, size: 20, color: const Color(0xFF444746)),
              ),
              DefaultTextStyle.merge(
                style: const TextStyle(
                  color: Color(0xFF444746),
                  overflow: TextOverflow.ellipsis,
                  fontSize: 14,
                ),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ViewModeMenu extends StatelessWidget {
  const ViewModeMenu({super.key, required this.breakpoint});
  final double breakpoint;

  Widget _buildTransition(BuildContext context, double value, Widget? child) {
    if (value == 0) {
      return const SizedBox.shrink();
    }
    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(width: 80 * value),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ViewMode(
      child: Builder(
        builder: (BuildContext context) {
          final selected =
              AppStateManager.documentStateOf(context)[SelectionKey.viewMode]! as ViewModeOption;
          return TweenAnimationBuilder(
            tween: MediaQuery.widthOf(context) < breakpoint
                ? Tween<double>(begin: 1.0, end: 0.0)
                : Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: _buildTransition,
            child: Text(selected.label),
          );
        },
      ),
    );
  }
}
