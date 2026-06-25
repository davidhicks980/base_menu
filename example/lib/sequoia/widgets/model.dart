import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class MenuItem {
  const MenuItem({required this.label, this.shortcut, this.children = const []});

  final String label;
  final MenuSerializableShortcut? shortcut;
  final List<MenuItem> children;
}

class MenuDividerItem extends MenuItem {
  const MenuDividerItem() : super(label: '', children: const []);
}

const List<MenuItem> sequoiaMenu = [
  MenuItem(
    label: 'System',
    children: [
      MenuItem(label: 'About This Tree'),
      MenuDividerItem(),
      MenuItem(label: 'System Settings...'),
      MenuItem(label: 'Tree Store...'),
      MenuDividerItem(),
      MenuItem(
        label: 'Recent Items',
        children: [
          MenuItem(
            label: 'Documents',
            children: [MenuItem(label: 'No Recent Items')],
          ),
          MenuItem(
            label: 'Applications',
            children: [MenuItem(label: 'No Recent Items')],
          ),
          MenuItem(
            label: 'Servers',
            children: [MenuItem(label: 'No Recent Items')],
          ),
          MenuDividerItem(),
          MenuItem(label: 'Clear Menu'),
        ],
      ),
      MenuDividerItem(),
      MenuItem(
        label: 'Force Quit...',
        shortcut: SingleActivator(LogicalKeyboardKey.escape, meta: true, alt: true),
      ),
      MenuDividerItem(),
      MenuItem(label: 'Sleep'),
      MenuItem(label: 'Restart...'),
      MenuItem(label: 'Shut Down...'),
      MenuDividerItem(),
      MenuItem(
        label: 'Lock Screen',
        shortcut: SingleActivator(LogicalKeyboardKey.keyQ, meta: true, control: true),
      ),
      MenuItem(
        label: 'Log Out...',
        shortcut: SingleActivator(LogicalKeyboardKey.keyQ, meta: true, shift: true),
      ),
    ],
  ),
  MenuItem(
    label: 'Code',
    children: [
      MenuItem(label: 'About Code'),
      MenuDividerItem(),
      MenuItem(label: 'Settings', shortcut: SingleActivator(LogicalKeyboardKey.comma, meta: true)),
      MenuItem(
        label: 'Services',
        children: [MenuItem(label: 'No Services Apply')],
      ),
      MenuDividerItem(),
      MenuItem(label: 'Hide Code', shortcut: SingleActivator(LogicalKeyboardKey.keyH, meta: true)),
      MenuItem(
        label: 'Hide Others',
        shortcut: SingleActivator(LogicalKeyboardKey.keyH, meta: true, alt: true),
      ),
      MenuItem(label: 'Show All'),
      MenuDividerItem(),
      MenuItem(label: 'Quit Code', shortcut: SingleActivator(LogicalKeyboardKey.keyQ, meta: true)),
    ],
  ),
  MenuItem(
    label: 'File',
    children: [
      MenuItem(
        label: 'New Text File',
        shortcut: SingleActivator(LogicalKeyboardKey.keyN, meta: true),
      ),
      MenuItem(
        label: 'New File...',
        shortcut: SingleActivator(LogicalKeyboardKey.keyN, meta: true, alt: true),
      ),
      MenuItem(
        label: 'New Window',
        shortcut: SingleActivator(LogicalKeyboardKey.keyN, meta: true, shift: true),
      ),
      MenuDividerItem(),
      MenuItem(label: 'Open...', shortcut: SingleActivator(LogicalKeyboardKey.keyO, meta: true)),
      MenuItem(
        label: 'Open Folder...',
        shortcut: SingleActivator(LogicalKeyboardKey.keyO, meta: true, alt: true),
      ),
      MenuItem(
        label: 'Open Recent',
        children: [
          MenuItem(
            label: 'Reopen Closed Editor',
            shortcut: SingleActivator(LogicalKeyboardKey.keyT, meta: true, shift: true),
          ),
          MenuDividerItem(),
          MenuItem(label: 'More...'),
          MenuDividerItem(),
          MenuItem(label: 'Clear Recently Opened'),
        ],
      ),
      MenuDividerItem(),
      MenuItem(label: 'Save', shortcut: SingleActivator(LogicalKeyboardKey.keyS, meta: true)),
      MenuItem(
        label: 'Save As...',
        shortcut: SingleActivator(LogicalKeyboardKey.keyS, meta: true, shift: true),
      ),
      MenuItem(
        label: 'Save All',
        shortcut: SingleActivator(LogicalKeyboardKey.keyS, meta: true, alt: true),
      ),
      MenuDividerItem(),
      MenuItem(label: 'Auto Save'),
      MenuItem(
        label: 'Preferences',
        children: [
          MenuItem(
            label: 'Settings',
            shortcut: SingleActivator(LogicalKeyboardKey.comma, meta: true),
          ),
          MenuItem(
            label: 'Keyboard Shortcuts',
            shortcut: SingleActivator(LogicalKeyboardKey.keyK, meta: true),
          ),
          MenuItem(label: 'User Snippets'),
          MenuItem(label: 'Color Theme'),
          MenuItem(label: 'File Icon Theme'),
        ],
      ),
      MenuDividerItem(),
      MenuItem(
        label: 'Close Editor',
        shortcut: SingleActivator(LogicalKeyboardKey.keyW, meta: true),
      ),
      MenuItem(
        label: 'Close Window',
        shortcut: SingleActivator(LogicalKeyboardKey.keyW, meta: true, shift: true),
      ),
      MenuDividerItem(),
      MenuItem(label: 'Exit'),
    ],
  ),
  MenuItem(
    label: 'Edit',
    children: [
      MenuItem(label: 'Undo', shortcut: SingleActivator(LogicalKeyboardKey.keyZ, meta: true)),
      MenuItem(
        label: 'Redo',
        shortcut: SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true),
      ),
      MenuDividerItem(),
      MenuItem(label: 'Cut', shortcut: SingleActivator(LogicalKeyboardKey.keyX, meta: true)),
      MenuItem(label: 'Copy', shortcut: SingleActivator(LogicalKeyboardKey.keyC, meta: true)),
      MenuItem(label: 'Paste', shortcut: SingleActivator(LogicalKeyboardKey.keyV, meta: true)),
      MenuDividerItem(),
      MenuItem(label: 'Find', shortcut: SingleActivator(LogicalKeyboardKey.keyF, meta: true)),
      MenuItem(
        label: 'Replace',
        shortcut: SingleActivator(LogicalKeyboardKey.keyF, meta: true, alt: true),
      ),
      MenuDividerItem(),
      MenuItem(
        label: 'Find in Files',
        shortcut: SingleActivator(LogicalKeyboardKey.keyF, meta: true, shift: true),
      ),
      MenuItem(
        label: 'Replace in Files',
        shortcut: SingleActivator(LogicalKeyboardKey.keyH, meta: true, shift: true),
      ),
    ],
  ),
  MenuItem(
    label: 'Selection',
    children: [
      MenuItem(label: 'Select All', shortcut: SingleActivator(LogicalKeyboardKey.keyA, meta: true)),
      MenuItem(
        label: 'Expand Selection',
        shortcut: SingleActivator(LogicalKeyboardKey.keyA, meta: true, shift: true, control: true),
      ),
      MenuItem(
        label: 'Shrink Selection',
        shortcut: SingleActivator(LogicalKeyboardKey.keyS, meta: true, shift: true, control: true),
      ),
      MenuDividerItem(),
      MenuItem(
        label: 'Copy Line Up',
        shortcut: SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, alt: true),
      ),
      MenuItem(
        label: 'Copy Line Down',
        shortcut: SingleActivator(LogicalKeyboardKey.arrowDown, shift: true, alt: true),
      ),
      MenuItem(
        label: 'Move Line Up',
        shortcut: SingleActivator(LogicalKeyboardKey.arrowUp, alt: true),
      ),
      MenuItem(
        label: 'Move Line Down',
        shortcut: SingleActivator(LogicalKeyboardKey.arrowDown, alt: true),
      ),
      MenuDividerItem(),
      MenuItem(
        label: 'Add Cursor Above',
        shortcut: SingleActivator(LogicalKeyboardKey.arrowUp, meta: true, alt: true),
      ),
      MenuItem(
        label: 'Add Cursor Below',
        shortcut: SingleActivator(LogicalKeyboardKey.arrowDown, meta: true, alt: true),
      ),
    ],
  ),
  MenuItem(
    label: 'View',
    children: [
      MenuItem(
        label: 'Command Palette...',
        shortcut: SingleActivator(LogicalKeyboardKey.keyP, meta: true, shift: true),
      ),
      MenuItem(label: 'Open View...'),
      MenuDividerItem(),
      MenuItem(
        label: 'Appearance',
        children: [
          MenuItem(
            label: 'Full Screen',
            shortcut: SingleActivator(LogicalKeyboardKey.keyF, control: true, meta: true),
          ),
          MenuItem(
            label: 'Zen Mode',
            shortcut: SingleActivator(LogicalKeyboardKey.keyZ, meta: true),
          ),
          MenuItem(label: 'Centered Layout'),
          MenuDividerItem(),
          MenuItem(label: 'Menu Bar'),
          MenuItem(
            label: 'Side Bar',
            shortcut: SingleActivator(LogicalKeyboardKey.keyB, meta: true),
          ),
          MenuItem(label: 'Panel', shortcut: SingleActivator(LogicalKeyboardKey.keyJ, meta: true)),
          MenuItem(label: 'Status Bar'),
        ],
      ),
      MenuItem(
        label: 'Editor Layout',
        children: [
          MenuItem(label: 'Single'),
          MenuItem(label: 'Two Columns'),
          MenuItem(label: 'Three Columns'),
          MenuItem(label: 'Grid (2x2)'),
        ],
      ),
      MenuDividerItem(),
      MenuItem(
        label: 'Explorer',
        shortcut: SingleActivator(LogicalKeyboardKey.keyE, meta: true, shift: true),
      ),
      MenuItem(
        label: 'Search',
        shortcut: SingleActivator(LogicalKeyboardKey.keyF, meta: true, shift: true),
      ),
      MenuItem(
        label: 'Source Control',
        shortcut: SingleActivator(LogicalKeyboardKey.keyG, meta: true, shift: true, control: true),
      ),
      MenuItem(
        label: 'Run',
        shortcut: SingleActivator(LogicalKeyboardKey.keyD, meta: true, shift: true),
      ),
      MenuItem(
        label: 'Extensions',
        shortcut: SingleActivator(LogicalKeyboardKey.keyX, meta: true, shift: true),
      ),
      MenuDividerItem(),
      MenuItem(
        label: 'Output',
        shortcut: SingleActivator(LogicalKeyboardKey.keyU, meta: true, shift: true),
      ),
      MenuItem(
        label: 'Terminal',
        shortcut: SingleActivator(LogicalKeyboardKey.backquote, control: true),
      ),
      MenuDividerItem(),
      MenuItem(label: 'Word Wrap', shortcut: SingleActivator(LogicalKeyboardKey.keyZ, alt: true)),
    ],
  ),
  MenuItem(
    label: 'Go',
    children: [
      MenuItem(
        label: 'Back',
        shortcut: SingleActivator(LogicalKeyboardKey.bracketLeft, control: true),
      ),
      MenuItem(
        label: 'Forward',
        shortcut: SingleActivator(LogicalKeyboardKey.bracketRight, control: true),
      ),
      MenuDividerItem(),
      MenuItem(
        label: 'Go to File...',
        shortcut: SingleActivator(LogicalKeyboardKey.keyP, meta: true),
      ),
      MenuItem(
        label: 'Go to Symbol in Editor...',
        shortcut: SingleActivator(LogicalKeyboardKey.keyO, meta: true, shift: true),
      ),
      MenuItem(
        label: 'Go to Symbol in Project...',
        shortcut: SingleActivator(LogicalKeyboardKey.keyT, meta: true),
      ),
      MenuDividerItem(),
      MenuItem(
        label: 'Go to Line/Column...',
        shortcut: SingleActivator(LogicalKeyboardKey.keyG, control: true),
      ),
      MenuDividerItem(),
      MenuItem(label: 'Next Problem', shortcut: SingleActivator(LogicalKeyboardKey.f8)),
      MenuItem(
        label: 'Previous Problem',
        shortcut: SingleActivator(LogicalKeyboardKey.f8, shift: true),
      ),
    ],
  ),
  MenuItem(
    label: 'Run',
    children: [
      MenuItem(label: 'Start Debugging', shortcut: SingleActivator(LogicalKeyboardKey.f5)),
      MenuItem(
        label: 'Run Without Debugging',
        shortcut: SingleActivator(LogicalKeyboardKey.f5, control: true),
      ),
      MenuItem(
        label: 'Stop Debugging',
        shortcut: SingleActivator(LogicalKeyboardKey.f5, shift: true),
      ),
      MenuItem(
        label: 'Restart Debugging',
        shortcut: SingleActivator(LogicalKeyboardKey.f5, meta: true, shift: true),
      ),
      MenuDividerItem(),
      MenuItem(label: 'Toggle Breakpoint', shortcut: SingleActivator(LogicalKeyboardKey.f9)),
      MenuItem(label: 'New Breakpoint'),
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
        shortcut: SingleActivator(LogicalKeyboardKey.backslash, meta: true),
      ),
      MenuDividerItem(),
      MenuItem(label: 'Run Selected Text'),
      MenuItem(label: 'Run Active File'),
    ],
  ),
  MenuItem(
    label: 'Help',
    children: [
      MenuItem(label: 'Welcome'),
      MenuItem(
        label: 'Show All Commands',
        shortcut: SingleActivator(LogicalKeyboardKey.keyP, meta: true, shift: true),
      ),
      MenuItem(label: 'Documentation'),
      MenuItem(label: 'Editor Playground'),
      MenuDividerItem(),
      MenuItem(label: 'Keyboard Shortcuts Reference'),
      MenuItem(label: 'Video Tutorials'),
      MenuItem(label: 'Tips and Tricks'),
      MenuDividerItem(),
      MenuItem(label: 'Join Us on TreeTube'),
      MenuItem(label: 'Search Feature Requests'),
      MenuItem(label: 'Report Issue'),
      MenuDividerItem(),
      MenuItem(label: 'View License'),
      MenuItem(label: 'Privacy Statement'),
      MenuDividerItem(),
      MenuItem(
        label: 'Toggle Developer Tools',
        shortcut: SingleActivator(LogicalKeyboardKey.keyI, meta: true, alt: true),
      ),
      MenuItem(label: 'Open Process Explorer'),
      MenuDividerItem(),
      MenuItem(label: 'About'),
    ],
  ),
];
