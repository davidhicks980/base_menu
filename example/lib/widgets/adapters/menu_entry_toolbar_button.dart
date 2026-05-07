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
          child: ToolbarIconButton(
            tooltip: item.label,
            intent: item.intent,
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
    return ToolbarIconButton(
      tooltip: item.label,
      intent: item.intent,
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

class ToolbarIconButton extends StatelessWidget {
  const ToolbarIconButton({
    super.key,
    required this.child,
    this.onPressed,
    this.onFocusChange,
    this.focusNode,
    this.tooltip,
    this.autofocus = false,
    this.intent,
    this.decoration,
    this.constraints = const BoxConstraints.tightFor(width: 30, height: 30),
  });

  final Widget child;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final String? tooltip;
  final void Function(bool)? onFocusChange;
  final WidgetStateProperty<BoxDecoration>? decoration;
  final BoxConstraints constraints;
  final bool autofocus;
  final Intent? intent;

  static const _focusedScopeDecoration = WidgetStateProperty<BoxDecoration>.fromMap({
    WidgetState.pressed: BoxDecoration(
      color: FloogleColors.toolbarItemPressed,
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    WidgetState.focused: BoxDecoration(
      color: FloogleColors.toolbarItemHoverFocus,
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    WidgetState.hovered: BoxDecoration(
      color: FloogleColors.toolbarItemHoverFocus,
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    WidgetState.any: BoxDecoration(),
  });

  @override
  Widget build(BuildContext context) {
    final focusOnHover =
        MenuController.maybeIsOpenOf(context) != true && FocusScope.of(context).hasFocus;
    return IconButton(
      autofocus: autofocus,
      onPressed: onPressed,
      onFocusChange: onFocusChange,
      focusNode: focusNode,
      requestFocusOnHover: focusOnHover,
      decoration: decoration ?? (focusOnHover ? _focusedScopeDecoration : null),
      child: child,
    );
  }
}
