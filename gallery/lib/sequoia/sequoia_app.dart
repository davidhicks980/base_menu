import 'package:flutter/material.dart';

import '../cupertino_menu_bar/cupertino_menu_bar_app.dart';
import '../cupertino_menu_bar/src/theme.dart';
import '../shared/package.dart';
import 'src/surface.dart';

const EdgeInsets _kCupertinoMenuItemPadding = EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.5);
const Radius _kCupertinoMenuBorderRadius = Radius.circular(4.0);

class SequoiaApp extends StatelessWidget {
  const SequoiaApp({super.key});

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
          surfacePadding:
              EdgeInsets.all(3 / View.of(context).devicePixelRatio) + const EdgeInsets.all(4),
          surface: const SequoiaMenuSurface(),
          child: const CupertinoMenuBarItemTheme(
            radius: Radius.circular(5),
            child: CupertinoMenuItemTheme(
              highlightColor: Color.from(alpha: 1, red: 0.082, green: 0.388, blue: 0.725),
              radius: _kCupertinoMenuBorderRadius,
              padding: _kCupertinoMenuItemPadding,
              showIcon: false,
              expandedColor: Color.fromARGB(24, 255, 255, 255),
              secondaryTextStyle: TextStyle(fontSize: 13),

              child: CupertinoMenuBarApp(),
            ),
          ),
        ),
      ],
    );
  }
}
