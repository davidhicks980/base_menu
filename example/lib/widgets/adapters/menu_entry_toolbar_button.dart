import 'package:flutter/widgets.dart';

import '../../app_state_manager.dart';
import '../../model/intents.dart';
import '../../model/model.dart';
import '../../utilities/colors.dart';
import '../icon_button.dart';

class MenuEntryToolbarButton extends StatelessWidget {
  const MenuEntryToolbarButton({super.key, required this.item, this.iconTheme});

  final MenuEntryWithIntent item;
  final IconThemeData? iconTheme;

  @override
  Widget build(BuildContext context) {
    if (item.intent case FloogleSelectableBooleanIntent(:final key, :final value)) {
      final toggled = AppStateManager.documentStateOf(context)[key] == value;
      return MergeSemantics(
        child: Semantics(
          toggled: toggled,
          child: IconButton(
            tooltip: item.label,
            onPressed: () {
              Actions.invoke(context, item.intent);
            },
            decoration: toggled
                ? const WidgetStatePropertyAll(
                    BoxDecoration(
                      color: FloogleColors.selectedButtonBackground,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  )
                : null,
            child: IconTheme.merge(
              data: IconThemeData(
                size: 18,
                color: toggled ? FloogleColors.selectedButton : FloogleColors.grey,
              ).merge(iconTheme),
              child: Icon(item.icon, size: 18),
            ),
          ),
        ),
      );
    }
    return IconButton(
      tooltip: item.label,
      onPressed: () {
        Actions.invoke(context, item.intent);
      },
      child: IconTheme.merge(
        data: const IconThemeData(size: 18, color: FloogleColors.grey).merge(iconTheme),
        child: Icon(item.icon),
      ),
    );
  }
}
