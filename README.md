# Base Menu

A composable toolkit for building custom menu systems in Flutter.

[![Pub Version](https://img.shields.io/pub/v/base_menu)](https://pub.dev/packages/base_menu)
[![Deploy Platform](https://img.shields.io/badge/platform-flutter%20%7C%20web%20%7C%20desktop-blue)](#)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

[Live Gallery](https://base-menu-library.web.app/) · [Floogle Docs Demo](https://floogle-docs.web.app/) · [API Reference](https://pub.dev/documentation/base_menu/latest/)

<p align="center">
  <img src="assets/images/sequoia.png" width="560" alt="Base Menu Sequoia Demo">
</p>

## Features

* Completely headless. No pixels are painted by this library.
* Keyboard support that follows the [WAI-ARIA Menubar
  guidelines](https://www.w3.org/WAI/ARIA/apg/patterns/menubar/)
* Menu aim assist (safe triangles)
* A robust positioning algorithm with support for custom layout delegates
* Built on the [MenuController](https://api.flutter.dev/flutter/widgets/MenuController-class.html) API


## Architecture

Base Menu provides a small set of primitive widgets that control keyboard
traversal, focus routing, and menu positioning. These widgets can be composed to create a wide

**Menus**:

* `BaseMenu` – A single-layer menu overlay or context trigger.
* `BaseSubmenu` – A BaseMenu specialized for nested menus. Coordinates
  cross-axis keyboard navigation and hover traversal. Uses a `BaseMenuItem`
  as its anchor.
* `BaseMenuBar` – An inline grouping layer that coordinates keyboard and focus
  routing for a set of menu buttons.

**Panels**:

* `BaseMenuPanel` – Linearly arranges menu items in a given `orientation` and
  tracks mouse boundaries.

**Controls**:

* `BaseHoverable` – A `MouseRegion` that passes hover state to its descendants.
* `BaseFocusable` – A `Focus` widget that passes focus state to its descendants.
* `BaseControl` - A widget that composes `BaseHoverable` and `BaseFocusable`
  with a `RawGestureDetector` to pass hover, focus, and pressed states to
  descendants. Also handles keyboard activation.
* `BaseMenuItem` – A `BaseControl` that adds hover-to-focus
  and close-on-activate actions.

## Styling Controls

Adding custom styling to menu items

Because `BaseMenuItem` and `BaseControl` communicate their visual state through
inherited widgets, theming can be isolated into a separate widget.

```dart
// Implement styling for a menu item using the inherited state from BaseMenuItem.
class StyledLabel extends StatelessWidget {
  const StyledLabel({super.key, required this.child});
  final Widget child;

  static const WidgetStateProperty<BoxDecoration> decoration = WidgetStateProperty.fromMap({
    WidgetState.pressed: BoxDecoration(color: Color(0xFF2B4678)),
    WidgetState.focused: BoxDecoration(color: Color(0xFF445E91)),
    WidgetState.any: BoxDecoration(color: Color(0x00000000)),
  });

  static const WidgetStateProperty<TextStyle> textStyle = WidgetStateProperty.fromMap({
    WidgetState.disabled: TextStyle(color: Color(0xFF74777F)),
    WidgetState.pressed: TextStyle(color: Color(0xFFFFFFFF)),
    WidgetState.focused: TextStyle(color: Color(0xFFFFFFFF)),
    WidgetState.any: TextStyle(color: Color(0xFF1A1B20)),
  });

  @override
  Widget build(BuildContext context) {
    final states = BaseMenuItem.statesOf(context);
    return DecoratedBox(
      decoration: decoration.resolve(states),
      child: DefaultTextStyle.merge(
        style: textStyle.resolve(states),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Align(alignment: AlignmentDirectional.centerStart, child: child),
        ),
      ),
    );
  }
}

class CustomMenuItem extends StatelessWidget {
  const CustomMenuItem({super.key, required this.child, this.onPressed});
  final Widget child;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return BaseMenuItem(
      onPressed: onPressed,
      child: StyledLabel(child: child),
    );
  }
}
```

This makes it easy to swap out the styling of menu items without changing the
underlying menu logic.


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
                          return const ColoredBox(color: Color(0xFFFF0000));
                        } else {
                          return const ColoredBox(color: Color(0xFF000000));
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

## Getting started

Add the package to your `pubspec.yaml` and import it into your project:

```dart
import 'package:base_menu/base_menu.dart';
```

### Example:

```dart
class BaseMenuApp extends StatefulWidget {
  const BaseMenuApp({super.key});

  @override
  State<BaseMenuApp> createState() => _BaseMenuAppState();
}

class _BaseMenuAppState extends State<BaseMenuApp> {
  final MenuController controllerOne = MenuController();
  final MenuController controllerTwo = MenuController();
  String message = 'Nothing';

  static const panelDecoration = BoxDecoration(
    color: Color(0xFFFFFFFF),
    boxShadow: [BoxShadow(color: Color(0x28000000), blurRadius: 4, offset: Offset(0, 2))],
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: .center,
      mainAxisSize: .max,
      spacing: 16,
      children: [
        const Text('BaseMenu Example', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text('Pressed $message', style: const TextStyle(fontSize: 16)),
        BaseMenuBar(
          child: BaseMenuPanel(
            constraints: const BoxConstraints.tightFor(height: 30),
            children: <Widget>[
              BaseSubmenu(
                controller: controllerOne,
                requestCloseOnPointerExit: false,
                menu: DecoratedBox(
                  decoration: panelDecoration,
                  child: BaseMenuPanel(
                    constraints: const BoxConstraints.tightFor(width: 100),
                    children: <Widget>[
                      BaseMenuItem(
                        onPressed: () {
                          setState(() {
                            message = 'New';
                          });
                        },
                        child: const Label(child: Text('New')),
                      ),
                      BaseMenuItem(
                        onPressed: () {
                          setState(() {
                            message = 'Open';
                          });
                        },
                        child: const Label(child: Text('Open...')),
                      ),
                    ],
                  ),
                ),
                child: const Label(
                  color: Color(0xFFB1D2FF),
                  padding: .symmetric(horizontal: 30),
                  child: Text('File'),
                ),
              ),
              BaseSubmenu(
                controller: controllerTwo,
                requestCloseOnPointerExit: false,
                menu: DecoratedBox(
                  decoration: panelDecoration,
                  child: BaseMenuPanel(
                    constraints: const BoxConstraints.tightFor(width: 100),
                    children: <Widget>[
                      BaseMenuItem(
                        onPressed: () {
                          setState(() {
                            message = 'Undo';
                          });
                        },
                        child: const Label(child: Text('Undo')),
                      ),
                      BaseMenuItem(
                        onPressed: () {
                          setState(() {
                            message = 'Redo';
                          });
                        },
                        child: const Label(child: Text('Redo')),
                      ),
                    ],
                  ),
                ),
                child: const Label(
                  color: Color(0xFFFFDEB1),
                  padding: .symmetric(horizontal: 30),
                  child: Text('Edit'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class Label extends StatelessWidget {
  const Label({
    super.key,
    required this.child,
    this.color,
    this.alignment = .centerStart,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });
  
  final Widget child;
  final Color? color;
  final AlignmentGeometry alignment;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BaseMenuItem.isFocusedOf(context)
          ? BoxDecoration(border: Border.all(width: 2), color: color)
          : BoxDecoration(color: color),
      child: Padding(
        padding: padding,
        child: Align(alignment: alignment, child: child),
      ),
    );
  }
}
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request on
GitHub. I'm especially interested in feedback on accessibility, API ergonomics,
and edge cases in keyboard traversal and menu positioning logic.
