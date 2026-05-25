import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

import 'menu_action_label.dart';

class MenuItem extends StatelessWidget {
  const MenuItem({
    super.key,
    this.onTap = emptyCallback,
    required this.child,
    this.leading,
    this.leadingWidth = 34,
    this.leadingMidpointAlignment = const AlignmentDirectional(0.23529412, 0),
    this.trailing,
    this.shortcut,
    this.mouseCursor = const WidgetStatePropertyAll(MouseCursor.defer),
    this.autofocus = false,
    this.requestFocusOnHover = true,
    this.isExpanded,
    this.intent,
  });

  final VoidCallback? onTap;
  final Widget child;
  final Widget? leading;
  final double leadingWidth;
  final AlignmentGeometry leadingMidpointAlignment;
  final Widget? trailing;
  final WidgetStateProperty<MouseCursor> mouseCursor;
  final MenuSerializableShortcut? shortcut;
  final Intent? intent;
  final bool? isExpanded;
  final bool requestFocusOnHover;
  final bool autofocus;

  static void emptyCallback() {}

  @override
  Widget build(BuildContext context) {
    final hasSubmenu = isExpanded != null;
    final item = BaseMenuItem(
      onPressed: intent != null
          ? () {
              Actions.invoke(context, intent!);
              onTap?.call();
            }
          : onTap,
      requestFocusOnHover: requestFocusOnHover,
      mouseCursor: mouseCursor,
      autofocus: autofocus,
      child: hasSubmenu
          ? SubmenuActionLabel(
              leading: leading,
              leadingWidth: leadingWidth,
              leadingMidpointAlignment: leadingMidpointAlignment,
              shortcut: shortcut,
              trailing: trailing,
              axis: Axis.vertical,
              child: child,
            )
          : MenuActionLabel(
              leading: leading,
              leadingWidth: leadingWidth,
              leadingMidpointAlignment: leadingMidpointAlignment,
              shortcut: shortcut,
              trailing: trailing,
              child: child,
            ),
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
