import 'package:flutter/material.dart';

import '../app/app.dart';
import '../shared/separator.dart';
import 'src/menu.dart';

class MenuApp extends StatelessWidget {
  const MenuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(
          child: Center(child: Popup(orientation: Axis.vertical)),
        ),
        Separator.horizontal(color: AppColorScheme.of(context).outlineVariant, thickness: 2),
        const Expanded(
          child: Center(child: Popup(orientation: Axis.horizontal)),
        ),
      ],
    );
  }
}
