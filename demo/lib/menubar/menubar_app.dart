import 'package:flutter/material.dart' hide MenuBar;

import '../app/app.dart';
import '../shared/theme.dart';
import 'src/menubar.dart';

class MenuBarApp extends StatelessWidget {
  const MenuBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(child: MenuBar(orientation: Axis.vertical)),
        Separator.horizontal(color: AppColorScheme.of(context).outlineVariant, thickness: 2),
        const Expanded(child: MenuBar(orientation: Axis.horizontal)),
      ],
    );
  }
}
