import 'package:flutter/material.dart' hide MenuBar;

import 'src/menubar.dart';

class MenuBarApp extends StatelessWidget {
  const MenuBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(child: MenuBar(orientation: Axis.vertical)),
        Container(height: 1, color: ColorScheme.of(context).outlineVariant),
        const Expanded(child: MenuBar(orientation: Axis.horizontal)),
      ],
    );
  }
}
