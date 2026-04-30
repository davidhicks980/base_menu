import 'package:flutter/widgets.dart';

import '../../app_state_manager.dart';
import '../../model/intents.dart';
import '../../model/model.dart';
import '../toolbar_icon_button.dart';

class MenuEntryToolbarButton extends StatelessWidget {
  const MenuEntryToolbarButton({
    super.key,
    required this.item,
    this.onPressed,
    this.requestCloseOnActivate = true,
    this.iconTheme,
  });

  final MenuEntryWithIntent item;
  final VoidCallback? onPressed;
  final bool requestCloseOnActivate;
  final IconThemeData? iconTheme;

  @override
  Widget build(BuildContext context) {
    if (item.intent case FloogleSelectableBooleanIntent(:final key, :final value)) {
      final toggled = AppStateManager.documentFlagsOf(context)[key] == value;
      return MergeSemantics(
        child: Semantics(
          toggled: toggled,
          child: ToolbarIconButton(
            tooltip: item.label,
            shortcut: item.shortcut,
            intent: item.intent,
            onPressed: onPressed,
            requestCloseOnActivate: requestCloseOnActivate,
            decoration: toggled
                ? const WidgetStatePropertyAll(
                    BoxDecoration(
                      color: Color.fromRGBO(211, 226, 253, 1),
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  )
                : null,
            child: IconTheme.merge(
              data: IconThemeData(
                size: 18,
                color: toggled
                    ? const Color.fromARGB(255, 5, 30, 73)
                    : const Color.fromARGB(255, 70, 70, 70),
              ).merge(iconTheme),
              child: Icon(item.icon, size: 18),
            ),
          ),
        ),
      );
    }
    return ToolbarIconButton(
      tooltip: item.label,
      shortcut: item.shortcut,
      intent: item.intent,
      onPressed: () {
        Actions.invoke(context, item.intent);
      },
      requestCloseOnActivate: requestCloseOnActivate,
      child: IconTheme.merge(
        data: const IconThemeData(
          size: 18,
          color: Color.fromARGB(255, 70, 70, 70),
        ).merge(iconTheme),
        child: Icon(item.icon),
      ),
    );
  }
}
