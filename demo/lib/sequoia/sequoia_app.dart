import 'package:flutter/material.dart';

import '../app/app.dart';
import '../shared/browser_context_menu_blocker.dart';
import 'src/context_menu.dart';
import 'src/menu.dart';
import 'src/model.dart';

class SequoiaApp extends StatefulWidget {
  const SequoiaApp({super.key});

  @override
  State<SequoiaApp> createState() => _SequoiaAppState();
}

class _SequoiaAppState extends State<SequoiaApp> {
  final MenuController contextMenuController = MenuController();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: .topLeft,
          child: SequoiaMenuBar(items: sequoiaMenu, onOpen: contextMenuController.close),
        ),
        Positioned(
          top: 100,
          left: 100,
          right: 100,
          bottom: 100,
          child: ContextMenuBlockerRegion(
            child: SequoiaContextMenu(
              controller: contextMenuController,
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
                    MenuItem(label: 'Search in Floogle'),
                    MenuItem(label: 'Translate'),
                  ],
                ),
              ],
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0x0fffffff),
                  border: Border.all(color: AppColorScheme.of(context).outlineVariant),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
