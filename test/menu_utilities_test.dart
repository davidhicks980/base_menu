// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_utilities/menu_utilities.dart';

// Tests that apply to select constructors have a suffix that indicates which
// constructor the test applies to:
//  * [Default]: Applies to [RawMenuAnchor],
//  * [OverlayBuilder]: Applies to [BaseMenu]
//  * [Node]: Applies to [RawMenuAnchor.menuPanel].
//  * [Overlays]: Applies to [RawMenuAnchor] and [BaseMenu]
// Otherwise, the test applies to all constructors.

void main() {
  late MenuController controller;
  String? focusedMenu;
  final selected = <Tag>[];
  final opened = <Tag>[];
  final closed = <Tag>[];

  void onPressed(Tag item) {
    selected.add(item);
  }

  void onOpen(Tag item) {
    opened.add(item);
  }

  void onClose(Tag item) {
    opened.remove(item);
    closed.add(item);
  }

  void handleFocusChange() {
    focusedMenu = (primaryFocus?.debugLabel ?? primaryFocus).toString();
  }

  setUp(() {
    focusedMenu = null;
    selected.clear();
    opened.clear();
    closed.clear();
    controller = MenuController();
    focusedMenu = null;
  });

  Future<void> changeSurfaceSize(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
  }

  void listenForFocusChanges() {
    FocusManager.instance.addListener(handleFocusChange);
    addTearDown(() => FocusManager.instance.removeListener(handleFocusChange));
  }

  Finder findOverlayContents() {
    return find.descendant(of: find.byType(BaseMenuPanel), matching: find.byType(IntrinsicWidth));
  }

  T findMenuPanelDescendent<T extends Widget>(WidgetTester tester) {
    return tester.firstWidget<T>(
      find.descendant(of: find.byType(BaseMenuPanel), matching: find.byType(T)),
    );
  }

  List<RenderObject> findAncestorRenderTheaters(RenderObject child) {
    final results = <RenderObject>[];
    RenderObject? node = child;
    while (node != null) {
      if (node.runtimeType.toString() == '_RenderTheater') {
        results.add(node);
      }
      final RenderObject? parent = node.parent;
      node = parent is RenderObject ? parent : null;
    }
    return results;
  }

  Matcher sizeCloseTo(Size size, num distance) {
    return within(
      distance: distance,
      from: size,
      distanceFunction: (Size a, Size b) {
        final double deltaWidth = (a.width - b.width).abs();
        final double deltaHeight = (a.height - b.height).abs();
        return math.max<double>(deltaWidth, deltaHeight);
      },
    );
  }

  testWidgets("[Overlays] MenuController.isOpen is true when a menu's overlay is shown", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      App(
        BaseMenu(
          controller: controller,
          menu: BaseMenuPanel(orientation: Axis.vertical, children: <Widget>[Text(Tag.a.text)]),
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    expect(controller.isOpen, isTrue);
    expect(find.text(Tag.a.text), findsOneWidget);

    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    expect(controller.isOpen, isFalse);
    expect(find.text(Tag.a.text), findsNothing);
  });

  testWidgets('[Overlays] MenuController.open() and .close() toggle overlay visibility', (
    WidgetTester tester,
  ) async {
    final nestedController = MenuController();
    await tester.pumpWidget(
      App(
        BaseMenu(
          controller: controller,
          menu: BaseMenuPanel(
            orientation: Axis.vertical,
            children: <Widget>[
              Text(Tag.a.text),
              BaseMenu(
                controller: nestedController,
                menu: BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[Text(Tag.b.a.text)],
                ),
                child: const AnchorButton(Tag.b),
              ),
            ],
          ),
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    // Create the menu. The menu is closed, so no menu items should be found in
    // the widget tree.
    expect(controller.isOpen, isFalse);
    expect(find.text(Tag.anchor.text), findsOne);
    expect(find.text(Tag.a.text), findsNothing);

    // Open the menu.
    controller.open();
    await tester.pump();

    expect(controller.isOpen, isTrue);
    expect(nestedController.isOpen, isFalse);
    expect(find.text(Tag.a.text), findsOneWidget);
    expect(find.text(Tag.b.a.text), findsNothing);

    // Open the nested menu.
    nestedController.open();
    await tester.pump();

    expect(controller.isOpen, isTrue);
    expect(nestedController.isOpen, isTrue);
    expect(find.text(Tag.a.text), findsOneWidget);
    expect(find.text(Tag.b.a.text), findsOneWidget);

    // Close the menu from the root controller.
    controller.close();
    await tester.pump();

    // All menus should be closed.
    expect(controller.isOpen, isFalse);
    expect(find.text(Tag.a.text), findsNothing);
    expect(find.text(Tag.b.a.text), findsNothing);

    // Open the nested menu.
    controller.open();
    await tester.pump();

    nestedController.open();
    await tester.pump();

    expect(controller.isOpen, isTrue);
    expect(nestedController.isOpen, isTrue);
    expect(find.text(Tag.a.text), findsOneWidget);
    expect(find.text(Tag.b.a.text), findsOneWidget);

    // Close the nested menu, but not the root menu.
    nestedController.close();
    await tester.pump();

    expect(controller.isOpen, isTrue);
    expect(nestedController.isOpen, isFalse);
    expect(find.text(Tag.a.text), findsOneWidget);
    expect(find.text(Tag.b.a.text), findsNothing);
  });

  testWidgets('[Overlays] MenuController.closeChildren closes submenu children', (
    WidgetTester tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      App(
        BaseMenu(
          controller: controller,
          menu: BaseMenuPanel(
            orientation: Axis.vertical,
            children: <Widget>[
              Text(Tag.a.text),
              BaseMenu(
                menu: BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[Text(Tag.b.a.text)],
                ),
                child: AnchorButton(Tag.b, focusNode: focusNode),
              ),
            ],
          ),
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    await tester.tap(find.text(Tag.b.text));
    await tester.pump();

    focusNode.requestFocus();
    await tester.pump();

    expect(find.text(Tag.b.text), findsOneWidget);
    expect(find.text(Tag.b.a.text), findsOneWidget);

    controller.closeChildren();
    await tester.pump();

    expect(controller.isOpen, isTrue);
    expect(find.text(Tag.b.text), findsOneWidget);
    expect(find.text(Tag.b.a.text), findsNothing);

    // Focus should stay on the anchor button.
    expect(FocusManager.instance.primaryFocus, focusNode);
  });

  testWidgets('[Overlays] Can only have one open child anchor', (WidgetTester tester) async {
    await tester.pumpWidget(
      App(
        BaseMenu(
          menu: Column(
            children: <Widget>[
              BaseMenu(
                menu: BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[Text(Tag.a.a.text)],
                ),
                child: const AnchorButton(Tag.a),
              ),
              BaseMenu(
                menu: BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[Text(Tag.b.a.text)],
                ),
                child: const AnchorButton(Tag.b),
              ),
            ],
          ),
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    expect(find.text(Tag.a.text), findsOneWidget);
    expect(find.text(Tag.b.text), findsOneWidget);
    expect(find.text(Tag.a.a.text), findsNothing);
    expect(find.text(Tag.b.a.text), findsNothing);

    await tester.tap(find.text(Tag.a.text));
    await tester.pump();

    expect(find.text(Tag.a.a.text), findsOneWidget);
    expect(find.text(Tag.b.a.text), findsNothing);

    await tester.tap(find.text(Tag.b.text));
    await tester.pump();

    expect(find.text(Tag.a.a.text), findsNothing);
    expect(find.text(Tag.b.a.text), findsOneWidget);
  });

  testWidgets('[Overlays] Context menus can be nested', (WidgetTester tester) async {
    await tester.pumpWidget(
      App(
        BaseMenu(
          menu: BaseMenuPanel(orientation: Axis.vertical, children: <Widget>[Button.tag(Tag.a.a)]),
          builder: (BuildContext context, MenuController controller, Widget? child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const AnchorButton(Tag.a),
                BaseMenu(
                  menu: BaseMenuPanel(
                    orientation: Axis.vertical,
                    children: <Widget>[Button.tag(Tag.b.a)],
                  ),
                  child: const AnchorButton(Tag.b),
                ),
              ],
            );
          },
        ),
      ),
    );

    await tester.tap(find.text(Tag.a.text));
    await tester.pump();

    expect(find.text(Tag.a.a.text), findsOneWidget);

    await tester.tap(find.text(Tag.b.text));
    await tester.pump();

    expect(find.text(Tag.b.a.text), findsOneWidget);
  });

  testWidgets('[Node] MenuController.isOpen is true when a descendent menu is open', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      App(
        BaseMenuBar(
          controller: controller,
          child: Row(
            children: <Widget>[
              BaseMenu(
                menu: BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[Text(Tag.a.a.text)],
                ),
                child: const AnchorButton(Tag.a),
              ),
              // Menu should not need to be a direct descendent.
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: BaseMenu(
                  menu: BaseMenuPanel(
                    orientation: Axis.vertical,
                    children: <Widget>[Text(Tag.b.a.text)],
                  ),
                  child: const AnchorButton(Tag.b),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(controller.isOpen, isFalse);

    await tester.tap(find.text(Tag.a.text));
    await tester.pump();

    expect(controller.isOpen, isTrue);
    expect(find.text(Tag.a.a.text), findsOneWidget);
    expect(find.text(Tag.b.a.text), findsNothing);

    await tester.tap(find.text(Tag.b.text));
    await tester.pump();
    await tester.pump();

    expect(controller.isOpen, isTrue);
    expect(find.text(Tag.a.a.text), findsNothing);
    expect(find.text(Tag.b.a.text), findsOneWidget);

    await tester.tap(find.text(Tag.b.text));
    await tester.pump();

    expect(controller.isOpen, isFalse);
    expect(find.text(Tag.b.a.text), findsNothing);
  });

  testWidgets('[Node] MenuController.open does nothing', (WidgetTester tester) async {
    final nestedController = MenuController();
    await tester.pumpWidget(
      App(
        BaseMenuBar(
          controller: controller,
          child: Column(
            children: <Widget>[
              BaseMenu(
                controller: nestedController,
                menu: BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[Text(Tag.b.a.text)],
                ),
                child: const AnchorButton(Tag.b),
              ),
            ],
          ),
        ),
      ),
    );

    // Create the menu. The menu is closed, so no menu items should be found in
    // the widget tree.
    expect(controller.isOpen, isFalse);
    expect(find.text(Tag.b.text), findsOne);
    expect(find.text(Tag.b.a.text), findsNothing);

    // Open the menu (which should do nothing).
    controller.open();
    await tester.pump();

    expect(controller.isOpen, isFalse);
    expect(nestedController.isOpen, isFalse);
    expect(find.text(Tag.b.text), findsOneWidget);
    expect(find.text(Tag.b.a.text), findsNothing);
  });

  testWidgets('[Node] MenuController.close closes children', (WidgetTester tester) async {
    final nestedController = MenuController();
    await tester.pumpWidget(
      App(
        BaseMenuBar(
          controller: controller,
          child: Column(
            children: <Widget>[
              BaseMenu(
                controller: nestedController,
                menu: BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[Text(Tag.b.a.text)],
                ),
                child: const AnchorButton(Tag.b),
              ),
            ],
          ),
        ),
      ),
    );

    // Open the nested anchor.
    nestedController.open();
    await tester.pump();

    expect(controller.isOpen, isTrue);
    expect(nestedController.isOpen, isTrue);
    expect(find.text(Tag.b.text), findsOneWidget);
    expect(find.text(Tag.b.a.text), findsOneWidget);

    // Close the root menu panel
    controller.close();
    await tester.pump();

    expect(controller.isOpen, isFalse);
    expect(nestedController.isOpen, isFalse);
    expect(find.text(Tag.b.text), findsOneWidget);
    expect(find.text(Tag.b.a.text), findsNothing);
  });

  testWidgets('[Node] MenuController.closeChildren closes children', (WidgetTester tester) async {
    final nestedController = MenuController();
    await tester.pumpWidget(
      App(
        BaseMenuBar(
          controller: controller,
          child: Column(
            children: <Widget>[
              BaseMenu(
                controller: nestedController,
                menu: BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[Text(Tag.b.a.text)],
                ),
                child: const AnchorButton(Tag.b),
              ),
            ],
          ),
        ),
      ),
    );

    // Open the nested anchor.
    nestedController.open();
    await tester.pump();

    expect(controller.isOpen, isTrue);
    expect(nestedController.isOpen, isTrue);
    expect(find.text(Tag.b.text), findsOneWidget);
    expect(find.text(Tag.b.a.text), findsOneWidget);

    // Close the root menu panel.
    controller.closeChildren();
    await tester.pump();

    expect(controller.isOpen, isFalse);
    expect(nestedController.isOpen, isFalse);
    expect(find.text(Tag.b.text), findsOneWidget);
    expect(find.text(Tag.b.a.text), findsNothing);
  });

  testWidgets('[Node] Should only display one open child anchor at a time', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      App(
        BaseMenuBar(
          child: Row(
            children: <Widget>[
              BaseMenu(
                menu: BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[Text(Tag.a.a.text)],
                ),
                child: const AnchorButton(Tag.a),
              ),
              BaseMenu(
                menu: BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[Text(Tag.b.a.text)],
                ),
                child: const AnchorButton(Tag.b),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text(Tag.a.text), findsOneWidget);
    expect(find.text(Tag.b.text), findsOneWidget);
    expect(find.text(Tag.a.a.text), findsNothing);
    expect(find.text(Tag.b.a.text), findsNothing);

    await tester.tap(find.text(Tag.a.text));
    await tester.pump();

    expect(find.text(Tag.a.a.text), findsOneWidget);
    expect(find.text(Tag.b.a.text), findsNothing);

    await tester.tap(find.text(Tag.b.text));
    await tester.pump();

    expect(find.text(Tag.a.a.text), findsNothing);
    expect(find.text(Tag.b.a.text), findsOneWidget);
  });

  testWidgets('MenuController can be changed', (WidgetTester tester) async {
    final controller = MenuController();
    final groupController = MenuController();

    final newController = MenuController();
    final newGroupController = MenuController();

    await tester.pumpWidget(
      App(
        BaseMenuBar(
          controller: controller,
          child: BaseMenu(
            controller: groupController,
            menu: BaseMenuPanel(orientation: Axis.vertical, children: <Widget>[Text(Tag.a.text)]),
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      ),
    );

    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    expect(find.text(Tag.a.text), findsOneWidget);
    expect(controller.isOpen, isTrue);
    expect(groupController.isOpen, isTrue);
    expect(newController.isOpen, isFalse);
    expect(newGroupController.isOpen, isFalse);

    // Swap the controllers.
    await tester.pumpWidget(
      App(
        BaseMenuBar(
          controller: newController,
          child: BaseMenu(
            controller: newGroupController,
            menu: BaseMenuPanel(orientation: Axis.vertical, children: <Widget>[Text(Tag.a.text)]),
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      ),
    );

    expect(find.text(Tag.a.text), findsOneWidget);
    expect(controller.isOpen, isFalse);
    expect(groupController.isOpen, isFalse);
    expect(newController.isOpen, isTrue);
    expect(newGroupController.isOpen, isTrue);

    // Close the new controller.
    newController.close();
    await tester.pump();

    expect(newController.isOpen, isFalse);
    expect(newGroupController.isOpen, isFalse);
    expect(find.text(Tag.a.text), findsNothing);
  });

  testWidgets('MenuController is detached on update', (WidgetTester tester) async {
    await tester.pumpWidget(
      App(
        BaseMenu(
          controller: controller,
          menu: const BaseMenuPanel(
            orientation: Axis.vertical,
            children: <Widget>[SizedBox.shrink()],
          ),
          child: const SizedBox.shrink(),
        ),
      ),
    );

    // Should not throw because the controller is attached to the menu.
    controller.closeChildren();

    await tester.pumpWidget(
      const App(
        BaseMenu(
          menu: BaseMenuPanel(orientation: Axis.vertical, children: <Widget>[SizedBox.shrink()]),
          child: SizedBox.shrink(),
        ),
      ),
    );

    var serializedException = '';
    runZonedGuarded(controller.closeChildren, (Object exception, StackTrace stackTrace) {
      serializedException = exception.toString();
    });

    expect(serializedException, contains('_anchor != null'));
  });

  testWidgets('MenuController is detached on dispose', (WidgetTester tester) async {
    await tester.pumpWidget(
      App(
        BaseMenu(
          controller: controller,
          menu: const BaseMenuPanel(orientation: Axis.vertical, children: <SizedBox>[]),
          child: const SizedBox(),
        ),
      ),
    );

    // Should not throw because the controller is attached to the menu.
    controller.closeChildren();

    await tester.pumpWidget(const App(SizedBox()));

    var serializedException = '';
    runZonedGuarded(controller.closeChildren, (Object exception, StackTrace stackTrace) {
      serializedException = exception.toString();
    });

    expect(serializedException, contains('_anchor != null'));
  });

  // testWidgets('[Default] Previous focus is restored on menu close', (WidgetTester tester) async {
  //   final externalFocus = FocusNode();
  //   final aaaFocusNode = FocusNode();
  //   addTearDown(aaaFocusNode.dispose);
  //   addTearDown(externalFocus.dispose);

  //   await tester.pumpWidget(
  //     App(
  //       Column(
  //         children: <Widget>[
  //           BaseMenuBar(
  //             controller: controller,
  //             child: Row(
  //               children: <Widget>[
  //                 BaseMenu(
  //                   panel: BaseMenuPanel(
  //                     direction: Axis.vertical,
  //                     menuChildren: <Widget>[
  //                       BaseMenu(
  //                         panel: BaseMenuPanel(
  //                           direction: Axis.vertical,
  //                           menuChildren: <Widget>[Button.tag(Tag.a.a.a, focusNode: aaaFocusNode)],
  //                         ),
  //                         child: AnchorButton(Tag.a.a),
  //                       ),
  //                     ],
  //                   ),
  //                   child: const AnchorButton(Tag.a),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           Button.tag(Tag.b, autofocus: true, focusNode: externalFocus),
  //         ],
  //       ),
  //     ),
  //   );

  //   await tester.pump();

  //   expect(FocusManager.instance.primaryFocus, equals(externalFocus));

  //   await tester.tap(find.text(Tag.a.text));
  //   await tester.pump();

  //   await tester.tap(find.text(Tag.a.a.text));
  //   await tester.pump();

  //   aaaFocusNode.requestFocus();
  //   await tester.pump();

  //   expect(FocusManager.instance.primaryFocus, isNot(externalFocus));

  //   controller.close();
  //   await tester.pump();

  //   expect(FocusManager.instance.primaryFocus, equals(externalFocus));
  // });

  testWidgets('[Default] Previous focus is restored on submenu close', (WidgetTester tester) async {
    final acaFocusNode = FocusNode();
    final buttonFocus = FocusNode();
    addTearDown(acaFocusNode.dispose);
    addTearDown(buttonFocus.dispose);

    await tester.pumpWidget(
      App(
        BaseMenuBar(
          child: Row(
            children: <Widget>[
              BaseMenu(
                menu: BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[
                    Button.tag(Tag.a.a, focusNode: buttonFocus),
                    Button.tag(Tag.a.b),
                    BaseMenu(
                      controller: controller,
                      menu: BaseMenuPanel(
                        orientation: Axis.vertical,
                        children: <Widget>[Button.tag(Tag.a.c.a, focusNode: acaFocusNode)],
                      ),
                      child: AnchorButton(Tag.a.c),
                    ),
                  ],
                ),
                child: const AnchorButton(Tag.a),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text(Tag.a.text));
    await tester.pump();

    buttonFocus.requestFocus();
    await tester.pump();

    await tester.tap(find.text(Tag.a.c.text));
    await tester.pump();

    acaFocusNode.requestFocus();
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, isNot(buttonFocus));

    controller.close();
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, equals(buttonFocus));
  });

  testWidgets('Escape key closes menus', (WidgetTester tester) async {
    final aFocusNode = FocusNode();
    final baaFocusNode = FocusNode();
    addTearDown(aFocusNode.dispose);
    addTearDown(baaFocusNode.dispose);

    await tester.pumpWidget(
      App(
        BaseMenuBar(
          child: Row(
            children: <Widget>[
              Button.tag(Tag.a, focusNode: aFocusNode, onPressed: () {}),
              BaseMenu(
                controller: controller,
                menu: BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[
                    BaseMenu(
                      menu: BaseMenuPanel(
                        orientation: Axis.vertical,
                        children: <Widget>[
                          Button.tag(Tag.b.a.a, focusNode: baaFocusNode, onPressed: () {}),
                        ],
                      ),
                      child: AnchorButton(Tag.b.a),
                    ),
                  ],
                ),
                child: const AnchorButton(Tag.b),
              ),
            ],
          ),
        ),
      ),
    );

    controller.open();
    await tester.pump();

    aFocusNode.requestFocus();
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, aFocusNode);
    expect(find.text(Tag.b.a.text), findsOneWidget);

    // Test panel child can close siblings with escape key.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(find.text(Tag.b.a.text), findsNothing);

    await tester.tap(find.text(Tag.b.text));
    await tester.pump();
    await tester.tap(find.text(Tag.b.a.text));
    await tester.pump();
    baaFocusNode.requestFocus();
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, baaFocusNode);

    // Test ancestors menus are closed with escape key.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(find.text(Tag.b.a.text), findsNothing);
  });

  // Credit to Closure library for the test idea.
  testWidgets('Intents are not blocked by closed anchor', (WidgetTester tester) async {
    final invokedIntents = <Intent>[];
    final aFocusNode = FocusNode();
    addTearDown(aFocusNode.dispose);

    await tester.pumpWidget(
      App(
        Actions(
          actions: <Type, Action<Intent>>{
            DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
              onInvoke: (DirectionalFocusIntent intent) {
                invokedIntents.add(intent);
                return;
              },
            ),
            NextFocusIntent: CallbackAction<NextFocusIntent>(
              onInvoke: (NextFocusIntent intent) {
                invokedIntents.add(intent);
                return;
              },
            ),
            PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(
              onInvoke: (PreviousFocusIntent intent) {
                invokedIntents.add(intent);
                return;
              },
            ),
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (DismissIntent intent) {
                invokedIntents.add(intent);
                return;
              },
            ),
          },
          child: BaseMenuBar(
            child: Row(
              children: <Widget>[
                BaseMenu(
                  menu: BaseMenuPanel(
                    orientation: Axis.vertical,
                    children: <Widget>[Text(Tag.a.text)],
                  ),
                  child: AnchorButton(Tag.anchor, focusNode: aFocusNode),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    aFocusNode.requestFocus();
    await tester.pump();
    Actions.invoke(aFocusNode.context!, const DirectionalFocusIntent(TraversalDirection.left));
    Actions.invoke(aFocusNode.context!, const DirectionalFocusIntent(TraversalDirection.right));
    Actions.invoke(aFocusNode.context!, const NextFocusIntent());
    Actions.invoke(aFocusNode.context!, const PreviousFocusIntent());
    Actions.invoke(aFocusNode.context!, const DismissIntent());
    await tester.pump();

    expect(
      invokedIntents,
      equals(const <Intent>[
        DirectionalFocusIntent(TraversalDirection.left),
        DirectionalFocusIntent(TraversalDirection.right),
        NextFocusIntent(),
        PreviousFocusIntent(),
        DismissIntent(),
      ]),
    );
  });

  testWidgets('[OverlayBuilder] Focus traversal shortcuts are not bound to actions', (
    WidgetTester tester,
  ) async {
    final anchorFocusNode = FocusNode(debugLabel: Tag.anchor.focusNode);
    final bFocusNode = FocusNode(debugLabel: Tag.b.focusNode);
    addTearDown(anchorFocusNode.dispose);
    addTearDown(bFocusNode.dispose);

    final traversalShortcuts = <ShortcutActivator, Intent>{
      LogicalKeySet(LogicalKeyboardKey.tab): const NextFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.tab): const PreviousFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.arrowLeft): const DirectionalFocusIntent(
        TraversalDirection.left,
      ),
    };

    final invokedIntents = <Intent>[];
    await tester.pumpWidget(
      App(
        Column(
          children: <Widget>[
            Button.tag(Tag.a),
            Actions(
              actions: <Type, Action<Intent>>{
                DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
                  onInvoke: (DirectionalFocusIntent intent) {
                    invokedIntents.add(intent);
                    return null;
                  },
                ),
                NextFocusIntent: CallbackAction<NextFocusIntent>(
                  onInvoke: (NextFocusIntent intent) {
                    invokedIntents.add(intent);
                    return null;
                  },
                ),
                PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(
                  onInvoke: (PreviousFocusIntent intent) {
                    invokedIntents.add(intent);
                    return null;
                  },
                ),
              },
              child: BaseMenu(
                controller: controller,
                menu: Column(
                  children: <Widget>[
                    Button.tag(Tag.a),
                    Shortcuts(
                      // Web doesn't automatically handle directional traversal.
                      shortcuts: traversalShortcuts,
                      child: Button.tag(Tag.b, focusNode: bFocusNode),
                    ),
                    Button.tag(Tag.d),
                  ],
                ),
                child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
              ),
            ),
            Button.tag(Tag.c),
          ],
        ),
      ),
    );

    listenForFocusChanges();

    controller.open();
    await tester.pump();

    anchorFocusNode.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(focusedMenu, equals(Tag.anchor.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(focusedMenu, equals(Tag.anchor.focusNode));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    expect(focusedMenu, equals(Tag.anchor.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    expect(focusedMenu, equals(Tag.anchor.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    expect(focusedMenu, equals(Tag.anchor.focusNode));

    bFocusNode.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(focusedMenu, equals(Tag.b.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(focusedMenu, equals(Tag.b.focusNode));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    expect(focusedMenu, equals(Tag.b.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    expect(focusedMenu, equals(Tag.b.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    expect(focusedMenu, equals(Tag.b.focusNode));

    expect(
      invokedIntents,
      equals(const <Intent>[
        DirectionalFocusIntent(TraversalDirection.left),
        NextFocusIntent(),
        PreviousFocusIntent(),
        DirectionalFocusIntent(TraversalDirection.left),
        NextFocusIntent(),
        PreviousFocusIntent(),
      ]),
    );
  });

  testWidgets('Actions that wrap RawMenuAnchor are invoked by both anchor and overlay', (
    WidgetTester tester,
  ) async {
    final anchorFocusNode = FocusNode();
    final aFocusNode = FocusNode();
    addTearDown(anchorFocusNode.dispose);
    addTearDown(aFocusNode.dispose);
    var invokedAnchor = false;
    var invokedOverlay = false;

    await tester.pumpWidget(
      App(
        Actions(
          actions: <Type, Action<Intent>>{
            VoidCallbackIntent: CallbackAction<VoidCallbackIntent>(
              onInvoke: (VoidCallbackIntent intent) {
                intent.callback();
                return null;
              },
            ),
          },
          child: BaseMenu(
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[Button.tag(Tag.a, focusNode: aFocusNode)],
            ),
            child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
          ),
        ),
      ),
    );

    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    Actions.invoke(
      anchorFocusNode.context!,
      VoidCallbackIntent(() {
        invokedAnchor = true;
      }),
    );
    Actions.invoke(
      aFocusNode.context!,
      VoidCallbackIntent(() {
        invokedOverlay = true;
      }),
    );

    await tester.pump();

    // DismissIntent should not close the menu.
    expect(invokedAnchor, isTrue);
    expect(invokedOverlay, isTrue);
  });

  testWidgets('DismissMenuAction closes menus', (WidgetTester tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      App(
        BaseMenu(
          menu: BaseMenuPanel(
            orientation: Axis.vertical,
            children: <Widget>[
              Text(Tag.a.text),
              BaseMenu(
                menu: BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[
                    Text(Tag.b.a.text),
                    BaseMenu(
                      controller: controller,
                      menu: BaseMenuPanel(
                        orientation: Axis.vertical,
                        children: <Widget>[Text(Tag.b.b.a.text)],
                      ),
                      child: AnchorButton(Tag.b.b, focusNode: focusNode),
                    ),
                  ],
                ),
                child: const AnchorButton(Tag.b),
              ),
            ],
          ),
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();
    await tester.tap(find.text(Tag.b.text));
    await tester.pump();
    await tester.tap(find.text(Tag.b.b.text));
    await tester.pump();

    expect(controller.isOpen, isTrue);

    focusNode.requestFocus();
    await tester.pump();

    const ActionDispatcher().invokeAction(
      DismissMenuAction(controller: controller),
      const DismissIntent(),
      focusNode.context,
    );

    await tester.pump();

    expect(find.text(Tag.a.text), findsNothing);
  });

  testWidgets('[Node] Menu panel builder', (WidgetTester tester) async {
    await tester.pumpWidget(
      App(
        alignment: AlignmentDirectional.topStart,
        BaseMenuBar(
          child: Padding(
            key: Tag.anchor.key,
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(width: 100, height: 100, color: const ui.Color(0xff0000ff)),
                Container(width: 100, height: 100, color: const ui.Color(0xFFFF00D4)),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(Tag.anchor.key), findsOneWidget);
    expect(tester.getRect(find.byKey(Tag.anchor.key)), const Rect.fromLTWH(0, 0, 216, 116));
  });

  testWidgets('Menus close and consume tap when consumesOutsideTap is true', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      App(
        Column(
          children: <Widget>[
            Button.tag(
              Tag.outside,
              onPressed: () {
                selected.add(Tag.outside);
              },
            ),
            BaseMenuBar(
              child: Column(
                children: <Widget>[
                  BaseMenu(
                    consumeOutsideTaps: true,
                    onOpen: () => onOpen(Tag.anchor),
                    onClose: () => onClose(Tag.anchor),
                    menu: BaseMenuPanel(
                      orientation: Axis.vertical,
                      children: <Widget>[
                        BaseMenu(
                          consumeOutsideTaps: true,
                          onOpen: () => onOpen(Tag.a),
                          onClose: () => onClose(Tag.a),
                          menu: BaseMenuPanel(
                            orientation: Axis.vertical,
                            children: <Widget>[Text(Tag.a.a.text)],
                          ),
                          child: AnchorButton(Tag.a, onPressed: onPressed),
                        ),
                      ],
                    ),
                    child: AnchorButton(Tag.anchor, onPressed: onPressed),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    expect(opened, isEmpty);
    expect(closed, isEmpty);

    // Doesn't consume tap when the menu is closed.
    await tester.tap(find.text(Tag.outside.text));
    await tester.pump();

    expect(selected, equals(<NestedTag>[Tag.outside]));
    selected.clear();

    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();
    await tester.tap(find.text(Tag.a.text));
    await tester.pump();

    expect(opened, equals(<NestedTag>[Tag.anchor, Tag.a]));
    expect(closed, isEmpty);
    expect(selected, equals(<NestedTag>[Tag.anchor, Tag.a]));
    opened.clear();
    closed.clear();
    selected.clear();

    await tester.tap(find.text(Tag.outside.text));
    await tester.pump();

    expect(opened, isEmpty);
    expect(closed, equals(<NestedTag>[Tag.a, Tag.anchor]));
    expect(selected, isEmpty);

    // When the menu is open, don't expect the outside button to be selected.
    expect(selected, isEmpty);
    selected.clear();
    opened.clear();
    closed.clear();
  });

  testWidgets('[Overlays] Menus close and do not consume tap when consumesOutsideTap is false', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      App(
        Column(
          children: <Widget>[
            Button.tag(
              Tag.outside,
              onPressed: () {
                selected.add(Tag.outside);
              },
            ),
            BaseMenuBar(
              child: Column(
                children: <Widget>[
                  BaseMenu(
                    onOpen: () => onOpen(Tag.anchor),
                    onClose: () => onClose(Tag.anchor),
                    // ignore: avoid_redundant_argument_values
                    consumeOutsideTaps: false,
                    menu: BaseMenuPanel(
                      orientation: Axis.vertical,
                      children: <Widget>[
                        BaseMenu(
                          onOpen: () => onOpen(Tag.a),
                          onClose: () => onClose(Tag.a),
                          menu: BaseMenuPanel(
                            orientation: Axis.vertical,
                            children: <Widget>[Text(Tag.a.a.text)],
                          ),
                          child: AnchorButton(Tag.a, onPressed: onPressed),
                        ),
                      ],
                    ),
                    child: AnchorButton(Tag.anchor, onPressed: onPressed),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    expect(opened, isEmpty);
    expect(closed, isEmpty);

    await tester.tap(find.text(Tag.outside.text));
    await tester.pump();

    // Doesn't consume tap when the menu is closed.
    expect(selected, equals(<Tag>[Tag.outside]));

    selected.clear();

    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();
    await tester.tap(find.text(Tag.a.text));
    await tester.pump();

    expect(opened, equals(<Tag>[Tag.anchor, Tag.a]));
    expect(closed, isEmpty);
    expect(selected, equals(<Tag>[Tag.anchor, Tag.a]));

    opened.clear();
    closed.clear();
    selected.clear();

    await tester.tap(find.text(Tag.outside.text));
    await tester.pumpAndSettle();

    // Because consumesOutsideTap is false, outsideButton is expected to
    // receive a tap.
    expect(opened, isEmpty);
    expect(closed, equals(<Tag>[Tag.a, Tag.anchor]));
    expect(selected, equals(<Tag>[Tag.outside]));

    selected.clear();
    opened.clear();
    closed.clear();
  });

  testWidgets('onOpen is called when the menu is opened', (WidgetTester tester) async {
    var opened = false;
    await tester.pumpWidget(
      App(
        BaseMenu(
          controller: controller,
          onOpen: () {
            opened = true;
          },
          menu: const BaseMenuPanel(orientation: Axis.vertical, children: <Widget>[]),
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );
    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    expect(opened, isTrue);

    opened = false;
    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    // onOpen should not be called again.
    expect(opened, isFalse);

    controller.open();
    await tester.pump();

    expect(opened, isTrue);
  });

  testWidgets('onClose is called when the menu is closed', (WidgetTester tester) async {
    var closed = true;
    await tester.pumpWidget(
      App(
        BaseMenu(
          controller: controller,
          onOpen: () {
            closed = false;
          },
          onClose: () {
            closed = true;
          },
          menu: const BaseMenuPanel(orientation: Axis.vertical, children: <Widget>[]),
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    expect(closed, isFalse);

    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    expect(closed, isTrue);

    controller.open();
    await tester.pump();

    expect(closed, isFalse);

    controller.close();
    await tester.pump();

    expect(closed, isTrue);
  });

  testWidgets('panel diagnostics', (WidgetTester tester) async {
    const panel = BaseMenuPanel(
      orientation: Axis.vertical,
      padding: EdgeInsetsDirectional.all(5),
      constrainCrossAxis: true,
      children: <Widget>[Text('1')],
    );

    await tester.pumpWidget(const App(panel));
    await tester.pump();

    final builder = DiagnosticPropertiesBuilder();
    panel.debugFillProperties(builder);
    final List<String> properties = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(properties, const <String>[
      'constrainCrossAxis: true',
      'padding override: EdgeInsetsDirectional(5.0, 5.0, 5.0, 5.0)',
      'direction: vertical',
    ]);
  });

  testWidgets('[Default] diagnostics', (WidgetTester tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    final menuAnchor = BaseMenu(
      controller: controller,
      menu: const Text('PANEL'),
      child: const Text('BUTTON'),
    );

    await tester.pumpWidget(App(menuAnchor));
    controller.open();
    await tester.pump();

    final builder = DiagnosticPropertiesBuilder();
    menuAnchor.debugFillProperties(builder);
    final List<String> properties = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(properties, const <String>['has controller']);
  });

  testWidgets('[Node] diagnostics', (WidgetTester tester) async {
    final menuNode = BaseMenuBar(
      controller: controller,
      child: const SizedBox(height: 30, width: 30),
    );

    await tester.pumpWidget(App(menuNode));
    await tester.pump();

    final builder = DiagnosticPropertiesBuilder();
    menuNode.debugFillProperties(builder);
    final Iterable<String> properties = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString());
    expect(properties, equals(const <String>['has controller', 'axis: horizontal']));
  });

  testWidgets('Surface clip behavior', (WidgetTester tester) async {
    await tester.pumpWidget(
      App(
        BaseMenu(
          controller: controller,
          menu: const BaseMenuPanel(
            orientation: Axis.vertical,
            children: <Widget>[Text('Button 1')],
          ),
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    controller.open();
    await tester.pump();

    // Test default clip behavior.
    expect(findMenuPanelDescendent<SingleChildScrollView>(tester).clipBehavior, equals(Clip.none));

    await tester.pumpWidget(
      App(
        BaseMenu(
          controller: controller,
          menu: const BaseMenuPanel(
            orientation: Axis.vertical,
            clipBehavior: Clip.hardEdge,
            children: <Widget>[Text('Button 1')],
          ),
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    // Test custom clip behavior.
    expect(
      findMenuPanelDescendent<SingleChildScrollView>(tester).clipBehavior,
      equals(Clip.hardEdge),
    );
  });

  testWidgets('MenuBar Home key focuses first menu bar item', (WidgetTester tester) async {
    final aFocusNode = FocusNode(debugLabel: Tag.a.focusNode);
    final cFocusNode = FocusNode(debugLabel: Tag.c.focusNode);
    addTearDown(aFocusNode.dispose);
    addTearDown(cFocusNode.dispose);

    await tester.pumpWidget(
      App(
        BaseMenuBar(
          child: Row(
            children: <Widget>[
              Button.tag(Tag.a, focusNode: aFocusNode),
              Button.tag(Tag.b),
              Button.tag(Tag.c, focusNode: cFocusNode, autofocus: true),
              Button.tag(Tag.d),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    expect(primaryFocus, equals(cFocusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();

    expect(primaryFocus, equals(aFocusNode));
  });

  testWidgets('MenuBar End key focuses last menu bar item', (WidgetTester tester) async {
    final bFocusNode = FocusNode(debugLabel: Tag.b.focusNode);
    final dFocusNode = FocusNode(debugLabel: Tag.d.focusNode);
    addTearDown(bFocusNode.dispose);
    addTearDown(dFocusNode.dispose);

    await tester.pumpWidget(
      App(
        BaseMenuBar(
          child: Row(
            children: <Widget>[
              Button.tag(Tag.a),
              Button.tag(Tag.b, focusNode: bFocusNode, autofocus: true),
              Button.tag(Tag.c),
              Button.tag(Tag.d, focusNode: dFocusNode),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    expect(primaryFocus, equals(bFocusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();

    expect(primaryFocus, equals(dFocusNode));
  });

  testWidgets('Home key from a menu item focuses first sibling', (WidgetTester tester) async {
    final aFocusNode = FocusNode(debugLabel: Tag.a.focusNode);
    final cFocusNode = FocusNode(debugLabel: Tag.c.focusNode);
    final anchorFocusNode = FocusNode(debugLabel: Tag.anchor.focusNode);
    addTearDown(aFocusNode.dispose);
    addTearDown(cFocusNode.dispose);
    addTearDown(anchorFocusNode.dispose);

    await tester.pumpWidget(
      App(
        BaseMenu(
          menu: BaseMenuPanel(
            orientation: Axis.vertical,
            children: <Widget>[
              Button.tag(Tag.a, focusNode: aFocusNode),
              Button.tag(Tag.b),
              Button.tag(Tag.c, focusNode: cFocusNode),
              Button.tag(Tag.d),
              Button.tag(Tag.e),
            ],
          ),
          child: AnchorButton(autofocus: true, Tag.anchor, focusNode: anchorFocusNode),
        ),
      ),
    );

    await tester.pump();

    expect(primaryFocus, equals(anchorFocusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.home);

    // Test that home key doesn't affect root anchor focus.
    expect(primaryFocus, equals(anchorFocusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);

    expect(primaryFocus, equals(cFocusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.home);

    expect(primaryFocus, equals(aFocusNode));
  });

  testWidgets('End key from a menu item focuses last sibling', (WidgetTester tester) async {
    final eFocusNode = FocusNode(debugLabel: Tag.e.focusNode);
    final cFocusNode = FocusNode(debugLabel: Tag.c.focusNode);
    final anchorFocusNode = FocusNode(debugLabel: Tag.anchor.focusNode);
    addTearDown(eFocusNode.dispose);
    addTearDown(cFocusNode.dispose);
    addTearDown(anchorFocusNode.dispose);

    await tester.pumpWidget(
      App(
        BaseMenu(
          menu: BaseMenuPanel(
            orientation: Axis.vertical,
            children: <Widget>[
              Button.tag(Tag.a),
              Button.tag(Tag.b),
              Button.tag(Tag.c, focusNode: cFocusNode),
              Button.tag(Tag.d),
              Button.tag(Tag.e, focusNode: eFocusNode),
            ],
          ),
          child: AnchorButton(autofocus: true, Tag.anchor, focusNode: anchorFocusNode),
        ),
      ),
    );

    await tester.pump();

    expect(primaryFocus, equals(anchorFocusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.end);

    // Test that end key doesn't affect root anchor focus.
    expect(primaryFocus, equals(anchorFocusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);

    expect(primaryFocus, equals(cFocusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.end);

    expect(primaryFocus, equals(eFocusNode));
  });

  testWidgets('Submenu Home key focuses first sibling', (WidgetTester tester) async {
    final baaFocusNode = FocusNode(debugLabel: Tag.b.a.focusNode);
    final bacFocusNode = FocusNode(debugLabel: Tag.b.c.focusNode);

    addTearDown(baaFocusNode.dispose);
    addTearDown(bacFocusNode.dispose);

    await tester.pumpWidget(
      App(
        BaseMenu(
          menu: BaseMenuPanel(
            orientation: Axis.vertical,
            children: <Widget>[
              Button.tag(Tag.a),
              BaseMenu(
                menu: BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[
                    Button.tag(Tag.b.a, focusNode: baaFocusNode),
                    Button.tag(Tag.b.b),
                    Button.tag(Tag.b.c, focusNode: bacFocusNode),
                  ],
                ),
                child: const AnchorButton(Tag.b),
              ),
            ],
          ),
          child: const AnchorButton(Tag.anchor, autofocus: true),
        ),
      ),
    );

    // Open menus and push focus all the way down into the submenu
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    // Move down to the 3rd item in the submenu
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(primaryFocus, equals(bacFocusNode));

    // Press home key inside submenu
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();

    // Focus should only rewind to the top of the submenu
    expect(primaryFocus, equals(baaFocusNode));
  });

  testWidgets('Submenu End key focuses last sibling', (WidgetTester tester) async {
    final baaFocusNode = FocusNode(debugLabel: Tag.b.a.focusNode);
    final bacFocusNode = FocusNode(debugLabel: Tag.b.c.focusNode);

    addTearDown(baaFocusNode.dispose);
    addTearDown(bacFocusNode.dispose);

    await tester.pumpWidget(
      App(
        BaseMenu(
          menu: BaseMenuPanel(
            orientation: Axis.vertical,
            children: <Widget>[
              Button.tag(Tag.a),
              BaseMenu(
                menu: BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[
                    Button.tag(Tag.b.a, focusNode: baaFocusNode),
                    Button.tag(Tag.b.b),
                    Button.tag(Tag.b.c, focusNode: bacFocusNode),
                  ],
                ),
                child: const AnchorButton(Tag.b),
              ),
            ],
          ),
          child: const AnchorButton(Tag.anchor, autofocus: true),
        ),
      ),
    );

    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(primaryFocus, equals(baaFocusNode));

    // Press end key inside submenu
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();

    // Focus should warp to the bottom of the submenu
    expect(primaryFocus, equals(bacFocusNode));
  });

  testWidgets('[Default] End key from a menu item focuses last sibling', (
    WidgetTester tester,
  ) async {
    const anchorConstraints = BoxConstraints.tightFor(height: 200, width: 225);
    final anchorFocusNode = FocusNode(debugLabel: Tag.anchor.focusNode);
    final bFocusNode = FocusNode(debugLabel: Tag.b.focusNode);
    final baFocusNode = FocusNode(debugLabel: Tag.b.a.focusNode);

    addTearDown(anchorFocusNode.dispose);
    addTearDown(bFocusNode.dispose);
    addTearDown(baFocusNode.dispose);

    await tester.pumpWidget(
      App(
        BaseMenu(
          // childFocusNode: anchorFocusNode,
          controller: controller,
          menu: BaseMenuPanel(
            orientation: Axis.vertical,
            constraints: const BoxConstraints(maxHeight: 500),
            children: <Widget>[
              Button.tag(Tag.a, constraints: anchorConstraints),
              BaseMenu(
                // childFocusNode: bFocusNode,
                menu: BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[
                    Button.tag(Tag.b.a, focusNode: baFocusNode),
                    Button.tag(Tag.b.b),
                    Button.tag(Tag.b.c),
                  ],
                ),
                child: AnchorButton(Tag.b, focusNode: bFocusNode, constraints: anchorConstraints),
              ),
              Button.tag(Tag.c, constraints: anchorConstraints),
              Button.tag(Tag.d, constraints: anchorConstraints),
            ],
          ),
          child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
        ),
      ),
    );

    listenForFocusChanges();

    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    expect(focusedMenu, equals(Tag.anchor.focusNode));

    // Test that root anchor is not affected by end key.
    await tester.sendKeyEvent(LogicalKeyboardKey.end);

    expect(focusedMenu, equals(Tag.anchor.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);

    expect(focusedMenu, Tag.a.focusNode);
    expect(find.text(Tag.d.text).hitTestable(), findsNothing);

    // Test from menu item sibling.
    await tester.sendKeyEvent(LogicalKeyboardKey.end);

    expect(focusedMenu, equals(Tag.d.focusNode));
    expect(find.text(Tag.d.text).hitTestable(), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(focusedMenu, Tag.b.focusNode);
    expect(find.text(Tag.b.a.text), findsOneWidget);

    // Test from opened anchor sibling to check that the event doesn't affect
    // attached submenu.
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();

    expect(focusedMenu, equals(Tag.d.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.tap(find.text(Tag.b.text));
    await tester.pump();
    baFocusNode.requestFocus();
    await tester.pump();

    expect(find.text(Tag.b.a.text), findsOneWidget);
    expect(focusedMenu, equals(Tag.b.a.focusNode));

    // Test from nested overlay.
    await tester.sendKeyEvent(LogicalKeyboardKey.end);

    expect(focusedMenu, equals(Tag.b.c.focusNode));
  });

  testWidgets('[Default] ArrowDown key from open root anchor focuses first menu item', (
    WidgetTester tester,
  ) async {
    final focusNode = FocusNode(debugLabel: Tag.anchor.focusNode);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      App(
        BaseMenu(
          controller: controller,
          // childFocusNode: focusNode,
          menu: BaseMenuPanel(
            orientation: Axis.vertical,
            children: <Widget>[Button.tag(Tag.a), Button.tag(Tag.b)],
          ),
          child: AnchorButton(Tag.anchor, focusNode: focusNode),
        ),
      ),
    );

    listenForFocusChanges();

    controller.open();
    await tester.pump();

    expect(find.text(Tag.b.text), findsOneWidget);
    expect(focusedMenu, equals(Tag.anchor.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(focusedMenu, equals(Tag.a.focusNode));

    // Test that the action still works in a menu panel.
    await tester.pumpWidget(
      App(
        BaseMenuBar(
          child: Column(
            children: <Widget>[
              BaseMenu(
                controller: controller,
                // childFocusNode: focusNode,
                menu: BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[Button.tag(Tag.a), Button.tag(Tag.b)],
                ),
                child: AnchorButton(Tag.anchor, focusNode: focusNode),
              ),
            ],
          ),
        ),
      ),
    );

    controller.open();
    await tester.pump();

    expect(find.text(Tag.b.text), findsOneWidget);
    expect(focusedMenu, equals(Tag.anchor.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(focusedMenu, equals(Tag.a.focusNode));
  });

  testWidgets('[Default] ArrowUp key from open root anchor focuses last menu item', (
    WidgetTester tester,
  ) async {
    final focusNode = FocusNode(debugLabel: Tag.anchor.focusNode);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      App(
        BaseMenu(
          controller: controller,
          // childFocusNode: focusNode,
          menu: BaseMenuPanel(
            orientation: Axis.vertical,
            children: <Widget>[Button.tag(Tag.a), Button.tag(Tag.b)],
          ),
          child: AnchorButton(Tag.anchor, focusNode: focusNode),
        ),
      ),
    );

    listenForFocusChanges();

    controller.open();
    await tester.pump();

    expect(find.text(Tag.a.text), findsOneWidget);
    expect(focusedMenu, equals(Tag.anchor.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();

    expect(focusedMenu, equals(Tag.b.focusNode));

    // Test that the action works in a menu panel.
    await tester.pumpWidget(
      App(
        BaseMenuBar(
          child: Column(
            children: <Widget>[
              BaseMenu(
                controller: controller,
                // childFocusNode: focusNode,
                menu: BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[Button.tag(Tag.a), Button.tag(Tag.b)],
                ),
                child: AnchorButton(Tag.anchor, focusNode: focusNode),
              ),
            ],
          ),
        ),
      ),
    );

    controller.open();
    await tester.pump();

    expect(find.text(Tag.a.text), findsOneWidget);
    expect(focusedMenu, equals(Tag.anchor.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();

    expect(focusedMenu, equals(Tag.b.focusNode));
  });

  testWidgets('[Default] LTR ArrowRight key opens a submenu anchor and focuses first item', (
    WidgetTester tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      App(
        BaseMenu(
          menu: BaseMenuPanel(
            orientation: Axis.vertical,
            children: <Widget>[
              Button.tag(Tag.a),
              Button.tag(Tag.b),
              BaseMenu(
                menu: BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[Button.tag(Tag.c.a), Button.tag(Tag.c.b)],
                ),
                child: AnchorButton(Tag.c, focusNode: focusNode),
              ),
            ],
          ),
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    listenForFocusChanges();

    // Have to open a menu initially to start things going.
    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    focusNode.requestFocus();
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, equals(focusNode));
    expect(find.text(Tag.c.a.text), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(find.text(Tag.c.a.text), findsOneWidget);
    expect(focusedMenu, equals(Tag.c.a.focusNode));
  });

  testWidgets('[Default] RTL ArrowLeft key opens a submenu anchor and focuses first item', (
    WidgetTester tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      App(
        textDirection: TextDirection.rtl,
        BaseMenu(
          menu: BaseMenuPanel(
            orientation: Axis.vertical,
            children: <Widget>[
              Button.tag(Tag.a),
              Button.tag(Tag.b),
              BaseMenu(
                menu: BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[Button.tag(Tag.c.a), Button.tag(Tag.c.b)],
                ),
                child: AnchorButton(Tag.c, focusNode: focusNode),
              ),
            ],
          ),
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    listenForFocusChanges();

    // Have to open a menu initially to start things going.
    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    focusNode.requestFocus();
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, equals(focusNode));
    expect(find.text(Tag.c.a.text), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();

    expect(find.text(Tag.c.a.text), findsOneWidget);
    expect(focusedMenu, equals(Tag.c.a.focusNode));
  });

  testWidgets('[Default] LTR ArrowLeft key closes a submenu', (WidgetTester tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      App(
        BaseMenu(
          menu: BaseMenuPanel(
            orientation: Axis.vertical,
            children: <Widget>[
              Button.tag(Tag.a),
              Button.tag(Tag.b),
              BaseMenu(
                menu: BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[
                    Button.tag(Tag.c.a),
                    Button.tag(Tag.c.b),
                    BaseMenu(
                      menu: const BaseMenuPanel(orientation: Axis.vertical, children: <Widget>[]),
                      child: AnchorButton(Tag.c.c),
                    ),
                  ],
                ),
                child: const AnchorButton(Tag.c),
              ),
            ],
          ),
          child: AnchorButton(Tag.anchor, focusNode: focusNode),
        ),
      ),
    );

    listenForFocusChanges();

    // Move into submenu.
    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(focusedMenu, equals(Tag.c.a.focusNode));

    // Arrow left from regular item should close the submenu and refocus its
    // anchor.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();

    expect(focusedMenu, equals(Tag.c.focusNode));
    expect(find.text(Tag.c.a.text), findsNothing);

    // ArrowLeft from submenu anchor should close the submenu and refocus its
    // anchor.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();

    expect(focusedMenu, equals(Tag.c.focusNode));
    expect(find.text(Tag.c.a.text), findsNothing);

    // ArrowLeft from root overlay anchor and root overlay button should do
    // nothing.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();

    expect(focusedMenu, equals(Tag.c.focusNode));
    expect(find.text(Tag.c.a.text), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();

    expect(focusedMenu, equals(Tag.b.focusNode));
    expect(find.text(Tag.c.a.text), findsNothing);
  });

  testWidgets('[Default] RTL ArrowRight key closes a submenu', (WidgetTester tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      App(
        textDirection: TextDirection.rtl,
        BaseMenu(
          menu: BaseMenuPanel(
            orientation: Axis.vertical,
            children: <Widget>[
              Button.tag(Tag.a),
              Button.tag(Tag.b),
              BaseMenu(
                menu: BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[
                    Button.tag(Tag.c.a),
                    Button.tag(Tag.c.b),
                    BaseMenu(
                      menu: const BaseMenuPanel(orientation: Axis.vertical, children: <Widget>[]),
                      child: AnchorButton(Tag.c.c),
                    ),
                  ],
                ),
                child: const AnchorButton(Tag.c),
              ),
            ],
          ),
          child: AnchorButton(Tag.anchor, focusNode: focusNode),
        ),
      ),
    );

    listenForFocusChanges();

    // Move into submenu.
    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();

    expect(focusedMenu, equals(Tag.c.a.focusNode));

    // Arrow left from regular item should close the submenu and refocus its
    // anchor.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(focusedMenu, equals(Tag.c.focusNode));
    expect(find.text(Tag.c.a.text), findsNothing);

    // arrowRight from submenu anchor should close the submenu and refocus its
    // anchor.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(focusedMenu, equals(Tag.c.focusNode));
    expect(find.text(Tag.c.a.text), findsNothing);

    // arrowRight from root overlay anchor and root overlay button should do
    // nothing.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(focusedMenu, equals(Tag.c.focusNode));
    expect(find.text(Tag.c.a.text), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(focusedMenu, equals(Tag.b.focusNode));
    expect(find.text(Tag.c.a.text), findsNothing);
  });

  testWidgets('[Default] LTR Directional traversal', (WidgetTester tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    var eventBubbled = false;
    await tester.pumpWidget(
      App(
        Actions(
          actions: <Type, Action<Intent>>{
            // Intents should not bubble up to the root anchor.
            DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
              onInvoke: (DirectionalFocusIntent intent) {
                eventBubbled = true;
                return null;
              },
            ),
          },
          child: BaseMenu(
            // childFocusNode: focusNode,
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                Button.tag(Tag.a),
                Button.tag(Tag.b),
                BaseMenu(
                  menu: BaseMenuPanel(
                    orientation: Axis.vertical,
                    children: <Widget>[Button.tag(Tag.c.a), Button.tag(Tag.c.b)],
                  ),
                  child: const AnchorButton(Tag.c),
                ),
                Button.tag(Tag.d),
                BaseMenu(
                  menu: BaseMenuPanel(
                    orientation: Axis.vertical,
                    children: <Widget>[
                      Button.tag(Tag.e.a),
                      Button.tag(Tag.e.b),
                      BaseMenu(
                        menu: BaseMenuPanel(
                          orientation: Axis.vertical,
                          children: <Widget>[
                            Button.tag(Tag.e.c.a),
                            Button.tag(Tag.e.c.b),
                            Button.tag(Tag.e.c.c),
                          ],
                        ),
                        child: AnchorButton(Tag.e.c),
                      ),
                    ],
                  ),
                  child: const AnchorButton(Tag.e),
                ),
              ],
            ),
            child: AnchorButton(Tag.anchor, focusNode: focusNode),
          ),
        ),
      ),
    );

    listenForFocusChanges();

    // Have to open a menu initially to start things going.
    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    // Arrow down moves to first item
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(focusedMenu, equals(Tag.a.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(focusedMenu, equals(Tag.b.focusNode));

    // Horizontal traversal on menu items without submenus shouldn't do
    // anything.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(focusedMenu, equals(Tag.b.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(focusedMenu, equals(Tag.b.focusNode));

    // Move to the first submenu
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(focusedMenu, equals(Tag.c.focusNode));

    // Arrow left should do nothing since no menu is open
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();

    expect(focusedMenu, equals(Tag.c.focusNode));

    // Arrow right should open the submenu and focus the first item
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(focusedMenu, equals(Tag.c.a.focusNode));

    // Arrow left should close the submenu and refocus its anchor.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();

    expect(focusedMenu, equals(Tag.c.focusNode));
    expect(find.text(Tag.c.a.text), findsNothing);

    // Enter should open the submenu without changing focus.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(focusedMenu, equals(Tag.c.focusNode));
    expect(find.text(Tag.c.a.text), findsOneWidget);

    // Arrow down should close the submenu and focus the next anchor sibling.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(focusedMenu, equals(Tag.d.focusNode));
    expect(find.text(Tag.c.a.text), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(focusedMenu, equals(Tag.e.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(focusedMenu, equals(Tag.a.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(focusedMenu, equals(Tag.b.focusNode));

    // Cycle back up
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    expect(focusedMenu, equals(Tag.a.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    expect(focusedMenu, equals(Tag.e.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);

    expect(focusedMenu, equals(Tag.e.a.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    expect(focusedMenu, equals(Tag.e.c.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(focusedMenu, equals(Tag.e.c.a.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(focusedMenu, equals(Tag.e.c.b.focusNode));

    // Arrow left should close a menu item's overlay and refocus its anchor.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();

    expect(focusedMenu, equals(Tag.e.c.focusNode));
    expect(find.text(Tag.e.c.a.text), findsNothing);

    // Arrow left from the submenu anchor should behave the same as a regular
    // menu item.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(focusedMenu, equals(Tag.e.focusNode));
    expect(find.text(Tag.e.c.text), findsNothing);
    expect(eventBubbled, isFalse);
  });

  testWidgets('[Default] RTL Directional traversal', (WidgetTester tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    var eventBubbled = false;
    await tester.pumpWidget(
      App(
        textDirection: TextDirection.rtl,
        Actions(
          actions: <Type, Action<Intent>>{
            // Intents should not bubble up to the root anchor.
            DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
              onInvoke: (DirectionalFocusIntent intent) {
                eventBubbled = true;
                return null;
              },
            ),
          },
          child: BaseMenu(
            // childFocusNode: focusNode,
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                Button.tag(Tag.a),
                Button.tag(Tag.b),
                BaseMenu(
                  menu: BaseMenuPanel(
                    orientation: Axis.vertical,
                    children: <Widget>[Button.tag(Tag.c.a), Button.tag(Tag.c.b)],
                  ),
                  child: const AnchorButton(Tag.c),
                ),
                Button.tag(Tag.d),
                BaseMenu(
                  menu: BaseMenuPanel(
                    orientation: Axis.vertical,
                    children: <Widget>[
                      Button.tag(Tag.e.a),
                      Button.tag(Tag.e.b),
                      BaseMenu(
                        menu: BaseMenuPanel(
                          orientation: Axis.vertical,
                          children: <Widget>[
                            Button.tag(Tag.e.c.a),
                            Button.tag(Tag.e.c.b),
                            Button.tag(Tag.e.c.c),
                          ],
                        ),
                        child: AnchorButton(Tag.e.c),
                      ),
                    ],
                  ),
                  child: const AnchorButton(Tag.e),
                ),
              ],
            ),
            child: AnchorButton(Tag.anchor, focusNode: focusNode),
          ),
        ),
      ),
    );

    listenForFocusChanges();
    // Have to open a menu initially to start things going.
    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    // Arrow down moves to first item
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(focusedMenu, equals(Tag.a.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(focusedMenu, equals(Tag.b.focusNode));

    // Horizontal traversal on menu items without submenus shouldn't do
    // anything.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(focusedMenu, equals(Tag.b.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(focusedMenu, equals(Tag.b.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(focusedMenu, equals(Tag.c.focusNode));

    // Arrow right should do nothing since no menu is open
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(focusedMenu, equals(Tag.c.focusNode));

    // Arrow left should open the submenu and focus the first item
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();

    expect(focusedMenu, equals(Tag.c.a.focusNode));

    // Arrow right should close the submenu and refocus its anchor.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(focusedMenu, equals(Tag.c.focusNode));
    expect(find.text(Tag.c.a.text), findsNothing);

    // Enter should open the submenu without changing focus.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(focusedMenu, equals(Tag.c.focusNode));
    expect(find.text(Tag.c.a.text), findsOneWidget);

    // Arrow down should close the submenu and focus the next anchor sibling.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(focusedMenu, equals(Tag.d.focusNode));
    expect(find.text(Tag.c.a.text), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(focusedMenu, equals(Tag.e.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(focusedMenu, equals(Tag.a.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(focusedMenu, equals(Tag.b.focusNode));

    // Cycle back up
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    expect(focusedMenu, equals(Tag.a.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    expect(focusedMenu, equals(Tag.e.focusNode));

    // Drill down to the nested anchor.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);

    expect(focusedMenu, equals(Tag.e.a.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    expect(focusedMenu, equals(Tag.e.c.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(focusedMenu, equals(Tag.e.c.a.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(focusedMenu, equals(Tag.e.c.b.focusNode));

    // Arrow right should close a menu item's overlay refocus its anchor.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(focusedMenu, equals(Tag.e.c.focusNode));
    expect(find.text(Tag.e.c.a.text), findsNothing);

    // Arrow right from the submenu anchor should behave the same as a menu
    // item without a submenu.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(focusedMenu, equals(Tag.e.focusNode));
    expect(find.text(Tag.e.c.text), findsNothing);
    expect(eventBubbled, isFalse);
  });

  testWidgets('[Default] Closed RawMenuAnchor does not affect anchor tab traversal', (
    WidgetTester tester,
  ) async {
    final focusNode = FocusNode(debugLabel: Tag.b.focusNode);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      App(
        Row(
          children: <Widget>[
            Button.tag(Tag.a),
            BaseMenu(
              controller: controller,
              menu: BaseMenuPanel(
                orientation: Axis.vertical,
                children: <Widget>[Button.tag(Tag.b.a), Button.tag(Tag.b.b), Button.tag(Tag.b.c)],
              ),
              child: AnchorButton(Tag.b, focusNode: focusNode),
            ),
            Button.tag(Tag.c),
          ],
        ),
      ),
    );

    listenForFocusChanges();

    focusNode.requestFocus();
    await tester.pump();
    expect(focusedMenu, equals(Tag.b.focusNode));

    // Tab on an unopened anchor should move focus to next widget
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(focusedMenu, equals(Tag.c.focusNode));

    // Move focus back to the anchor
    focusNode.requestFocus();
    await tester.pump();
    expect(focusedMenu, equals(Tag.b.focusNode));

    // Shift+Tab on unopened anchor should move focus to previous widget
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    expect(focusedMenu, equals(Tag.a.focusNode));
  });

  // Menu implementations differ as to whether tabbing traverses a closes a
  // menu or traverses its items. By default, we let the user choose whether
  // to close the menu or traverse its items.
  testWidgets('Tab traversal is not handled.', (WidgetTester tester) async {
    final focusNode = FocusNode(debugLabel: Tag.b.focusNode);
    addTearDown(focusNode.dispose);
    final invokedIntents = <Intent>[];

    await tester.pumpWidget(
      App(
        Row(
          children: <Widget>[
            Actions(
              actions: <Type, Action<Intent>>{
                NextFocusIntent: CallbackAction<NextFocusIntent>(
                  onInvoke: (NextFocusIntent intent) {
                    invokedIntents.add(intent);
                    return null;
                  },
                ),
                PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(
                  onInvoke: (PreviousFocusIntent intent) {
                    invokedIntents.add(intent);
                    return null;
                  },
                ),
              },
              child: BaseMenuBar(
                child: Column(
                  children: <Widget>[
                    Button.tag(Tag.a),
                    BaseMenu(
                      controller: controller,
                      // childFocusNode: focusNode,
                      menu: BaseMenuPanel(
                        orientation: Axis.vertical,
                        children: <Widget>[
                          Button.tag(Tag.b.a),
                          Button.tag(Tag.b.b),
                          Button.tag(Tag.b.c),
                        ],
                      ),
                      child: AnchorButton(Tag.b, focusNode: focusNode),
                    ),
                    Button.tag(Tag.c),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    listenForFocusChanges();

    // Open overlay and focus first menu item
    focusNode.requestFocus();
    await tester.pump();

    expect(focusedMenu, equals(Tag.b.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(focusedMenu, equals(Tag.b.focusNode));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pump();

    expect(focusedMenu, equals(Tag.b.focusNode));

    // Open and move focus to nested menu
    await tester.tap(find.text(Tag.b.text));
    await tester.pump();
    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(focusedMenu, equals(Tag.b.b.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(focusedMenu, equals(Tag.b.b.focusNode));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pump();

    expect(focusedMenu, equals(Tag.b.b.focusNode));
    expect(
      invokedIntents,
      equals(const <Intent>[
        NextFocusIntent(),
        PreviousFocusIntent(),
        NextFocusIntent(),
        PreviousFocusIntent(),
      ]),
    );
  });

  testWidgets('[Default] Menus close when anchor and overlay are blurred', (
    WidgetTester tester,
  ) async {
    final bFocusNode = FocusNode(debugLabel: Tag.b.focusNode);
    final cFocusNode = FocusNode(debugLabel: Tag.c.focusNode);
    addTearDown(bFocusNode.dispose);
    addTearDown(cFocusNode.dispose);

    await tester.pumpWidget(
      App(
        Row(
          children: <Widget>[
            Button.tag(Tag.a),
            BaseMenu(
              // childFocusNode: bFocusNode,
              menu: BaseMenuPanel(
                orientation: Axis.vertical,
                children: <Widget>[
                  Button.tag(Tag.b.a),
                  BaseMenu(
                    menu: BaseMenuPanel(
                      orientation: Axis.vertical,
                      children: <Widget>[Button.tag(Tag.b.b.a)],
                    ),
                    child: AnchorButton(Tag.b.b),
                  ),
                  Button.tag(Tag.b.c),
                ],
              ),
              child: AnchorButton(Tag.b, focusNode: bFocusNode),
            ),
            Button.tag(Tag.c, focusNode: cFocusNode),
          ],
        ),
      ),
    );

    listenForFocusChanges();

    // First, test that a root anchor is closed when tabbing away from it.
    bFocusNode.requestFocus();
    await tester.tap(find.text(Tag.b.text));
    await tester.pump();

    expect(focusedMenu, equals(Tag.b.focusNode));
    expect(find.text(Tag.b.a.text), findsOneWidget);

    // Tab moves focus to the next root anchor sibling
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    // Menu should be closed
    expect(focusedMenu, equals(Tag.c.focusNode));
    expect(find.text(Tag.b.a.text), findsNothing);

    bFocusNode.requestFocus();
    await tester.tap(find.text(Tag.b.text));
    await tester.pump();

    expect(focusedMenu, equals(Tag.b.focusNode));
    expect(find.text(Tag.b.a.text), findsOneWidget);

    // Move focus to the previous root anchor sibling
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pump();

    // Menu should be closed
    expect(focusedMenu, equals(Tag.a.focusNode));
    expect(find.text(Tag.b.a.text), findsNothing);

    // Next, test that a nested anchor is closed when tabbing away from it.
    // This test also checks that the presence of a focus node does not
    // affect the menu

    // Open nested menu and focus first anchor
    bFocusNode.requestFocus();
    await tester.tap(find.text(Tag.b.text));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(focusedMenu, equals(Tag.b.b.focusNode));
    expect(find.text(Tag.b.b.a.text), findsOneWidget);

    // Tab moves focus to the next anchor sibling
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    // Nested menu should be closed
    expect(focusedMenu, equals(Tag.b.c.focusNode));
    expect(find.text(Tag.b.b.a.text), findsNothing);

    // Move focus to nested anchor and open menu.
    bFocusNode.requestFocus();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(focusedMenu, equals(Tag.b.b.focusNode));
    expect(find.text(Tag.b.b.a.text), findsOneWidget);

    // Shift+Tab moves focus to the previous root anchor sibling
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pump();

    // Nested menu should be closed
    expect(focusedMenu, equals(Tag.b.a.focusNode));
    expect(find.text(Tag.b.b.a.text), findsNothing);

    // Finally, test that menus are closed when focus is moved
    // programmatically.
    cFocusNode.requestFocus();
    await tester.pump();
    await tester.pump();

    expect(focusedMenu, equals(Tag.c.focusNode));
    expect(find.text(Tag.b.a.text), findsNothing);
  });

  testWidgets('Menu closes on view size change', (WidgetTester tester) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    final mediaQueryData = MediaQueryData.fromView(tester.view);

    var opened = false;
    var closed = false;

    Widget build(Size size) {
      return MediaQuery(
        data: mediaQueryData.copyWith(size: size),
        child: App(
          SingleChildScrollView(
            controller: scrollController,
            child: Container(
              height: 1000,
              alignment: Alignment.center,
              child: BaseMenu(
                onOpen: () {
                  opened = true;
                  closed = false;
                },
                onClose: () {
                  opened = false;
                  closed = true;
                },
                controller: controller,
                menu: BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[Text(Tag.a.text)],
                ),
                child: const AnchorButton(Tag.anchor),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(build(mediaQueryData.size));
    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    expect(opened, isTrue);
    expect(closed, isFalse);

    const smallSize = Size(200, 200);
    await changeSurfaceSize(tester, smallSize);
    await tester.pumpWidget(build(smallSize));

    expect(opened, isFalse);
    expect(closed, isTrue);
  });

  testWidgets('Menu closes on ancestor scroll', (WidgetTester tester) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      App(
        SingleChildScrollView(
          controller: scrollController,
          child: BaseMenu(
            // alignment: Alignment.bottomCenter,
            // menuAlignment: Alignment.topCenter,
            onOpen: () {
              onOpen(Tag.anchor);
            },
            onClose: () {
              onClose(Tag.anchor);
            },
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                Button.tag(Tag.a),
                Button.tag(Tag.b),
                Button.tag(Tag.c),
                Button.tag(Tag.d),
              ],
            ),
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      ),
    );

    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    expect(opened, isNotEmpty);
    expect(closed, isEmpty);
    opened.clear();

    scrollController.jumpTo(1000);
    await tester.pump();

    expect(opened, isEmpty);
    expect(closed, isNotEmpty);
  });

  testWidgets('Menus do not close on root menu internal scroll', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/122168.
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    var rootOpened = false;
    const largeButtonConstraints = BoxConstraints.tightFor(width: 200, height: 300);

    await tester.pumpWidget(
      App(
        SingleChildScrollView(
          controller: scrollController,
          child: Container(
            height: 700,
            alignment: Alignment.topLeft,
            child: BaseMenu(
              // alignment: Alignment.bottomCenter,
              // menuAlignment: Alignment.topCenter,
              onOpen: () {
                rootOpened = true;
              },
              onClose: () {
                rootOpened = false;
              },
              menu: BaseMenuPanel(
                orientation: Axis.vertical,
                children: <Widget>[
                  BaseMenu(
                    // alignmentOffset: const Offset(10, 0),
                    // alignment: Alignment.topRight,
                    // menuAlignment: Alignment.topLeft,
                    onOpen: () {
                      onOpen(Tag.a);
                    },
                    onClose: () {
                      onClose(Tag.a);
                    },
                    menu: BaseMenuPanel(
                      orientation: Axis.vertical,
                      children: <Widget>[Button.tag(Tag.a.a, constraints: largeButtonConstraints)],
                    ),
                    child: const AnchorButton(Tag.a, constraints: largeButtonConstraints),
                  ),
                  Button.tag(Tag.b, constraints: largeButtonConstraints),
                  Button.tag(Tag.c, constraints: largeButtonConstraints),
                  Button.tag(Tag.d, constraints: largeButtonConstraints),
                ],
              ),
              child: const AnchorButton(Tag.anchor),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();
    expect(rootOpened, true);

    // Hover the first submenu anchor.
    final pointer = TestPointer(1, ui.PointerDeviceKind.mouse);
    await tester.tap(find.text(Tag.a.text));
    await tester.sendEventToBinding(pointer.hover(tester.getCenter(find.text(Tag.a.text))));
    await tester.pump();
    expect(opened, equals(<Tag>[Tag.a]));

    // Menus do not close on internal scroll.
    await tester.sendEventToBinding(pointer.scroll(const Offset(0.0, 30.0)));
    await tester.pump();
    expect(rootOpened, true);
    expect(closed, isEmpty);

    // Menus close on external scroll.
    scrollController.jumpTo(700);
    await tester.pump();
    expect(rootOpened, false);
    expect(closed, equals(<Tag>[Tag.a]));
  });

  // Copied from [MenuAnchor] tests.
  //
  // Regression test for https://github.com/flutter/flutter/issues/157606.
  testWidgets('RawMenuAnchor builder rebuilds when isOpen state changes', (
    WidgetTester tester,
  ) async {
    var isOpen = false;
    var openCount = 0;
    var closeCount = 0;

    await tester.pumpWidget(
      App(
        BaseMenu(
          menu: BaseMenuPanel(
            orientation: Axis.vertical,
            children: <Widget>[Button.text('Menu Item')],
          ),
          builder: (BuildContext context, MenuController controller, Widget? child) {
            isOpen = controller.isOpen;
            return Button(
              Text(isOpen ? 'close' : 'open'),
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
            );
          },
          onOpen: () => openCount++,
          onClose: () => closeCount++,
        ),
      ),
    );

    expect(find.text('open'), findsOneWidget);
    expect(isOpen, false);
    expect(openCount, 0);
    expect(closeCount, 0);

    await tester.tap(find.text('open'));
    await tester.pump();

    expect(find.text('close'), findsOneWidget);
    expect(isOpen, true);
    expect(openCount, 1);
    expect(closeCount, 0);

    await tester.tap(find.text('close'));
    await tester.pump();

    expect(find.text('open'), findsOneWidget);
    expect(isOpen, false);
    expect(openCount, 1);
    expect(closeCount, 1);
  });

  // Copied from [MenuAnchor] tests.
  //
  // Regression test for https://github.com/flutter/flutter/issues/155034.
  testWidgets('Content is shown in the root overlay when useRootOverlay is true', (
    WidgetTester tester,
  ) async {
    final controller = MenuController();
    final overlayKey = UniqueKey();
    final Finder a = find.text(Tag.a.text);
    final Finder aa = find.text(Tag.a.a.text);

    late final OverlayEntry overlayEntry;
    addTearDown(() {
      overlayEntry.remove();
      overlayEntry.dispose();
    });

    await tester.pumpWidget(
      App(
        Overlay(
          key: overlayKey,
          initialEntries: <OverlayEntry>[
            overlayEntry = OverlayEntry(
              builder: (BuildContext context) {
                return Center(
                  child: BaseMenu(
                    useRootOverlay: true,
                    controller: controller,
                    menu: BaseMenuPanel(
                      orientation: Axis.vertical,
                      children: <Widget>[
                        BaseMenu(
                          menu: BaseMenuPanel(
                            orientation: Axis.vertical,
                            children: <Widget>[Button.tag(Tag.a.a)],
                          ),
                          child: const AnchorButton(Tag.a),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );

    expect(a, findsNothing);

    // Open the menu.
    controller.open();
    await tester.pump();
    await tester.tap(a);
    await tester.pump();

    expect(a, findsOne);
    expect(aa, findsOne);

    // Expect two overlays: the root overlay created by WidgetsApp and the
    // overlay created by the boilerplate code.
    expect(find.byType(Overlay), findsNWidgets(2));

    final Iterable<Overlay> overlays = tester.widgetList<Overlay>(find.byType(Overlay));
    final Overlay nonRootOverlay = tester.widget(find.byKey(overlayKey));
    final Overlay rootOverlay = overlays.firstWhere((Overlay overlay) => overlay != nonRootOverlay);

    final RenderObject menuTheater = findAncestorRenderTheaters(tester.renderObject(a)).first;
    final RenderObject submenuTheater = findAncestorRenderTheaters(tester.renderObject(aa)).first;

    // Check that the ancestor _RenderTheater for the menu item is the one
    // from the root overlay.
    expect(menuTheater, tester.renderObject(find.byWidget(rootOverlay)));
    expect(menuTheater, submenuTheater);
  });

  testWidgets('Content is shown in the nearest ancestor overlay when useRootOverlay is false', (
    WidgetTester tester,
  ) async {
    final controller = MenuController();
    final overlayKey = UniqueKey();
    final Finder a = find.text(Tag.a.text);
    final Finder aa = find.text(Tag.a.a.text);

    late final OverlayEntry overlayEntry;
    addTearDown(() {
      overlayEntry.remove();
      overlayEntry.dispose();
    });

    await tester.pumpWidget(
      App(
        Overlay(
          key: overlayKey,
          initialEntries: <OverlayEntry>[
            overlayEntry = OverlayEntry(
              builder: (BuildContext context) {
                return Center(
                  child: BaseMenu(
                    controller: controller,
                    menu: BaseMenuPanel(
                      orientation: Axis.vertical,
                      children: <Widget>[
                        // Nested menus should be rendered in the same overlay as
                        // their parent, so useRootOverlay should have no effect.
                        BaseMenu(
                          useRootOverlay: true,
                          menu: BaseMenuPanel(
                            orientation: Axis.vertical,
                            children: <Widget>[Button.tag(Tag.a.a)],
                          ),
                          child: const AnchorButton(Tag.a),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );

    expect(a, findsNothing);

    // Open the menu.
    controller.open();
    await tester.pump();
    await tester.tap(a);
    await tester.pump();

    expect(a, findsOne);
    expect(aa, findsOne);

    // Expect two overlays: the root overlay created by WidgetsApp and the
    // overlay created by the boilerplate code.
    expect(find.byType(Overlay), findsNWidgets(2));

    final Overlay nonRootOverlay = tester.widget(find.byKey(overlayKey));
    final RenderObject menuTheater = findAncestorRenderTheaters(tester.renderObject(a)).first;
    final RenderObject submenuTheater = findAncestorRenderTheaters(tester.renderObject(aa)).first;

    // Check that the ancestor _RenderTheater for the menu item is the one
    // from the root overlay.
    expect(menuTheater, tester.renderObject(find.byWidget(nonRootOverlay)));
    expect(menuTheater, submenuTheater);
  });
  group('Focus', () {
    Future<void> expectFocusPath(
      WidgetTester tester,
      List<(LogicalKeyboardKey key, Tag tag)> path,
    ) async {
      for (var i = 0; i < path.length; i++) {
        final step = path[i];
        await tester.sendKeyEvent(step.$1);
        await tester.pump();

        final currentFocus = FocusManager.instance.primaryFocus?.debugLabel;
        expect(
          currentFocus,
          contains(step.$2.focusNode),
          reason:
              'Failed on step $i. Failed after pressing ${step.$1.debugName}. Expected ${step.$2.text} but got $currentFocus.',
        );
      }
    }

    testWidgets(
      '[Browser] Focus wraps on all platforms',
      skip: !kIsWeb, // [intended] Web wraps focus regardless of platform.
      (WidgetTester tester) async {
        final anchorFocusNode = FocusNode();
        final firstItemFocusNode = FocusNode();
        final lastItemFocusNode = FocusNode();
        addTearDown(anchorFocusNode.dispose);
        addTearDown(firstItemFocusNode.dispose);
        addTearDown(lastItemFocusNode.dispose);

        await tester.pumpWidget(
          App(
            BaseMenu(
              controller: controller,
              menu: BaseMenuPanel(
                orientation: Axis.vertical,
                children: <Widget>[
                  Button.tag(Tag.a, focusNode: firstItemFocusNode),
                  Button.tag(Tag.b),
                  Button.tag(Tag.c, focusNode: lastItemFocusNode),
                ],
              ),
              child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
            ),
          ),
        );

        controller.open();
        await tester.pump();
        await tester.pumpAndSettle();

        firstItemFocusNode.requestFocus();
        await tester.pump();

        expect(FocusManager.instance.primaryFocus, firstItemFocusNode);

        // Arrow up from first item should wrap to last item
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();

        expect(FocusManager.instance.primaryFocus, lastItemFocusNode);

        // Arrow down from last item should wrap to first item
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();

        expect(FocusManager.instance.primaryFocus, firstItemFocusNode);
      },
    );

    testWidgets(
      '[Not Browser] Focus wraps when traversing with arrow keys on non-Apple platforms',
      skip: kIsWeb, // [intended] Browser behavior is tested above.
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.android,
        TargetPlatform.fuchsia,
        TargetPlatform.linux,
        TargetPlatform.windows,
      }),
      (WidgetTester tester) async {
        final anchorFocusNode = FocusNode();
        final firstItemFocusNode = FocusNode();
        final lastItemFocusNode = FocusNode();
        addTearDown(anchorFocusNode.dispose);
        addTearDown(firstItemFocusNode.dispose);
        addTearDown(lastItemFocusNode.dispose);

        await tester.pumpWidget(
          App(
            BaseMenu(
              controller: controller,
              menu: BaseMenuPanel(
                orientation: Axis.vertical,
                children: <Widget>[
                  Button.tag(Tag.a, focusNode: firstItemFocusNode),
                  Button.tag(Tag.b),
                  Button.tag(Tag.c, focusNode: lastItemFocusNode),
                ],
              ),
              child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
            ),
          ),
        );

        controller.open();
        await tester.pump();
        await tester.pumpAndSettle();

        firstItemFocusNode.requestFocus();
        await tester.pump();

        expect(FocusManager.instance.primaryFocus, firstItemFocusNode);

        // Arrow up from first item should wrap to last item
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();

        expect(FocusManager.instance.primaryFocus, lastItemFocusNode);

        // Arrow down from last item should wrap to first item
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();

        expect(FocusManager.instance.primaryFocus, firstItemFocusNode);
      },
    );

    testWidgets(
      '[Not Browser] Focus does not wrap when traversing with arrow keys on Apple platforms',
      skip: kIsWeb, // [intended] Browser behavior is tested above.
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      }),
      (WidgetTester tester) async {
        final anchorFocusNode = FocusNode();
        final firstItemFocusNode = FocusNode();
        final lastItemFocusNode = FocusNode();
        addTearDown(anchorFocusNode.dispose);
        addTearDown(firstItemFocusNode.dispose);
        addTearDown(lastItemFocusNode.dispose);

        await tester.pumpWidget(
          App(
            BaseMenu(
              controller: controller,
              menu: BaseMenuPanel(
                orientation: Axis.vertical,
                children: <Widget>[
                  Button.tag(Tag.a, focusNode: firstItemFocusNode),
                  Button.tag(Tag.b),
                  Button.tag(Tag.c, focusNode: lastItemFocusNode),
                ],
              ),
              child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
            ),
          ),
        );

        await tester.tap(find.text(Tag.anchor.text));
        await tester.pump();
        await tester.pumpAndSettle();

        firstItemFocusNode.requestFocus();
        await tester.pump();

        expect(FocusManager.instance.primaryFocus, firstItemFocusNode);

        // Arrow up from first item should not move focus on Apple platforms
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();

        expect(FocusManager.instance.primaryFocus, firstItemFocusNode);

        lastItemFocusNode.requestFocus();
        await tester.pump();

        // Arrow down from last item should not move focus on Apple platforms
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();

        expect(FocusManager.instance.primaryFocus, lastItemFocusNode);
      },
    );

    testWidgets('Menu items can be activated with enter key', (WidgetTester tester) async {
      final anchorFocusNode = FocusNode();
      final aFocusNode = FocusNode();
      var itemActivated = false;
      addTearDown(anchorFocusNode.dispose);
      addTearDown(aFocusNode.dispose);

      await tester.pumpWidget(
        App(
          BaseMenu(
            controller: controller,
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                Button.tag(
                  Tag.a,
                  focusNode: aFocusNode,
                  onPressed: () {
                    itemActivated = true;
                  },
                ),
              ],
            ),
            child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
          ),
        ),
      );

      controller.open();
      await tester.pump();
      await tester.pumpAndSettle();

      aFocusNode.requestFocus();
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, aFocusNode);
      expect(itemActivated, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(itemActivated, isTrue);
    });

    testWidgets('Menu closes with escape key', (WidgetTester tester) async {
      final anchorFocusNode = FocusNode();
      final aFocusNode = FocusNode();
      addTearDown(anchorFocusNode.dispose);
      addTearDown(aFocusNode.dispose);

      await tester.pumpWidget(
        App(
          BaseMenu(
            controller: controller,
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[Button.tag(Tag.a, focusNode: aFocusNode)],
            ),
            child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
          ),
        ),
      );

      controller.open();
      await tester.pump();
      await tester.pumpAndSettle();

      aFocusNode.requestFocus();
      await tester.pump();

      expect(controller.isOpen, isTrue);
      expect(FocusManager.instance.primaryFocus, aFocusNode);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(controller.isOpen, isFalse);
    });

    group('Extended Traversal & Interactions', () {
      testWidgets('Tab and Shift+Tab do not move focus within open menus', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const App(MenuSystem(layers: [Axis.horizontal, Axis.vertical], autofocus: .a)),
        );

        // Open menu and move to 'b'
        await expectFocusPath(tester, [
          (LogicalKeyboardKey.arrowDown, Tag.a.a),
          (LogicalKeyboardKey.arrowDown, Tag.a.b),
        ]);

        // Press Tab (Should do nothing to internal focus based on implementation constraints)
        await expectFocusPath(tester, [
          (LogicalKeyboardKey.tab, Tag.a.b),
          (LogicalKeyboardKey.tab, Tag.a.b),
        ]);

        // Press Shift+Tab (Should also do nothing internally)
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
        await tester.pump();

        final currentFocus = FocusManager.instance.primaryFocus?.debugLabel;
        expect(
          currentFocus,
          contains(Tag.a.b.focusNode),
          reason: 'Shift+Tab should not change the primary internal focus traversal.',
        );
      });

      testWidgets('Keyboard traversal resumes correctly after an item is hovered', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const App(MenuSystem(layers: [Axis.horizontal, Axis.vertical], autofocus: .a)),
        );

        // Start keyboard tracking
        await expectFocusPath(tester, [(LogicalKeyboardKey.arrowDown, Tag.a.a)]);

        // Manually hover over item 'Tag.a.d'
        final pointer = TestPointer(1, ui.PointerDeviceKind.mouse);
        final targetOffset = tester.getCenter(find.text(Tag.a.d.text));

        await tester.sendEventToBinding(pointer.hover(targetOffset));
        await tester.pumpAndSettle();

        // Focus should have jumped to the hovered item 'Tag.a.d' via the pointer event
        expect(
          FocusManager.instance.primaryFocus?.debugLabel,
          contains(Tag.a.d.focusNode),
          reason: 'Hovering should request focus on the hovered item.',
        );

        // Resume keyboard traversal, ArrowDown should logically move to 'Tag.a.e'
        await expectFocusPath(tester, [
          (LogicalKeyboardKey.arrowDown, Tag.a.e),
          (LogicalKeyboardKey.arrowUp, Tag.a.d),
        ]);
      });

      testWidgets('Dropdown [V] traversal', (WidgetTester tester) async {
        await tester.pumpWidget(
          const App(MenuSystem(layers: [Axis.vertical], autofocus: Tag.anchor, isMenuBar: false)),
        );

        await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
          (LogicalKeyboardKey.arrowDown, Tag.a),
          (LogicalKeyboardKey.arrowDown, Tag.b),
          (LogicalKeyboardKey.arrowDown, Tag.c),
          (LogicalKeyboardKey.arrowDown, Tag.d),
          (LogicalKeyboardKey.arrowDown, Tag.e),
          (LogicalKeyboardKey.arrowDown, Tag.a),
          (LogicalKeyboardKey.arrowUp, Tag.e),
          (LogicalKeyboardKey.arrowUp, Tag.d),
          (LogicalKeyboardKey.arrowUp, Tag.c),
          (LogicalKeyboardKey.arrowUp, Tag.b),
          (LogicalKeyboardKey.arrowUp, Tag.a),
          (LogicalKeyboardKey.arrowUp, Tag.e),

          // Horizontal movement should NOT work for single-layer vertical dropdown items
          (LogicalKeyboardKey.arrowRight, Tag.e),
          (LogicalKeyboardKey.arrowLeft, Tag.e),
        ]);
      });

      testWidgets('Dropdown [H] LTR traversal', (WidgetTester tester) async {
        await tester.pumpWidget(
          const App(MenuSystem(layers: [Axis.horizontal], autofocus: Tag.anchor, isMenuBar: false)),
        );

        await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
          // Vertical movement should work
          (LogicalKeyboardKey.arrowDown, Tag.a),
          (LogicalKeyboardKey.arrowRight, Tag.b),
          (LogicalKeyboardKey.arrowRight, Tag.c),
          (LogicalKeyboardKey.arrowRight, Tag.d),
          (LogicalKeyboardKey.arrowRight, Tag.e),
          (LogicalKeyboardKey.arrowRight, Tag.a),
          (LogicalKeyboardKey.arrowLeft, Tag.e),
          (LogicalKeyboardKey.arrowLeft, Tag.d),
          (LogicalKeyboardKey.arrowLeft, Tag.c),
          (LogicalKeyboardKey.arrowLeft, Tag.b),
          (LogicalKeyboardKey.arrowLeft, Tag.a),
          (LogicalKeyboardKey.arrowLeft, Tag.e),

          (LogicalKeyboardKey.home, Tag.a),
          (LogicalKeyboardKey.end, Tag.e),
        ]);
      });

      testWidgets('Dropdown [H] RTL traversal', (WidgetTester tester) async {
        await tester.pumpWidget(
          const App(
            MenuSystem(layers: [Axis.horizontal], autofocus: Tag.anchor, isMenuBar: false),
            textDirection: TextDirection.rtl,
          ),
        );

        await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
          // Vertical movement should work
          (LogicalKeyboardKey.arrowDown, Tag.a),
          (LogicalKeyboardKey.arrowLeft, Tag.b),
          (LogicalKeyboardKey.arrowLeft, Tag.c),
          (LogicalKeyboardKey.arrowLeft, Tag.d),
          (LogicalKeyboardKey.arrowLeft, Tag.e),
          (LogicalKeyboardKey.arrowLeft, Tag.a),
          (LogicalKeyboardKey.arrowRight, Tag.e),
          (LogicalKeyboardKey.arrowRight, Tag.d),
          (LogicalKeyboardKey.arrowRight, Tag.c),
          (LogicalKeyboardKey.arrowRight, Tag.b),
          (LogicalKeyboardKey.arrowRight, Tag.a),
          (LogicalKeyboardKey.arrowRight, Tag.e),

          (LogicalKeyboardKey.home, Tag.a),
          (LogicalKeyboardKey.end, Tag.e),
        ]);
      });

      group('MenuBar', () {
        testWidgets('MenuBar [H] [LTR]: ArrowLeft/ArrowRight traversal', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            const App(
              MenuSystem(layers: [Axis.horizontal, Axis.vertical], autofocus: .b),
              textDirection: ui.TextDirection.ltr,
            ),
          );

          await expectFocusPath(tester, [
            (LogicalKeyboardKey.arrowLeft, Tag.a),
            (LogicalKeyboardKey.arrowLeft, Tag.e),
            (LogicalKeyboardKey.arrowLeft, Tag.d),
            (LogicalKeyboardKey.arrowRight, Tag.e),
            (LogicalKeyboardKey.arrowRight, Tag.a),
            (LogicalKeyboardKey.arrowRight, Tag.b),
          ]);

          // Make sure no menu is opened
          expect(find.text(Tag.b.a.text), findsNothing);

          await tester.pumpWidget(
            App(
              MenuSystem(
                layers: const [Axis.horizontal, Axis.vertical],
                autofocus: .a,
                leading: Button.tag(Tag.leading),
                trailing: Button.tag(Tag.trailing),
              ),
              textDirection: ui.TextDirection.ltr,
            ),
          );

          await expectFocusPath(tester, [
            (LogicalKeyboardKey.arrowLeft, Tag.leading),
            (LogicalKeyboardKey.arrowLeft, Tag.trailing),
            (LogicalKeyboardKey.arrowLeft, Tag.e),
            (LogicalKeyboardKey.arrowRight, Tag.trailing),
            (LogicalKeyboardKey.arrowRight, Tag.leading),
            (LogicalKeyboardKey.arrowRight, Tag.a),
          ]);

          // Make sure no menu is opened
          expect(find.text(Tag.a.a.text), findsNothing);
        });

        testWidgets('MenuBar [H] [RTL]: ArrowRight/ArrowLeft traversal', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            const App(
              MenuSystem(layers: [Axis.horizontal, Axis.vertical], autofocus: .b),
              textDirection: ui.TextDirection.rtl,
            ),
          );

          await expectFocusPath(tester, [
            (LogicalKeyboardKey.arrowRight, Tag.a),
            (LogicalKeyboardKey.arrowRight, Tag.e),
            (LogicalKeyboardKey.arrowRight, Tag.d),
            (LogicalKeyboardKey.arrowLeft, Tag.e),
            (LogicalKeyboardKey.arrowLeft, Tag.a),
            (LogicalKeyboardKey.arrowLeft, Tag.b),
          ]);

          // Make sure no menu is opened
          expect(find.text(Tag.b.a.text), findsNothing);

          await tester.pumpWidget(
            App(
              MenuSystem(
                layers: const [Axis.horizontal, Axis.vertical],
                autofocus: .a,
                leading: Button.tag(Tag.leading),
                trailing: Button.tag(Tag.trailing),
              ),
              textDirection: ui.TextDirection.rtl,
            ),
          );

          await expectFocusPath(tester, [
            (LogicalKeyboardKey.arrowRight, Tag.leading),
            (LogicalKeyboardKey.arrowRight, Tag.trailing),
            (LogicalKeyboardKey.arrowRight, Tag.e),
            (LogicalKeyboardKey.arrowLeft, Tag.trailing),
            (LogicalKeyboardKey.arrowLeft, Tag.leading),
            (LogicalKeyboardKey.arrowLeft, Tag.a),
          ]);

          // Make sure no menu is opened
          expect(find.text(Tag.a.a.text), findsNothing);
        });

        testWidgets('MenuBar [V]: ArrowUp/ArrowDown traversal', (WidgetTester tester) async {
          await tester.pumpWidget(
            const App(MenuSystem(layers: [Axis.vertical, Axis.vertical], autofocus: .b)),
          );

          await expectFocusPath(tester, [
            (LogicalKeyboardKey.arrowUp, Tag.a),
            (LogicalKeyboardKey.arrowUp, Tag.e),
            (LogicalKeyboardKey.arrowUp, Tag.d),
            (LogicalKeyboardKey.arrowDown, Tag.e),
            (LogicalKeyboardKey.arrowDown, Tag.a),
            (LogicalKeyboardKey.arrowDown, Tag.b),
          ]);

          // Make sure no menu is opened
          expect(find.text(Tag.b.a.text), findsNothing);

          await tester.pumpWidget(
            App(
              MenuSystem(
                layers: const [Axis.vertical],
                autofocus: .a,
                leading: Button.tag(Tag.leading),
                trailing: Button.tag(Tag.trailing),
              ),
              // Text direction should not make a difference.
              textDirection: ui.TextDirection.rtl,
            ),
          );

          await expectFocusPath(tester, [
            (LogicalKeyboardKey.arrowUp, Tag.leading),
            (LogicalKeyboardKey.arrowUp, Tag.trailing),
            (LogicalKeyboardKey.arrowUp, Tag.e),
            (LogicalKeyboardKey.arrowDown, Tag.trailing),
            (LogicalKeyboardKey.arrowDown, Tag.leading),
            (LogicalKeyboardKey.arrowDown, Tag.a),
          ]);

          // Make sure no menu is opened
          expect(find.text(Tag.a.a.text), findsNothing);
        });

        testWidgets('MenuBar [H]: ArrowUp/ArrowDown does not traverse', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            const App(
              MenuSystem(layers: [Axis.horizontal], autofocus: .b),
              textDirection: ui.TextDirection.rtl,
            ),
          );

          await expectFocusPath(tester, [
            (LogicalKeyboardKey.arrowDown, Tag.b),
            (LogicalKeyboardKey.arrowDown, Tag.b),
            (LogicalKeyboardKey.arrowUp, Tag.b),
            (LogicalKeyboardKey.arrowUp, Tag.b),
          ]);
        });

        testWidgets('MenuBar [V]: ArrowLeft/ArrowRight does not traverse', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(const App(MenuSystem(layers: [Axis.vertical], autofocus: .b)));

          await expectFocusPath(tester, [
            (LogicalKeyboardKey.arrowLeft, Tag.b),
            (LogicalKeyboardKey.arrowLeft, Tag.b),
            (LogicalKeyboardKey.arrowRight, Tag.b),
            (LogicalKeyboardKey.arrowRight, Tag.b),
          ]);
        });

        testWidgets('MenuBar [H]: Home/End keys focus first and last items', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            const App(MenuSystem(layers: [Axis.horizontal, Axis.vertical], autofocus: Tag.c)),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.home, Tag.a),
            (LogicalKeyboardKey.end, Tag.e),
          ]);

          await tester.pumpWidget(
            App(
              MenuSystem(
                layers: const [Axis.horizontal, Axis.vertical],
                autofocus: Tag.c,
                leading: Button.tag(Tag.leading),
                trailing: Button.tag(Tag.trailing),
              ),
            ),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.home, Tag.leading),
            (LogicalKeyboardKey.end, Tag.trailing),
          ]);
        });

        testWidgets('MenuBar [V]: Home/End keys focus first and last items', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            const App(MenuSystem(layers: [Axis.vertical, Axis.horizontal], autofocus: Tag.c)),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.home, Tag.a),
            (LogicalKeyboardKey.end, Tag.e),
          ]);

          await tester.pumpWidget(
            App(
              MenuSystem(
                layers: const [Axis.vertical, Axis.horizontal],
                autofocus: Tag.c,
                leading: Button.tag(Tag.leading),
                trailing: Button.tag(Tag.trailing),
              ),
            ),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.home, Tag.leading),
            (LogicalKeyboardKey.end, Tag.trailing),
          ]);
        });
      });

      group('Submenu', () {
        testWidgets('Submenu [H -> V]: ArrowDown on anchor enters submenu from top', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            const App(MenuSystem(layers: [Axis.horizontal, Axis.vertical], autofocus: Tag.a)),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.arrowDown, Tag.a.a),
          ]);
        });

        testWidgets('Submenu [H -> V]: ArrowUp on anchor enters submenu from bottom', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            const App(MenuSystem(layers: [Axis.horizontal, Axis.vertical], autofocus: Tag.a)),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.arrowUp, Tag.a.e),
          ]);
        });

        testWidgets('Submenu [H -> V]: Submenu traversal', (WidgetTester tester) async {
          await tester.pumpWidget(
            const App(MenuSystem(layers: [Axis.horizontal, Axis.vertical], autofocus: Tag.a)),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.arrowDown, Tag.a.a),
            (LogicalKeyboardKey.arrowDown, Tag.a.b),
            (LogicalKeyboardKey.arrowDown, Tag.a.c),
            (LogicalKeyboardKey.arrowDown, Tag.a.d),
            (LogicalKeyboardKey.arrowDown, Tag.a.e),
            (LogicalKeyboardKey.arrowDown, Tag.a.a), // Wraps to start
            (LogicalKeyboardKey.arrowUp, Tag.a.e), // Wraps to end
            (LogicalKeyboardKey.arrowUp, Tag.a.d),
            (LogicalKeyboardKey.arrowUp, Tag.a.c),
            (LogicalKeyboardKey.arrowUp, Tag.a.b),
            (LogicalKeyboardKey.arrowUp, Tag.a.a),
            (LogicalKeyboardKey.arrowUp, Tag.a.e),
            (LogicalKeyboardKey.home, Tag.a.a),
            (LogicalKeyboardKey.end, Tag.a.e),
          ]);
        });

        testWidgets(
          'Submenu [H -> V] [LTR]: ArrowLeft in submenu moves focus to previous parent anchor sibling',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              const App(MenuSystem(layers: [Axis.horizontal, Axis.vertical], autofocus: Tag.a)),
            );

            await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
              (LogicalKeyboardKey.arrowDown, Tag.a.a),
              (LogicalKeyboardKey.arrowLeft, Tag.e),
            ]);

            expect(find.text(Tag.e.a.text), findsOneWidget);
          },
        );

        testWidgets(
          'Submenu [H -> V] [RTL]: ArrowRight in submenu moves focus to previous parent anchor sibling',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              const App(
                MenuSystem(layers: [Axis.horizontal, Axis.vertical], autofocus: Tag.a),
                textDirection: TextDirection.rtl,
              ),
            );

            await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
              (LogicalKeyboardKey.arrowDown, Tag.a.a),
              (LogicalKeyboardKey.arrowRight, Tag.e),
            ]);

            expect(find.text(Tag.e.a.text), findsOneWidget);
          },
        );

        testWidgets(
          'Submenu [H -> V] [LTR]: ArrowRight in submenu moves focus to next parent anchor sibling',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              const App(MenuSystem(layers: [Axis.horizontal, Axis.vertical], autofocus: Tag.e)),
            );

            await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
              (LogicalKeyboardKey.arrowDown, Tag.e.a),
              (LogicalKeyboardKey.arrowRight, Tag.a),
            ]);

            expect(find.text(Tag.a.a.text), findsOneWidget);
          },
        );

        testWidgets(
          'Submenu [H -> V] [RTL]: ArrowLeft in submenu moves focus to next parent anchor sibling',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              const App(
                MenuSystem(layers: [Axis.horizontal, Axis.vertical], autofocus: Tag.e),
                textDirection: TextDirection.rtl,
              ),
            );

            await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
              (LogicalKeyboardKey.arrowDown, Tag.e.a),
              (LogicalKeyboardKey.arrowLeft, Tag.a),
            ]);

            expect(find.text(Tag.a.a.text), findsOneWidget);
          },
        );

        testWidgets('Submenu [H -> H]: ArrowDown on anchor enters submenu from start', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            const App(MenuSystem(layers: [Axis.horizontal, Axis.horizontal], autofocus: Tag.a)),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.arrowDown, Tag.a.a),
          ]);
        });

        testWidgets('Submenu [H -> H]: ArrowUp on anchor enters submenu from end', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            const App(MenuSystem(layers: [Axis.horizontal, Axis.horizontal], autofocus: Tag.a)),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.arrowUp, Tag.a.e),
          ]);
        });

        testWidgets(
          'Submenu [H -> H]: ArrowUp in submenu closes submenu and returns focus to parent anchor',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              const App(MenuSystem(layers: [Axis.horizontal, Axis.horizontal], autofocus: Tag.a)),
            );

            await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
              (LogicalKeyboardKey.arrowDown, Tag.a.a),
              (LogicalKeyboardKey.arrowUp, Tag.a),
            ]);

            expect(find.text(Tag.a.a.text), findsNothing);
          },
        );

        testWidgets('Submenu [H -> H] [LTR]: Submenu traversal', (WidgetTester tester) async {
          await tester.pumpWidget(
            const App(MenuSystem(layers: [Axis.horizontal, Axis.horizontal], autofocus: Tag.a)),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.arrowDown, Tag.a.a),
            (LogicalKeyboardKey.arrowRight, Tag.a.b),
            (LogicalKeyboardKey.arrowRight, Tag.a.c),
            (LogicalKeyboardKey.arrowRight, Tag.a.d),
            (LogicalKeyboardKey.arrowRight, Tag.a.e),
            (LogicalKeyboardKey.arrowRight, Tag.a.a), // Wraps to start
            (LogicalKeyboardKey.arrowLeft, Tag.a.e), // Wraps to end
            (LogicalKeyboardKey.arrowLeft, Tag.a.d),
            (LogicalKeyboardKey.arrowLeft, Tag.a.c),
            (LogicalKeyboardKey.arrowLeft, Tag.a.b),
            (LogicalKeyboardKey.arrowLeft, Tag.a.a),
            (LogicalKeyboardKey.arrowLeft, Tag.a.e),

            (LogicalKeyboardKey.home, Tag.a.a),
            (LogicalKeyboardKey.end, Tag.a.e),
          ]);
        });

        testWidgets('Submenu [H -> H] [RTL]: Submenu traversal', (WidgetTester tester) async {
          await tester.pumpWidget(
            const App(
              MenuSystem(layers: [Axis.horizontal, Axis.horizontal], autofocus: Tag.a),
              textDirection: TextDirection.rtl,
            ),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.arrowDown, Tag.a.a),
            (LogicalKeyboardKey.arrowLeft, Tag.a.b),
            (LogicalKeyboardKey.arrowLeft, Tag.a.c),
            (LogicalKeyboardKey.arrowLeft, Tag.a.d),
            (LogicalKeyboardKey.arrowLeft, Tag.a.e),
            (LogicalKeyboardKey.arrowLeft, Tag.a.a), // Wraps to start
            (LogicalKeyboardKey.arrowRight, Tag.a.e), // Wraps to end
            (LogicalKeyboardKey.arrowRight, Tag.a.d),
            (LogicalKeyboardKey.arrowRight, Tag.a.c),
            (LogicalKeyboardKey.arrowRight, Tag.a.b),
            (LogicalKeyboardKey.arrowRight, Tag.a.a),
            (LogicalKeyboardKey.arrowRight, Tag.a.e),

            (LogicalKeyboardKey.home, Tag.a.a),
            (LogicalKeyboardKey.end, Tag.a.e),
          ]);
        });

        testWidgets('Submenu [V -> V] [LTR]: ArrowRight on anchor enters submenu from top', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            const App(MenuSystem(layers: [Axis.vertical, Axis.vertical], autofocus: Tag.a)),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.arrowRight, Tag.a.a),
          ]);
        });
        testWidgets('Submenu [V -> V] [LTR]: ArrowLeft on anchor does nothing', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            const App(MenuSystem(layers: [Axis.vertical, Axis.vertical], autofocus: Tag.a)),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.arrowLeft, Tag.a),
          ]);
        });

        testWidgets(
          'Submenu [V -> V] [LTR]: ArrowLeft in submenu closes submenu and returns focus to parent anchor',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              const App(MenuSystem(layers: [Axis.vertical, Axis.vertical], autofocus: Tag.a)),
            );

            await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
              (LogicalKeyboardKey.arrowRight, Tag.a.a),
              (LogicalKeyboardKey.arrowLeft, Tag.a),
            ]);

            expect(find.text(Tag.a.a.text), findsNothing);
          },
        );

        testWidgets('Submenu [V -> V] [RTL]: ArrowLeft on anchor enters submenu from top', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            const App(
              MenuSystem(layers: [Axis.vertical, Axis.vertical], autofocus: Tag.a),
              textDirection: TextDirection.rtl,
            ),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.arrowLeft, Tag.a.a),
          ]);
        });
        testWidgets('Submenu [V -> V] [RTL]: ArrowRight on anchor does nothing', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            const App(
              MenuSystem(layers: [Axis.vertical, Axis.vertical], autofocus: Tag.a),
              textDirection: TextDirection.rtl,
            ),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.arrowRight, Tag.a),
          ]);
        });

        testWidgets(
          'Submenu [V -> V] [RTL]: ArrowRight in submenu closes submenu and returns focus to parent anchor',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              const App(
                MenuSystem(layers: [Axis.vertical, Axis.vertical], autofocus: Tag.a),
                textDirection: TextDirection.rtl,
              ),
            );

            await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
              (LogicalKeyboardKey.arrowLeft, Tag.a.a),
              (LogicalKeyboardKey.arrowRight, Tag.a),
            ]);

            expect(find.text(Tag.a.a.text), findsNothing);
          },
        );

        testWidgets('Submenu [V -> V]: Submenu traversal', (WidgetTester tester) async {
          await tester.pumpWidget(
            const App(MenuSystem(layers: [Axis.vertical, Axis.vertical], autofocus: Tag.a)),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.arrowRight, Tag.a.a),
            (LogicalKeyboardKey.arrowDown, Tag.a.b),
            (LogicalKeyboardKey.arrowDown, Tag.a.c),
            (LogicalKeyboardKey.arrowDown, Tag.a.d),
            (LogicalKeyboardKey.arrowDown, Tag.a.e),
            (LogicalKeyboardKey.arrowDown, Tag.a.a), // Wraps to start
            (LogicalKeyboardKey.arrowUp, Tag.a.e), // Wraps to end
            (LogicalKeyboardKey.arrowUp, Tag.a.d),
            (LogicalKeyboardKey.arrowUp, Tag.a.c),
            (LogicalKeyboardKey.arrowUp, Tag.a.b),
            (LogicalKeyboardKey.arrowUp, Tag.a.a),
            (LogicalKeyboardKey.arrowUp, Tag.a.e),

            (LogicalKeyboardKey.home, Tag.a.a),
            (LogicalKeyboardKey.end, Tag.a.e),
          ]);
        });

        testWidgets('Submenu [V -> H] [LTR]: ArrowRight on anchor enters submenu from start', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            const App(
              MenuSystem(layers: [Axis.vertical, Axis.horizontal], autofocus: Tag.a),
              textDirection: TextDirection.ltr,
            ),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.arrowRight, Tag.a.a),
          ]);
        });

        testWidgets('Submenu [V -> H] [LTR]: ArrowLeft on anchor enters submenu from end', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            const App(
              MenuSystem(layers: [Axis.vertical, Axis.horizontal], autofocus: Tag.a),
              textDirection: TextDirection.ltr,
            ),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.arrowLeft, Tag.a.e),
          ]);
        });

        testWidgets('Submenu [V -> H] [RTL]: ArrowLeft on anchor enters submenu from start', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            const App(
              MenuSystem(layers: [Axis.vertical, Axis.horizontal], autofocus: Tag.a),
              textDirection: TextDirection.rtl,
            ),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.arrowLeft, Tag.a.a),
          ]);
        });

        testWidgets('Submenu [V -> H] [RTL]: ArrowRight on anchor enters submenu from end', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            const App(
              MenuSystem(layers: [Axis.vertical, Axis.horizontal], autofocus: Tag.a),
              textDirection: TextDirection.rtl,
            ),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.arrowRight, Tag.a.e),
          ]);
        });

        testWidgets('Submenu [V -> H]: ArrowUp in submenu moves to previous crossaxis ancestor', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            const App(MenuSystem(layers: [Axis.vertical, Axis.horizontal], autofocus: Tag.a)),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.arrowRight, Tag.a.a),
            (LogicalKeyboardKey.arrowUp, Tag.e),
          ]);

          expect(find.text(Tag.e.a.text), findsOneWidget);
        });

        testWidgets('Submenu [V -> H]: ArrowDown in submenu moves to next crossaxis ancestor', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            const App(MenuSystem(layers: [Axis.vertical, Axis.horizontal], autofocus: Tag.e)),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.arrowRight, Tag.e.a),
            (LogicalKeyboardKey.arrowDown, Tag.a),
          ]);

          expect(find.text(Tag.a.a.text), findsOneWidget);
        });

        testWidgets('Submenu [V -> H] [LTR]: Submenu traversal', (WidgetTester tester) async {
          await tester.pumpWidget(
            const App(MenuSystem(layers: [Axis.vertical, Axis.horizontal], autofocus: Tag.a)),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.arrowRight, Tag.a.a),
            (LogicalKeyboardKey.arrowRight, Tag.a.b),
            (LogicalKeyboardKey.arrowRight, Tag.a.c),
            (LogicalKeyboardKey.arrowRight, Tag.a.d),
            (LogicalKeyboardKey.arrowRight, Tag.a.e),
            (LogicalKeyboardKey.arrowRight, Tag.a.a), // Wraps to start
            (LogicalKeyboardKey.arrowLeft, Tag.a.e), // Wraps to end
            (LogicalKeyboardKey.arrowLeft, Tag.a.d),
            (LogicalKeyboardKey.arrowLeft, Tag.a.c),
            (LogicalKeyboardKey.arrowLeft, Tag.a.b),
            (LogicalKeyboardKey.arrowLeft, Tag.a.a),
            (LogicalKeyboardKey.arrowLeft, Tag.a.e),

            (LogicalKeyboardKey.home, Tag.a.a),
            (LogicalKeyboardKey.end, Tag.a.e),
          ]);
        });

        testWidgets('Submenu [V -> H] [RTL]: Submenu traversal', (WidgetTester tester) async {
          await tester.pumpWidget(
            const App(
              MenuSystem(layers: [Axis.vertical, Axis.horizontal], autofocus: Tag.a),
              textDirection: TextDirection.rtl,
            ),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.arrowLeft, Tag.a.a),
            (LogicalKeyboardKey.arrowLeft, Tag.a.b),
            (LogicalKeyboardKey.arrowLeft, Tag.a.c),
            (LogicalKeyboardKey.arrowLeft, Tag.a.d),
            (LogicalKeyboardKey.arrowLeft, Tag.a.e),
            (LogicalKeyboardKey.arrowLeft, Tag.a.a), // Wraps to start
            (LogicalKeyboardKey.arrowRight, Tag.a.e), // Wraps to end
            (LogicalKeyboardKey.arrowRight, Tag.a.d),
            (LogicalKeyboardKey.arrowRight, Tag.a.c),
            (LogicalKeyboardKey.arrowRight, Tag.a.b),
            (LogicalKeyboardKey.arrowRight, Tag.a.a),
            (LogicalKeyboardKey.arrowRight, Tag.a.e),

            (LogicalKeyboardKey.home, Tag.a.a),
            (LogicalKeyboardKey.end, Tag.a.e),
          ]);
        });

        testWidgets(
          'Submenu [Anchor Hover]: Opens after delay and closes when mouse leaves anchor',
          (WidgetTester tester) async {
            final anchorFocusNode = FocusNode(debugLabel: Tag.anchor.focusNode);
            addTearDown(anchorFocusNode.dispose);
            final controller = MenuController();
            await tester.pumpWidget(
              App(
                Column(
                  children: [
                    Text(Tag.outside.text),
                    BaseSubmenu(
                      semanticProperties: const SemanticsProperties(),
                      role: null,
                      controller: controller,
                      hoverOpenDelay: const Duration(milliseconds: 100),
                      hoverCloseDelay: const Duration(milliseconds: 200),
                      menu: BaseMenuPanel(
                        orientation: Axis.vertical,
                        children: [Button(Text(Tag.a.text))],
                      ),
                      onPressed: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                      focusNode: anchorFocusNode,
                      child: Text(
                        Tag.anchor.text,
                        style: const TextStyle(color: Color(0xFfffffff)),
                      ),
                    ),
                  ],
                ),
              ),
            );

            final gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
            await gesture.addPointer(location: Offset.zero);
            await gesture.moveTo(tester.getCenter(find.text(Tag.anchor.text)));
            await tester.pump();

            expect(controller.isOpen, isFalse);
            expect(primaryFocus?.debugLabel, contains(Tag.anchor.focusNode));

            await tester.pump(const Duration(milliseconds: 100));
            expect(controller.isOpen, isTrue);

            await gesture.moveTo(tester.getCenter(find.text(Tag.outside.text)));
            await tester.pump();

            await tester.pump(const Duration(milliseconds: 201));
            expect(controller.isOpen, isFalse);

            await gesture.removePointer();
          },
        );
      });

      group('Nested Submenu', () {
        testWidgets(
          'Submenu [V -> V -> V] [LTR]: ArrowLeft within nested submenu closes the menu and returns focus to parent anchor',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              const App(
                MenuSystem(layers: [Axis.vertical, Axis.vertical, Axis.vertical], autofocus: Tag.a),
              ),
            );

            await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
              (LogicalKeyboardKey.arrowRight, Tag.a.a),
              (LogicalKeyboardKey.arrowRight, Tag.a.a.a),
              (LogicalKeyboardKey.arrowLeft, Tag.a.a),
              (LogicalKeyboardKey.arrowLeft, Tag.a),
            ]);

            expect(find.text(Tag.a.a.a.text), findsNothing);
            expect(find.text(Tag.a.a.text), findsNothing);
          },
        );

        testWidgets(
          'Submenu [V -> V -> V] [RTL]: ArrowRight within nested submenu closes the menu and returns focus to parent anchor',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              const App(
                MenuSystem(layers: [Axis.vertical, Axis.vertical, Axis.vertical], autofocus: Tag.a),
                textDirection: TextDirection.rtl,
              ),
            );

            await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
              (LogicalKeyboardKey.arrowLeft, Tag.a.a),
              (LogicalKeyboardKey.arrowLeft, Tag.a.a.a),
              (LogicalKeyboardKey.arrowRight, Tag.a.a),
              (LogicalKeyboardKey.arrowRight, Tag.a),
            ]);

            expect(find.text(Tag.a.a.a.text), findsNothing);
            expect(find.text(Tag.a.a.text), findsNothing);
          },
        );

        testWidgets('Submenu [V -> V -> V]: Nested submenu traversal', (WidgetTester tester) async {
          await tester.pumpWidget(
            const App(
              MenuSystem(layers: [Axis.vertical, Axis.vertical, Axis.vertical], autofocus: Tag.a),
            ),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.arrowRight, Tag.a.a),
            (LogicalKeyboardKey.arrowRight, Tag.a.a.a),
            (LogicalKeyboardKey.arrowDown, Tag.a.a.b),
            (LogicalKeyboardKey.arrowDown, Tag.a.a.c),
            (LogicalKeyboardKey.arrowDown, Tag.a.a.d),
            (LogicalKeyboardKey.arrowDown, Tag.a.a.e),
            (LogicalKeyboardKey.arrowDown, Tag.a.a.a), // Wraps to start
            (LogicalKeyboardKey.arrowUp, Tag.a.a.e), // Wraps to end
            (LogicalKeyboardKey.arrowUp, Tag.a.a.d),
            (LogicalKeyboardKey.arrowUp, Tag.a.a.c),
            (LogicalKeyboardKey.arrowUp, Tag.a.a.b),
            (LogicalKeyboardKey.arrowUp, Tag.a.a.a),
            (LogicalKeyboardKey.arrowUp, Tag.a.a.e),
            (LogicalKeyboardKey.home, Tag.a.a.a),
            (LogicalKeyboardKey.end, Tag.a.a.e),
          ]);
        });

        testWidgets(
          'Submenu [H -> H -> H]: ArrowUp within submenu closes the menu and returns focus to parent anchor',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              const App(
                MenuSystem(
                  layers: [Axis.horizontal, Axis.horizontal, Axis.horizontal],
                  autofocus: Tag.a,
                ),
                textDirection: TextDirection.rtl,
              ),
            );

            await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
              (LogicalKeyboardKey.arrowDown, Tag.a.a),
              (LogicalKeyboardKey.arrowDown, Tag.a.a.a),
              (LogicalKeyboardKey.arrowUp, Tag.a.a),
              (LogicalKeyboardKey.arrowUp, Tag.a),
            ]);

            expect(find.text(Tag.a.a.a.text), findsNothing);
            expect(find.text(Tag.a.a.text), findsNothing);
          },
        );

        testWidgets('Submenu [H -> H -> H] [LTR]: Nested submenu traversal', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            const App(
              MenuSystem(
                layers: [Axis.horizontal, Axis.horizontal, Axis.horizontal],
                autofocus: Tag.a,
              ),
            ),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.arrowDown, Tag.a.a),
            (LogicalKeyboardKey.arrowDown, Tag.a.a.a),
            (LogicalKeyboardKey.arrowRight, Tag.a.a.b),
            (LogicalKeyboardKey.arrowRight, Tag.a.a.c),
            (LogicalKeyboardKey.arrowRight, Tag.a.a.d),
            (LogicalKeyboardKey.arrowRight, Tag.a.a.e),
            (LogicalKeyboardKey.arrowRight, Tag.a.a.a), // Wraps to start
            (LogicalKeyboardKey.arrowLeft, Tag.a.a.e), // Wraps to end
            (LogicalKeyboardKey.arrowLeft, Tag.a.a.d),
            (LogicalKeyboardKey.arrowLeft, Tag.a.a.c),
            (LogicalKeyboardKey.arrowLeft, Tag.a.a.b),
            (LogicalKeyboardKey.arrowLeft, Tag.a.a.a),
            (LogicalKeyboardKey.arrowLeft, Tag.a.a.e),
            (LogicalKeyboardKey.home, Tag.a.a.a),
            (LogicalKeyboardKey.end, Tag.a.a.e),
          ]);
        });

        testWidgets('Submenu [H -> H -> H] [RTL]: Nested submenu traversal', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            const App(
              MenuSystem(
                layers: [Axis.horizontal, Axis.horizontal, Axis.horizontal],
                autofocus: Tag.a,
              ),
              textDirection: TextDirection.rtl,
            ),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.arrowDown, Tag.a.a),
            (LogicalKeyboardKey.arrowDown, Tag.a.a.a),
            (LogicalKeyboardKey.arrowLeft, Tag.a.a.b),
            (LogicalKeyboardKey.arrowLeft, Tag.a.a.c),
            (LogicalKeyboardKey.arrowLeft, Tag.a.a.d),
            (LogicalKeyboardKey.arrowLeft, Tag.a.a.e),
            (LogicalKeyboardKey.arrowLeft, Tag.a.a.a), // Wraps to start
            (LogicalKeyboardKey.arrowRight, Tag.a.a.e), // Wraps to end
            (LogicalKeyboardKey.arrowRight, Tag.a.a.d),
            (LogicalKeyboardKey.arrowRight, Tag.a.a.c),
            (LogicalKeyboardKey.arrowRight, Tag.a.a.b),
            (LogicalKeyboardKey.arrowRight, Tag.a.a.a),
            (LogicalKeyboardKey.arrowRight, Tag.a.a.e),
            (LogicalKeyboardKey.home, Tag.a.a.a),
            (LogicalKeyboardKey.end, Tag.a.a.e),
          ]);
        });

        testWidgets('Submenu [H -> V -> V] [LTR]: ArrowRight moves to next cross-axis ancestor', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            const App(
              MenuSystem(layers: [Axis.horizontal, Axis.vertical, Axis.vertical], autofocus: Tag.a),
            ),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.arrowDown, Tag.a.a),
            (LogicalKeyboardKey.arrowRight, Tag.a.a.a),
            (LogicalKeyboardKey.arrowRight, Tag.b),
          ]);

          expect(find.text(Tag.a.a.a.text), findsNothing);
          expect(find.text(Tag.b.a.text), findsOneWidget);
        });

        testWidgets('Submenu [H -> V -> V] [RTL]: ArrowLeft moves to next cross-axis ancestor', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            const App(
              MenuSystem(layers: [Axis.horizontal, Axis.vertical, Axis.vertical], autofocus: Tag.a),
              textDirection: TextDirection.rtl,
            ),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.arrowDown, Tag.a.a),
            (LogicalKeyboardKey.arrowLeft, Tag.a.a.a),
            (LogicalKeyboardKey.arrowLeft, Tag.b),
          ]);

          expect(find.text(Tag.a.a.a.text), findsNothing);
          expect(find.text(Tag.b.a.text), findsOneWidget);
        });

        testWidgets(
          'Submenu [H -> V -> V] [LTR]: ArrowLeft closes nested submenu and moves focus to parent anchor',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              const App(
                MenuSystem(
                  layers: [Axis.horizontal, Axis.vertical, Axis.vertical],
                  autofocus: Tag.a,
                ),
              ),
            );

            await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
              (LogicalKeyboardKey.arrowDown, Tag.a.a),
              (LogicalKeyboardKey.arrowRight, Tag.a.a.a),
              (LogicalKeyboardKey.arrowLeft, Tag.a.a),
            ]);

            expect(find.text(Tag.a.a.a.text), findsNothing);
          },
        );

        testWidgets(
          'Submenu [H -> V -> V] [RTL]: ArrowRight closes nested submenu and moves focus to parent anchor',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              const App(
                MenuSystem(
                  layers: [Axis.horizontal, Axis.vertical, Axis.vertical],
                  autofocus: Tag.a,
                ),
                textDirection: TextDirection.rtl,
              ),
            );

            await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
              (LogicalKeyboardKey.arrowDown, Tag.a.a),
              (LogicalKeyboardKey.arrowLeft, Tag.a.a.a),
              (LogicalKeyboardKey.arrowRight, Tag.a.a),
            ]);

            expect(find.text(Tag.a.a.a.text), findsNothing);
          },
        );

        testWidgets(
          'Submenu [H -> H -> V -> V] [LTR]: ArrowRight moves to next cross-axis ancestor',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              const App(
                MenuSystem(
                  layers: [Axis.horizontal, Axis.horizontal, Axis.vertical, Axis.vertical],
                  autofocus: Tag.a,
                ),
              ),
            );

            await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
              (LogicalKeyboardKey.arrowDown, Tag.a.a),
              (LogicalKeyboardKey.arrowDown, Tag.a.a.a),
              (LogicalKeyboardKey.arrowRight, Tag.a.a.a.a),
              (LogicalKeyboardKey.arrowRight, Tag.a.b),
            ]);

            expect(find.text(Tag.a.a.a.text), findsNothing);
            expect(find.text(Tag.a.b.a.text), findsOneWidget);

            await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
              (LogicalKeyboardKey.arrowLeft, Tag.a.a),
              (LogicalKeyboardKey.arrowLeft, Tag.a.e),
              (LogicalKeyboardKey.arrowDown, Tag.a.e.a),
              (LogicalKeyboardKey.arrowRight, Tag.a.e.a.a),
              (LogicalKeyboardKey.arrowRight, Tag.a.a),
            ]);

            expect(find.text(Tag.a.e.a.text), findsNothing);
            expect(find.text(Tag.a.a.a.text), findsOneWidget);
          },
        );

        testWidgets(
          'Submenu [H -> H -> V -> V] [RTL]: ArrowLeft moves to next cross-axis ancestor',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              const App(
                MenuSystem(
                  layers: [Axis.horizontal, Axis.horizontal, Axis.vertical, Axis.vertical],
                  autofocus: Tag.a,
                ),
                textDirection: TextDirection.rtl,
              ),
            );

            await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
              (LogicalKeyboardKey.arrowDown, Tag.a.a),
              (LogicalKeyboardKey.arrowDown, Tag.a.a.a),
              (LogicalKeyboardKey.arrowLeft, Tag.a.a.a.a),
              (LogicalKeyboardKey.arrowLeft, Tag.a.b),
            ]);

            expect(find.text(Tag.a.a.a.text), findsNothing);
            expect(find.text(Tag.a.b.a.text), findsOneWidget);

            await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
              (LogicalKeyboardKey.arrowRight, Tag.a.a),
              (LogicalKeyboardKey.arrowRight, Tag.a.e),
              (LogicalKeyboardKey.arrowDown, Tag.a.e.a),
              (LogicalKeyboardKey.arrowLeft, Tag.a.e.a.a),
              (LogicalKeyboardKey.arrowLeft, Tag.a.a),
            ]);

            expect(find.text(Tag.a.e.a.text), findsNothing);
            expect(find.text(Tag.a.a.a.text), findsOneWidget);
          },
        );

        testWidgets(
          'Submenu [V -> H -> H]: ArrowDown in nested submenu closes child and moves to next cross-axis ancestor',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              const App(
                MenuSystem(
                  layers: [Axis.vertical, Axis.horizontal, Axis.horizontal],
                  autofocus: Tag.a,
                ),
              ),
            );

            await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
              (LogicalKeyboardKey.arrowRight, Tag.a.a),
              (LogicalKeyboardKey.arrowDown, Tag.a.a.a),
              (LogicalKeyboardKey.arrowDown, Tag.b),
            ]);

            expect(find.text(Tag.a.a.a.text), findsNothing);
            expect(find.text(Tag.b.a.text), findsOneWidget);
          },
        );

        testWidgets(
          'Submenu [V -> H -> H]: ArrowUp closes nested submenu and moves focus to parent anchor',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              const App(
                MenuSystem(
                  layers: [Axis.vertical, Axis.horizontal, Axis.horizontal],
                  autofocus: Tag.a,
                ),
              ),
            );

            await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
              (LogicalKeyboardKey.arrowRight, Tag.a.a),
              (LogicalKeyboardKey.arrowDown, Tag.a.a.a),
              (LogicalKeyboardKey.arrowUp, Tag.a.a),
            ]);

            expect(find.text(Tag.a.a.a.text), findsNothing);
          },
        );

        testWidgets('Submenu [V -> V -> H ]: ArrowUp moves to previous cross-axis ancestor', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            const App(
              MenuSystem(layers: [Axis.vertical, Axis.vertical, Axis.horizontal], autofocus: Tag.a),
            ),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.arrowRight, Tag.a.a),
            (LogicalKeyboardKey.arrowRight, Tag.a.a.a),
            (LogicalKeyboardKey.arrowUp, Tag.a.e),
          ]);

          expect(find.text(Tag.a.a.a.text), findsNothing);
          expect(find.text(Tag.a.e.a.text), findsOneWidget);
        });

        testWidgets('Submenu [V -> V -> H -> H]: ArrowDown moves to next cross-axis ancestor', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            const App(
              MenuSystem(
                layers: [Axis.vertical, Axis.vertical, Axis.horizontal, Axis.horizontal],
                autofocus: Tag.a,
              ),
            ),
          );

          await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
            (LogicalKeyboardKey.arrowRight, Tag.a.a),
            (LogicalKeyboardKey.arrowRight, Tag.a.a.a),
            (LogicalKeyboardKey.arrowDown, Tag.a.a.a.a),
            (LogicalKeyboardKey.arrowDown, Tag.a.b),
          ]);

          expect(find.text(Tag.a.a.a.text), findsNothing);
          expect(find.text(Tag.a.b.a.text), findsOneWidget);
          expect(find.text(Tag.a.b.a.a.text), findsNothing);
        });

        testWidgets(
          'Dropdown + Submenu [V -> V]: Horizontal arrow keys on leaf items do not move focus in dropdown',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              App(
                Column(
                  children: [
                    Button.tag(Tag.leading),
                    const MenuSystem(
                      layers: [Axis.vertical, Axis.vertical],
                      autofocus: Tag.anchor,
                      isMenuBar: false,
                    ),
                    Button.tag(Tag.trailing),
                  ],
                ),
                textDirection: TextDirection.ltr,
              ),
            );

            await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
              (LogicalKeyboardKey.arrowDown, Tag.a),
              (LogicalKeyboardKey.arrowRight, Tag.a.a),
              (LogicalKeyboardKey.arrowRight, Tag.a.a),
              (LogicalKeyboardKey.arrowRight, Tag.a.a),
              (LogicalKeyboardKey.arrowLeft, Tag.a),
              (LogicalKeyboardKey.arrowLeft, Tag.a),
            ]);
          },
        );

        testWidgets(
          'Dropdown + Submenu [H -> H]: Vertical arrow keys on leaf items do not move focus in dropdown',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              App(
                Column(
                  children: [
                    Button.tag(Tag.leading),
                    const MenuSystem(
                      layers: [Axis.horizontal, Axis.horizontal],
                      autofocus: Tag.anchor,
                      isMenuBar: false,
                    ),
                    Button.tag(Tag.trailing),
                  ],
                ),
                textDirection: TextDirection.ltr,
              ),
            );

            await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
              (LogicalKeyboardKey.arrowDown, Tag.a),
              (LogicalKeyboardKey.arrowDown, Tag.a.a),
              (LogicalKeyboardKey.arrowDown, Tag.a.a),
              (LogicalKeyboardKey.arrowDown, Tag.a.a),
              (LogicalKeyboardKey.arrowUp, Tag.a),
              (LogicalKeyboardKey.arrowUp, Tag.a),
            ]);
          },
        );
      });

      testWidgets('Disabled items are skipped by directional intents', (WidgetTester tester) async {
        await tester.pumpWidget(
          App(
            MenuSystem(
              layers: const [Axis.vertical, Axis.vertical, Axis.horizontal],
              autofocus: Tag.a,
              disabledItems: {Tag.b, Tag.e, Tag.a.a, Tag.a.e, Tag.a.b.c, Tag.a.b.e},
            ),
          ),
        );

        await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
          (LogicalKeyboardKey.arrowDown, Tag.c),
          (LogicalKeyboardKey.arrowDown, Tag.d),
          (LogicalKeyboardKey.arrowDown, Tag.a),

          (LogicalKeyboardKey.end, Tag.d),
          (LogicalKeyboardKey.home, Tag.a),

          (LogicalKeyboardKey.arrowRight, Tag.a.b),
          (LogicalKeyboardKey.arrowDown, Tag.a.c),
          (LogicalKeyboardKey.arrowDown, Tag.a.d),
          (LogicalKeyboardKey.arrowDown, Tag.a.b),

          (LogicalKeyboardKey.end, Tag.a.d),
          (LogicalKeyboardKey.home, Tag.a.b),

          (LogicalKeyboardKey.arrowRight, Tag.a.b.a),
          (LogicalKeyboardKey.arrowRight, Tag.a.b.b),
          (LogicalKeyboardKey.arrowRight, Tag.a.b.d),
          (LogicalKeyboardKey.arrowRight, Tag.a.b.a),
          (LogicalKeyboardKey.arrowLeft, Tag.a.b.d),

          (LogicalKeyboardKey.home, Tag.a.b.a),
          (LogicalKeyboardKey.end, Tag.a.b.d),
        ]);
      });

      testWidgets('Traversal: Focus remains inside menu when using Tab if configured to stop', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const App(MenuSystem(layers: [Axis.horizontal, Axis.vertical], autofocus: Tag.a)),
        );

        await expectFocusPath(tester, <(LogicalKeyboardKey, Tag)>[
          (LogicalKeyboardKey.arrowDown, Tag.a.a),
          (LogicalKeyboardKey.arrowDown, Tag.a.b),
          (LogicalKeyboardKey.tab, Tag.a.b),
          (LogicalKeyboardKey.tab, Tag.a.b),
        ]);
      });

      testWidgets(
        'Focus Restoration: Closing a nested menu by tapping outside restores focus to the original external FocusNode',
        (WidgetTester tester) async {
          final externalFocusNode = FocusNode();
          final rootController = MenuController();
          addTearDown(externalFocusNode.dispose);

          await tester.pumpWidget(
            App(
              Column(
                children: [
                  Button(const Text('External Button'), focusNode: externalFocusNode),
                  BaseMenu(
                    controller: rootController,
                    menu: BaseMenuPanel(
                      orientation: Axis.vertical,
                      children: <Widget>[Button.tag(Tag.a)],
                    ),
                    child: const AnchorButton(Tag.anchor),
                  ),
                ],
              ),
            ),
          );

          externalFocusNode.requestFocus();
          await tester.pump();

          expect(FocusManager.instance.primaryFocus, externalFocusNode);

          await tester.tap(find.text(Tag.anchor.text));
          await tester.pump();

          expect(FocusManager.instance.primaryFocus, isNot(externalFocusNode));

          await tester.tap(find.text('External Button'));
          await tester.pumpAndSettle();

          expect(rootController.isOpen, isFalse);
          expect(FocusManager.instance.primaryFocus, externalFocusNode);
        },
      );
    });
  });

  testWidgets('Focus returns to button after menu closes', (WidgetTester tester) async {
    final anchorFocusNode = FocusNode();
    final aFocusNode = FocusNode();
    addTearDown(anchorFocusNode.dispose);
    addTearDown(aFocusNode.dispose);

    await tester.pumpWidget(
      App(
        BaseMenu(
          controller: controller,
          menu: BaseMenuPanel(
            orientation: Axis.vertical,
            children: <Widget>[Button.tag(Tag.a, focusNode: aFocusNode)],
          ),
          child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
        ),
      ),
    );

    anchorFocusNode.requestFocus();
    await tester.pump();
    await tester.pumpAndSettle();

    controller.open();
    await tester.pump();

    aFocusNode.requestFocus();
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, aFocusNode);

    // Close menu with escape
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(controller.isOpen, isFalse);
    expect(FocusManager.instance.primaryFocus, anchorFocusNode);
  });

  testWidgets('Down key on closed menu button opens menu and focuses first item', (
    WidgetTester tester,
  ) async {
    final anchorFocusNode = FocusNode();
    final firstItemFocusNode = FocusNode();
    addTearDown(anchorFocusNode.dispose);
    addTearDown(firstItemFocusNode.dispose);

    await tester.pumpWidget(
      App(
        BaseMenu(
          controller: controller,
          menu: BaseMenuPanel(
            orientation: Axis.vertical,
            children: <Widget>[
              Button.tag(Tag.a, focusNode: firstItemFocusNode),
              Button.tag(Tag.b),
            ],
          ),
          child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
        ),
      ),
    );

    // Focus the anchor button first.
    anchorFocusNode.requestFocus();
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, anchorFocusNode);
    expect(controller.isOpen, isFalse);

    // Press down arrow key - should open menu and focus first item.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(controller.isOpen, isTrue);
    expect(FocusManager.instance.primaryFocus, firstItemFocusNode);
  });

  testWidgets('Up key on closed menu button opens menu and focuses last item', (
    WidgetTester tester,
  ) async {
    final anchorFocusNode = FocusNode();
    final lastItemFocusNode = FocusNode();
    addTearDown(anchorFocusNode.dispose);
    addTearDown(lastItemFocusNode.dispose);

    await tester.pumpWidget(
      App(
        BaseMenu(
          controller: controller,
          menu: BaseMenuPanel(
            orientation: Axis.vertical,
            children: <Widget>[
              Button.tag(Tag.a),
              Button.tag(Tag.b, focusNode: lastItemFocusNode),
            ],
          ),
          child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
        ),
      ),
    );

    // Focus the anchor button first.
    anchorFocusNode.requestFocus();
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, anchorFocusNode);
    expect(controller.isOpen, isFalse);

    // Press up arrow key - should open menu and focus last item.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(controller.isOpen, isTrue);
    expect(FocusManager.instance.primaryFocus, lastItemFocusNode);
  });

  testWidgets('Down key after menu opens focuses the first menu item', (WidgetTester tester) async {
    final anchorFocusNode = FocusNode();
    final firstItemFocusNode = FocusNode();
    final secondItemFocusNode = FocusNode();
    addTearDown(anchorFocusNode.dispose);
    addTearDown(firstItemFocusNode.dispose);
    addTearDown(secondItemFocusNode.dispose);

    await tester.pumpWidget(
      App(
        BaseMenu(
          controller: controller,
          menu: BaseMenuPanel(
            orientation: Axis.vertical,
            children: <Widget>[
              Button.tag(Tag.a, focusNode: firstItemFocusNode),
              Button.tag(Tag.b, focusNode: secondItemFocusNode),
            ],
          ),
          child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
        ),
      ),
    );

    // Focus the anchor button first
    anchorFocusNode.requestFocus();
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, anchorFocusNode);

    // Open the menu
    controller.open();
    await tester.pump();
    await tester.pumpAndSettle();

    // Press down arrow key - should focus first menu item
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, firstItemFocusNode);
  });

  testWidgets('Up key after open focuses the last menu item', (WidgetTester tester) async {
    final anchorFocusNode = FocusNode();
    final firstItemFocusNode = FocusNode();
    final lastItemFocusNode = FocusNode();
    addTearDown(anchorFocusNode.dispose);
    addTearDown(firstItemFocusNode.dispose);
    addTearDown(lastItemFocusNode.dispose);

    await tester.pumpWidget(
      App(
        BaseMenu(
          controller: controller,
          menu: BaseMenuPanel(
            orientation: Axis.vertical,
            children: <Widget>[
              Button.tag(Tag.a, focusNode: firstItemFocusNode),
              Button.tag(Tag.b),
              Button.tag(Tag.c, focusNode: lastItemFocusNode),
            ],
          ),
          child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
        ),
      ),
    );

    // Focus the anchor button first
    anchorFocusNode.requestFocus();
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, anchorFocusNode);

    // Open the menu
    controller.open();
    await tester.pump();
    await tester.pumpAndSettle();

    // Press up arrow key - should focus last menu item
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, lastItemFocusNode);
  });

  testWidgets('Home key moves focus to first menu item', (WidgetTester tester) async {
    final anchorFocusNode = FocusNode();
    final firstItemFocusNode = FocusNode();
    final middleItemFocusNode = FocusNode();
    final lastItemFocusNode = FocusNode();
    addTearDown(anchorFocusNode.dispose);
    addTearDown(firstItemFocusNode.dispose);
    addTearDown(middleItemFocusNode.dispose);
    addTearDown(lastItemFocusNode.dispose);

    await tester.pumpWidget(
      App(
        BaseMenu(
          controller: controller,
          menu: BaseMenuPanel(
            orientation: Axis.vertical,
            children: <Widget>[
              Button.tag(Tag.a, focusNode: firstItemFocusNode),
              Button.tag(Tag.b, focusNode: middleItemFocusNode),
              Button.tag(Tag.c, focusNode: lastItemFocusNode),
            ],
          ),
          child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
        ),
      ),
    );

    controller.open();
    await tester.pump();
    await tester.pumpAndSettle();

    lastItemFocusNode.requestFocus();
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, lastItemFocusNode);

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, firstItemFocusNode);
  });

  testWidgets('End key moves focus to last menu item', (WidgetTester tester) async {
    final anchorFocusNode = FocusNode();
    final firstItemFocusNode = FocusNode();
    final middleItemFocusNode = FocusNode();
    final lastItemFocusNode = FocusNode();
    addTearDown(anchorFocusNode.dispose);
    addTearDown(firstItemFocusNode.dispose);
    addTearDown(middleItemFocusNode.dispose);
    addTearDown(lastItemFocusNode.dispose);

    await tester.pumpWidget(
      App(
        BaseMenu(
          controller: controller,
          menu: BaseMenuPanel(
            orientation: Axis.vertical,
            children: <Widget>[
              Button.tag(Tag.a, focusNode: firstItemFocusNode),
              Button.tag(Tag.b, focusNode: middleItemFocusNode),
              Button.tag(Tag.c, focusNode: lastItemFocusNode),
            ],
          ),
          child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
        ),
      ),
    );

    controller.open();
    await tester.pump();
    await tester.pumpAndSettle();

    firstItemFocusNode.requestFocus();
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, firstItemFocusNode);

    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus, lastItemFocusNode);
  });

  group('[Default] Layout', () {
    final alignments = <AlignmentGeometry>[
      for (double x = -2; x <= 2; x += 1)
        for (double y = -2; y <= 2; y += 1) Alignment(x, y),
      for (double x = -2; x <= 2; x += 1)
        for (double y = -2; y <= 2; y += 1) AlignmentDirectional(x, y),
    ];

    /// Returns the rects of the menu's contents. If [clipped] is true, the
    /// rect is taken after UnconstrainedBox clips its contents.
    List<Rect> collectOverlays({bool clipped = true}) {
      final menuRects = <Rect>[];
      final Finder finder = clipped ? find.byType(BaseMenuPanel) : findOverlayContents();
      for (final Element candidate in finder.evaluate().toList()) {
        final box = candidate.renderObject! as RenderBox;
        final Offset topLeft = box.localToGlobal(box.size.topLeft(Offset.zero));
        menuRects.add(topLeft & box.size);
      }
      return menuRects;
    }

    testWidgets('LTR alignment', (WidgetTester tester) async {
      Widget buildApp({AlignmentGeometry? alignment}) {
        return App(
          BaseMenu(
            positionDelegate: DefaultBaseMenuPositioningDelegate(
              anchorAlignment: alignment,
              menuAlignment: Alignment.center,
            ),

            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                Container(
                  width: 100,
                  height: 50,
                  color: const Color(0xFF0000FF),
                  child: Text(Tag.a.text),
                ),
              ],
            ),
            child: const AnchorButton(Tag.anchor),
          ),
        );
      }

      await tester.pumpWidget(buildApp());
      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      // Anchor position is fixed.
      final ui.Rect anchorRect = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));

      for (final alignment in alignments) {
        await tester.pumpWidget(buildApp(alignment: alignment));
        final ui.Rect overlay = tester.getRect(find.widgetWithText(Container, Tag.a.text).first);
        expect(
          alignment.resolve(TextDirection.ltr).withinRect(anchorRect),
          overlay.center,
          reason:
              'Anchor alignment: $alignment \n'
              'Menu rect: $overlay \n',
        );
      }
    });

    testWidgets('RTL alignment', (WidgetTester tester) async {
      Widget buildApp({AlignmentGeometry? alignment}) {
        return App(
          textDirection: TextDirection.rtl,
          BaseMenu(
            positionDelegate: DefaultBaseMenuPositioningDelegate(
              anchorAlignment: alignment,
              menuAlignment: Alignment.center,
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                Container(
                  width: 100,
                  height: 50,
                  color: const Color(0xFF0000FF),
                  child: Text(Tag.a.text),
                ),
              ],
            ),
            child: const AnchorButton(Tag.anchor),
          ),
        );
      }

      await tester.pumpWidget(buildApp());
      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      // Anchor position is fixed.
      final ui.Rect anchorRect = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));

      for (final alignment in alignments) {
        await tester.pumpWidget(buildApp(alignment: alignment));
        final ui.Rect overlay = tester.getRect(find.widgetWithText(Container, Tag.a.text).first);
        expect(
          alignment.resolve(TextDirection.rtl).withinRect(anchorRect),
          overlay.center,
          reason:
              'Anchor alignment: $alignment \n'
              'Menu rect: $overlay \n',
        );
      }
    });

    testWidgets('LTR menu alignment', (WidgetTester tester) async {
      const size = Size(800, 600);
      await changeSurfaceSize(tester, size);

      Widget buildApp({AlignmentGeometry? alignment}) {
        return App(
          BaseMenu(
            positionDelegate: DefaultBaseMenuPositioningDelegate(
              anchorAlignment: Alignment.center,
              menuAlignment: alignment,
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                Container(
                  width: 100,
                  height: 50,
                  alignment: Alignment.center,
                  color: const Color(0xFF0000FF),
                  child: Text(Tag.a.text),
                ),
              ],
            ),
            child: const AnchorButton(Tag.anchor),
          ),
        );
      }

      await tester.pumpWidget(buildApp());
      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      for (final alignment in alignments) {
        for (double y = -2; y <= 2; y += 1) {
          await tester.pumpWidget(buildApp(alignment: alignment));
          final ui.Rect overlay = tester.getRect(find.widgetWithText(Container, Tag.a.text).first);

          expect(
            alignment.resolve(TextDirection.ltr).withinRect(overlay),
            size.center(Offset.zero),
            reason:
                'Menu alignment: $alignment \n'
                'Menu rect: $overlay \n',
          );
        }
      }
    });

    testWidgets('RTL menu alignment', (WidgetTester tester) async {
      const size = Size(800, 600);
      await changeSurfaceSize(tester, size);
      Widget buildApp({AlignmentGeometry? alignment}) {
        return App(
          textDirection: TextDirection.rtl,
          BaseMenu(
            positionDelegate: DefaultBaseMenuPositioningDelegate(
              anchorAlignment: Alignment.center,
              menuAlignment: alignment,
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                Container(
                  width: 100,
                  height: 50,
                  color: const Color(0xFF0000FF),
                  child: Text(Tag.a.text),
                ),
              ],
            ),
            child: const AnchorButton(Tag.anchor),
          ),
        );
      }

      await tester.pumpWidget(buildApp());
      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      for (final alignment in alignments) {
        await tester.pumpWidget(buildApp(alignment: alignment));
        final ui.Rect overlay = tester.getRect(find.widgetWithText(Container, Tag.a.text).first);
        expect(
          alignment.resolve(TextDirection.rtl).withinRect(overlay),
          size.center(Offset.zero),
          reason:
              'Menu alignment: $alignment \n'
              'Menu rect: $overlay \n',
        );
      }
    });

    testWidgets('LTR menu top-start attaches to anchor bottom-start by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          BaseMenu(
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                Container(width: 100, height: 100, color: const Color(0xFF00FF00)),
              ],
            ),
            child: AnchorButton.small(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      final Offset anchorBottomLeft = tester.getBottomLeft(
        find.widgetWithText(Button, Tag.anchor.text),
      );

      expect(anchorBottomLeft, equals(collectOverlays().first.topLeft));
    });

    testWidgets('RTL menu top-start attaches to anchor bottom-start by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          textDirection: TextDirection.rtl,
          BaseMenu(
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                Container(width: 100, height: 100, color: const Color(0xFF00FF00)),
              ],
            ),
            child: AnchorButton.small(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      final Offset anchorBottomLeft = tester.getBottomLeft(
        find.widgetWithText(Button, Tag.anchor.text),
      );

      expect(anchorBottomLeft, equals(collectOverlays().first.topLeft));
    });

    testWidgets('LTR submenu top-start attaches to anchor top-end by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          BaseMenu(
            menu: ColoredBox(
              color: const Color(0xFFFF00FF),
              child: BaseMenuPanel(
                orientation: Axis.vertical,
                children: <Widget>[
                  BaseMenu(
                    menu: BaseMenuPanel(
                      orientation: Axis.vertical,
                      children: <Widget>[
                        Container(width: 100, height: 100, color: const Color(0xFF00FF00)),
                      ],
                    ),
                    child: AnchorButton.small(Tag.a),
                  ),
                ],
              ),
            ),
            child: AnchorButton.small(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.tap(find.text(Tag.a.text));
      await tester.pump();

      final [ui.Rect menu, ui.Rect submenu] = collectOverlays();
      expect(submenu.topLeft, equals(menu.topRight));
      expect(submenu.bottomRight - menu.topRight, equals(const Offset(100, 100)));
    });

    testWidgets('RTL submenu top-start attaches to anchor top-end by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          textDirection: TextDirection.rtl,
          BaseMenu(
            menu: ColoredBox(
              color: const Color(0xFF0000FF),
              child: BaseMenuPanel(
                orientation: Axis.vertical,
                children: <Widget>[
                  BaseMenu(
                    menu: const ColoredBox(
                      color: Color(0xFFFF00FF),
                      child: BaseMenuPanel(
                        orientation: Axis.vertical,
                        children: <Widget>[SizedBox.square(dimension: 100)],
                      ),
                    ),
                    child: AnchorButton.small(Tag.a),
                  ),
                ],
              ),
            ),
            child: AnchorButton.small(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.tap(find.text(Tag.a.text));
      await tester.pump();

      final [ui.Rect menu, ui.Rect submenu] = collectOverlays();
      expect(submenu.topRight, equals(menu.topLeft));
      expect(submenu.bottomRight - menu.topRight, equals(const Offset(-100, 100)));
    });

    testWidgets('alignmentOffset is directional by default', (WidgetTester tester) async {
      const offset = Offset(24, 33);

      Widget buildApp({
        Offset alignmentOffset = Offset.zero,
        ui.TextDirection textDirection = ui.TextDirection.ltr,
      }) {
        return App(
          textDirection: textDirection,
          BaseMenu(
            positionDelegate: DefaultBaseMenuPositioningDelegate(offset: alignmentOffset),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                Container(
                  width: 250,
                  height: 66,
                  alignment: Alignment.center,
                  color: const Color(0xFF0000FF),
                  child: Text(Tag.a.text),
                ),
              ],
            ),
            child: AnchorButton.small(Tag.anchor),
          ),
        );
      }

      await tester.pumpWidget(buildApp());
      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      final Rect ltrPosition = collectOverlays().first;

      await tester.pumpWidget(buildApp(alignmentOffset: offset));

      final Rect ltrPositionTwo = collectOverlays().first;

      expect(ltrPositionTwo, equals(ltrPosition.shift(offset)));

      await tester.pumpWidget(buildApp(textDirection: ui.TextDirection.rtl));

      final Rect rtlPosition = collectOverlays().first;

      await tester.pumpWidget(
        buildApp(alignmentOffset: offset, textDirection: ui.TextDirection.rtl),
      );

      final Rect rtlPositionTwo = collectOverlays().first;

      expect(rtlPositionTwo, equals(rtlPosition.shift(offset)));
    });

    testWidgets('LTR alignmentOffset', (WidgetTester tester) async {
      const offset = Offset(24, 33);

      Widget buildApp({
        Offset alignmentOffset = Offset.zero,
        AlignmentGeometry anchorAlignment = Alignment.center,
      }) {
        return App(
          BaseMenu(
            // alignment: anchorAlignment,
            // menuAlignment: Alignment.center,
            // alignmentOffset: alignmentOffset,
            positionDelegate: DefaultBaseMenuPositioningDelegate(
              anchorAlignment: anchorAlignment,
              menuAlignment: Alignment.center,
              offset: alignmentOffset,
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                Container(
                  width: 125,
                  height: 66,
                  alignment: Alignment.center,
                  color: const Color(0xFF0000FF),
                  child: Text(Tag.a.text),
                ),
              ],
            ),
            child: AnchorButton.small(Tag.anchor),
          ),
        );
      }

      await tester.pumpWidget(buildApp());

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      final Rect center = collectOverlays().first;

      await tester.pumpWidget(buildApp(alignmentOffset: offset));

      expect(center.shift(offset), equals(collectOverlays().first));

      await tester.pumpWidget(buildApp(alignmentOffset: -offset));

      expect(center.shift(-offset), equals(collectOverlays().first));
    });

    testWidgets('RTL alignmentOffset', (WidgetTester tester) async {
      // Should be the same as LTR alignmentOffset test.
      const offset = Offset(24, 33);

      Widget buildApp({
        Offset alignmentOffset = Offset.zero,
        AlignmentGeometry anchorAlignment = Alignment.center,
      }) {
        return App(
          textDirection: ui.TextDirection.rtl,
          BaseMenu(
            positionDelegate: DefaultBaseMenuPositioningDelegate(
              anchorAlignment: anchorAlignment,
              menuAlignment: Alignment.center,
              offset: alignmentOffset,
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                Container(
                  width: 125,
                  height: 66,
                  alignment: Alignment.center,
                  color: const Color(0xFF0000FF),
                  child: Text(Tag.a.text),
                ),
              ],
            ),
            child: AnchorButton.small(Tag.anchor),
          ),
        );
      }

      await tester.pumpWidget(buildApp());

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      final Rect center = collectOverlays().first;

      await tester.pumpWidget(buildApp(alignmentOffset: offset));

      expect(center.shift(offset), equals(collectOverlays().first));

      await tester.pumpWidget(buildApp(alignmentOffset: -offset));

      expect(center.shift(-offset), equals(collectOverlays().first));
    });

    testWidgets(
      'LTR alignmentOffset.dx does not change when menuAlignment is an AlignmentDirectional',
      (WidgetTester tester) async {
        const offset = Offset(24, 33);

        Widget buildApp({
          AlignmentGeometry alignment = Alignment.center,
          Offset alignmentOffset = Offset.zero,
        }) {
          return App(
            BaseMenu(
              positionDelegate: DefaultBaseMenuPositioningDelegate(
                anchorAlignment: alignment,
                menuAlignment: Alignment.center,
                offset: alignmentOffset,
              ),
              menu: BaseMenuPanel(
                orientation: Axis.vertical,
                children: <Widget>[
                  Container(
                    width: 50,
                    height: 66,
                    color: const Color(0xFF0000FF),
                    child: Text(Tag.a.text),
                  ),
                ],
              ),
              child: const AnchorButton(
                Tag.anchor,
                constraints: BoxConstraints.tightFor(width: 125, height: 66),
              ),
            ),
          );
        }

        await tester.pumpWidget(buildApp());

        await tester.tap(find.text(Tag.anchor.text));
        await tester.pump();

        final Rect center = collectOverlays().first;

        await tester.pumpWidget(buildApp(alignmentOffset: offset));

        final Rect centerOffset = collectOverlays().first;

        // Switching from Alignment.center to AlignmentDirectional.center won't
        // relayout the menu, so pump an empty offset to trigger a relayout.
        await tester.pumpWidget(buildApp());

        await tester.pumpWidget(
          buildApp(alignmentOffset: offset, alignment: AlignmentDirectional.center),
        );

        final Rect centerDirectionalOffset = collectOverlays().first;

        expect(centerOffset, equals(center.shift(offset)));
        expect(centerDirectionalOffset, equals(centerOffset));
      },
    );

    testWidgets('RTL alignmentOffset.dx is negated when alignment is an AlignmentDirectional', (
      WidgetTester tester,
    ) async {
      const offset = Offset(24, 33);

      Widget buildApp({
        AlignmentGeometry alignment = Alignment.center,
        Offset alignmentOffset = Offset.zero,
      }) {
        return App(
          textDirection: ui.TextDirection.rtl,
          BaseMenu(
            controller: controller,
            positionDelegate: DefaultBaseMenuPositioningDelegate(
              anchorAlignment: alignment,
              menuAlignment: Alignment.center,
              offset: alignmentOffset,
              overlayPadding: EdgeInsets.zero,
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                Container(
                  width: 50,
                  height: 66,
                  color: const Color(0xFF0000FF),
                  child: Text(Tag.a.text),
                ),
              ],
            ),
            child: AnchorButton.small(Tag.anchor),
          ),
        );
      }

      await tester.pumpWidget(buildApp());
      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      final Rect center = collectOverlays().first;

      await tester.pumpWidget(buildApp(alignmentOffset: offset));

      final Rect centerOffset = collectOverlays().first;

      // Switching from Alignment.center to AlignmentDirectional.center won't
      // relayout the menu, so pump an empty offset to trigger a relayout.
      await tester.pumpWidget(buildApp());

      await tester.pumpWidget(
        buildApp(alignmentOffset: offset, alignment: AlignmentDirectional.center),
      );

      final Rect centerDirectionalOffset = collectOverlays().first;

      expect(centerOffset, equals(center.shift(offset)));
      expect(centerDirectionalOffset, equals(center.shift(Offset(-offset.dx, offset.dy))));
    });

    testWidgets(
      'RTL alignmentOffset.dx is not negated when menuAlignment is an AlignmentDirectional',
      (WidgetTester tester) async {
        const offset = Offset(24, 33);

        Widget buildApp({
          AlignmentGeometry alignment = Alignment.center,
          Offset alignmentOffset = Offset.zero,
        }) {
          return App(
            textDirection: ui.TextDirection.rtl,
            BaseMenu(
              positionDelegate: DefaultBaseMenuPositioningDelegate(
                anchorAlignment: Alignment.center,
                menuAlignment: alignment,
                offset: alignmentOffset,
                overlayPadding: EdgeInsets.zero,
              ),
              menu: BaseMenuPanel(
                orientation: Axis.vertical,
                children: <Widget>[
                  Container(
                    width: 50,
                    height: 66,
                    color: const Color(0xFF0000FF),
                    child: Text(Tag.a.text),
                  ),
                ],
              ),
              child: AnchorButton.small(Tag.anchor),
            ),
          );
        }

        await tester.pumpWidget(buildApp());

        await tester.tap(find.text(Tag.anchor.text));
        await tester.pump();

        final Rect center = collectOverlays().first;

        await tester.pumpWidget(buildApp(alignmentOffset: offset));

        final Rect centerOffset = collectOverlays().first;

        // Switching from Alignment.center to AlignmentDirectional.center won't
        // relayout the menu, so pump an empty offset to trigger a relayout.
        await tester.pumpWidget(buildApp());

        await tester.pumpWidget(
          buildApp(alignmentOffset: offset, alignment: AlignmentDirectional.center),
        );

        final Rect centerDirectionalOffset = collectOverlays().first;

        expect(centerOffset, equals(center.shift(offset)));
        expect(centerDirectionalOffset, equals(centerOffset));
      },
    );

    testWidgets('LTR constrained and offset menu placement', (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(200, 200));
      const constraints = BoxConstraints.tightFor(width: 100, height: 100);

      await tester.pumpWidget(
        App(
          BaseMenu(
            positionDelegate: const DefaultBaseMenuPositioningDelegate(
              offset: Offset(-100, 100),
              overlayPadding: EdgeInsets.zero,
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              constraints: constraints,
              children: <Widget>[
                BaseMenu(
                  positionDelegate: const DefaultBaseMenuPositioningDelegate(
                    offset: Offset(100, -100),
                    overlayPadding: EdgeInsets.zero,
                  ),
                  menu: BaseMenuPanel(
                    orientation: Axis.vertical,
                    constraints: constraints,
                    children: <Widget>[
                      Container(color: const Color(0xFF0000FF), constraints: constraints),
                    ],
                  ),
                  child: const AnchorButton(Tag.a, constraints: constraints),
                ),
              ],
            ),
            child: const AnchorButton(Tag.anchor, constraints: constraints),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.tap(find.text(Tag.a.text));
      await tester.pump();

      expect(collectOverlays(), const <Rect>[
        Rect.fromLTRB(0.0, 100.0, 100.0, 200.0),
        Rect.fromLTRB(100.0, 0.0, 200.0, 100.0),
      ]);
    });

    testWidgets('RTL constrained and offset menu placement', (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(200, 200));
      const constraints = BoxConstraints.tightFor(width: 100, height: 100);

      await tester.pumpWidget(
        App(
          textDirection: TextDirection.rtl,
          BaseMenu(
            positionDelegate: const DefaultBaseMenuPositioningDelegate(
              offset: Offset(-100, 100),
              overlayPadding: EdgeInsets.zero,
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              constraints: constraints,
              children: <Widget>[
                BaseMenu(
                  positionDelegate: const DefaultBaseMenuPositioningDelegate(
                    offset: Offset(100, -100),
                    overlayPadding: EdgeInsets.zero,
                  ),
                  menu: BaseMenuPanel(
                    orientation: Axis.vertical,
                    constraints: constraints,
                    children: <Widget>[
                      Container(color: const Color(0xFF0000FF), constraints: constraints),
                    ],
                  ),
                  child: const AnchorButton(Tag.a, constraints: constraints),
                ),
              ],
            ),
            child: const AnchorButton(Tag.anchor, constraints: constraints),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.tap(find.text(Tag.a.text));
      await tester.pump();

      expect(collectOverlays(), const <Rect>[
        Rect.fromLTRB(0.0, 100.0, 100.0, 200.0),
        Rect.fromLTRB(0.0, 0.0, 100.0, 100.0),
      ]);
    });

    testWidgets('LTR constrained menu placement with unconstrained crossaxis', (
      WidgetTester tester,
    ) async {
      await changeSurfaceSize(tester, const Size(200, 200));
      const constraints = BoxConstraints.tightFor(width: 300, height: 40);

      await tester.pumpWidget(
        App(
          BaseMenu(
            positionDelegate: const DefaultBaseMenuPositioningDelegate(
              overlayPadding: EdgeInsets.zero,
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                BaseMenu(
                  positionDelegate: const DefaultBaseMenuPositioningDelegate(
                    overlayPadding: EdgeInsets.zero,
                  ),
                  menu: BaseMenuPanel(
                    orientation: Axis.vertical,
                    children: <Widget>[Button.tag(Tag.a.a, constraints: constraints)],
                  ),
                  child: const AnchorButton(Tag.a, constraints: constraints),
                ),
              ],
            ),
            child: const AnchorButton(Tag.anchor, constraints: constraints),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.tap(find.text(Tag.a.text));
      await tester.pump();

      // The (unclipped) menu surface can grow beyond the screen. The left
      // edge should be 0 so that the leading edge (left when LTR) of a menu
      // item is visible.
      expect(collectOverlays(clipped: false), const <Rect>[
        Rect.fromLTRB(0.0, 120.0, 300.0, 160.0),
        Rect.fromLTRB(0.0, 160.0, 300.0, 200.0),
      ]);
    });

    testWidgets('RTL constrained menu placement with unconstrained crossaxis', (
      WidgetTester tester,
    ) async {
      await changeSurfaceSize(tester, const Size(200, 200));
      const constraints = BoxConstraints.tightFor(width: 300, height: 40);

      await tester.pumpWidget(
        App(
          textDirection: TextDirection.rtl,
          BaseMenu(
            positionDelegate: const DefaultBaseMenuPositioningDelegate(
              overlayPadding: EdgeInsets.zero,
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                BaseMenu(
                  positionDelegate: const DefaultBaseMenuPositioningDelegate(
                    overlayPadding: EdgeInsets.zero,
                  ),
                  menu: BaseMenuPanel(
                    orientation: Axis.vertical,
                    children: <Widget>[Button.tag(Tag.a.a, constraints: constraints)],
                  ),
                  child: const AnchorButton(Tag.a, constraints: constraints),
                ),
              ],
            ),
            child: const AnchorButton(Tag.anchor, constraints: constraints),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.tap(find.text(Tag.a.text));
      await tester.pump();

      // The (unclipped) menu surface can grow beyond the screen. The left
      // edge should be negative so that the leading edge (right when RTL) of
      // a menu item is visible.
      expect(collectOverlays(clipped: false), const <Rect>[
        Rect.fromLTRB(-100.0, 120.0, 200.0, 160.0),
        Rect.fromLTRB(-100.0, 160.0, 200.0, 200.0),
      ]);
    });

    testWidgets('LTR constrained menu placement with constrained crossaxis', (
      WidgetTester tester,
    ) async {
      await changeSurfaceSize(tester, const Size(200, 200));
      const constraints = BoxConstraints.tightFor(width: 300, height: 40);

      await tester.pumpWidget(
        App(
          BaseMenu(
            positionDelegate: const DefaultBaseMenuPositioningDelegate(
              overlayPadding: EdgeInsets.zero,
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              constrainCrossAxis: true,
              children: <Widget>[
                BaseMenu(
                  positionDelegate: const DefaultBaseMenuPositioningDelegate(
                    overlayPadding: EdgeInsets.zero,
                  ),
                  menu: BaseMenuPanel(
                    orientation: Axis.vertical,
                    constrainCrossAxis: true,
                    children: <Widget>[Button.tag(Tag.a.a, constraints: constraints)],
                  ),
                  child: const AnchorButton(Tag.a, constraints: constraints),
                ),
              ],
            ),
            child: const AnchorButton(Tag.anchor, constraints: constraints),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.tap(find.text(Tag.a.text));
      await tester.pump();

      // The (unclipped) menu surface will not grow beyond the screen.
      expect(collectOverlays(clipped: false), const <ui.Rect>[
        Rect.fromLTRB(0.0, 120.0, 200.0, 160.0),
        Rect.fromLTRB(0.0, 160.0, 200.0, 200.0),
      ]);
    });

    testWidgets('RTL constrained menu placement with constrained crossaxis', (
      WidgetTester tester,
    ) async {
      await changeSurfaceSize(tester, const Size(200, 200));
      const constraints = BoxConstraints.tightFor(width: 300, height: 40);

      await tester.pumpWidget(
        App(
          textDirection: TextDirection.rtl,
          BaseMenu(
            positionDelegate: const DefaultBaseMenuPositioningDelegate(
              overlayPadding: EdgeInsets.zero,
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              constrainCrossAxis: true,
              children: <Widget>[
                BaseMenu(
                  positionDelegate: const DefaultBaseMenuPositioningDelegate(
                    overlayPadding: EdgeInsets.zero,
                  ),
                  menu: BaseMenuPanel(
                    orientation: Axis.vertical,
                    constrainCrossAxis: true,
                    children: <Widget>[Button.tag(Tag.a.a, constraints: constraints)],
                  ),
                  child: const AnchorButton(Tag.a, constraints: constraints),
                ),
              ],
            ),
            child: const AnchorButton(Tag.anchor, constraints: constraints),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.tap(find.text(Tag.a.text));
      await tester.pump();

      // The (unclipped) menu surface will not grow beyond the screen.
      expect(collectOverlays(clipped: false), const <Rect>[
        Rect.fromLTRB(0.0, 120.0, 200.0, 160.0),
        Rect.fromLTRB(0.0, 160.0, 200.0, 200.0),
      ]);
    });

    testWidgets('Constraints applied to anchor do not affect overlay', (WidgetTester tester) async {
      await tester.pumpWidget(
        App(
          ConstrainedBox(
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            child: BaseMenu(
              menu: BaseMenuPanel(
                orientation: Axis.vertical,
                children: <Widget>[
                  Container(color: const Color(0xFFFF0000), height: 125, width: 200),
                ],
              ),
              child: AnchorButton.small(Tag.anchor),
            ),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      expect(collectOverlays().first, const Rect.fromLTRB(380.0, 320.0, 580.0, 445.0));
    });

    testWidgets('LTR menu position flips to left when overflowing screen right', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          alignment: const Alignment(0.5, 0),
          BaseMenu(
            positionDelegate: const DefaultBaseMenuPositioningDelegate(
              anchorAlignment: Alignment.topLeft,
              menuAlignment: Alignment(-0.75, -0.75),
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                Container(width: 350, height: 100, color: const Color(0x86FF00FF)),
              ],
            ),
            child: AnchorButton.small(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump();

      final [ui.Rect menu] = collectOverlays();
      final ui.Rect anchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));
      expect(const Alignment(0.75, -0.75).withinRect(menu), equals(anchor.topRight));
    });

    testWidgets('RTL menu position flips to left when overflowing screen right', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          textDirection: TextDirection.rtl,
          alignment: const Alignment(0.5, 0),
          BaseMenu(
            positionDelegate: const DefaultBaseMenuPositioningDelegate(
              anchorAlignment: Alignment.topLeft,
              menuAlignment: Alignment(-0.75, -0.75),
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                Container(width: 350, height: 100, color: const Color(0x86FF00FF)),
              ],
            ),
            child: AnchorButton.small(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump();

      final [ui.Rect menu] = collectOverlays();
      final Offset anchorTopRight = tester.getTopRight(
        find.widgetWithText(Button, Tag.anchor.text),
      );
      expect(const Alignment(0.75, -0.75).withinRect(menu), equals(anchorTopRight));
    });

    testWidgets('LTR menu position flips to right when overflowing screen left', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          alignment: const Alignment(-0.5, 0),
          BaseMenu(
            positionDelegate: const DefaultBaseMenuPositioningDelegate(
              anchorAlignment: Alignment.topLeft,
              menuAlignment: Alignment(0.75, -0.75),
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                Container(width: 350, height: 100, color: const Color(0x86FF00FF)),
              ],
            ),
            child: AnchorButton.small(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      final [ui.Rect menu] = collectOverlays();
      final ui.Offset anchorTopRight = tester.getTopRight(
        find.widgetWithText(Button, Tag.anchor.text),
      );
      expect(const Alignment(-0.75, -0.75).withinRect(menu), equals(anchorTopRight));
    });

    testWidgets('RTL menu position flips to right when overflowing screen left', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          textDirection: TextDirection.rtl,
          alignment: const Alignment(-0.5, 0),
          BaseMenu(
            positionDelegate: const DefaultBaseMenuPositioningDelegate(
              anchorAlignment: Alignment.topLeft,
              menuAlignment: Alignment(0.75, -0.75),
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                Container(width: 350, height: 100, color: const Color(0x86FF00FF)),
              ],
            ),
            child: AnchorButton.small(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      final [ui.Rect menu] = collectOverlays();
      final ui.Offset anchorTopRight = tester.getTopRight(
        find.widgetWithText(Button, Tag.anchor.text),
      );
      expect(const Alignment(-0.75, -0.75).withinRect(menu), equals(anchorTopRight));
    });

    testWidgets(
      'Menus that overflow the same screen edge when flipped are placed against that edge',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          App(
            BaseMenu(
              controller: controller,
              positionDelegate: const DefaultBaseMenuPositioningDelegate(
                menuAlignment: Alignment.center,
                overlayPadding: EdgeInsets.zero,
              ),
              menu: BaseMenuPanel(
                orientation: Axis.vertical,
                children: <Widget>[
                  Container(width: 100, height: 100, color: const Color(0x86FF00FF)),
                ],
              ),
              child: const Stack(
                children: <Widget>[Positioned.fill(child: ColoredBox(color: Color(0xff00ff00)))],
              ),
            ),
          ),
        );

        controller.open(position: const Offset(750, 50));
        await tester.pump();

        // Overflow top and right, so the menu should be placed against the top
        // right corner.
        expect(collectOverlays().first, equals(const Rect.fromLTRB(700, 0, 800, 100)));

        controller.open(position: const Offset(50, 550));
        await tester.pump();

        // Overflow bottom and left, so the menu should be placed against the bottom
        // left corner.
        expect(collectOverlays().first, equals(const Rect.fromLTRB(0, 500, 100, 600)));
      },
    );

    testWidgets(
      'Menu attaches to closest vertical edge of anchor when overflowing screen left and right',
      (WidgetTester tester) async {
        await changeSurfaceSize(tester, const Size(200, 200));

        await tester.pumpWidget(
          App(
            // Overlaps the bottom of the anchor by 4px.
            BaseMenu(
              positionDelegate: const DefaultBaseMenuPositioningDelegate(
                offset: Offset(0, -4),
                anchorAlignment: AlignmentDirectional.bottomEnd,
                menuAlignment: AlignmentDirectional.topStart,
              ),
              menu: ColoredBox(
                color: const Color(0xFF0000FF),
                child: BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[
                    // Overlaps the top of the anchor by 4px.
                    BaseMenu(
                      positionDelegate: const DefaultBaseMenuPositioningDelegate(
                        offset: Offset(0, 4),
                        anchorAlignment: AlignmentDirectional.topStart,
                        menuAlignment: AlignmentDirectional.bottomEnd,
                      ),
                      menu: ColoredBox(
                        color: const ui.Color(0xFF00FF77),
                        child: BaseMenuPanel(
                          orientation: Axis.vertical,
                          children: <Widget>[
                            Container(width: 125, height: 30, color: const Color(0xFFFF00FF)),
                          ],
                        ),
                      ),
                      child: const AnchorButton(
                        Tag.a,
                        constraints: BoxConstraints.tightFor(width: 125, height: 30),
                      ),
                    ),
                  ],
                ),
              ),
              child: const AnchorButton(
                Tag.anchor,
                constraints: BoxConstraints.tightFor(width: 125, height: 30),
              ),
            ),
          ),
        );

        await tester.tap(find.text(Tag.anchor.text));
        await tester.pump();
        await tester.tap(find.text(Tag.a.text));
        await tester.pump();

        final Rect anchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));
        final Rect nestedAnchor = tester.getRect(find.widgetWithText(Button, Tag.a.text));

        final List<ui.Rect> overlays = collectOverlays();
        expect(overlays.first.top, equals(anchor.bottom));
        expect(overlays.last.bottom, equals(nestedAnchor.top));
      },
    );

    testWidgets('Menu flips above anchor when overflowing screen bottom', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          alignment: const Alignment(0, 0.5),
          BaseMenu(
            positionDelegate: const DefaultBaseMenuPositioningDelegate(offset: Offset(0, -8)),
            menu: ColoredBox(
              color: const Color(0xFF0000FF),
              child: BaseMenuPanel(
                orientation: Axis.vertical,
                children: <Widget>[
                  Container(width: 225, height: 230, color: const Color(0xFFFF00FF)),
                ],
              ),
            ),
            child: AnchorButton.small(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      final Rect anchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));
      expect(collectOverlays().first.bottom, equals(anchor.top + 8));
    });

    testWidgets('Menu flips below anchor when overflowing screen top', (WidgetTester tester) async {
      await tester.pumpWidget(
        App(
          alignment: const Alignment(0, -0.5),
          BaseMenu(
            positionDelegate: const DefaultBaseMenuPositioningDelegate(
              anchorAlignment: AlignmentDirectional.topStart,
              menuAlignment: AlignmentDirectional.bottomStart,
              offset: Offset(0, -8),
            ),
            menu: ColoredBox(
              color: const Color(0xFF0000FF),
              child: BaseMenuPanel(
                orientation: Axis.vertical,
                children: <Widget>[
                  Container(width: 225, height: 230, color: const Color(0xFFFF00FF)),
                ],
              ),
            ),
            child: AnchorButton.small(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      final Rect anchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));
      expect(collectOverlays().first.top, equals(anchor.bottom + 8));
    });

    testWidgets('AlignmentOffset is reflected across anchor when menu flips', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          alignment: const Alignment(0.8, 0.8),
          BaseMenu(
            positionDelegate: const DefaultBaseMenuPositioningDelegate(
              anchorAlignment: Alignment.center,
              menuAlignment: Alignment.center,
              offset: Offset(200, 200),
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[Container(width: 50, height: 50, color: const Color(0xFFFF00FF))],
            ),
            child: AnchorButton.small(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      final Offset anchorCenter = tester.getCenter(find.widgetWithText(Button, Tag.anchor.text));
      expect(collectOverlays().first.center, equals(anchorCenter - const Offset(200, 200)));
    });

    testWidgets('Alignment is reflected across anchor when menu flips', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          alignment: const AlignmentDirectional(0.95, 0.95),
          BaseMenu(
            positionDelegate: const DefaultBaseMenuPositioningDelegate(
              anchorAlignment: AlignmentDirectional.bottomEnd,
              menuAlignment: Alignment.center,
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[Container(width: 50, height: 50, color: const Color(0xFFFF00FF))],
            ),
            child: AnchorButton.small(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      final Offset anchorTopLeft = tester.getTopLeft(find.widgetWithText(Button, Tag.anchor.text));
      expect(collectOverlays().first.center, equals(anchorTopLeft));
    });

    testWidgets('MenuAlignment is reflected across anchor when menu flips', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          alignment: const AlignmentDirectional(0.95, 0.95),
          BaseMenu(
            positionDelegate: const DefaultBaseMenuPositioningDelegate(
              anchorAlignment: Alignment.center,
              menuAlignment: AlignmentDirectional.topStart,
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[Container(width: 50, height: 50, color: const Color(0xFFFF00FF))],
            ),
            child: AnchorButton.small(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      final Offset anchorCenter = tester.getCenter(find.widgetWithText(Button, Tag.anchor.text));
      expect(collectOverlays().first.bottomLeft, equals(anchorCenter));
    });

    testWidgets(
      'Menus opened with a position apply the positional offset relative to the top left corner of the anchor',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 600));

        Widget buildApp([TextDirection textDirection = TextDirection.ltr]) {
          return App(
            textDirection: textDirection,
            BaseMenu(
              controller: controller,
              positionDelegate: const DefaultBaseMenuPositioningDelegate(
                anchorAlignment: Alignment.topLeft,
                menuAlignment: Alignment.topCenter,
              ),
              menu: BaseMenuPanel(
                orientation: Axis.vertical,
                constraints: const BoxConstraints(),
                children: <Widget>[
                  Container(color: const Color(0xFFFF0000), height: 100, width: 100),
                ],
              ),
              child: Container(width: 100, height: 100, color: const ui.Color(0xFF00FF00)),
            ),
          );
        }

        await tester.pumpWidget(buildApp());

        controller.open();
        await tester.pump();

        final ui.Rect control = collectOverlays().first;

        controller.open(position: const Offset(33, 45));
        await tester.pump();

        expect(collectOverlays().first, control.shift(const Offset(33, 45)));

        // Should not be affected by text direction.
        await tester.pumpWidget(buildApp(TextDirection.rtl));

        expect(collectOverlays().first, control.shift(const Offset(33, 45)));

        controller.open(position: const Offset(45, 75));
        await tester.pump();

        expect(collectOverlays().first, control.shift(const Offset(45, 75)));
      },
    );

    testWidgets('Menus opened with a position ignore `alignmentOffset`', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      await tester.pumpWidget(
        App(
          BaseMenu(
            positionDelegate: const DefaultBaseMenuPositioningDelegate(
              offset: Offset(33, 45),
              anchorAlignment: Alignment.topLeft,
              menuAlignment: Alignment.topCenter,
            ),
            controller: controller,
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              constraints: const BoxConstraints(),
              children: <Widget>[
                Container(color: const Color(0xFFFF0000), height: 100, width: 100),
              ],
            ),
            child: Container(width: 100, height: 100, color: const ui.Color(0xFF00FF00)),
          ),
        ),
      );

      controller.open();
      await tester.pump();

      // Get position with alignmentOffset.
      final ui.Rect control = collectOverlays().first;

      controller.open(position: Offset.zero);
      await tester.pump();

      // Alignment offset should be removed.
      expect(collectOverlays().first, control.shift(const Offset(-33, -45)));
    });

    testWidgets('Menus opened with a position ignore `alignment`', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      await tester.pumpWidget(
        App(
          BaseMenu(
            controller: controller,
            positionDelegate: const DefaultBaseMenuPositioningDelegate(
              anchorAlignment: Alignment.bottomRight,
              menuAlignment: Alignment.topLeft,
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              constraints: const BoxConstraints(),
              children: <Widget>[
                Container(color: const Color(0xFFFF0000), height: 100, width: 100),
              ],
            ),
            child: Container(width: 100, height: 100, color: const ui.Color(0xFF00FF00)),
          ),
        ),
      );
      controller.open();
      await tester.pump();

      // Get position with alignmentOffset.
      final ui.Rect control = collectOverlays().first;

      controller.open(position: Offset.zero);
      await tester.pump();

      // A positioned menu is placed relative to the top left corner of the
      // anchor. The anchor is 100x100, and the alignment is set to
      // bottom-right, so setting the position to
      // Offset.zero should offset the menu by -100 x -100.
      expect(collectOverlays().first, control.shift(const Offset(-100, -100)));
    });

    testWidgets('Menus opened with a position respect the menuAlignment property', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          BaseMenu(
            controller: controller,
            positionDelegate: const DefaultBaseMenuPositioningDelegate(
              anchorAlignment: Alignment.topLeft,
              menuAlignment: Alignment.center,
              padding: EdgeInsets.all(25),
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              constraints: const BoxConstraints(),
              children: <Widget>[
                Container(color: const Color(0xFFFF0000), height: 100, width: 100),
              ],
            ),
            child: Container(width: 100, height: 100, color: const ui.Color(0xFF00FF00)),
          ),
        ),
      );
      controller.open();
      await tester.pump();

      // Get position with alignmentOffset.
      final ui.Rect control = collectOverlays().first;

      controller.open(position: const Offset(100, 100));
      await tester.pump();

      // A positioned menu is placed relative to the top left corner of the
      // anchor. The anchor is 100x100, and the alignment is set to
      // bottom-right, so setting the position to
      // Offset.zero should offset the menu by -100 x -100.
      expect(collectOverlays().first, control.shift(const Offset(100, 100)));
    });

    testWidgets('Menus opened with a position flip relative to an empty rect at `position`', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          BaseMenu(
            controller: controller,
            positionDelegate: const DefaultBaseMenuPositioningDelegate(
              menuAlignment: Alignment.topLeft,
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              constraints: const BoxConstraints(),
              children: <Widget>[
                Container(color: const ui.Color(0xFF2200FF), height: 100, width: 100),
              ],
            ),
            child: const Stack(
              fit: StackFit.expand,
              children: <Widget>[ColoredBox(color: ui.Color(0xFFFFC800))],
            ),
          ),
        ),
      );

      controller.open(position: const Offset(700, 500));
      await tester.pump();

      // The menu should be placed at the `position` argument, and should
      // fit within the overlay without flipping.
      expect(collectOverlays().first, equals(const Offset(700, 500) & const Size(100, 100)));

      // Overflow right and bottom by 50 pixels.
      controller.open(position: const Offset(750, 550));
      await tester.pump();

      // The menu should horizontally and vertically overflow the overlay,
      // leading to the menu surface flipping across the menu position.
      expect(collectOverlays().first, equals(const Offset(650, 450) & const Size(100, 100)));
    });

    testWidgets('Menu vertical padding', (WidgetTester tester) async {
      const paddingColor = Color(0x62000DFF);
      const childColor = Color(0xACFF0080);
      final child = BaseMenu(
        controller: controller,
        positionDelegate: const DefaultBaseMenuPositioningDelegate(
          anchorAlignment: AlignmentDirectional.bottomStart,
          menuAlignment: AlignmentDirectional.topStart,
          padding: EdgeInsets.fromLTRB(0, 5, 0, 3),
        ),
        menu: ColoredBox(
          color: paddingColor,
          child: BaseMenuPanel(
            orientation: Axis.vertical,
            padding: const EdgeInsets.fromLTRB(0, 5, 0, 3),
            children: <Widget>[
              ColoredBox(
                color: childColor,
                child: BaseMenu(
                  positionDelegate: const DefaultBaseMenuPositioningDelegate(
                    anchorAlignment: AlignmentDirectional.topEnd,
                    menuAlignment: AlignmentDirectional.topStart,
                    padding: EdgeInsets.fromLTRB(0, 11, 0, 17),
                  ),
                  menu: ColoredBox(
                    color: paddingColor,
                    child: BaseMenuPanel(
                      orientation: Axis.vertical,
                      padding: const EdgeInsets.fromLTRB(0, 11, 0, 17),
                      children: <Widget>[
                        Container(
                          key: ValueKey<String>(Tag.a.a.text),
                          color: childColor,
                          height: 100,
                          width: 100,
                          child: Text(Tag.a.a.text),
                        ),
                      ],
                    ),
                  ),
                  child: const AnchorButton(Tag.a),
                ),
              ),
            ],
          ),
        ),
        child: AnchorButton.small(Tag.anchor),
      );
      // First, collect measurements without padding.
      await tester.pumpWidget(App(child));

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.tap(find.text(Tag.a.text));
      await tester.pump();

      final Finder anchorFinder = find.widgetWithText(Button, Tag.anchor.text);
      final Finder aFinder = find.widgetWithText(Button, Tag.a.text);
      final Finder aaFinder = find.widgetWithText(Container, Tag.a.a.text);

      var [Rect menu, Rect sub] = collectOverlays();
      ui.Rect anchor = tester.getRect(anchorFinder);
      ui.Rect a = tester.getRect(aFinder);
      ui.Rect aa = tester.getRect(aaFinder.first);

      // Menu padding - top: 5 bottom: 3
      // Submenu padding - top: 11 bottom: 17

      expect(a.top, equals(anchor.bottom));
      expect(a.top - 5, equals(menu.top));
      expect(a.bottom + 3, equals(menu.bottom));

      expect(a.top, equals(aa.top));
      expect(aa.top - 11, equals(sub.top));
      expect(aa.bottom + 17, equals(sub.bottom));

      controller.close();
      await tester.pump();

      // Test flipped menu padding.
      await tester.pumpWidget(App(alignment: const Alignment(0, 0.9), child));

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.tap(find.text(Tag.a.text));
      await tester.pump();

      [menu, sub] = collectOverlays();
      anchor = tester.getRect(anchorFinder);
      a = tester.getRect(aFinder);
      aa = tester.getRect(aaFinder.first);

      expect(a.bottom, equals(anchor.top));
      expect(a.bottom + 3, equals(menu.bottom));
      expect(a.top - 5, equals(menu.top));

      expect(a.bottom, equals(aa.bottom));
      expect(aa.bottom + 17, equals(sub.bottom));
      expect(aa.top - 11, equals(sub.top));
    });

    testWidgets('LTR menu horizontal padding', (WidgetTester tester) async {
      final Finder anchorFinder = find.widgetWithText(Button, Tag.anchor.text);
      final Finder aFinder = find.widgetWithText(Button, Tag.a.text);
      final Finder aaFinder = find.widgetWithText(Container, Tag.a.a.text);

      const paddingColor = Color(0x62000DFF);
      const childColor = Color(0xACFF0080);
      final child = BaseMenu(
        controller: controller,
        positionDelegate: const DefaultBaseMenuPositioningDelegate(
          anchorAlignment: AlignmentDirectional.bottomStart,
          menuAlignment: AlignmentDirectional.topStart,
          padding: EdgeInsetsDirectional.fromSTEB(5, 0, 3, 0),
        ),
        menu: ColoredBox(
          color: paddingColor,
          child: BaseMenuPanel(
            padding: const EdgeInsetsDirectional.fromSTEB(5, 0, 3, 0),

            orientation: Axis.vertical,
            children: <Widget>[
              ColoredBox(
                color: childColor,
                child: BaseMenu(
                  positionDelegate: const DefaultBaseMenuPositioningDelegate(
                    anchorAlignment: AlignmentDirectional.topEnd,
                    menuAlignment: AlignmentDirectional.topStart,
                    padding: EdgeInsetsDirectional.fromSTEB(11, 0, 17, 0),
                  ),
                  menu: ColoredBox(
                    color: paddingColor,
                    child: BaseMenuPanel(
                      orientation: Axis.vertical,
                      padding: const EdgeInsetsDirectional.fromSTEB(11, 0, 17, 0),

                      children: <Widget>[
                        Container(
                          key: ValueKey<String>(Tag.a.a.text),
                          color: childColor,
                          height: 100,
                          width: 100,
                          child: Text(Tag.a.a.text),
                        ),
                      ],
                    ),
                  ),
                  child: const AnchorButton(Tag.a),
                ),
              ),
            ],
          ),
        ),
        child: AnchorButton.small(Tag.anchor),
      );
      // First, collect measurements without padding.
      await tester.pumpWidget(App(child));

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.tap(find.text(Tag.a.text));
      await tester.pump();

      var [Rect menu, Rect sub] = collectOverlays();
      ui.Rect anchor = tester.getRect(anchorFinder);
      ui.Rect a = tester.getRect(aFinder);
      ui.Rect aa = tester.getRect(aaFinder.first);

      // Menu padding - top: 5 bottom: 3
      // Submenu padding - top: 11 bottom: 17

      expect(a.left, equals(anchor.left));
      expect(a.left - 5, equals(menu.left));
      expect(a.right + 3, equals(menu.right));

      expect(a.right, equals(aa.left));
      expect(aa.left - 11, equals(sub.left));
      expect(aa.right + 17, equals(sub.right));

      controller.close();
      await tester.pump();

      // Test flipped menu padding.
      await tester.pumpWidget(App(alignment: const AlignmentDirectional(0.9, 0.0), child));

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.tap(find.text(Tag.a.text));
      await tester.pump();

      [menu, sub] = collectOverlays();
      anchor = tester.getRect(anchorFinder);
      a = tester.getRect(aFinder);
      aa = tester.getRect(aaFinder.first);

      expect(a.right, equals(anchor.right));
      expect(a.right + 3, equals(menu.right));
      expect(a.left - 5, equals(menu.left));

      expect(a.left, equals(aa.right));
      expect(aa.right + 17, equals(sub.right));
      expect(aa.left - 11, equals(sub.left));
    });

    testWidgets('RTL menu horizontal padding', (WidgetTester tester) async {
      const paddingColor = Color(0x62000DFF);
      const childColor = Color(0xACFF0080);

      final Finder anchorFinder = find.widgetWithText(Button, Tag.anchor.text);
      final Finder aFinder = find.widgetWithText(Button, Tag.a.text);
      final Finder aaFinder = find.widgetWithText(Container, Tag.a.a.text);

      final child = BaseMenu(
        controller: controller,
        positionDelegate: const DefaultBaseMenuPositioningDelegate(
          anchorAlignment: AlignmentDirectional.bottomStart,
          menuAlignment: AlignmentDirectional.topStart,
          padding: EdgeInsetsDirectional.fromSTEB(5, 0, 3, 0),
        ),
        menu: ColoredBox(
          color: paddingColor,
          child: BaseMenuPanel(
            orientation: Axis.vertical,
            padding: const EdgeInsetsDirectional.fromSTEB(5, 0, 3, 0),
            children: <Widget>[
              ColoredBox(
                color: childColor,
                child: BaseMenu(
                  positionDelegate: const DefaultBaseMenuPositioningDelegate(
                    anchorAlignment: AlignmentDirectional.topEnd,
                    menuAlignment: AlignmentDirectional.topStart,
                    padding: EdgeInsetsDirectional.fromSTEB(11, 0, 17, 0),
                  ),
                  menu: ColoredBox(
                    color: paddingColor,
                    child: BaseMenuPanel(
                      orientation: Axis.vertical,
                      padding: const EdgeInsetsDirectional.fromSTEB(11, 0, 17, 0),

                      children: <Widget>[
                        Container(
                          key: ValueKey<String>(Tag.a.a.text),
                          color: childColor,
                          height: 100,
                          width: 100,
                          child: Text(Tag.a.a.text),
                        ),
                      ],
                    ),
                  ),
                  child: const AnchorButton(Tag.a),
                ),
              ),
            ],
          ),
        ),
        child: AnchorButton.small(Tag.anchor),
      );
      // First, collect measurements without padding.
      await tester.pumpWidget(App(textDirection: TextDirection.rtl, child));

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.tap(find.text(Tag.a.text));
      await tester.pump();

      var [Rect menu, Rect sub] = collectOverlays();
      ui.Rect anchor = tester.getRect(anchorFinder);
      ui.Rect a = tester.getRect(aFinder);
      ui.Rect aa = tester.getRect(aaFinder.first);

      // Menu padding    - left: 3 right: 5
      // Submenu padding - left: 17 right: 11

      expect(a.right, equals(anchor.right));
      expect(a.right + 5, equals(menu.right));
      expect(a.left - 3, equals(menu.left));

      expect(a.left, equals(aa.right));
      expect(aa.right + 11, equals(sub.right));
      expect(aa.left - 17, equals(sub.left));

      controller.close();
      await tester.pump();

      // Test flipped menu padding.
      await tester.pumpWidget(
        App(
          textDirection: TextDirection.rtl,
          alignment: const AlignmentDirectional(0.9, 0.0),
          child,
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.tap(find.text(Tag.a.text));
      await tester.pump();

      [menu, sub] = collectOverlays();
      anchor = tester.getRect(anchorFinder);
      a = tester.getRect(aFinder);
      aa = tester.getRect(aaFinder.first);

      expect(a.left, equals(anchor.left));
      expect(a.left - 3, equals(menu.left));
      expect(a.right + 5, equals(menu.right));

      expect(a.right, equals(aa.left));
      expect(aa.left - 17, equals(sub.left));
      expect(aa.right + 11, equals(sub.right));
    });

    testWidgets('Menu padding should not overflow screen', (WidgetTester tester) async {
      final Widget menu = BaseMenu(
        controller: controller,
        positionDelegate: const DefaultBaseMenuPositioningDelegate(
          anchorAlignment: AlignmentDirectional.topEnd,
          menuAlignment: AlignmentDirectional.topStart,
          padding: EdgeInsets.only(right: 50, top: 30),
          overlayPadding: EdgeInsets.zero,
        ),
        menu: ColoredBox(
          color: const Color(0x62000DFF),
          child: BaseMenuPanel(
            padding: const EdgeInsets.only(right: 50, top: 30),
            orientation: Axis.vertical,
            children: <Widget>[
              Container(
                key: ValueKey<String>(Tag.a.text),
                color: const Color(0xACFF0080),
                height: 100,
                width: 100,
              ),
            ],
          ),
        ),
        child: AnchorButton.small(Tag.anchor),
      );

      // The menu should fit in the top-right corner of the screen, with no
      // additional space to the right or top.
      await tester.pumpWidget(
        App(Stack(children: <Widget>[Positioned(top: 30, right: 150, child: menu)])),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      final Offset anchorTopRight = tester.getTopRight(
        find.widgetWithText(Button, Tag.anchor.text),
      );
      final Offset menuTopLeft = tester.getTopLeft(find.byKey(ValueKey<String>(Tag.a.text)));

      // Menu should not overflow the screen
      expect(menuTopLeft, equals(anchorTopRight));

      controller.close();
      await tester.pump();

      // Reduce the amount of space available to the menu by (1px, 1px).
      await tester.pumpWidget(
        App(Stack(children: <Widget>[Positioned(top: 29, right: 149, child: menu)])),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      final Offset anchorTopLeft = tester.getTopLeft(find.widgetWithText(Button, Tag.anchor.text));
      final Offset menuTopRight = tester.getTopRight(find.byKey(ValueKey<String>(Tag.a.text)));

      // Menu overflowed the screen, so it should be placed at the top left
      // corner of the anchor.
      expect(menuTopRight - const Offset(0, 1), equals(anchorTopLeft));
    });

    testWidgets('LTR app and anchor padding', (WidgetTester tester) async {
      // Out of App:
      //    - overlay position affected
      //    - anchor position affected
      // In App:
      //    - anchor position affected
      //
      // Padding inside App DOES NOT affect the overlay position but
      // DOES affect the anchor position.
      await changeSurfaceSize(tester, const Size(400, 400));

      Widget buildApp({
        required EdgeInsetsGeometry appPadding,
        required EdgeInsetsGeometry anchorPadding,
      }) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Padding(
            padding: appPadding,
            child: App(
              alignment: AlignmentDirectional.topStart,
              Padding(
                padding: anchorPadding,
                child: BaseMenu(
                  positionDelegate: const DefaultBaseMenuPositioningDelegate(
                    anchorAlignment: AlignmentDirectional.topStart,
                    menuAlignment: AlignmentDirectional.bottomEnd,
                  ),
                  menu: BaseMenuPanel(
                    orientation: Axis.vertical,
                    children: <Widget>[
                      BaseMenu(
                        menu: BaseMenuPanel(
                          orientation: Axis.vertical,
                          children: <Widget>[Button.tag(Tag.a.a)],
                        ),
                        child: AnchorButton.small(Tag.a),
                      ),
                    ],
                  ),
                  child: AnchorButton.small(Tag.anchor),
                ),
              ),
            ),
          ),
        );
      }

      // First, collect measurements without padding.
      await tester.pumpWidget(
        buildApp(appPadding: EdgeInsets.zero, anchorPadding: EdgeInsets.zero),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.tap(find.text(Tag.a.text));
      await tester.pump();
      await tester.tap(find.text(Tag.a.a.text));
      await tester.pump();

      final Rect anchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));
      final [Rect first, Rect second] = collectOverlays();

      await tester.pumpWidget(
        buildApp(
          appPadding: const EdgeInsetsDirectional.fromSTEB(31, 7, 43, 0),
          anchorPadding: const EdgeInsetsDirectional.fromSTEB(64, 50, 17, 0),
        ),
      );

      final [Rect firstPadded, Rect secondPadded] = collectOverlays();
      final Rect paddedAnchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));

      expect(paddedAnchor, equals(anchor.shift(const Offset(31 + 64, 7 + 50))));

      // Hits padding on top/left
      expect(firstPadded, equals(first.shift(const Offset(31, 7))));

      // Hits padding on top/right
      expect(secondPadded, equals(second.shift(const Offset(-43, 7))));
    });

    testWidgets('RTL app and anchor padding', (WidgetTester tester) async {
      // Out of App:
      //    - overlay position affected
      //    - anchor position affected
      // In App:
      //    - anchor position affected
      //
      // Padding inside App DOES NOT affect the overlay position but
      // DOES affect the anchor position.

      // First, collect measurements without padding.
      Widget buildApp({
        required EdgeInsetsGeometry appPadding,
        required EdgeInsetsGeometry anchorPadding,
      }) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: appPadding,
            child: App(
              alignment: AlignmentDirectional.topStart,
              Padding(
                padding: anchorPadding,
                child: BaseMenu(
                  positionDelegate: const DefaultBaseMenuPositioningDelegate(
                    anchorAlignment: AlignmentDirectional.topStart,
                    menuAlignment: AlignmentDirectional.bottomEnd,
                  ),
                  menu: BaseMenuPanel(
                    orientation: Axis.vertical,
                    children: <Widget>[
                      BaseMenu(
                        menu: BaseMenuPanel(
                          orientation: Axis.vertical,
                          children: <Widget>[Button.tag(Tag.a.a)],
                        ),
                        child: AnchorButton.small(Tag.a),
                      ),
                    ],
                  ),
                  child: AnchorButton.small(Tag.anchor),
                ),
              ),
            ),
          ),
        );
      }

      // First, collect measurements without padding.
      await tester.pumpWidget(
        buildApp(appPadding: EdgeInsets.zero, anchorPadding: EdgeInsets.zero),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.tap(find.text(Tag.a.text));
      await tester.pump();
      await tester.tap(find.text(Tag.a.a.text));
      await tester.pump();

      final Rect anchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));
      final [Rect first, Rect second] = collectOverlays();

      // Next, collect measurements with padding.
      await tester.pumpWidget(
        buildApp(
          appPadding: const EdgeInsetsDirectional.fromSTEB(31, 7, 43, 0),
          anchorPadding: const EdgeInsetsDirectional.fromSTEB(64, 50, 17, 0),
        ),
      );

      final [Rect menuPadded, Rect subPadded] = collectOverlays();
      final Rect anchorPadded = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));

      expect(anchorPadded, equals(anchor.shift(const Offset(-31 - 64, 7 + 50))));
      expect(menuPadded, equals(first.shift(const Offset(43, 7))));
      expect(subPadded, equals(second.shift(const Offset(43, 7))));
    });

    testWidgets('LTR overlay padding', (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(800, 600));
      const overlayPadding = EdgeInsetsDirectional.fromSTEB(21, 11, 650, 400);

      // Padding should stack
      await tester.pumpWidget(
        App(
          textDirection: TextDirection.ltr,
          BaseMenu(
            controller: controller,
            positionDelegate: const DefaultBaseMenuPositioningDelegate(
              overlayPadding: overlayPadding,
            ),
            menu: Container(
              key: Tag.a.key,
              constraints: BoxConstraints.tight(const Size(200, 200)),
              color: const ui.Color(0xFF007AFF),
            ),
            child: Container(
              padding: overlayPadding - const EdgeInsetsDirectional.all(2),
              color: const ui.Color(0xFFFF9500),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      controller.open(position: Offset.zero);
      await tester.pump();
      await tester.pumpAndSettle();

      final Rect overlay = tester.getRect(find.byKey(Tag.a.key));

      expect(
        overlay.topLeft,
        offsetMoreOrLessEquals(Offset(overlayPadding.start, overlayPadding.top), epsilon: 0.01),
      );

      expect(overlay.size, sizeCloseTo(const Size(129, 189), 0.01));
    });

    testWidgets('RTL overlay padding', (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(800, 600));
      const overlayPadding = EdgeInsetsDirectional.fromSTEB(21, 11, 650, 400);

      // Padding should stack
      await tester.pumpWidget(
        App(
          textDirection: TextDirection.rtl,
          BaseMenu(
            controller: controller,
            positionDelegate: const DefaultBaseMenuPositioningDelegate(
              overlayPadding: overlayPadding,
            ),
            menu: Container(
              key: Tag.a.key,
              constraints: BoxConstraints.tight(const Size(200, 200)),
              color: const ui.Color(0xFF007AFF),
            ),
            child: Container(
              padding: overlayPadding - const EdgeInsetsDirectional.all(2),
              color: const ui.Color(0xFFFF9500),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      controller.open(position: Offset.zero);
      await tester.pump();
      await tester.pumpAndSettle();

      final Rect overlay = tester.getRect(find.byKey(Tag.a.key));

      expect(
        overlay.topLeft,
        offsetMoreOrLessEquals(
          Offset(800 - (overlayPadding.start + 129), overlayPadding.top),
          epsilon: 0.1,
        ),
      );

      expect(overlay.size, sizeCloseTo(const Size(129, 189), 0.01));
    });

    testWidgets('App and overlay padding', (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(800, 600));
      const appPadding = EdgeInsetsDirectional.fromSTEB(31, 7, 27, 50);
      const overlayPadding = EdgeInsetsDirectional.fromSTEB(21, 11, 600, 400);

      // Overlay padding should stack with App padding
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            color: const ui.Color(0xFFF2F2F7),
            padding: appPadding,
            child: App(
              textDirection: TextDirection.ltr,
              BaseMenu(
                controller: controller,
                positionDelegate: const DefaultBaseMenuPositioningDelegate(
                  overlayPadding: overlayPadding,
                ),
                menu: Container(
                  key: Tag.a.key,
                  constraints: BoxConstraints.tight(const Size(200, 200)),
                  color: const ui.Color(0xFF007AFF),
                ),
                child: Container(
                  padding: overlayPadding - const EdgeInsetsDirectional.all(2),
                  color: const ui.Color(0xFFFF9500),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      );

      controller.open(position: Offset.zero);
      await tester.pump();
      await tester.pumpAndSettle();

      final Rect overlay = tester.getRect(find.byKey(Tag.a.key));
      expect(
        overlay.topLeft,
        offsetMoreOrLessEquals(
          Offset(appPadding.start + overlayPadding.start, appPadding.top + overlayPadding.top),
          epsilon: 0.01,
        ),
      );

      expect(overlay.size, sizeCloseTo(const Size(121, 132), 0.01));
    });

    testWidgets('App and anchor padding', (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(800, 600));

      // Out of App:
      //    - overlay position affected
      //    - anchor position affected
      // In App:
      //    - anchor position affected
      //
      // Padding inside the App DOES NOT affect the overlay position but
      // DOES affect the anchor position.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            color: const ui.Color(0xFFF2F2F7),
            padding: const EdgeInsets.fromLTRB(31, 7, 550, 0),
            child: App(
              alignment: Alignment.topLeft,
              Container(
                color: const ui.Color(0xFFC7C7CC),
                padding: const EdgeInsets.fromLTRB(21, 11, 17, 0),
                child: BaseMenu(
                  positionDelegate: const DefaultBaseMenuPositioningDelegate(
                    overlayPadding: EdgeInsets.zero,
                  ),
                  menu: Container(
                    key: Tag.a.key,
                    color: const Color(0xFF007AFF),
                    constraints: const BoxConstraints.tightFor(width: 250, height: 250),
                  ),
                  child: const AnchorButton(
                    Tag.anchor,
                    constraints: BoxConstraints.tightFor(width: 125, height: 50),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pumpAndSettle();

      final Offset overlay = tester.getTopLeft(find.byKey(Tag.a.key));
      final Offset anchor = tester.getTopLeft(find.widgetWithText(AnchorButton, Tag.anchor.text));

      expect(anchor, offsetMoreOrLessEquals(const Offset(31 + 21, 7 + 11), epsilon: 0.01));
      expect(overlay, offsetMoreOrLessEquals(const Offset(31, 7 + 11 + 50), epsilon: 0.01));
    });

    testWidgets('LTR nested menu placement', (WidgetTester tester) async {
      var children = <Widget>[Container(height: 600, width: 50, color: const Color(0xFF0000FF))];
      var layers = 5;
      while (layers-- > 0) {
        children = <Widget>[
          for (int index = 0; index < 4; index++)
            Button.text(
              "${'Sub' * layers}menu $index",
              constraints: const BoxConstraints(maxHeight: 30),
            ),
          BaseMenu(
            positionDelegate: const DefaultBaseMenuPositioningDelegate(
              anchorAlignment: AlignmentDirectional.topEnd,
              menuAlignment: AlignmentDirectional.topStart,
              padding: EdgeInsetsDirectional.fromSTEB(0.5, 4, 1, 6),
              offset: Offset(-1, 0),
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              constraints: BoxConstraints(minWidth: 125 + 75.0 * layers),
              children: children,
            ),
            child: AnchorButton(
              Tag.values[layers % Tag.values.length],
              constraints: const BoxConstraints(maxHeight: 30),
            ),
          ),
        ];
      }
      await tester.pumpWidget(
        App(
          alignment: AlignmentDirectional.topStart,
          BaseMenu(
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              constraints: const BoxConstraints(maxWidth: 150),
              children: children,
            ),
            child: AnchorButton.small(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.tap(find.text(Tag.a.text));
      await tester.pump();
      await tester.tap(find.text(Tag.b.text));
      await tester.pump();
      await tester.tap(find.text(Tag.c.text));
      await tester.pump();
      await tester.tap(find.text(Tag.d.text));
      await tester.pump();
      await tester.tap(find.text(Tag.e.text));
      await tester.pump();

      expect(collectOverlays(), const <Rect>[
        Rect.fromLTRB(0.0, 30.0, 109.0, 181.0),
        Rect.fromLTRB(107.0, 146.5, 259.5, 307.5),
        Rect.fromLTRB(256.5, 267.0, 456.5, 428.0),
        Rect.fromLTRB(453.5, 387.5, 728.5, 548.5),
        Rect.fromLTRB(106.5, 387.0, 456.5, 548.0),
        Rect.fromLTRB(375.0, 0.0, 800.0, 600.0),
      ]);
    });

    testWidgets('RTL nested menu placement', (WidgetTester tester) async {
      var children = <Widget>[Container(height: 600, width: 50, color: const Color(0xFF0000FF))];
      var layers = 5;
      while (layers-- > 0) {
        children = <Widget>[
          for (int index = 0; index < 4; index++)
            Button.text(
              "${'Sub' * layers}menu $index",
              constraints: const BoxConstraints(maxHeight: 30),
            ),
          BaseMenu(
            positionDelegate: const DefaultBaseMenuPositioningDelegate(
              anchorAlignment: AlignmentDirectional.topEnd,
              padding: EdgeInsetsDirectional.fromSTEB(0.5, 4, 1, 6),
              offset: Offset(-1, 0),
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              constraints: BoxConstraints(minWidth: 125 + 75.0 * layers),
              children: children,
            ),
            child: AnchorButton(
              Tag.values[layers % Tag.values.length],
              constraints: const BoxConstraints(maxHeight: 30),
            ),
          ),
        ];
      }
      await tester.pumpWidget(
        App(
          textDirection: TextDirection.rtl,
          alignment: AlignmentDirectional.topStart,
          BaseMenu(
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              constraints: const BoxConstraints(maxWidth: 150),
              children: children,
            ),
            child: AnchorButton.small(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.tap(find.text(Tag.a.text));
      await tester.pump();
      await tester.tap(find.text(Tag.b.text));
      await tester.pump();
      await tester.tap(find.text(Tag.c.text));
      await tester.pump();
      await tester.tap(find.text(Tag.d.text));
      await tester.pump();
      await tester.tap(find.text(Tag.e.text));
      await tester.pump();

      expect(collectOverlays(), const <Rect>[
        Rect.fromLTRB(691.0, 30.0, 800.0, 181.0),
        Rect.fromLTRB(540.5, 146.5, 693.0, 307.5),
        Rect.fromLTRB(343.5, 267.0, 543.5, 428.0),
        Rect.fromLTRB(71.5, 387.5, 346.5, 548.5),
        Rect.fromLTRB(343.5, 387.0, 693.5, 548.0),
        Rect.fromLTRB(0.0, 0.0, 425.0, 600.0),
      ]);
    });

    testWidgets('Menu is positioned around display features', (WidgetTester tester) async {
      await tester.pumpWidget(
        App(
          MediaQuery(
            data: const MediaQueryData(
              platformBrightness: Brightness.dark,
              size: Size(800, 600),
              displayFeatures: <ui.DisplayFeature>[
                // A 20-pixel wide vertical display feature, similar to a
                // foldable with a visible hinge. Splits the display into two
                // "virtual screens".
                ui.DisplayFeature(
                  bounds: Rect.fromLTRB(390, 0, 410, 600),
                  type: ui.DisplayFeatureType.cutout,
                  state: ui.DisplayFeatureState.unknown,
                ),
              ],
            ),
            child: ColoredBox(
              color: const Color(0xFF004CFF),
              child: Stack(
                children: <Widget>[
                  // Pink box for visualizing the display feature.
                  Positioned.fromRect(
                    rect: const Rect.fromLTRB(390, 0, 410, 600),
                    child: const ColoredBox(color: Color(0xF7FF2190)),
                  ),
                  Positioned(
                    left: 500,
                    top: 300,
                    child: BaseMenu(
                      positionDelegate: const DefaultBaseMenuPositioningDelegate(
                        anchorAlignment: Alignment.topLeft,
                        menuAlignment: Alignment.topRight,
                      ),
                      menu: const BaseMenuPanel(
                        orientation: Axis.vertical,
                        children: <Widget>[SizedBox(width: 150, height: 50)],
                      ),
                      child: AnchorButton.small(Tag.anchor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      final double menuLeft = collectOverlays().first.left;
      final ui.Rect anchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));

      // Since the display feature splits the display into 2 sub-screens, the
      // menu should be positioned to fit in the second virtual screen.
      expect(menuLeft, equals(anchor.right));
    });

    testWidgets('Menu constraints are applied to menu surface', (WidgetTester tester) async {
      await tester.pumpWidget(
        App(
          BaseMenu(
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              constraints: const BoxConstraints(minWidth: 75, maxHeight: 100),
              children: <Widget>[
                Container(key: Tag.a.key, color: const Color(0xFFFF0000), height: 150, width: 50),
              ],
            ),
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      expect(collectOverlays().first.size, equals(const Size(75, 100)));

      // Height will remain 150 since it's located inside a scrollable.
      expect(tester.getSize(find.byKey(Tag.a.key)), equals(const Size(50, 150)));
    });

    testWidgets('Padding is applied before constraints', (WidgetTester tester) async {
      await tester.pumpWidget(
        App(
          BaseMenu(
            menu: ColoredBox(
              color: const Color(0xFF0000FF),
              child: BaseMenuPanel(
                orientation: Axis.vertical,
                constraints: BoxConstraints.tight(const Size(100, 100)),
                padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 35),
                children: <Widget>[
                  Container(key: Tag.a.key, color: const Color(0xFFFF0000), height: 50, width: 50),
                ],
              ),
            ),
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      expect(tester.getSize(find.byType(BaseMenuPanel)), equals(const Size(100, 100)));
    });

    testWidgets('Menu is positioned in the root overlay when useRootOverlay is true', (
      WidgetTester tester,
    ) async {
      // The menu should not overflow the bottom of the root overlay, so the
      // menu should be placed below the anchor button.
      final entry = OverlayEntry(
        builder: (BuildContext context) {
          return const Positioned(
            bottom: 0,
            child: BaseMenu(
              useRootOverlay: true,
              positionDelegate: DefaultBaseMenuPositioningDelegate(overlayPadding: EdgeInsets.zero),
              menu: ColoredBox(
                color: Color(0xFF0000FF),
                child: BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[
                    BaseMenu(
                      positionDelegate: DefaultBaseMenuPositioningDelegate(
                        anchorAlignment: AlignmentDirectional.bottomStart,
                        menuAlignment: AlignmentDirectional.topStart,
                        overlayPadding: EdgeInsets.zero,
                      ),
                      menu: BaseMenuPanel(
                        orientation: Axis.vertical,
                        children: <Widget>[SizedBox.square(dimension: 100)],
                      ),
                      child: AnchorButton(Tag.a),
                    ),
                  ],
                ),
              ),
              child: AnchorButton(Tag.anchor),
            ),
          );
        },
      );

      // Overlay entries leak if they are not disposed.
      addTearDown(() {
        entry.remove();
        entry.dispose();
      });

      await tester.pumpWidget(
        App(
          Stack(
            children: <Widget>[
              Positioned(
                left: 200,
                top: 200,
                height: 200,
                width: 200,
                child: ColoredBox(
                  color: const Color(0xFFFF0000),
                  child: Overlay(initialEntries: <OverlayEntry>[entry]),
                ),
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.tap(find.text(Tag.a.text));
      await tester.pump();

      final [ui.Rect menu, ui.Rect subMenu] = collectOverlays();
      final Rect anchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));
      final Rect subAnchor = tester.getRect(find.widgetWithText(Button, Tag.a.text));

      expect(menu.topLeft, equals(anchor.bottomLeft));
      expect(subMenu.topLeft, equals(subAnchor.bottomLeft));
    });

    testWidgets(
      'Menu is positioned within the closest ancestor overlay when useRootOverlay is false',
      (WidgetTester tester) async {
        // The menu should overflow the bottom of the nearest ancestor overlay, so
        // the menu should be placed above the anchor button.
        final entry = OverlayEntry(
          builder: (BuildContext context) {
            return const Positioned(
              bottom: 0,
              child: BaseMenu(
                positionDelegate: DefaultBaseMenuPositioningDelegate(
                  overlayPadding: EdgeInsets.zero,
                ),
                menu: ColoredBox(
                  color: Color(0xFF0000FF),
                  child: BaseMenuPanel(
                    orientation: Axis.vertical,
                    children: <Widget>[
                      // Nested menus should be placed in the same overlay as their
                      // parent menu, so this menu should be placed in the nearest
                      // overlay instead of the root overlay.
                      BaseMenu(
                        positionDelegate: DefaultBaseMenuPositioningDelegate(
                          overlayPadding: EdgeInsets.zero,
                          menuAlignment: AlignmentDirectional.topStart,
                          anchorAlignment: AlignmentDirectional.bottomStart,
                        ),
                        useRootOverlay: true,

                        menu: BaseMenuPanel(
                          orientation: Axis.vertical,
                          children: <Widget>[SizedBox.square(dimension: 100)],
                        ),
                        child: AnchorButton(Tag.a),
                      ),
                    ],
                  ),
                ),
                child: AnchorButton(Tag.anchor),
              ),
            );
          },
        );

        // Overlay entries leak if they are not disposed.
        addTearDown(() {
          entry.remove();
          entry.dispose();
        });

        await tester.pumpWidget(
          App(
            Stack(
              children: <Widget>[
                Positioned(
                  left: 200,
                  top: 200,
                  height: 200,
                  width: 200,
                  child: Overlay(initialEntries: <OverlayEntry>[entry]),
                ),
              ],
            ),
          ),
        );

        await tester.tap(find.text(Tag.anchor.text));
        await tester.pump();
        await tester.tap(find.text(Tag.a.text));
        await tester.pump();

        final [ui.Rect menu, ui.Rect subMenu] = collectOverlays();
        final Rect anchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));
        final Rect subAnchor = tester.getRect(find.widgetWithText(Button, Tag.a.text));

        expect(menu.bottomLeft, equals(anchor.topLeft));
        expect(subMenu.bottomLeft, equals(subAnchor.topLeft));
      },
    );
  });
}
