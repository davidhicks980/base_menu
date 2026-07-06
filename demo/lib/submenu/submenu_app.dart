import 'package:flutter/material.dart';

import 'src/submenu.dart';

class SubmenuApp extends StatelessWidget {
  const SubmenuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(
          child: Center(child: Submenu(orientation: Axis.vertical)),
        ),
        Container(height: 1, color: ColorScheme.of(context).outlineVariant),
        const Expanded(
          child: Center(child: Submenu(orientation: Axis.horizontal)),
        ),
      ],
    );
  }
}
