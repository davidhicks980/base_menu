import 'package:flutter/material.dart';

import '../cupertino_menu_bar/cupertino_menu_bar_app.dart';
import '../cupertino_menu_bar/src/theme.dart';
import '../shared/package.dart';
import 'src/surface.dart';

class LookingGlassApp extends StatelessWidget {
  const LookingGlassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: ExactAssetImage('assets/images/mountains.jpeg', package: kPackage),

                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        CupertinoMenuTheme(
          surface: const LookingGlassSurface(),
          surfacePadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: CupertinoMenuBarItemTheme(
            radius: const Radius.circular(16),
            child: CupertinoMenuItemTheme(
              radius: const Radius.circular(8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              showIcon: true,
              highlightColor: const Color.from(alpha: 1, red: 0.172, green: 0.345, blue: 0.728),
              expandedColor: const Color.from(alpha: 0.392, red: 1, green: 1, blue: 1),
              secondaryTextStyle: const TextStyle(fontSize: 13),
              secondaryTextHighlight: TextStyle(
                fontSize: 13,
                foreground: Paint()
                  ..color = const Color.fromARGB(20, 255, 255, 255)
                  ..blendMode = BlendMode.overlay,
              ),
              child: const CupertinoMenuBarApp(),
            ),
          ),
        ),
      ],
    );
  }
}
