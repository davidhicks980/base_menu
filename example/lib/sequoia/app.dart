import 'package:flutter/material.dart';
import 'package:menu_utilities/menu_utilities.dart';

import 'menu.dart';
import 'model.dart';

class SequoiaApp extends StatefulWidget {
  const SequoiaApp({super.key});

  @override
  State<SequoiaApp> createState() => _SequoiaAppState();
}

class _SequoiaAppState extends State<SequoiaApp> {
  @override
  Widget build(BuildContext context) {
    return const App(
      backgroundColor: Color(0xff0f00ff),
      localizationsDelegates: [
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      SequoiaMenu(items: sequoiaMenu),
    );
  }
}
