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
    label: 'File',
    children: [
      MenuItem(
        label: 'New',
        children: [
          MenuItem(
            label: 'Blank Document',
            shortcut: SingleActivator(LogicalKeyboardKey.keyN, meta: true),
          ),
          MenuItem(
            label: 'From Template',
            shortcut: SingleActivator(LogicalKeyboardKey.keyN, meta: true, shift: true),
          ),
          MenuItem(label: 'Project Folder'),
        ],
      ),
      MenuItem(
        label: 'Open',
        children: [
          MenuItem(
            label: 'Recent Files',
            shortcut: SingleActivator(LogicalKeyboardKey.keyO, meta: true),
          ),
          MenuItem(label: 'iCloud Drive'),
          MenuItem(label: 'On My Mac'),
          MenuItem(label: 'Network Server'),
        ],
      ),
      MenuDividerItem(),
      MenuItem(label: 'Save', shortcut: SingleActivator(LogicalKeyboardKey.keyS, meta: true)),
      MenuItem(label: 'Export As...'),
      MenuItem(label: 'Print', shortcut: SingleActivator(LogicalKeyboardKey.keyP, meta: true)),
    ],
  ),
  MenuItem(
    label: 'Edit',
    children: [
      MenuItem(
        label: 'Undo',
        shortcut: SingleActivator(LogicalKeyboardKey.keyZ, meta: true),
        children: [
          MenuItem(label: 'Undo Typing'),
          MenuItem(label: 'Undo Formatting'),
          MenuItem(
            label: 'Redo',
            shortcut: SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true),
          ),
          MenuItem(label: 'Undo History'),
        ],
      ),

      MenuItem(label: 'Cut', shortcut: SingleActivator(LogicalKeyboardKey.keyX, meta: true)),
      MenuItem(label: 'Copy', shortcut: SingleActivator(LogicalKeyboardKey.keyC, meta: true)),
      MenuItem(label: 'Paste', shortcut: SingleActivator(LogicalKeyboardKey.keyV, meta: true)),
      MenuDividerItem(),

      MenuItem(
        label: 'Find',
        children: [
          MenuItem(
            label: 'Find...',
            shortcut: SingleActivator(LogicalKeyboardKey.keyF, meta: true),
          ),
          MenuItem(
            label: 'Find and Replace',
            shortcut: SingleActivator(LogicalKeyboardKey.keyF, meta: true, alt: true),
          ),
          MenuItem(
            label: 'Find Next',
            shortcut: SingleActivator(LogicalKeyboardKey.keyG, meta: true),
          ),
          MenuItem(
            label: 'Use Selection for Find',
            shortcut: SingleActivator(LogicalKeyboardKey.keyE, meta: true),
          ),
        ],
      ),
    ],
  ),
  MenuItem(
    label: 'View',
    children: [
      MenuItem(
        label: 'Editor Layout',
        children: [
          MenuItem(label: 'Single Column'),
          MenuItem(label: 'Two Columns'),
          MenuItem(label: 'Grid View'),
          MenuItem(label: 'Centered Content'),
        ],
      ),
      MenuItem(
        label: 'Show/Hide',
        children: [
          MenuItem(
            label: 'Sidebar',
            shortcut: SingleActivator(LogicalKeyboardKey.keyB, meta: true, control: true),
          ),
          MenuItem(label: 'Toolbar'),
          MenuItem(label: 'Status Bar'),
          MenuItem(label: 'Hidden Characters'),
        ],
      ),
      MenuDividerItem(),
      MenuItem(label: 'Zoom In', shortcut: SingleActivator(LogicalKeyboardKey.equal, meta: true)),
      MenuItem(label: 'Zoom Out', shortcut: SingleActivator(LogicalKeyboardKey.minus, meta: true)),
    ],
  ),
  MenuItem(
    label: 'Insert',
    children: [
      MenuItem(
        label: 'Table',
        children: [
          MenuItem(label: 'Insert Table...'),
          MenuItem(label: 'Add Row Above'),
          MenuItem(label: 'Add Column Left'),
          MenuItem(label: 'Convert Text to Table'),
        ],
      ),
      MenuDividerItem(),
      MenuItem(
        label: 'Reference',
        children: [
          MenuItem(label: 'Footnote'),
          MenuItem(label: 'Citation'),
          MenuItem(label: 'Link', shortcut: SingleActivator(LogicalKeyboardKey.keyK, meta: true)),
          MenuItem(label: 'Bookmark'),
        ],
      ),
      MenuItem(label: 'Equation'),
      MenuItem(label: 'Horizontal Rule'),
    ],
  ),
  MenuItem(
    label: 'Format',
    children: [
      MenuItem(
        label: 'Text Alignment',
        children: [
          MenuItem(label: 'Left'),
          MenuItem(label: 'Center'),
          MenuItem(label: 'Right'),
          MenuItem(label: 'Justify'),
        ],
      ),
      MenuItem(
        label: 'Font Styles',
        children: [
          MenuItem(label: 'Bold', shortcut: SingleActivator(LogicalKeyboardKey.keyB, meta: true)),
          MenuItem(label: 'Italic', shortcut: SingleActivator(LogicalKeyboardKey.keyI, meta: true)),
          MenuItem(
            label: 'Underline',
            shortcut: SingleActivator(LogicalKeyboardKey.keyU, meta: true),
          ),
          MenuItem(label: 'Strikethrough'),
        ],
      ),
      MenuItem(label: 'Bullet Points'),
      MenuItem(label: 'Line Spacing'),
    ],
  ),
  MenuItem(
    label: 'Tools',
    children: [
      MenuItem(
        label: 'Language',
        children: [
          MenuItem(label: 'Set Language...'),
          MenuItem(label: 'Auto-Detect'),
          MenuItem(label: 'Thesaurus'),
          MenuItem(label: 'Hyphenation'),
        ],
      ),
      MenuItem(
        label: 'Scripts',
        children: [
          MenuItem(label: 'Run Macro'),
          MenuItem(label: 'Manage Scripts'),
          MenuItem(label: 'Script Editor'),
          MenuItem(label: 'Terminal Console'),
        ],
      ),
      MenuItem(label: 'Spell Check'),
      MenuItem(label: 'Word Count'),
    ],
  ),
  MenuItem(
    label: 'Help',
    children: [
      MenuItem(
        label: 'Online Resources',
        children: [
          MenuItem(label: 'Documentation'),
          MenuItem(label: 'Video Tutorials'),
          MenuItem(label: 'API Reference'),
          MenuItem(label: 'Usage Statistics'),
        ],
      ),
      MenuItem(
        label: 'Legal',
        children: [
          MenuItem(label: 'Terms of Service'),
          MenuItem(label: 'Privacy Policy'),
          MenuItem(label: 'Third Party Notices'),
          MenuItem(label: 'License Info'),
        ],
      ),
      MenuDividerItem(),
      MenuItem(label: 'Contact Support'),
      MenuItem(label: 'About Sequoia'),
    ],
  ),
];
