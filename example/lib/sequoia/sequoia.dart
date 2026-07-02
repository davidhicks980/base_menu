import 'package:flutter/material.dart';

import 'src/context_menu.dart';
import 'src/menu.dart';
import 'src/model.dart';

class SequoiaApp extends StatefulWidget {
  const SequoiaApp({super.key});

  @override
  State<SequoiaApp> createState() => _SequoiaAppState();
}

class _SequoiaAppState extends State<SequoiaApp> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Align(
          alignment: .topLeft,
          child: SequoiaMenuBar(items: sequoiaMenu),
        ),
        Positioned(
          top: 100,
          left: 100,
          right: 100,
          bottom: 100,
          child: SequoiaContextMenuRegion(
            item: const [
              MenuItem(label: 'Undo'),
              MenuItem(label: 'Redo'),
              MenuDividerItem(),
              MenuItem(label: 'Cut'),
              MenuItem(label: 'Copy'),
              MenuItem(label: 'Paste'),
              MenuDividerItem(),
              MenuItem(
                label: 'Share',
                children: [
                  MenuItem(
                    label: 'Social Media',
                    children: [
                      MenuItem(label: 'Twitter'),
                      MenuItem(label: 'Facebook'),
                      MenuItem(label: 'Instagram'),
                      MenuItem(label: 'LinkedIn'),
                    ],
                  ),
                  MenuItem(
                    label: 'Email',
                    children: [
                      MenuItem(label: 'Work Email'),
                      MenuItem(label: 'Personal Email'),
                      MenuItem(label: 'Support'),
                    ],
                  ),
                  MenuItem(label: 'Messages'),
                  MenuItem(label: 'AirDrop'),
                ],
              ),
              MenuItem(
                label: 'Services',
                children: [
                  MenuItem(label: 'Search in Google'),
                  MenuItem(label: 'Translate'),
                ],
              ),
            ],
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0x0fffffff),
                border: Border.all(color: ColorScheme.of(context).outlineVariant),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
