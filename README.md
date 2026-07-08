# Base Menu (WIP)

Composable widgets for building menu systems.

Warning: This package is a work in progress and the API is subject to change.
Use with caution and be prepared for breaking changes.

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
import 'package:base_menu/base_menu.dart';
```

### Basic usage:

```dart
BaseMenuBar(
  child: BaseMenuPanel(
    constraints: const BoxConstraints(height: 30),
    children: <Widget>[
      BaseSubmenu(
        controller: controllerOne,
        menu: ColoredBox(
          color: const Color(0xFFFFFFFF),
          child: BaseMenuPanel(
            padding: const EdgeInsets.all(10),
            children: <Widget>[
              BaseMenuItem(
                onPressed: () {
                  print('New');
                },
                child: const Text('New'),
              ),
              BaseMenuItem(
                onPressed: () {
                  print('Open');
                },
                child: const Text('Open...'),
              ),
            ],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          color: const Color(0xFF61FF71),
          alignment: .center,
          child: const Text('File'),
        ),
      ),
      BaseSubmenu(
        controller: controllerTwo,
        menu: ColoredBox(
          color: const Color(0xFFFFFFFF),
          child: BaseMenuPanel(
            padding: const EdgeInsets.all(10),
            children: <Widget>[
              BaseMenuItem(
                onPressed: () {
                  print('Undo');
                },
                child: const Text('Undo'),
              ),
              BaseMenuItem(
                onPressed: () {
                  print('Redo');
                },
                child: const Text('Redo'),
              ),
            ],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          color: const Color(0xFF619BFF),
          alignment: .center,
          child: const Text('Edit'),
        ),
      ),
    ],
  ),
);
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request on
GitHub. I'm especially interested in feedback on accessibility, API ergonomics,
and edge cases in keyboard traversal and menu positioning logic.
