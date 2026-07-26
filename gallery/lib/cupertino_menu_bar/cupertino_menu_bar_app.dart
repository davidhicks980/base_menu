import 'package:base_menu/base_menu.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../shared/browser_context_menu_blocker.dart';
import 'src/context_menu.dart';
import 'src/menu.dart';
import 'src/model.dart';

class CupertinoMenuBarApp extends StatefulWidget {
  const CupertinoMenuBarApp({super.key});

  @override
  State<CupertinoMenuBarApp> createState() => _CupertinoMenuBarAppState();
}

class _CupertinoMenuBarAppState extends State<CupertinoMenuBarApp> {
  final MenuController contextMenuController = MenuController();
  @override
  Widget build(BuildContext context) {
    return MenuAimScope(
      enable: true,
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            width: 100,
            top: 100,
            bottom: 100,
            child: ColoredBox(color: Color(0x45000000)),
          ),
          const Positioned(
            left: 0,
            right: 0,
            height: 100,
            bottom: 0,
            child: ColoredBox(color: Color(0x45000000)),
          ),
          const Positioned(
            right: 0,
            width: 100,
            top: 100,
            bottom: 100,
            child: ColoredBox(color: Color(0x45000000)),
          ),
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 100,
            child: ColoredBox(color: Color(0x45000000)),
          ),
          Align(
            alignment: .topLeft,
            child: CupertinoMenuBar(items: sequoiaMenu, onOpen: contextMenuController.close),
          ),

          Positioned(
            top: 100,
            bottom: 100,
            right: 100,
            left: 100,
            child: ContextMenuBlockerRegion(
              child: CupertinoContextMenu(
                controller: contextMenuController,
                item: const [
                  MenuItem(label: 'Undo', icon: CupertinoIcons.arrow_uturn_left),
                  MenuItem(label: 'Redo', icon: CupertinoIcons.arrow_uturn_right),
                  MenuDividerItem(),
                  MenuItem(label: 'Cut', icon: CupertinoIcons.scissors),
                  MenuItem(label: 'Copy', icon: CupertinoIcons.doc_on_doc),
                  MenuItem(label: 'Paste', icon: CupertinoIcons.doc_on_clipboard),
                  MenuDividerItem(),
                  MenuItem(
                    label: 'Share',
                    icon: CupertinoIcons.share,
                    children: [
                      MenuItem(
                        label: 'Social Media',
                        icon: CupertinoIcons.person_2,
                        children: [
                          MenuItem(label: 'Twitter', icon: CupertinoIcons.chat_bubble),
                          MenuItem(label: 'Facebook', icon: CupertinoIcons.person_2_square_stack),
                          MenuItem(label: 'Instagram', icon: CupertinoIcons.camera),
                          MenuItem(label: 'LinkedIn', icon: CupertinoIcons.briefcase),
                        ],
                      ),
                      MenuItem(
                        label: 'Email',
                        icon: CupertinoIcons.mail,
                        children: [
                          MenuItem(label: 'Work Email', icon: CupertinoIcons.briefcase),
                          MenuItem(label: 'Personal Email', icon: CupertinoIcons.person),
                          MenuItem(label: 'Support', icon: CupertinoIcons.question_circle),
                        ],
                      ),
                      MenuItem(label: 'Messages', icon: CupertinoIcons.chat_bubble_text),
                      MenuItem(label: 'WindDrop', icon: CupertinoIcons.drop),
                    ],
                  ),
                  MenuItem(
                    label: 'Services',
                    icon: CupertinoIcons.slider_horizontal_3,
                    children: [
                      MenuItem(label: 'Search in Floogle', icon: CupertinoIcons.search),
                      MenuItem(label: 'Translate', icon: CupertinoIcons.text_bubble),
                    ],
                  ),
                ],
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
