# Menu Utilities (WIP)

Composable widgets for building menu systems in Flutter.

Warning: This package is a work in progress and the API is subject to change.
Use with caution and be prepared for breaking changes.

## Features

* **Robust Keyboard Traversal:** Built-in shortcut mappings for navigating menus
  and submenus via the keyboard (arrows, tab, home, end, etc.).
* **Adaptive Positioning:** Customizable positioning logic that adapts to
  padding, offsets, and screen boundaries to ensure menus are always fully
  visible.
* **Multi-axis:** Works for both vertical and horizontal menu layouts,
  making it suitable for dropdowns, context menus, toolbars, and more.
* **Unstyled by default:** Provides core functionality without imposing any visual
  opinions, allowing you to style menus to fit your app's unique look and feel.

## Motivation

This package is designed to fill the gap between RawMenuAnchor and the
platform-specific menu implementations (MenuAnchor, MenuBar,
CupertinoMenuAnchor). Many of the features contained in this package will
eventually be proposed for inclusion in the Flutter SDK, but this package is
intended to allow developers to start using and providing feedback on these
features in the meantime.

## Getting started

Add the package to your `pubspec.yaml` and import it into your project:

```dart
import 'package:menu_utilities/menu_utilities.dart';
```

## Usage

```dart
import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

class MyDropdownMenu extends StatelessWidget {
  const MyDropdownMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseMenu(
      builder: (BuildContext context, MenuController controller, Widget? child) {
        return BaseButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          child: const Text('Open Menu'),
        );
      },
      panel: ColoredBox(
        color: const Color(0xFFFFFFFF),
        child: BaseMenuPanel(
          axis: Axis.vertical,
          menuChildren: [
            BaseMenuItem(
              onPressed: () => print('Item 1 clicked'),
              child: const Text('Menu Item 1'),
            ),
            BaseMenuItem(
              onPressed: () => print('Item 2 clicked'),
              child: const Text('Menu Item 2'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Advanced Interactions

You can hook into the interactive state of your menu items to dynamically apply
styles using `BaseControl` scopes:

```dart
class StyledMenuItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseMenuItem(
      onPressed: () {},
      child: Builder(
        builder: (context) {
          final isHovered = BaseControl.isHoveredOf(context);
          final isFocused = BaseControl.isFocusedOf(context);
          return Container(
            color: isHovered || isFocused ? Colors.blue : Colors.transparent,
            child: const Text('Interactive Item'),
          );
        }
      ),
    );
  }
}
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request on
GitHub. I'm especially interested in feedback on accessibility, API ergonomics,
and edge cases in keyboard traversal and menu positioning logic.
