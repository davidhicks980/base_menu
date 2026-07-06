import 'package:flutter/material.dart';

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
        Container(height: 1, color: ColorScheme.of(context).outlineVariant),
        const Expanded(
          child: Center(child: Popup(orientation: Axis.horizontal)),
        ),
      ],
    );
  }
}
