import 'package:flutter/material.dart';

import 'widgets/menu.dart';
import 'widgets/model.dart';

class SequoiaApp extends StatefulWidget {
  const SequoiaApp({super.key});

  @override
  State<SequoiaApp> createState() => _SequoiaAppState();
}

class _SequoiaAppState extends State<SequoiaApp> {
  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: .topLeft,
      child: SequoiaMenu(items: sequoiaMenu),
    );
  }
}
