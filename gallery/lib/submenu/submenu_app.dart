import 'package:flutter/material.dart';

import '../app/app.dart';
import '../shared/separator.dart';
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
        Separator.horizontal(color: AppColorScheme.of(context).outlineVariant, thickness: 2),
        const Expanded(
          child: Center(child: Submenu(orientation: Axis.horizontal)),
        ),
      ],
    );
  }
}
