import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class MenuItemRadioSemantics extends StatelessWidget {
  const MenuItemRadioSemantics({
    super.key,
    required this.checked,
    required this.child,
  });

  final bool checked;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool? accessibilitySelected;
    String? semanticsHint;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        accessibilitySelected = null;
        semanticsHint = null;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        accessibilitySelected = checked;
        // Only provide hint for unselected radio buttons to avoid duplication
        // of the selected state announcement.
        // Selected state is already announced by iOS via the 'selected' property.
        if (!checked) {
          final WidgetsLocalizations localizations = WidgetsLocalizations.of(context);
          semanticsHint = localizations.radioButtonUnselectedLabel;
        }
    }
    return MergeSemantics(
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        checked: checked,
        selected: accessibilitySelected,
        hint: semanticsHint,
        role: SemanticsRole.menuItemRadio,
        child: child,
      ),
    );
  }
}
