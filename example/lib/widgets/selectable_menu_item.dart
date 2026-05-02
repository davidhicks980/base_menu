import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'menu_item.dart';

enum CheckboxMenuItemControlAffinity { leading, trailing }

class SelectableMenuItem extends StatelessWidget {
  const SelectableMenuItem({
    super.key,
    this.onPressed,
    this.icon,
    this.shortcut,
    this.isExpanded,
    this.control = const Icon(Symbols.check, size: 18),
    this.controlAffinity = .leading,
    required this.selected,
    required this.child,
    this.autofocus = false,
  });

  final bool selected;
  final Widget control;
  final CheckboxMenuItemControlAffinity controlAffinity;
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final MenuSerializableShortcut? shortcut;
  final bool? isExpanded;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final check = selected ? control : null;
    return MergeSemantics(
      child: Semantics(
        checked: selected,
        child: MenuItem(
          autofocus: autofocus,
          leading: controlAffinity == .leading ? check : icon,
          onPressed: onPressed,
          isExpanded: isExpanded,
          shortcut: shortcut,
          trailing: controlAffinity == .trailing ? check : icon,
          child: child,
        ),
      ),
    );
  }
}
