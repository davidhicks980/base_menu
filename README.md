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
        return BaseControl(
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

### Menu Items

Menu Utilities provides compositional widgets that allow you to build menu items with
different levels of theming granularity.

Theme with the inherited `WidgetState` of a menu item:

```dart
/// A menu item that changes color when hovered, focused, or pressed.
class MenuItem extends StatelessWidget {
  const MenuItem({super.key, required this.child, required this.onPressed, this.suffix});
  final Widget child;
  final Widget? suffix;
  final VoidCallback? onPressed;

  static const WidgetStateProperty<BoxDecoration> decoration = WidgetStateProperty.fromMap({
    WidgetState.pressed: BoxDecoration(color: Color(0xFFE9E9E9)),
    WidgetState.hovered: BoxDecoration(color: Color(0xFFEDEDED)),
    WidgetState.focused: BoxDecoration(color: Color(0xFFEDEDED)),
    WidgetState.any:     BoxDecoration(color: Color(0x00000000)),
  });

  @override
  Widget build(BuildContext context) {
    final Widget body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: suffix != null
        ? Row(spacing: 12, mainAxisAlignment: .spaceBetween, children: [child, suffix!])
        : child,
    );

    return BaseMenuItem(
      onPressed: () {},
      child: Builder(
        builder: (context) {
          // Rebuilds any time the menu item is hovered, focused, pressed, or
          // disabled.
          return DecoratedBox(
            decoration: decoration.resolve(BaseMenuItem.statesOf(context)),
            child: body,
          );
        },
      ),
    );
  }
}
```

Depend on a specific menu item state to isolate updates:

```dart
/// A suffix that changes color when its parent menu item is hovered.
class Suffix extends StatelessWidget {
  const Suffix({super.key});

  @override
  Widget build(BuildContext context) {
    const box = SizedBox.square(dimension: 20);
    // Rebuilds only when the parent menu item is hovered.
    if (BaseMenuItem.isHoveredOf(context)) {
      return const ColoredBox(color: Color(0xFFFF0000), child: box);
    } else {
      return const ColoredBox(color: Color(0xFF000000), child: box);
    }
  }
}
```

Isolate hover effects to a particular part of a menu item:

```dart
/// A suffix that changes color it is hovered, but not when its parent menu item
/// is hovered.
class HoverableSuffix extends StatelessWidget {
  const HoverableSuffix({super.key});

  @override
  Widget build(BuildContext context) {
    const box = SizedBox.square(dimension: 20);
    return BaseHoverable(
      child: Builder(
        builder: (context) {
          // Rebuilds only when this widget is hovered.
          if (BaseHoverable.isHoveredOf(context)) {
            return const ColoredBox(color: Color(0xFFFF0000), child: box);
          } else {
            return const ColoredBox(color: Color(0xFF000000), child: box);
          }
        },
      ),
    );
  }
}
```

Use `BaseHoverable` with a generic type parameter to pass hover state to
descendant widgets without exposing the Menu Utilities API:

```dart
/// A suffix that passes its hover state to its child.
class SpecializedSuffix extends StatelessWidget {
  const SpecializedSuffix({super.key, required this.child});
  final Widget child;

  static bool isHovered(BuildContext context) {
    return BaseHoverable.isHoveredOf<SpecializedSuffix>(context);
  }

  @override
  Widget build(BuildContext context) {
    return BaseHoverable<SpecializedSuffix>(
      child: ConstrainedBox(
        constraints: const BoxConstraints.tightFor(width: 20, height: 20),
        child: child,
      ),
    );
  }
}
```

Putting it all together:

```dart
class CustomizedMenu extends StatelessWidget {
  const CustomizedMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
      child: ColoredBox(
        color: const Color(0xFF0FF0FF),
        child: BaseMenu(
          builder: (BuildContext context, MenuController controller, Widget? child) {
            return BaseControl(
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
          menu: ColoredBox(
            color: const Color(0xFFFFFFFF),
            child: BaseMenuPanel(
              direction: .vertical,
              children: [
                MenuItem(
                  onPressed: () {
                    print('Suffix Pressed');
                  },
                  suffix: const Suffix(),
                  child: const Text('Suffix'),
                ),
                MenuItem(
                  onPressed: () {
                    print('Hoverable Suffix Pressed');
                  },
                  suffix: const HoverableSuffix(),
                  child: const Text('Hoverable Suffix'),
                ),
                MenuItem(
                  onPressed: () {
                    print('Specialized Suffix Pressed');
                  },
                  suffix: SpecializedSuffix(
                    child: Builder(
                      builder: (context) {
                        if (SpecializedSuffix.isHovered(context)) {
                          return const ColoredBox(
                            color: Color(0xFFFF0000),
                          );
                        } else {
                          return const ColoredBox(
                            color: Color(0xFF000000),
                          );
                        }
                      },
                    ),
                  ),
                  child: const Text('Specialized Suffix'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request on
GitHub. I'm especially interested in feedback on accessibility, API ergonomics,
and edge cases in keyboard traversal and menu positioning logic.
