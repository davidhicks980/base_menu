import 'package:base_menu/src/menu.dart';
import 'package:flutter/material.dart';

import '../shared/alignment_template.dart';
import 'src/positioning.dart';

class PositioningApp extends StatelessWidget {
  const PositioningApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = MenuController();
    return AlignmentTemplate(
      controller: controller,
      build: (BuildContext context, DefaultMenuPositioningDelegate delegate) {
        return Submenu(
          controller: controller,
          orientation: Axis.vertical,
          submenuPositioningDelegate: delegate,
        );
      },
    );
  }
}
