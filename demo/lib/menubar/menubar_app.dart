import 'package:flutter/material.dart' hide MenuBar;

import '../shared/theme.dart';
import 'src/menubar.dart';

class MenuBarApp extends StatelessWidget {
  const MenuBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Expanded(child: MenuBar(orientation: Axis.vertical)),
        MenuDivider.horizontal(),
        Expanded(child: MenuBar(orientation: Axis.horizontal)),
      ],
    );
  }
}
