import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

import 'menu_action_label.dart';

class SequoiaMenuItem extends StatelessWidget {
  const SequoiaMenuItem({
    super.key,
    this.onTap = emptyCallback,
    required this.child,
    this.leading,
    this.shortcut,
    this.isExpanded,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Widget? leading;
  final MenuSerializableShortcut? shortcut;
  final bool? isExpanded;

  static void emptyCallback() {}

  @override
  Widget build(BuildContext context) {
    final hasSubmenu = isExpanded != null;
    final item = BaseMenuItem(
      onPressed: onTap,
      child: hasSubmenu
          ? SequoiaSubmenuActionLabel(leading: leading, shortcut: shortcut, child: child)
          : SequoiaMenuActionLabel(leading: leading, shortcut: shortcut, child: child),
    );

    if (!hasSubmenu) {
      return item;
    }
    return MergeSemantics(
      child: Semantics.fromProperties(
        properties: SemanticsProperties(expanded: isExpanded),
        child: item,
      ),
    );
  }
}
