import 'package:flutter/material.dart';

import '../shared/theme.dart';
import 'src/menu.dart';

class MenuApp extends StatelessWidget {
  const MenuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Expanded(
          child: Center(child: Popup(orientation: Axis.vertical)),
        ),
        MenuDivider.horizontal(),
        Expanded(
          child: Center(child: Popup(orientation: Axis.horizontal)),
        ),
      ],
    );
  }
}
