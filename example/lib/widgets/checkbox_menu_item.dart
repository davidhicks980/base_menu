import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'menu_item.dart';

enum CheckboxMenuItemControlAffinity { leading, trailing }

class CheckboxMenuItem extends StatelessWidget {
  const CheckboxMenuItem({
    super.key,
    this.onPressed,
    this.icon,
    this.shortcut,
    this.isExpanded,
    this.control = const Icon(Symbols.check, size: 16),
    this.controlAffinity = .leading,
    required this.checked,
    required this.child,
    this.autofocus = false,
  });

  final bool checked;
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
    final check = checked ? control : null;
    return MergeSemantics(
      child: Semantics(
        checked: checked,
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
