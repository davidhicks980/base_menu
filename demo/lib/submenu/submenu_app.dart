import 'package:flutter/material.dart';

import '../shared/theme.dart';
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
        MenuDivider.horizontal(),
        const Expanded(
          child: Center(child: Submenu(orientation: Axis.horizontal)),
        ),
      ],
    );
  }
}
