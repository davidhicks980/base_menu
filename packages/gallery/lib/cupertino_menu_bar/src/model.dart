import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class MenuItem {
  const MenuItem({required this.label, this.icon, this.shortcut, this.children = const []});

  final String label;
  final IconData? icon;
  final MenuSerializableShortcut? shortcut;
  final List<MenuItem> children;
}

class MenuDividerItem extends MenuItem {
  const MenuDividerItem() : super(label: '', children: const []);
}

const List<MenuItem> sequoiaMenu = [
  MenuItem(
    label: 'System',
    icon: CupertinoIcons.desktopcomputer,
    children: [
      MenuItem(label: 'About This Tree', icon: CupertinoIcons.info),
      MenuDividerItem(),
      MenuItem(label: 'System Settings...', icon: CupertinoIcons.gear),
      MenuItem(label: 'Tree Store...', icon: CupertinoIcons.bag),
      MenuDividerItem(),
      MenuItem(
        label: 'Recent Items',
        icon: CupertinoIcons.clock,
        children: [
          MenuItem(
            label: 'Documents',
            icon: CupertinoIcons.doc,
            children: [MenuItem(label: 'No Recent Items', icon: CupertinoIcons.clear)],
          ),
          MenuItem(
            label: 'Applications',
            icon: CupertinoIcons.square_grid_2x2,
            children: [MenuItem(label: 'No Recent Items', icon: CupertinoIcons.clear)],
          ),
          MenuItem(
            label: 'Servers',
            icon: CupertinoIcons.desktopcomputer,
            children: [MenuItem(label: 'No Recent Items', icon: CupertinoIcons.clear)],
          ),
          MenuDividerItem(),
          MenuItem(label: 'Clear Menu', icon: CupertinoIcons.trash),
        ],
      ),
      MenuDividerItem(),
      MenuItem(
        label: 'Force Quit...',
        icon: CupertinoIcons.xmark_circle,
        shortcut: SingleActivator(LogicalKeyboardKey.escape, meta: true, alt: true),
      ),
      MenuDividerItem(),
      MenuItem(label: 'Sleep', icon: CupertinoIcons.moon),
      MenuItem(label: 'Restart...', icon: CupertinoIcons.restart),
      MenuItem(label: 'Shut Down...', icon: CupertinoIcons.power),
      MenuDividerItem(),
      MenuItem(
        label: 'Lock Screen',
        icon: CupertinoIcons.lock,
        shortcut: SingleActivator(LogicalKeyboardKey.keyQ, meta: true, control: true),
      ),
      MenuItem(
        label: 'Log Out...',
        icon: CupertinoIcons.square_arrow_right,
        shortcut: SingleActivator(LogicalKeyboardKey.keyQ, meta: true, shift: true),
      ),
    ],
  ),
  MenuItem(
    label: 'Code',
    icon: CupertinoIcons.chevron_left_slash_chevron_right,
    children: [
      MenuItem(label: 'About Code', icon: CupertinoIcons.info_circle),
      MenuDividerItem(),
      MenuItem(
        label: 'Settings',
        icon: CupertinoIcons.gear_alt,
        shortcut: SingleActivator(LogicalKeyboardKey.comma, meta: true),
      ),
      MenuItem(
        label: 'Services',
        icon: CupertinoIcons.slider_horizontal_3,
        children: [MenuItem(label: 'No Services Apply', icon: CupertinoIcons.clear)],
      ),
      MenuDividerItem(),
      MenuItem(
        label: 'Hide Code',
        icon: CupertinoIcons.eye_slash,
        shortcut: SingleActivator(LogicalKeyboardKey.keyH, meta: true),
      ),
      MenuItem(
        label: 'Hide Others',
        icon: CupertinoIcons.eye_slash_fill,
        shortcut: SingleActivator(LogicalKeyboardKey.keyH, meta: true, alt: true),
      ),
      MenuItem(label: 'Show All', icon: CupertinoIcons.eye),
      MenuDividerItem(),
      MenuItem(
        label: 'Quit Code',
        icon: CupertinoIcons.power,
        shortcut: SingleActivator(LogicalKeyboardKey.keyQ, meta: true),
      ),
    ],
  ),
  MenuItem(
    label: 'File',
    icon: CupertinoIcons.doc,
    children: [
      MenuItem(
        label: 'New Text File',
        icon: CupertinoIcons.doc_plaintext,
        shortcut: SingleActivator(LogicalKeyboardKey.keyN, meta: true),
      ),
      MenuItem(
        label: 'New File...',
        shortcut: SingleActivator(LogicalKeyboardKey.keyN, meta: true, alt: true),
      ),
      MenuItem(
        label: 'New Window',
        icon: CupertinoIcons.square_stack,
        shortcut: SingleActivator(LogicalKeyboardKey.keyN, meta: true, shift: true),
      ),
      MenuDividerItem(),
      MenuItem(
        label: 'Open...',
        icon: CupertinoIcons.folder,
        shortcut: SingleActivator(LogicalKeyboardKey.keyO, meta: true),
      ),
      MenuItem(
        label: 'Open Folder...',
        icon: CupertinoIcons.folder_badge_plus,
        shortcut: SingleActivator(LogicalKeyboardKey.keyO, meta: true, alt: true),
      ),
      MenuItem(
        label: 'Open Recent',
        icon: CupertinoIcons.clock,
        children: [
          MenuItem(
            label: 'Reopen Closed Editor',
            icon: CupertinoIcons.arrow_counterclockwise,
            shortcut: SingleActivator(LogicalKeyboardKey.keyT, meta: true, shift: true),
          ),
          MenuDividerItem(),
          MenuItem(label: 'More...', icon: CupertinoIcons.ellipsis),
          MenuDividerItem(),
          MenuItem(label: 'Clear Recently Opened', icon: CupertinoIcons.trash),
        ],
      ),
      MenuDividerItem(),
      MenuItem(label: 'Save', shortcut: SingleActivator(LogicalKeyboardKey.keyS, meta: true)),
      MenuItem(
        label: 'Save As...',
        icon: CupertinoIcons.doc_on_doc,
        shortcut: SingleActivator(LogicalKeyboardKey.keyS, meta: true, shift: true),
      ),
      MenuItem(
        label: 'Save All',
        icon: CupertinoIcons.square_fill_on_square_fill,
        shortcut: SingleActivator(LogicalKeyboardKey.keyS, meta: true, alt: true),
      ),
      MenuDividerItem(),
      MenuItem(label: 'Auto Save', icon: CupertinoIcons.refresh_thin),
      MenuItem(
        label: 'Preferences',
        icon: CupertinoIcons.slider_horizontal_3,
        children: [
          MenuItem(
            label: 'Settings',
            icon: CupertinoIcons.gear,
            shortcut: SingleActivator(LogicalKeyboardKey.comma, meta: true),
          ),
          MenuItem(
            label: 'Keyboard Shortcuts',
            icon: CupertinoIcons.keyboard,
            shortcut: SingleActivator(LogicalKeyboardKey.keyK, meta: true),
          ),
          MenuItem(label: 'User Snippets', icon: CupertinoIcons.chevron_left_slash_chevron_right),
          MenuItem(label: 'Color Theme', icon: CupertinoIcons.paintbrush),
          MenuItem(label: 'File Icon Theme', icon: CupertinoIcons.photo),
        ],
      ),
      MenuDividerItem(),
      MenuItem(
        label: 'Close Editor',
        icon: CupertinoIcons.xmark,
        shortcut: SingleActivator(LogicalKeyboardKey.keyW, meta: true),
      ),
      MenuItem(
        label: 'Close Window',
        icon: CupertinoIcons.xmark_square,
        shortcut: SingleActivator(LogicalKeyboardKey.keyW, meta: true, shift: true),
      ),
      MenuDividerItem(),
      MenuItem(label: 'Exit', icon: CupertinoIcons.square_arrow_right),
    ],
  ),
  MenuItem(
    label: 'Edit',
    icon: CupertinoIcons.pencil,
    children: [
      MenuItem(
        label: 'Undo',
        icon: CupertinoIcons.arrow_counterclockwise,
        shortcut: SingleActivator(LogicalKeyboardKey.keyZ, meta: true),
      ),
      MenuItem(
        label: 'Redo',
        icon: CupertinoIcons.arrow_clockwise,
        shortcut: SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true),
      ),
      MenuDividerItem(),
      MenuItem(
        label: 'Cut',
        icon: CupertinoIcons.scissors,
        shortcut: SingleActivator(LogicalKeyboardKey.keyX, meta: true),
      ),
      MenuItem(
        label: 'Copy',
        icon: CupertinoIcons.doc_on_doc,
        shortcut: SingleActivator(LogicalKeyboardKey.keyC, meta: true),
      ),
      MenuItem(
        label: 'Paste',
        icon: CupertinoIcons.doc_on_clipboard,
        shortcut: SingleActivator(LogicalKeyboardKey.keyV, meta: true),
      ),
      MenuDividerItem(),
      MenuItem(
        label: 'Find',
        icon: CupertinoIcons.search,
        shortcut: SingleActivator(LogicalKeyboardKey.keyF, meta: true),
      ),
      MenuItem(
        label: 'Replace',
        icon: CupertinoIcons.arrow_right_arrow_left,
        shortcut: SingleActivator(LogicalKeyboardKey.keyF, meta: true, alt: true),
      ),
      MenuDividerItem(),
      MenuItem(
        label: 'Find in Files',
        icon: CupertinoIcons.doc_text_search,
        shortcut: SingleActivator(LogicalKeyboardKey.keyF, meta: true, shift: true),
      ),
      MenuItem(
        label: 'Replace in Files',
        icon: CupertinoIcons.arrow_right_arrow_left_square,
        shortcut: SingleActivator(LogicalKeyboardKey.keyH, meta: true, shift: true),
      ),
    ],
  ),
  MenuItem(
    label: 'Selection',
    icon: CupertinoIcons.selection_pin_in_out,
    children: [
      MenuItem(
        label: 'Select All',
        icon: CupertinoIcons.square_grid_2x2,
        shortcut: SingleActivator(LogicalKeyboardKey.keyA, meta: true),
      ),
      MenuItem(
        label: 'Expand Selection',
        icon: CupertinoIcons.arrow_up_left_arrow_down_right,
        shortcut: SingleActivator(LogicalKeyboardKey.keyA, meta: true, shift: true, control: true),
      ),
      MenuItem(
        label: 'Shrink Selection',
        icon: CupertinoIcons.arrow_down_right_arrow_up_left,
        shortcut: SingleActivator(LogicalKeyboardKey.keyS, meta: true, shift: true, control: true),
      ),
      MenuDividerItem(),
      MenuItem(
        label: 'Copy Line Up',
        icon: CupertinoIcons.arrow_up,
        shortcut: SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, alt: true),
      ),
      MenuItem(
        label: 'Copy Line Down',
        icon: CupertinoIcons.arrow_down,
        shortcut: SingleActivator(LogicalKeyboardKey.arrowDown, shift: true, alt: true),
      ),
      MenuItem(
        label: 'Move Line Up',
        icon: CupertinoIcons.arrow_up,
        shortcut: SingleActivator(LogicalKeyboardKey.arrowUp, alt: true),
      ),
      MenuItem(
        label: 'Move Line Down',
        icon: CupertinoIcons.arrow_down,
        shortcut: SingleActivator(LogicalKeyboardKey.arrowDown, alt: true),
      ),
      MenuDividerItem(),
      MenuItem(
        label: 'Add Cursor Above',
        icon: CupertinoIcons.add,
        shortcut: SingleActivator(LogicalKeyboardKey.arrowUp, meta: true, alt: true),
      ),
      MenuItem(
        label: 'Add Cursor Below',
        icon: CupertinoIcons.add,
        shortcut: SingleActivator(LogicalKeyboardKey.arrowDown, meta: true, alt: true),
      ),
    ],
  ),
  MenuItem(
    label: 'View',
    icon: CupertinoIcons.eye,
    children: [
      MenuItem(
        label: 'Command Palette...',
        icon: CupertinoIcons.command,
        shortcut: SingleActivator(LogicalKeyboardKey.keyP, meta: true, shift: true),
      ),
      MenuItem(label: 'Open View...', icon: CupertinoIcons.viewfinder),
      MenuDividerItem(),
      MenuItem(
        label: 'Appearance',
        icon: CupertinoIcons.device_desktop,
        children: [
          MenuItem(
            label: 'Full Screen',
            icon: CupertinoIcons.fullscreen,
            shortcut: SingleActivator(LogicalKeyboardKey.keyF, control: true, meta: true),
          ),
          MenuItem(
            label: 'Zen Mode',
            icon: CupertinoIcons.square,
            shortcut: SingleActivator(LogicalKeyboardKey.keyZ, meta: true),
          ),
          MenuItem(label: 'Centered Layout', icon: CupertinoIcons.square_split_2x1),
          MenuDividerItem(),
          MenuItem(label: 'Menu Bar', icon: CupertinoIcons.bars),
          MenuItem(
            label: 'Side Bar',
            icon: CupertinoIcons.sidebar_left,
            shortcut: SingleActivator(LogicalKeyboardKey.keyB, meta: true),
          ),
          MenuItem(
            label: 'Panel',
            icon: CupertinoIcons.square_split_1x2,
            shortcut: SingleActivator(LogicalKeyboardKey.keyJ, meta: true),
          ),
          MenuItem(label: 'Status Bar', icon: CupertinoIcons.rectangle_dock),
        ],
      ),
      MenuItem(
        label: 'Editor Layout',
        icon: CupertinoIcons.square_grid_2x2,
        children: [
          MenuItem(label: 'Single', icon: CupertinoIcons.square),
          MenuItem(label: 'Two Columns', icon: CupertinoIcons.square_split_2x1),
          MenuItem(label: 'Three Columns', icon: CupertinoIcons.square_split_2x1),
          MenuItem(label: 'Grid (2x2)', icon: CupertinoIcons.square_grid_2x2),
        ],
      ),
      MenuDividerItem(),
      MenuItem(
        label: 'Explorer',
        icon: CupertinoIcons.folder,
        shortcut: SingleActivator(LogicalKeyboardKey.keyE, meta: true, shift: true),
      ),
      MenuItem(
        label: 'Search',
        icon: CupertinoIcons.search,
        shortcut: SingleActivator(LogicalKeyboardKey.keyF, meta: true, shift: true),
      ),
      MenuItem(
        label: 'Source Control',
        icon: CupertinoIcons.tuningfork,
        shortcut: SingleActivator(LogicalKeyboardKey.keyG, meta: true, shift: true, control: true),
      ),
      MenuItem(
        label: 'Run',
        icon: CupertinoIcons.play,
        shortcut: SingleActivator(LogicalKeyboardKey.keyD, meta: true, shift: true),
      ),
      MenuItem(
        label: 'Extensions',
        icon: CupertinoIcons.square_stack_3d_up,
        shortcut: SingleActivator(LogicalKeyboardKey.keyX, meta: true, shift: true),
      ),
      MenuDividerItem(),
      MenuItem(
        label: 'Output',
        icon: CupertinoIcons.text_bubble,
        shortcut: SingleActivator(LogicalKeyboardKey.keyU, meta: true, shift: true),
      ),
      MenuItem(
        label: 'Terminal',
        shortcut: SingleActivator(LogicalKeyboardKey.backquote, control: true),
      ),
      MenuDividerItem(),
      MenuItem(
        label: 'Word Wrap',
        icon: CupertinoIcons.arrow_right_arrow_left,
        shortcut: SingleActivator(LogicalKeyboardKey.keyZ, alt: true),
      ),
    ],
  ),
  MenuItem(
    label: 'Go',
    icon: CupertinoIcons.arrow_right_arrow_left,
    children: [
      MenuItem(
        label: 'Back',
        icon: CupertinoIcons.arrow_left,
        shortcut: SingleActivator(LogicalKeyboardKey.bracketLeft, control: true),
      ),
      MenuItem(
        label: 'Forward',
        icon: CupertinoIcons.arrow_right,
        shortcut: SingleActivator(LogicalKeyboardKey.bracketRight, control: true),
      ),
      MenuDividerItem(),
      MenuItem(
        label: 'Go to File...',
        icon: CupertinoIcons.doc,
        shortcut: SingleActivator(LogicalKeyboardKey.keyP, meta: true),
      ),
      MenuItem(
        label: 'Go to Symbol in Editor...',
        icon: CupertinoIcons.at,
        shortcut: SingleActivator(LogicalKeyboardKey.keyO, meta: true, shift: true),
      ),
      MenuItem(
        label: 'Go to Symbol in Project...',
        icon: CupertinoIcons.number,
        shortcut: SingleActivator(LogicalKeyboardKey.keyT, meta: true),
      ),
      MenuDividerItem(),
      MenuItem(
        label: 'Go to Line/Column...',
        icon: CupertinoIcons.list_number,
        shortcut: SingleActivator(LogicalKeyboardKey.keyG, control: true),
      ),
      MenuDividerItem(),
      MenuItem(
        label: 'Next Problem',
        icon: CupertinoIcons.exclamationmark_triangle,
        shortcut: SingleActivator(LogicalKeyboardKey.f8),
      ),
      MenuItem(
        label: 'Previous Problem',
        icon: CupertinoIcons.exclamationmark_triangle_fill,
        shortcut: SingleActivator(LogicalKeyboardKey.f8, shift: true),
      ),
    ],
  ),
  MenuItem(
    label: 'Run',
    icon: CupertinoIcons.play,
    children: [
      MenuItem(
        label: 'Start Debugging',
        icon: CupertinoIcons.play_circle,
        shortcut: SingleActivator(LogicalKeyboardKey.f5),
      ),
      MenuItem(
        label: 'Run Without Debugging',
        icon: CupertinoIcons.play,
        shortcut: SingleActivator(LogicalKeyboardKey.f5, control: true),
      ),
      MenuItem(
        label: 'Stop Debugging',
        icon: CupertinoIcons.stop_circle,
        shortcut: SingleActivator(LogicalKeyboardKey.f5, shift: true),
      ),
      MenuItem(
        label: 'Restart Debugging',
        icon: CupertinoIcons.restart,
        shortcut: SingleActivator(LogicalKeyboardKey.f5, meta: true, shift: true),
      ),
      MenuDividerItem(),
      MenuItem(
        label: 'Toggle Breakpoint',
        icon: CupertinoIcons.smallcircle_fill_circle,
        shortcut: SingleActivator(LogicalKeyboardKey.f9),
      ),
      MenuItem(label: 'New Breakpoint', icon: CupertinoIcons.add_circled),
    ],
  ),
  MenuItem(
    label: 'Terminal',
    children: [
      MenuItem(
        label: 'New Terminal',
        shortcut: SingleActivator(LogicalKeyboardKey.backquote, control: true, shift: true),
      ),
      MenuItem(
        label: 'Split Terminal',
        icon: CupertinoIcons.square_split_2x1,
        shortcut: SingleActivator(LogicalKeyboardKey.backslash, meta: true),
      ),
      MenuDividerItem(),
      MenuItem(label: 'Run Selected Text', icon: CupertinoIcons.play),
      MenuItem(label: 'Run Active File', icon: CupertinoIcons.play),
    ],
  ),
  MenuItem(
    label: 'Help',
    icon: CupertinoIcons.question_circle,
    children: [
      MenuItem(label: 'Welcome', icon: CupertinoIcons.hand_draw),
      MenuItem(
        label: 'Show All Commands',
        icon: CupertinoIcons.command,
        shortcut: SingleActivator(LogicalKeyboardKey.keyP, meta: true, shift: true),
      ),
      MenuItem(label: 'Documentation', icon: CupertinoIcons.book),
      MenuItem(label: 'Editor Playground', icon: CupertinoIcons.gamecontroller),
      MenuDividerItem(),
      MenuItem(label: 'Keyboard Shortcuts Reference', icon: CupertinoIcons.keyboard),
      MenuItem(label: 'Video Tutorials', icon: CupertinoIcons.play_rectangle),
      MenuItem(label: 'Tips and Tricks', icon: CupertinoIcons.lightbulb),
      MenuDividerItem(),
      MenuItem(label: 'Join Us on TreeTube', icon: CupertinoIcons.tv),
      MenuItem(label: 'Search Feature Requests', icon: CupertinoIcons.search),
      MenuItem(label: 'Report Issue', icon: CupertinoIcons.flag),
      MenuDividerItem(),
      MenuItem(label: 'View License', icon: CupertinoIcons.doc_text),
      MenuItem(label: 'Privacy Statement', icon: CupertinoIcons.shield),
      MenuDividerItem(),
      MenuItem(
        label: 'Toggle Developer Tools',
        icon: CupertinoIcons.wrench,
        shortcut: SingleActivator(LogicalKeyboardKey.keyI, meta: true, alt: true),
      ),
      MenuItem(label: 'Open Process Explorer', icon: CupertinoIcons.speedometer),
      MenuDividerItem(),
      MenuItem(label: 'About', icon: CupertinoIcons.info),
    ],
  ),
];
