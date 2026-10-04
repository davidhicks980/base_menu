// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:base_menu/base_menu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utilities.dart';

void main() {
  late MenuController controller;

  setUp(() {
    controller = MenuController();
  });

  Future<void> changeSurfaceSize(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
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

  testWidgets("[BaseMenu] MenuController.isOpen is true when a menu's overlay is shown", (
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

  testWidgets('[BaseMenu] MenuController.open() and .close() toggle overlay visibility', (
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

  testWidgets('[BaseMenu] MenuController.closeChildren closes submenu children', (
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

  testWidgets('[BaseMenu] Can only have one open child anchor', (WidgetTester tester) async {
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

  testWidgets('[BaseMenuBar] MenuController.isOpen is true when a descendent menu is open', (
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

  testWidgets('[BaseMenuBar] MenuController.open does nothing', (WidgetTester tester) async {
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

  testWidgets('[BaseMenuBar] MenuController.close closes children', (WidgetTester tester) async {
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

  testWidgets('[BaseMenuBar] MenuController.closeChildren closes children', (
    WidgetTester tester,
  ) async {
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

  testWidgets('[BaseMenuBar] Should only display one open child anchor at a time', (
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
    final overlayController = MenuController();

    final newController = MenuController();
    final newOverlayController = MenuController();

    await tester.pumpWidget(
      App(
        BaseMenuBar(
          controller: controller,
          child: BaseMenu(
            controller: overlayController,
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
    expect(overlayController.isOpen, isTrue);
    expect(newController.isOpen, isFalse);
    expect(newOverlayController.isOpen, isFalse);

    // Swap the controllers.
    await tester.pumpWidget(
      App(
        BaseMenuBar(
          controller: newController,
          child: BaseMenu(
            controller: newOverlayController,
            menu: BaseMenuPanel(orientation: Axis.vertical, children: <Widget>[Text(Tag.a.text)]),
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      ),
    );

    expect(find.text(Tag.a.text), findsOneWidget);
    expect(controller.isOpen, isFalse);
    expect(overlayController.isOpen, isFalse);

    expect(newController.isOpen, isTrue);
    expect(newOverlayController.isOpen, isTrue);

    // Close the new controller.
    newController.close();
    await tester.pump();

    expect(newController.isOpen, isFalse);
    expect(newOverlayController.isOpen, isFalse);
    expect(find.text(Tag.a.text), findsNothing);

    await tester.pumpWidget(
      App(
        BaseMenuBar(
          child: BaseMenu(
            menu: BaseMenuPanel(orientation: Axis.vertical, children: <Widget>[Text(Tag.a.text)]),
            child: const AnchorButton(Tag.inner),
          ),
        ),
      ),
    );

    final innerController = MenuController.maybeOf(tester.element(find.byKey(Tag.inner.key)))!;
    final outerController = MenuController.maybeOf(tester.element(find.byType(BaseMenu)))!;

    expect(innerController, isNot(outerController));
    expect(innerController.isOpen, isFalse);
    expect(outerController.isOpen, isFalse);

    innerController.open();
    await tester.pump();

    expect(innerController.isOpen, isTrue);
    expect(outerController.isOpen, isTrue);

    await tester.pumpWidget(
      App(
        BaseMenuBar(
          controller: controller,
          child: BaseMenu(
            controller: overlayController,
            menu: BaseMenuPanel(orientation: Axis.vertical, children: <Widget>[Text(Tag.a.text)]),
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      ),
    );

    expect(controller.isOpen, isTrue);
    expect(overlayController.isOpen, isTrue);
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

  testWidgets('[BaseMenuBar] uses provided focusNode', (WidgetTester tester) async {
    final node = FocusScopeNode();
    addTearDown(node.dispose);

    await tester.pumpWidget(
      App(
        Column(
          children: [
            BaseMenuBar(
              child: BaseMenuItem<dynamic>(
                onPressed: () {},
                role: null,
                focusNode: node,
                child: Text(Tag.a.text),
              ),
            ),
            BaseControl(onPressed: () {}, autofocus: true, child: Text(Tag.a.text)),
          ],
        ),
      ),
    );

    expect(node.hasFocus, isFalse);

    node.requestFocus();
    await tester.pump();

    expect(node.hasFocus, isTrue);
  });

  testWidgets('[BaseMenuBar] creates internal focusNode if none is provided', (
    WidgetTester tester,
  ) async {
    FocusScopeNode focusScopeNode() {
      final scope = find
          .ancestor(of: find.byKey(Tag.overlay.key), matching: find.byType(FocusScope))
          .first;

      return tester.widget<FocusScope>(scope).focusNode! as FocusScopeNode;
    }

    await tester.pumpWidget(App(BaseMenuBar(child: SizedBox(key: Tag.overlay.key))));

    expect(focusScopeNode(), isNotNull);
  });

  testWidgets('[BaseMenuBar] creates internal focusNode if provided node is removed', (
    WidgetTester tester,
  ) async {
    final node = FocusScopeNode();
    addTearDown(node.dispose);

    FocusScopeNode focusScopeNode() {
      final scope = find
          .ancestor(of: find.byKey(Tag.overlay.key), matching: find.byType(FocusScope))
          .first;

      return tester.widget<FocusScope>(scope).focusNode! as FocusScopeNode;
    }

    await tester.pumpWidget(
      App(
        BaseMenuBar(
          focusScopeNode: node,
          child: SizedBox(key: Tag.overlay.key),
        ),
      ),
    );

    await tester.pumpWidget(App(BaseMenuBar(child: SizedBox(key: Tag.overlay.key))));

    expect(focusScopeNode(), isNotNull);
    expect(focusScopeNode(), isNot(node));
  });

  testWidgets(
    '[BaseMenuBar] does not throw when switching from an external focusNode to internal',
    (WidgetTester tester) async {
      final externalOneNode = FocusScopeNode();
      final externalTwoNode = FocusScopeNode();
      addTearDown(externalOneNode.dispose);
      addTearDown(externalTwoNode.dispose);

      await tester.pumpWidget(
        App(
          BaseMenuBar(
            focusScopeNode: externalOneNode,
            child: SizedBox(key: Tag.overlay.key),
          ),
        ),
      );

      await tester.pumpWidget(
        App(
          BaseMenuBar(
            focusScopeNode: externalTwoNode,
            child: SizedBox(key: Tag.overlay.key),
          ),
        ),
      );

      await tester.pumpWidget(App(BaseMenuBar(child: SizedBox(key: Tag.overlay.key))));
    },
  );

  testWidgets('[BaseMenuBar] disposes of internal focusNode if node is added', (
    WidgetTester tester,
  ) async {
    final node = FocusScopeNode();
    addTearDown(node.dispose);

    FocusScopeNode focusScopeNode() {
      final scope = find
          .ancestor(of: find.byKey(Tag.overlay.key), matching: find.byType(FocusScope))
          .first;

      return tester.widget<FocusScope>(scope).focusNode! as FocusScopeNode;
    }

    await tester.pumpWidget(App(BaseMenuBar(child: SizedBox(key: Tag.overlay.key))));

    final internalNode = focusScopeNode();
    expect(internalNode, isNotNull);
    expect(internalNode, isNot(node));

    await tester.pumpWidget(
      App(
        BaseMenuBar(
          focusScopeNode: node,
          child: SizedBox(key: Tag.overlay.key),
        ),
      ),
    );

    node.requestFocus();
    await tester.pump();

    expect(node.hasFocus, isTrue);
    expect(() => internalNode.addListener(() {}), throwsA(isA<AssertionError>()));
  });

  testWidgets('[BaseMenuBar] disposes internal focusNode when widget is removed', (
    WidgetTester tester,
  ) async {
    FocusScopeNode focusScopeNode() {
      final scope = find
          .ancestor(of: find.byKey(Tag.overlay.key), matching: find.byType(FocusScope))
          .first;

      return tester.widget<FocusScope>(scope).focusNode! as FocusScopeNode;
    }

    await tester.pumpWidget(App(BaseMenuBar(child: SizedBox(key: Tag.overlay.key))));
    final node = focusScopeNode();
    expect(node, isNotNull);
    expect(node.hasFocus, isFalse);

    await tester.pumpWidget(const App(SizedBox()));

    expect(() => node.addListener(() {}), throwsA(isA<AssertionError>()));
  });

  testWidgets('[BaseMenu] updates directionalFocusEdgeBehavior correctly', (
    WidgetTester tester,
  ) async {
    FocusScopeNode focusScopeNode() {
      final scope = find
          .ancestor(of: find.byKey(Tag.overlay.key), matching: find.byType(FocusScope))
          .first;

      return tester.widget<FocusScope>(scope).focusNode! as FocusScopeNode;
    }

    await tester.pumpWidget(
      App(
        BaseMenu(
          controller: controller,
          traversalEdgeBehavior: TraversalEdgeBehavior.leaveFlutterView,
          menu: SizedBox(key: Tag.overlay.key),
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    // Verify initial controller

    // Open menu to verify internal focus scope properties in the overlay
    controller.open();
    await tester.pump();

    final FocusScopeNode scopeNode = focusScopeNode();
    expect(scopeNode.traversalEdgeBehavior, TraversalEdgeBehavior.leaveFlutterView);

    // Update parameters
    await tester.pumpWidget(
      App(
        BaseMenu(
          controller: controller,
          traversalEdgeBehavior: TraversalEdgeBehavior.parentScope,
          menu: SizedBox(key: Tag.overlay.key),
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    expect(scopeNode.traversalEdgeBehavior, TraversalEdgeBehavior.parentScope);

    // Update back to null controller
    await tester.pumpWidget(
      App(
        BaseMenu(
          menu: SizedBox(key: Tag.overlay.key),
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    expect(scopeNode.traversalEdgeBehavior, TraversalEdgeBehavior.closedLoop);
  });

  testWidgets('[BaseMenu] updates key correctly', (WidgetTester tester) async {
    FocusScopeNode focusScopeNode() {
      final scope = find
          .ancestor(of: find.byKey(Tag.overlay.key), matching: find.byType(FocusScope))
          .first;

      return tester.widget<FocusScope>(scope).focusNode! as FocusScopeNode;
    }

    await tester.pumpWidget(
      App(
        BaseMenu(
          key: Tag.a.key,
          controller: controller,
          menu: SizedBox(key: Tag.overlay.key),
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    controller.open();
    await tester.pump();

    FocusScopeNode scopeNode = focusScopeNode();
    expect(scopeNode.debugLabel, contains(Tag.a.key.toString()));

    // Update parameters
    await tester.pumpWidget(
      App(
        BaseMenu(
          key: Tag.b.key,
          controller: controller,
          menu: SizedBox(key: Tag.overlay.key),
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    controller.open();
    await tester.pump();
    scopeNode = focusScopeNode();
    expect(scopeNode.debugLabel, contains(Tag.b.key.toString()));

    // Update back to null key
    await tester.pumpWidget(
      App(
        BaseMenu(
          controller: controller,
          menu: SizedBox(key: Tag.overlay.key),
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    controller.open();
    await tester.pump();
    scopeNode = focusScopeNode();
    expect(scopeNode.debugLabel, equals('BaseMenu FocusScopeNode'));
  });

  testWidgets('BaseSubmenu updates enabled, focusNode, and orientation correctly', (
    WidgetTester tester,
  ) async {
    final focusNodeA = FocusNode(debugLabel: 'A');
    final focusNodeB = FocusNode(debugLabel: 'B');
    final controller = MenuController();

    await tester.pumpWidget(
      App(
        BaseMenu(
          menu: BaseMenuPanel(
            orientation: Axis.vertical,
            children: <Widget>[
              BaseSubmenu(
                focusNode: focusNodeA,
                controller: controller,
                menu: const BaseMenuPanel(
                  orientation: .vertical,
                  children: <Widget>[Text('Submenu Content')],
                ),
                child: Button.tag(Tag.a),
              ),
            ],
          ),
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    // Open root menu to see submenu anchor
    MenuController.maybeOf(tester.element(find.text(Tag.anchor.text)))!.open();
    await tester.pump();

    // Verify initial state
    BaseSubmenu submenu = tester.widget(find.byType(BaseSubmenu));
    expect(submenu.enabled, isTrue);
    expect(submenu.focusNode, focusNodeA);
    expect(submenu.orientation, Axis.vertical);

    // Verify orientation update
    await tester.pumpWidget(
      App(
        BaseMenu(
          menu: BaseMenuPanel(
            orientation: .vertical,
            children: <Widget>[
              BaseSubmenu(
                focusNode: focusNodeA,
                controller: controller,
                orientation: Axis.horizontal,
                menu: const BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[Text('Submenu Content')],
                ),
                child: Button.tag(Tag.a),
              ),
            ],
          ),
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );
    submenu = tester.widget(find.byType(BaseSubmenu));
    expect(submenu.orientation, Axis.horizontal);

    // Verify focusNode update
    await tester.pumpWidget(
      App(
        BaseMenu(
          menu: BaseMenuPanel(
            orientation: Axis.vertical,
            children: <Widget>[
              BaseSubmenu(
                focusNode: focusNodeB,
                controller: controller,
                orientation: Axis.horizontal,
                menu: const BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[Text('Submenu Content')],
                ),
                child: Button.tag(Tag.a),
              ),
            ],
          ),
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );
    submenu = tester.widget(find.byType(BaseSubmenu));
    expect(submenu.focusNode, focusNodeB);

    // Verify enabled update (should close submenu if open and becoming disabled)
    controller.open();
    await tester.pump();
    expect(controller.isOpen, isTrue);

    await tester.pumpWidget(
      App(
        BaseMenu(
          menu: BaseMenuPanel(
            orientation: .vertical,
            children: <Widget>[
              BaseSubmenu(
                focusNode: focusNodeB,
                controller: controller,
                enabled: false,
                orientation: Axis.horizontal,
                menu: const BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[Text('Submenu Content')],
                ),
                child: Button.tag(Tag.a),
              ),
            ],
          ),
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );
    await tester.pump();
    expect(controller.isOpen, isFalse);
  });

  testWidgets('BaseMenuItem updates focusNode correctly', (WidgetTester tester) async {
    final focusNodeA = FocusNode(debugLabel: 'A');
    final focusNodeB = FocusNode(debugLabel: 'B');

    await tester.pumpWidget(
      App(
        BaseMenu(
          menu: BaseMenuPanel(
            orientation: Axis.vertical,
            children: <Widget>[BaseMenuItem<int>(focusNode: focusNodeA, child: const Text('Item'))],
          ),
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    // Open menu
    MenuController.maybeOf(tester.element(find.text(Tag.anchor.text)))!.open();
    await tester.pump();

    BaseMenuItem<int> menuItem = tester.widget(find.byType(BaseMenuItem<int>));
    expect(menuItem.focusNode, focusNodeA);

    // Update focusNode
    await tester.pumpWidget(
      App(
        BaseMenu(
          menu: BaseMenuPanel(
            orientation: .vertical,
            children: <Widget>[BaseMenuItem<int>(focusNode: focusNodeB, child: const Text('Item'))],
          ),
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );
    menuItem = tester.widget(find.byType(BaseMenuItem<int>));
    expect(menuItem.focusNode, focusNodeB);

    // Update back to null
    await tester.pumpWidget(
      const App(
        BaseMenu(
          menu: BaseMenuPanel(children: <Widget>[BaseMenuItem<int>(child: Text('Item'))]),
          child: AnchorButton(Tag.anchor),
        ),
      ),
    );
    menuItem = tester.widget(find.byType(BaseMenuItem<int>));
    expect(menuItem.focusNode, isNull);
  });

  testWidgets('Previous focus is restored on submenu close', (WidgetTester tester) async {
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
  testWidgets('[BaseMenu] Intents are not captured by closed anchor', (WidgetTester tester) async {
    final invokedIntents = <Intent>[];
    final anchorFocusNode = FocusNode();
    addTearDown(anchorFocusNode.dispose);

    await tester.pumpWidget(
      App(
        Actions(
          actions: <Type, Action<Intent>>{
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
          child: BaseMenu(
            menu: BaseMenuPanel(orientation: Axis.vertical, children: <Widget>[Text(Tag.a.text)]),
            child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
          ),
        ),
      ),
    );

    Actions.invoke<NextFocusIntent>(anchorFocusNode.context!, const NextFocusIntent());
    Actions.invoke<PreviousFocusIntent>(anchorFocusNode.context!, const PreviousFocusIntent());
    Actions.invoke<DismissIntent>(anchorFocusNode.context!, const DismissIntent());

    expect(
      invokedIntents,
      equals(const <Intent>[NextFocusIntent(), PreviousFocusIntent(), DismissIntent()]),
    );
  });

  testWidgets('[BaseMenuBar] NextFocusIntent/PreviousFocusIntent are captured by closed anchor', (
    WidgetTester tester,
  ) async {
    final invokedIntents = <Intent>[];
    final anchorFocusNode = FocusNode();
    addTearDown(anchorFocusNode.dispose);

    await tester.pumpWidget(
      App(
        Actions(
          actions: <Type, Action<Intent>>{
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
            child: Focus(focusNode: anchorFocusNode, child: const SizedBox()),
          ),
        ),
      ),
    );

    Actions.invoke<NextFocusIntent>(anchorFocusNode.context!, const NextFocusIntent());
    Actions.invoke<PreviousFocusIntent>(anchorFocusNode.context!, const PreviousFocusIntent());
    Actions.invoke<DismissIntent>(anchorFocusNode.context!, const DismissIntent());

    expect(invokedIntents, equals(const <Intent>[DismissIntent()]));
  });

  testWidgets('Actions that wrap BaseMenu are invoked by both anchor and overlay', (
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

  testWidgets('[BaseMenuBar] Menu panel builder', (WidgetTester tester) async {
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
    final opened = <NestedTag>[];
    final closed = <NestedTag>[];
    final selected = <NestedTag>[];
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
                    onOpen: () {
                      opened.add(Tag.anchor);
                    },
                    onClose: () {
                      closed.add(Tag.anchor);
                    },
                    menu: BaseMenuPanel(
                      orientation: Axis.vertical,
                      children: <Widget>[
                        BaseMenu(
                          consumeOutsideTaps: true,
                          onOpen: () {
                            opened.add(Tag.a);
                          },
                          onClose: () {
                            closed.add(Tag.a);
                          },
                          menu: BaseMenuPanel(
                            orientation: Axis.vertical,
                            children: <Widget>[Text(Tag.a.a.text)],
                          ),
                          child: AnchorButton(
                            Tag.a,
                            onPressed: (tag) {
                              selected.add(Tag.a);
                            },
                          ),
                        ),
                      ],
                    ),
                    child: AnchorButton(
                      Tag.anchor,
                      onPressed: (tag) {
                        selected.add(Tag.anchor);
                      },
                    ),
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

  testWidgets('[BaseMenu] Menus close and do not consume tap when consumesOutsideTap is false', (
    WidgetTester tester,
  ) async {
    final opened = <NestedTag>[];
    final closed = <NestedTag>[];
    final selected = <NestedTag>[];
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
                    onOpen: () {
                      opened.add(Tag.anchor);
                    },
                    onClose: () {
                      closed.add(Tag.anchor);
                    },
                    // ignore: avoid_redundant_argument_values
                    consumeOutsideTaps: false,
                    menu: BaseMenuPanel(
                      orientation: Axis.vertical,
                      children: <Widget>[
                        BaseMenu(
                          onOpen: () {
                            opened.add(Tag.a);
                          },
                          onClose: () {
                            closed.add(Tag.a);
                          },
                          menu: BaseMenuPanel(
                            orientation: Axis.vertical,
                            children: <Widget>[Text(Tag.a.a.text)],
                          ),
                          child: AnchorButton(
                            Tag.a,
                            onPressed: (tag) {
                              selected.add(Tag.a);
                            },
                          ),
                        ),
                      ],
                    ),
                    child: AnchorButton(
                      Tag.anchor,
                      onPressed: (tag) {
                        selected.add(Tag.anchor);
                      },
                    ),
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

  testWidgets('[BaseMenu] diagnostics', (WidgetTester tester) async {
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

  testWidgets('[BaseMenuBar] diagnostics', (WidgetTester tester) async {
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
          menu: BaseMenuPanel(orientation: Axis.vertical, children: <Widget>[Text(Tag.a.text)]),
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

  testWidgets('[BaseMenu] does not affect anchor tab traversal if closed', (
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

    focusNode.requestFocus();
    await tester.pump();
    expect(primaryFocus?.debugLabel, equals(Tag.b.focusNode));

    // Tab on an unopened anchor should move focus to next widget
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(primaryFocus?.debugLabel, equals(Tag.c.focusNode));

    // Move focus back to the anchor
    focusNode.requestFocus();
    await tester.pump();
    expect(primaryFocus?.debugLabel, equals(Tag.b.focusNode));

    // Shift+Tab on unopened anchor should move focus to previous widget
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    expect(primaryFocus?.debugLabel, equals(Tag.a.focusNode));
  });

  testWidgets('[BaseMenu] overlayChildBuilder wraps the menu overlay', (WidgetTester tester) async {
    await tester.pumpWidget(
      App(
        BaseMenu(
          controller: controller,
          overlayChildBuilder: (BuildContext context, Widget child) {
            return ColoredBox(key: Tag.overlay.key, color: const Color(0xFFABCDEF), child: child);
          },
          menu: BaseMenuPanel(orientation: Axis.vertical, children: <Widget>[Text(Tag.a.text)]),
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    // Opening the menu should trigger the overlayChildBuilder.
    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    expect(controller.isOpen, isTrue);

    // Verify that the wrapper widget (Container) is present in the tree.
    expect(find.byKey(Tag.overlay.key), findsOneWidget);

    // Verify that the menu content is a descendant of the wrapper widget.
    expect(
      find.descendant(of: find.byKey(Tag.overlay.key), matching: find.text(Tag.a.text)),
      findsOneWidget,
    );

    // Verify properties of the wrapper widget to ensure it's the correct instance.
    final ColoredBox coloredBox = tester.widget<ColoredBox>(find.byKey(Tag.overlay.key));
    expect(coloredBox.color, const Color(0xFFABCDEF));
  });

  testWidgets('[BaseMenu] tab moves between root menu enclosing scope.', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      App(
        Row(
          children: <Widget>[
            Button.tag(Tag.leading),
            BaseMenu(
              controller: controller,
              menu: Column(children: [Button.tag(Tag.a), Button.tag(Tag.b), Button.tag(Tag.c)]),
              child: const AnchorButton(Tag.anchor, autofocus: true),
            ),
            Button.tag(Tag.trailing),
          ],
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(primaryFocus?.debugLabel, contains(Tag.trailing.focusNode));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pump();

    expect(primaryFocus?.debugLabel, contains(Tag.anchor.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(primaryFocus?.debugLabel, contains(Tag.a.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(controller.isOpen, isFalse);
    expect(primaryFocus?.debugLabel, contains(Tag.trailing.focusNode));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pump();

    expect(primaryFocus?.debugLabel, contains(Tag.anchor.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();

    expect(primaryFocus?.debugLabel, contains(Tag.c.focusNode));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pump();

    expect(primaryFocus?.debugLabel, contains(Tag.leading.focusNode));
    expect(controller.isOpen, isFalse);
  });

  // Menu implementations differ as to whether tabbing traverses a closes a
  // menu or traverses its items. By default, we let the user choose whether
  // to close the menu or traverse its items.
  testWidgets('[BaseMenuBar] Tab moves between root menu enclosing scope.', (
    WidgetTester tester,
  ) async {
    final bFocusNode = FocusNode(debugLabel: Tag.b.focusNode);
    addTearDown(bFocusNode.dispose);
    final bbbFocusNode = FocusNode(debugLabel: Tag.b.b.b.focusNode);
    addTearDown(bbbFocusNode.dispose);
    final controller = MenuController();
    final nestedController = MenuController();
    const buttonConstraints = BoxConstraints.tightFor(width: 60, height: 30);

    await tester.pumpWidget(
      App(
        Row(
          children: <Widget>[
            Button.tag(Tag.leading),
            BaseMenuBar(
              child: BaseMenuPanel(
                children: <Widget>[
                  Button.tag(Tag.a, constraints: buttonConstraints),
                  ConstrainedBox(
                    constraints: buttonConstraints,
                    child: BaseSubmenu(
                      focusNode: bFocusNode,
                      controller: controller,
                      onClose: () {},
                      menu: BaseMenuPanel(
                        children: <Widget>[
                          Button.tag(Tag.b.a),
                          BaseSubmenu(
                            onClose: () {},
                            controller: nestedController,
                            menu: BaseMenuPanel(
                              children: <Widget>[
                                Button.tag(Tag.b.b.a),
                                Button.tag(Tag.b.b.b, focusNode: bbbFocusNode),
                                Button.tag(Tag.b.b.c),
                              ],
                            ),
                            child: SubmenuChild(tag: Tag.b.b, trailing: ''),
                          ),
                          Button.tag(Tag.b.c),
                        ],
                      ),
                      child: const SubmenuChild(tag: Tag.b, trailing: ''),
                    ),
                  ),
                  Button.tag(Tag.c, constraints: buttonConstraints),
                ],
              ),
            ),
            Button.tag(Tag.trailing),
          ],
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(primaryFocus?.debugLabel, contains(Tag.leading.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(primaryFocus?.debugLabel, equals(Tag.a.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(primaryFocus?.debugLabel, equals(Tag.b.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);

    expect(primaryFocus?.debugLabel, equals(Tag.trailing.focusNode));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pump();

    expect(primaryFocus?.debugLabel, equals(Tag.b.focusNode));

    controller.open();
    await tester.pump();
    nestedController.open();
    await tester.pump();
    bbbFocusNode.requestFocus();
    await tester.pump();

    expect(primaryFocus, equals(bbbFocusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(milliseconds: 1));

    expect(primaryFocus?.debugLabel, equals(Tag.trailing.focusNode));
    expect(controller.isOpen, isFalse);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pump();

    expect(primaryFocus?.debugLabel, equals(Tag.b.focusNode));

    controller.open();
    await tester.pump();
    nestedController.open();
    await tester.pump();
    bbbFocusNode.requestFocus();
    await tester.pump();

    expect(primaryFocus?.debugLabel, equals(Tag.b.b.b.focusNode));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pump();

    expect(primaryFocus?.debugLabel, equals(Tag.leading.focusNode));
  });

  testWidgets('Menu closes on view size change', (WidgetTester tester) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    final mediaQueryData = MediaQueryData.fromView(tester.view);

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

    expect(controller.isOpen, isTrue);

    const smallSize = Size(200, 200);
    await changeSurfaceSize(tester, smallSize);
    await tester.pumpWidget(build(smallSize));

    expect(controller.isOpen, isFalse);
  });

  testWidgets('Menu closes on ancestor scroll', (WidgetTester tester) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      App(
        SingleChildScrollView(
          controller: scrollController,
          child: BaseMenu(
            controller: controller,
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

    expect(controller.isOpen, isTrue);

    scrollController.jumpTo(1000);
    await tester.pump();

    expect(controller.isOpen, isFalse);
  });

  testWidgets('Menus do not close on root menu internal scroll', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/122168.
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    const largeButtonConstraints = BoxConstraints.tightFor(width: 200, height: 300);
    final nestedController = MenuController();

    await tester.pumpWidget(
      App(
        SingleChildScrollView(
          controller: scrollController,
          child: Container(
            height: 700,
            alignment: Alignment.topLeft,
            child: BaseMenu(
              controller: controller,
              menu: BaseMenuPanel(
                orientation: Axis.vertical,
                children: <Widget>[
                  BaseMenu(
                    controller: nestedController,
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

    expect(controller.isOpen, isTrue);

    // Hover the first submenu anchor.
    final pointer = TestPointer(1, ui.PointerDeviceKind.mouse);
    await tester.tap(find.text(Tag.a.text));
    await tester.sendEventToBinding(pointer.hover(tester.getCenter(find.text(Tag.a.text))));
    await tester.pump();

    expect(nestedController.isOpen, isTrue);

    // Menus do not close on internal scroll.
    await tester.sendEventToBinding(pointer.scroll(const Offset(0.0, 30.0)));
    await tester.pump();

    expect(controller.isOpen, isTrue);
    expect(nestedController.isOpen, isTrue);

    // Menus close on external scroll.
    scrollController.jumpTo(700);
    await tester.pump();

    expect(controller.isOpen, isFalse);
    expect(nestedController.isOpen, isFalse);
  });

  // Copied from [MenuAnchor] tests.
  //
  // Regression test for https://github.com/flutter/flutter/issues/157606.
  testWidgets('BaseMenu builder rebuilds when isOpen state changes', (WidgetTester tester) async {
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

  testWidgets('onFocusChange is called when focus enters and leaves the menu overlay', (
    WidgetTester tester,
  ) async {
    var focusChanged = false;
    late bool isFocused;
    final buttonFocusNode = FocusNode();
    final anchorFocusNode = FocusNode();
    addTearDown(buttonFocusNode.dispose);
    addTearDown(anchorFocusNode.dispose);

    await tester.pumpWidget(
      App(
        BaseMenu(
          controller: controller,
          onFocusChange: (bool value) {
            focusChanged = true;
            isFocused = value;
          },
          menu: BaseMenuPanel(
            orientation: Axis.vertical,
            children: <Widget>[Button.tag(Tag.a, focusNode: buttonFocusNode)],
          ),
          child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
        ),
      ),
    );

    // Opening the menu should not trigger onFocusChange yet.
    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    expect(controller.isOpen, isTrue);
    expect(focusChanged, isFalse);

    // Requesting focus on a button inside the menu should trigger onFocusChange(true).
    buttonFocusNode.requestFocus();
    await tester.pump();

    expect(focusChanged, isTrue);
    expect(isFocused, isTrue);

    // Closing the menu should trigger onFocusChange(false).
    focusChanged = false;

    anchorFocusNode.requestFocus();
    await tester.pump();

    expect(focusChanged, isTrue);
    expect(isFocused, isFalse);

    focusChanged = false;

    buttonFocusNode.requestFocus();
    await tester.pump();

    expect(focusChanged, isTrue);
    expect(isFocused, isTrue);

    controller.close();
    await tester.pump();

    expect(controller.isOpen, isFalse);
    expect(focusChanged, isTrue);
    expect(isFocused, isFalse);
  });

  testWidgets('BaseMenuBar has correct semantics', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(App(BaseMenuBar(child: Text(Tag.a.text))));
    final node = tester
        .getSemantics(find.byType(BaseMenuBar))
        .debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder)
        .single;

    expect(node.role, equals(SemanticsRole.menuBar));
    expect(node, matchesSemantics(scopesRoute: true));
    handle.dispose();
  });

  testWidgets('BaseMenu overlay has correct semantics', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final controller = MenuController();
    await tester.pumpWidget(
      App(
        BaseMenu(
          overlayChildBuilder: (context, child) {
            return KeyedSubtree(key: Tag.overlay.key, child: child);
          },
          controller: controller,
          menu: Column(children: <Widget>[Text(Tag.a.text), Text(Tag.b.text)]),
          child: Text(Tag.anchor.text),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text(Tag.anchor.text)),
      matchesSemantics(label: Tag.anchor.text),
    );

    controller.open();
    await tester.pump();
    final node = tester
        .getSemantics(find.byKey(Tag.overlay.key))
        .debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder)
        .single;

    expect(node.role, equals(SemanticsRole.menu));
    expect(node, matchesSemantics(scopesRoute: true));

    final children = node
        .debugListChildrenInOrder(.traversalOrder)
        .single
        .debugListChildrenInOrder(.traversalOrder);

    expect(children, [matchesSemantics(label: Tag.a.text), matchesSemantics(label: Tag.b.text)]);

    handle.dispose();
  });

  testWidgets('BaseMenu overlay has correct semantics', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final controller = MenuController();
    await tester.pumpWidget(
      App(
        BaseMenu(
          overlayChildBuilder: (context, child) {
            return KeyedSubtree(key: Tag.overlay.key, child: child);
          },
          semanticProperties: SemanticsProperties(label: Tag.overlay.text),
          controller: controller,
          menu: Column(children: <Widget>[Text(Tag.a.text), Text(Tag.b.text)]),
          child: Text(Tag.anchor.text),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text(Tag.anchor.text)),
      matchesSemantics(label: Tag.anchor.text),
    );

    controller.open();
    await tester.pump();
    final node = tester
        .getSemantics(find.byKey(Tag.overlay.key))
        .debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder)
        .single;

    expect(node.role, equals(SemanticsRole.none));
    expect(node, matchesSemantics(label: Tag.overlay.text));

    handle.dispose();
  });

  group('Aim', () {
    testWidgets('MenuAimInterceptor intercepts diagonal movement to submenu', (
      WidgetTester tester,
    ) async {
      Tag? hoveredItem;
      Widget buildTest(MenuPositioningDelegate positionDelegate) {
        return App(
          BaseMenuBar(
            orientation: .vertical,
            controller: controller,
            child: BaseMenuPanel(
              children: <Widget>[
                BaseMenuItem(
                  key: Tag.a.key,
                  onPressed: () {},
                  onPointerEnter: (_) {
                    hoveredItem = Tag.a;
                  },
                  child: const MenuItemChild(tag: Tag.a),
                ),
                BaseSubmenu(
                  controller: MenuController(),
                  positionDelegate: positionDelegate,
                  menu: Container(
                    key: Tag.overlay.key,
                    color: const Color.fromARGB(255, 0, 229, 255),
                    width: 100,
                    height: 300,
                    child: Text(Tag.b.a.text),
                  ),
                  child: const SubmenuChild(tag: Tag.b),
                ),
                BaseMenuItem(
                  onPressed: () {},
                  onPointerEnter: (_) {
                    hoveredItem = Tag.c;
                  },
                  child: const MenuItemChild(tag: Tag.c),
                ),
              ],
            ),
          ),
        );
      }

      await tester.pumpWidget(
        buildTest(
          const DefaultMenuPositioningDelegate(
            enableAimAssist: true,
            anchorAttachment: Alignment.centerRight,
            menuAttachment: Alignment.centerLeft,
          ),
        ),
      );

      // Hover Submenu Anchor to open it
      final Finder anchorFinder = find.byType(BaseSubmenu).first;
      final Offset anchorCenter = tester.getCenter(anchorFinder);
      final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(anchorCenter);
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.text(Tag.b.a.text), findsOneWidget);

      await moveMouse(
        gesture,
        tester: tester,
        start: anchorCenter,
        end: tester.getCenter(find.byKey(Tag.a.key)),
        duration: const Duration(milliseconds: 50),
        steps: 20,
      );

      await tester.pump(const Duration(milliseconds: 1));

      expect(hoveredItem, equals(Tag.a));
      hoveredItem = null;

      await gesture.moveTo(anchorCenter);
      await tester.pump(const Duration(milliseconds: 1));

      await moveMouse(
        gesture,
        tester: tester,
        start: anchorCenter,
        end: tester.getTopLeft(find.byKey(Tag.overlay.key)) + const Offset(1, 1),
        duration: const Duration(milliseconds: 500),
        steps: 20,
      );

      expect(hoveredItem, isNull);

      await gesture.moveTo(anchorCenter);
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.text(Tag.b.a.text), findsOneWidget);

      await moveMouse(
        gesture,
        tester: tester,
        start: anchorCenter,
        end: tester.getTopRight(find.byKey(Tag.overlay.key)) + const Offset(1, -1),
        duration: const Duration(milliseconds: 500),
        steps: 20,
      );

      await tester.pumpWidget(
        buildTest(
          const DefaultMenuPositioningDelegate(
            enableAimAssist: true,
            anchorAttachment: Alignment.centerLeft,
            menuAttachment: Alignment.centerRight,
          ),
        ),
      );

      final Offset flippedAnchorCenter = tester.getCenter(find.byType(BaseSubmenu));
      await gesture.moveTo(flippedAnchorCenter);
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.text(Tag.b.a.text), findsOneWidget);
      hoveredItem = null;

      await moveMouse(
        gesture,
        tester: tester,
        start: flippedAnchorCenter,
        end: tester.getTopRight(find.byKey(Tag.overlay.key)) + const Offset(-1, 1),
        duration: const Duration(milliseconds: 500),
        steps: 20,
      );

      expect(hoveredItem, isNull);
    });

    testWidgets('MenuAimInterceptor does not intercept movement from overlay to anchor', (
      WidgetTester tester,
    ) async {
      Tag? hoveredItem;
      await tester.pumpWidget(
        App(
          BaseMenuBar(
            orientation: .vertical,
            controller: controller,
            child: BaseMenuPanel(
              children: <Widget>[
                BaseMenuItem(
                  key: Tag.a.key,
                  onPressed: () {},
                  onPointerEnter: (_) {
                    hoveredItem = Tag.a;
                  },
                  child: const MenuItemChild(tag: Tag.a),
                ),
                BaseSubmenu(
                  controller: MenuController(),
                  positionDelegate: const DefaultMenuPositioningDelegate(
                    enableAimAssist: true,
                    anchorAttachment: Alignment.centerRight,
                    menuAttachment: Alignment.centerLeft,
                  ),
                  menu: Container(
                    key: Tag.overlay.key,
                    color: const Color.fromARGB(255, 0, 229, 255),
                    width: 100,
                    height: 300,
                    child: Text(Tag.b.a.text),
                  ),
                  child: const SubmenuChild(tag: Tag.b),
                ),
              ],
            ),
          ),
        ),
      );

      // Hover Submenu Anchor to open it
      final Finder anchorFinder = find.byType(BaseSubmenu).first;
      final Offset anchorCenter = tester.getCenter(anchorFinder);
      final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(anchorCenter);
      await tester.pump(const Duration(milliseconds: 1));
      final Offset start = tester.getTopLeft(find.byKey(Tag.overlay.key)) + const Offset(1, 1);
      await gesture.moveTo(start);
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.text(Tag.b.a.text), findsOneWidget);
      hoveredItem = null;

      await moveMouse(
        gesture,
        tester: tester,
        start: start,
        end: anchorCenter,
        duration: const Duration(milliseconds: 500),
        steps: 20,
      );

      expect(hoveredItem, equals(Tag.a));
    });
  });

  group('MenuEnterIntent', () {
    testWidgets('MenuEnterIntent.focusFirst() opens menu and focuses first item', (
      WidgetTester tester,
    ) async {
      final firstFocusNode = FocusNode();
      addTearDown(firstFocusNode.dispose);

      await tester.pumpWidget(
        App(
          BaseMenu(
            controller: controller,
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                Button.tag(Tag.a, focusNode: firstFocusNode),
                Button.tag(Tag.b),
              ],
            ),
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      );

      expect(controller.isOpen, isFalse);

      final BuildContext anchorContext = tester.element(find.text(Tag.anchor.text));
      Actions.invoke(anchorContext, const EnterMenuIntent.focusFirst());
      await tester.pump(); // Start opening
      await tester.pump(); // Post-frame callback for focus

      expect(controller.isOpen, isTrue);
      expect(firstFocusNode.hasFocus, isTrue);
    });

    testWidgets('MenuEnterIntent.focusLast() opens menu and focuses last item', (
      WidgetTester tester,
    ) async {
      final lastFocusNode = FocusNode();
      addTearDown(lastFocusNode.dispose);

      await tester.pumpWidget(
        App(
          BaseMenu(
            controller: controller,
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                Button.tag(Tag.a),
                Button.tag(Tag.b, focusNode: lastFocusNode),
              ],
            ),
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      );

      expect(controller.isOpen, isFalse);

      final BuildContext anchorContext = tester.element(find.text(Tag.anchor.text));
      Actions.invoke(anchorContext, const EnterMenuIntent.focusLast());
      await tester.pump(); // Start opening
      await tester.pump(); // Post-frame callback for focus

      expect(controller.isOpen, isTrue);
      expect(lastFocusNode.hasFocus, isTrue);
    });

    testWidgets('MenuEnterIntent.focusFirst() on open menu focuses first item', (
      WidgetTester tester,
    ) async {
      final firstFocusNode = FocusNode();
      addTearDown(firstFocusNode.dispose);

      await tester.pumpWidget(
        App(
          BaseMenu(
            controller: controller,
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                Button.tag(Tag.a, focusNode: firstFocusNode),
                Button.tag(Tag.b),
              ],
            ),
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      );

      controller.open();
      await tester.pump();
      expect(controller.isOpen, isTrue);
      expect(firstFocusNode.hasFocus, isFalse);

      final BuildContext anchorContext = tester.element(find.text(Tag.anchor.text));
      Actions.invoke(anchorContext, const EnterMenuIntent.focusFirst());
      await tester.pump();

      expect(firstFocusNode.hasFocus, isTrue);
    });

    testWidgets('MenuEnterIntent.focusLast() on open menu focuses last item', (
      WidgetTester tester,
    ) async {
      final lastFocusNode = FocusNode();
      addTearDown(lastFocusNode.dispose);

      await tester.pumpWidget(
        App(
          BaseMenu(
            controller: controller,
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                Button.tag(Tag.a),
                Button.tag(Tag.b, focusNode: lastFocusNode),
              ],
            ),
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      );

      controller.open();
      await tester.pump();
      expect(controller.isOpen, isTrue);
      expect(lastFocusNode.hasFocus, isFalse);

      final BuildContext anchorContext = tester.element(find.text(Tag.anchor.text));
      Actions.invoke(anchorContext, const EnterMenuIntent.focusLast());
      await tester.pump();

      expect(lastFocusNode.hasFocus, isTrue);
    });
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
      'Focus wraps when traversing with arrow keys on non-Apple platforms',
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
      'Focus does not wrap when traversing with arrow keys on Apple platforms',
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

    testWidgets(
      'default directionalFocusEdgeBehavior behavior matches platform expectations',
      skip: kIsWeb,
      (WidgetTester tester) async {
        const menu = BaseMenu(menu: SizedBox(), child: SizedBox());

        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        expect(menu.effectiveTraversalEdgeBehavior, TraversalEdgeBehavior.closedLoop);

        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        expect(menu.effectiveTraversalEdgeBehavior, TraversalEdgeBehavior.stop);

        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        expect(menu.effectiveTraversalEdgeBehavior, TraversalEdgeBehavior.stop);

        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        expect(menu.effectiveTraversalEdgeBehavior, TraversalEdgeBehavior.closedLoop);

        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets('default directionalFocusEdgeBehavior on web', skip: !kIsWeb, (
      WidgetTester tester,
    ) async {
      const menu = BaseMenu(menu: SizedBox(), child: SizedBox());
      expect(menu.effectiveTraversalEdgeBehavior, TraversalEdgeBehavior.closedLoop);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('directionalFocusEdgeBehavior.closedLoop wraps focus', (WidgetTester tester) async {
      final controller = MenuController();
      await tester.pumpWidget(
        App(
          BaseMenu(
            controller: controller,
            traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[Button.tag(Tag.a), Button.tag(Tag.b), Button.tag(Tag.c)],
            ),
            child: const AnchorButton(Tag.anchor, autofocus: true),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus?.debugLabel, equals(Tag.a.focusNode));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus?.debugLabel, equals(Tag.c.focusNode));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus?.debugLabel, equals(Tag.a.focusNode));
    });

    testWidgets('directionalFocusEdgeBehavior.stop does not wrap focus', (
      WidgetTester tester,
    ) async {
      final controller = MenuController();
      await tester.pumpWidget(
        App(
          BaseMenu(
            controller: controller,
            traversalEdgeBehavior: TraversalEdgeBehavior.stop,
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[Button.tag(Tag.a), Button.tag(Tag.b), Button.tag(Tag.c)],
            ),
            child: const AnchorButton(Tag.anchor, autofocus: true),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus?.debugLabel, equals(Tag.a.focusNode));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus?.debugLabel, equals(Tag.a.focusNode));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus?.debugLabel, equals(Tag.b.focusNode));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus?.debugLabel, equals(Tag.c.focusNode));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
    });

    testWidgets('directionalFocusEdgeBehavior.parentScope escapes to parent scope', (
      WidgetTester tester,
    ) async {
      final controller = MenuController();
      final afterNode = FocusNode(debugLabel: Tag.outside.focusNode);

      await tester.pumpWidget(
        App(
          Column(
            children: [
              BaseMenu(
                controller: controller,
                traversalEdgeBehavior: TraversalEdgeBehavior.parentScope,
                menu: BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[Button.tag(Tag.a)],
                ),
                child: const AnchorButton(Tag.anchor, autofocus: true),
              ),
              Focus(focusNode: afterNode, child: Text(Tag.outside.text)),
            ],
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus?.debugLabel, equals(Tag.a.focusNode));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, afterNode);
    });

    testWidgets('directionalFocusEdgeBehavior.leaveFlutterView escapes to parent scope', (
      WidgetTester tester,
    ) async {
      final controller = MenuController();

      final widget = BaseMenu(
        controller: controller,
        traversalEdgeBehavior: TraversalEdgeBehavior.leaveFlutterView,
        menu: BaseMenuPanel(orientation: Axis.vertical, children: <Widget>[Button.tag(Tag.a)]),
        child: const AnchorButton(Tag.anchor, autofocus: true),
      );

      await tester.pumpWidget(App(widget));

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus?.debugLabel, equals(Tag.a.focusNode));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        equals(widget.debugMenuFocusScopeLabel),
      );
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

    testWidgets('Down key after menu opens focuses the first menu item', (
      WidgetTester tester,
    ) async {
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

    group('Extended Traversal & Interactions', () {
      testWidgets('Keyboard traversal resumes correctly after an item is hovered', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          const App(MenuSystem(layers: [Axis.horizontal, Axis.vertical], autofocus: .a)),
        );

        // Start keyboard tracking
        await expectFocusPath(tester, [(LogicalKeyboardKey.arrowDown, Tag.a.a)]);

        // Manually hover over item 'Tag.a.d'
        final gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
        addTearDown(gesture.removePointer);

        await gesture.addPointer(location: Offset.zero);

        final targetOffset = tester.getCenter(find.text(Tag.a.d.text));

        await gesture.moveTo(targetOffset);
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
          'Submenu [Anchor Hover]: Opens after delay and closes when pointer leaves anchor',
          (WidgetTester tester) async {
            const hoverOpenDelay = Duration(milliseconds: 100);
            const hoverCloseDelay = Duration(milliseconds: 300);

            await tester.pumpWidget(
              App(
                BaseSubmenu(
                  controller: controller,
                  role: null,
                  hoverOpenDelay: hoverOpenDelay,
                  hoverCloseDelay: hoverCloseDelay,
                  menu: BaseMenuPanel(
                    orientation: Axis.vertical,
                    children: <Widget>[
                      Container(
                        width: 200,
                        height: 200,
                        color: const Color(0xFF00FF00),
                        child: Text(Tag.a.text),
                      ),
                    ],
                  ),
                  child: Text(
                    Tag.anchor.text,
                    style: const TextStyle(fontSize: 24, color: Color(0xFFFFFFFF)),
                  ),
                ),
              ),
            );

            final Finder anchorFinder = find.text(Tag.anchor.text);
            final gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
            addTearDown(gesture.removePointer);
            await gesture.addPointer(location: Offset.zero);

            expect(find.text(Tag.a.text), findsNothing);

            await gesture.moveTo(tester.getCenter(anchorFinder));
            await tester.pump();

            expect(find.text(Tag.a.text), findsNothing);

            await tester.pump(hoverOpenDelay);

            expect(find.text(Tag.a.text), findsOneWidget);

            await gesture.moveTo(Offset.zero);
            await tester.pump();

            expect(find.text(Tag.a.text), findsOneWidget);

            await tester.pump(hoverCloseDelay);

            expect(find.text(Tag.a.text), findsNothing);

            await gesture.moveTo(tester.getCenter(anchorFinder));
            await tester.pump();
            await tester.pump(hoverOpenDelay ~/ 2);

            expect(find.text(Tag.a.text), findsNothing);

            await gesture.moveTo(Offset.zero);
            await tester.pump();
            await tester.pump(hoverOpenDelay);

            expect(find.text(Tag.a.text), findsNothing);
          },
        );

        testWidgets(
          'Submenu [Anchor Hover]: Stays open when pointer moves from anchor to submenu',
          (WidgetTester tester) async {
            const hoverOpenDelay = Duration(milliseconds: 100);
            const hoverCloseDelay = Duration(milliseconds: 300);

            await tester.pumpWidget(
              App(
                BaseSubmenu(
                  controller: controller,
                  role: null,
                  onPressed: () {}, // Must be enabled for hover to work.
                  hoverOpenDelay: hoverOpenDelay,
                  hoverCloseDelay: hoverCloseDelay,
                  menu: BaseMenuPanel(
                    orientation: Axis.vertical,
                    children: <Widget>[
                      Container(
                        width: 200,
                        height: 200,
                        color: const Color(0xFF00FF00),
                        child: Text(Tag.a.text),
                      ),
                    ],
                  ),
                  child: Text(
                    Tag.anchor.text,
                    style: const TextStyle(fontSize: 24, color: Color(0xFFFFFFFF)),
                  ),
                ),
              ),
            );

            final Finder anchorFinder = find.text(Tag.anchor.text);
            final gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
            addTearDown(gesture.removePointer);
            await gesture.addPointer(location: Offset.zero);

            expect(find.text(Tag.a.text), findsNothing);

            await gesture.moveTo(tester.getCenter(anchorFinder));
            await tester.pump();
            await tester.pump(hoverOpenDelay);
            await gesture.moveTo(tester.getCenter(find.text(Tag.a.text)));
            await tester.pump();

            expect(find.text(Tag.a.text), findsOneWidget);

            await gesture.moveTo(Offset.zero);
            await tester.pump(hoverCloseDelay);

            expect(find.text(Tag.a.text), findsOneWidget);

            // Move back to anchor to refocus and leave to close the submenu.
            await gesture.moveTo(tester.getCenter(anchorFinder));
            await tester.pump();
            await tester.pump(hoverCloseDelay);

            expect(find.text(Tag.a.text), findsOneWidget);

            await gesture.moveTo(Offset.zero);
            await tester.pump();
            await tester.pump(hoverCloseDelay ~/ 2);

            expect(find.text(Tag.a.text), findsOneWidget);

            await tester.pump(hoverCloseDelay);

            expect(find.text(Tag.a.text), findsNothing);
          },
        );

        testWidgets('Submenu: transitioning between hover and directional traversal', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            const App(
              MenuSystem(layers: [Axis.horizontal, Axis.vertical, Axis.vertical], autofocus: Tag.a),
            ),
          );

          await expectFocusPath(tester, [(LogicalKeyboardKey.arrowDown, Tag.a.a)]);

          final gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
          addTearDown(gesture.removePointer);
          await gesture.addPointer(location: Offset.zero);
          await tester.pump();
          await gesture.moveTo(tester.getCenter(find.text(Tag.a.c.text)));
          await tester.pump(const Duration(milliseconds: 1));

          expect(FocusManager.instance.primaryFocus?.debugLabel, contains(Tag.a.c.focusNode));
          expect(find.text(Tag.a.c.a.text), findsOneWidget);

          await expectFocusPath(tester, [
            (LogicalKeyboardKey.arrowDown, Tag.a.c.a),
            (LogicalKeyboardKey.arrowLeft, Tag.a.c),
          ]);

          expect(find.text(Tag.a.c.a.text), findsNothing);

          await gesture.moveTo(tester.getCenter(find.text(Tag.a.b.text)));
          await tester.pump();

          expect(FocusManager.instance.primaryFocus?.debugLabel, contains(Tag.a.b.focusNode));

          await expectFocusPath(tester, [(LogicalKeyboardKey.arrowUp, Tag.a.a)]);
        });

        testWidgets('Menu: transitioning between hover and directional traversal', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            const App(MenuSystem(layers: [Axis.vertical], autofocus: Tag.anchor, isMenuBar: false)),
          );

          await expectFocusPath(tester, [(LogicalKeyboardKey.arrowDown, Tag.a)]);

          final gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
          addTearDown(gesture.removePointer);
          await gesture.addPointer(location: Offset.zero);
          await gesture.moveTo(tester.getCenter(find.text(Tag.c.text)));
          await tester.pumpAndSettle();

          expect(FocusManager.instance.primaryFocus?.debugLabel, contains(Tag.c.focusNode));

          await expectFocusPath(tester, [(LogicalKeyboardKey.arrowDown, Tag.d)]);
          await gesture.moveTo(tester.getCenter(find.text(Tag.b.text)));
          await tester.pumpAndSettle();

          expect(FocusManager.instance.primaryFocus?.debugLabel, contains(Tag.b.focusNode));

          await expectFocusPath(tester, [(LogicalKeyboardKey.arrowUp, Tag.a)]);
        });
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
    });
  });

  group('Layout', () {
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

    testWidgets('LTR attachment', (WidgetTester tester) async {
      Widget buildApp({AlignmentGeometry? attachment}) {
        return App(
          BaseMenu(
            positionDelegate: DefaultMenuPositioningDelegate(
              anchorAttachment: attachment,
              menuAttachment: Alignment.center,
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
        await tester.pumpWidget(buildApp(attachment: alignment));
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

    testWidgets('RTL attachment', (WidgetTester tester) async {
      Widget buildApp({AlignmentGeometry? attachment}) {
        return App(
          textDirection: TextDirection.rtl,
          BaseMenu(
            positionDelegate: DefaultMenuPositioningDelegate(
              anchorAttachment: attachment,
              menuAttachment: Alignment.center,
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
        await tester.pumpWidget(buildApp(attachment: alignment));
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

    testWidgets('LTR menu attachment', (WidgetTester tester) async {
      const size = Size(800, 600);
      await changeSurfaceSize(tester, size);

      Widget buildApp({AlignmentGeometry? attachment}) {
        return App(
          BaseMenu(
            positionDelegate: DefaultMenuPositioningDelegate(
              anchorAttachment: Alignment.center,
              menuAttachment: attachment,
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
          await tester.pumpWidget(buildApp(attachment: alignment));
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

    testWidgets('RTL menu attachment', (WidgetTester tester) async {
      const size = Size(800, 600);
      await changeSurfaceSize(tester, size);
      Widget buildApp({AlignmentGeometry? attachment}) {
        return App(
          textDirection: TextDirection.rtl,
          BaseMenu(
            positionDelegate: DefaultMenuPositioningDelegate(
              anchorAttachment: Alignment.center,
              menuAttachment: attachment,
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
        await tester.pumpWidget(buildApp(attachment: alignment));
        final ui.Rect overlay = tester.getRect(find.widgetWithText(Container, Tag.a.text).first);
        expect(
          alignment.resolve(TextDirection.rtl).withinRect(overlay),
          size.center(Offset.zero),
          reason:
              'Menu attachment: $alignment \n'
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

      final Offset anchorBottomLeft = tester.getBottomRight(
        find.widgetWithText(Button, Tag.anchor.text),
      );

      expect(anchorBottomLeft, equals(collectOverlays().first.topRight));
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

      final [_, ui.Rect submenu] = collectOverlays();
      expect(submenu.topRight, equals(tester.getTopLeft(find.byKey(Tag.a.key))));
    });

    testWidgets('offset is directional by default', (WidgetTester tester) async {
      const offset = Offset(24, 33);

      Widget buildApp({
        Offset offset = Offset.zero,
        ui.TextDirection textDirection = ui.TextDirection.ltr,
      }) {
        return App(
          textDirection: textDirection,
          BaseMenu(
            positionDelegate: DefaultMenuPositioningDelegate(
              offset: offset,
              anchorAttachment: Alignment.center,
              menuAttachment: Alignment.center,
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                Container(
                  width: 100,
                  height: 100,
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

      await tester.pumpWidget(buildApp(offset: offset));

      final Rect ltrPositionTwo = collectOverlays().first;

      expect(ltrPositionTwo, equals(ltrPosition.shift(offset)));

      await tester.pumpWidget(buildApp(textDirection: ui.TextDirection.rtl));

      final Rect rtlPosition = collectOverlays().first;

      await tester.pumpWidget(buildApp(offset: offset, textDirection: ui.TextDirection.rtl));

      final Rect rtlPositionTwo = collectOverlays().first;

      expect(rtlPositionTwo, equals(rtlPosition.shift(Offset(-offset.dx, offset.dy))));
    });

    testWidgets('LTR offset', (WidgetTester tester) async {
      const offset = Offset(24, 33);

      Widget buildApp({
        Offset offset = Offset.zero,
        AlignmentGeometry anchorAttachment = Alignment.center,
      }) {
        return App(
          BaseMenu(
            positionDelegate: DefaultMenuPositioningDelegate(
              anchorAttachment: anchorAttachment,
              menuAttachment: Alignment.center,
              offset: offset,
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

      await tester.pumpWidget(buildApp(offset: offset));

      expect(center.shift(offset), equals(collectOverlays().first));

      await tester.pumpWidget(buildApp(offset: -offset));

      expect(center.shift(-offset), equals(collectOverlays().first));
    });

    testWidgets('RTL offset with useDirectionalOffset set to false', (WidgetTester tester) async {
      const offset = Offset(24, 33);

      Widget buildApp({
        Offset offset = Offset.zero,
        AlignmentGeometry anchorAttachment = Alignment.center,
      }) {
        return App(
          textDirection: ui.TextDirection.rtl,
          BaseMenu(
            positionDelegate: DefaultMenuPositioningDelegate(
              anchorAttachment: anchorAttachment,
              menuAttachment: Alignment.center,
              offset: offset,
              useDirectionalOffset: false,
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

      await tester.pumpWidget(buildApp(offset: offset));

      expect(center.shift(offset), equals(collectOverlays().first));

      await tester.pumpWidget(buildApp(offset: -offset));

      expect(center.shift(-offset), equals(collectOverlays().first));
    });

    testWidgets('RTL offset', (WidgetTester tester) async {
      const offset = Offset(24, 33);

      Widget buildApp({Offset offset = Offset.zero}) {
        return App(
          textDirection: ui.TextDirection.rtl,
          BaseMenu(
            positionDelegate: DefaultMenuPositioningDelegate(
              anchorAttachment: Alignment.center,
              menuAttachment: Alignment.center,
              offset: offset,
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

      await tester.pumpWidget(buildApp(offset: offset));

      expect(center.shift(Offset(-offset.dx, offset.dy)), equals(collectOverlays().first));

      await tester.pumpWidget(buildApp(offset: -offset));

      expect(center.shift(Offset(offset.dx, -offset.dy)), equals(collectOverlays().first));
    });

    testWidgets('LTR constrained and offset menu placement', (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(200, 200));
      const constraints = BoxConstraints.tightFor(width: 100, height: 100);

      await tester.pumpWidget(
        App(
          BaseMenu(
            onCloseRequest: (hideOverlay) {},
            positionDelegate: const DefaultMenuPositioningDelegate(
              offset: Offset(-100, 100),
              anchorAttachment: .topStart,
              menuAttachment: .topStart,
              overlayPadding: EdgeInsets.zero,
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              constraints: constraints,
              children: <Widget>[
                BaseMenu(
                  onCloseRequest: (hideOverlay) {},
                  positionDelegate: const DefaultMenuPositioningDelegate(
                    offset: Offset(100, -100),
                    overlayPadding: EdgeInsets.zero,
                    anchorAttachment: .topStart,
                    menuAttachment: .topStart,
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
        Rect.fromLTRB(0.0, 0.0, 100.0, 100.0),
        Rect.fromLTRB(100.0, 100.0, 200.0, 200.0),
      ]);
    });

    testWidgets('RTL constrained and offset menu placement', (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(200, 200));
      const constraints = BoxConstraints.tightFor(width: 100, height: 100);

      await tester.pumpWidget(
        App(
          textDirection: TextDirection.rtl,
          BaseMenu(
            positionDelegate: const DefaultMenuPositioningDelegate(
              offset: Offset(-100, 100),
              overlayPadding: EdgeInsets.zero,
              anchorAttachment: .topStart,
              menuAttachment: .topStart,
              useDirectionalOffset: false,
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              constraints: constraints,
              children: <Widget>[
                BaseMenu(
                  positionDelegate: const DefaultMenuPositioningDelegate(
                    offset: Offset(100, -100),
                    overlayPadding: EdgeInsets.zero,
                    anchorAttachment: .topStart,
                    menuAttachment: .topStart,
                    useDirectionalOffset: false,
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
        Rect.fromLTRB(100.0, 0.0, 200.0, 100.0),
        Rect.fromLTRB(0.0, 100.0, 100.0, 200.0),
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
            positionDelegate: const DefaultMenuPositioningDelegate(
              overlayPadding: EdgeInsets.zero,
              edgeBehavior: EdgeBehavior(
                horizontal: EdgeBehaviorStrategy(shift: true, flip: true),
                vertical: EdgeBehaviorStrategy(shift: true, flip: true, constrain: true),
              ),
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                BaseMenu(
                  positionDelegate: const DefaultMenuPositioningDelegate(
                    overlayPadding: EdgeInsets.zero,
                    edgeBehavior: EdgeBehavior(
                      horizontal: EdgeBehaviorStrategy(shift: true, flip: true),
                      vertical: EdgeBehaviorStrategy(shift: true, flip: true, constrain: true),
                    ),
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

      expect(collectOverlays(clipped: false), const <Rect>[
        Rect.fromLTRB(0.0, 120.0, 300.0, 160.0),
        Rect.fromLTRB(0.0, 120.0, 300.0, 160.0),
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
            positionDelegate: const DefaultMenuPositioningDelegate(
              overlayPadding: EdgeInsets.zero,
              useDirectionalOffset: false,
              edgeBehavior: EdgeBehavior(
                horizontal: EdgeBehaviorStrategy(flip: true, shift: true),
                vertical: EdgeBehaviorStrategy(flip: true, shift: true, constrain: true),
              ),
            ),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                BaseMenu(
                  positionDelegate: const DefaultMenuPositioningDelegate(
                    overlayPadding: EdgeInsets.zero,
                    useDirectionalOffset: false,
                    edgeBehavior: EdgeBehavior(
                      horizontal: EdgeBehaviorStrategy(flip: true, shift: true),
                      vertical: EdgeBehaviorStrategy(flip: true, shift: true, constrain: true),
                    ),
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
        Rect.fromLTRB(-100.0, 120.0, 200.0, 160.0),
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
            positionDelegate: const DefaultMenuPositioningDelegate(overlayPadding: EdgeInsets.zero),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                BaseMenu(
                  positionDelegate: const DefaultMenuPositioningDelegate(
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

      // The (unclipped) menu surface will not grow beyond the screen.
      expect(collectOverlays(clipped: false), const <ui.Rect>[
        Rect.fromLTRB(0.0, 120.0, 200.0, 160.0),
        Rect.fromLTRB(0.0, 120.0, 200.0, 160.0),
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
            positionDelegate: const DefaultMenuPositioningDelegate(overlayPadding: EdgeInsets.zero),
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              children: <Widget>[
                BaseMenu(
                  positionDelegate: const DefaultMenuPositioningDelegate(
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

      // The (unclipped) menu surface will not grow beyond the screen.
      expect(collectOverlays(clipped: false), const <Rect>[
        Rect.fromLTRB(0.0, 120.0, 200.0, 160.0),
        Rect.fromLTRB(0.0, 120.0, 200.0, 160.0),
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
      await changeSurfaceSize(tester, const Size(1200, 600));

      await tester.pumpWidget(
        App(
          alignment: const Alignment(0.5, 0),
          BaseMenu(
            positionDelegate: const DefaultMenuPositioningDelegate(
              anchorAttachment: Alignment.center,
              menuAttachment: Alignment(-0.9, -0.9),
            ),
            onCloseRequest: (hideOverlay) {},
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
      ui.Rect anchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));
      expect(const Alignment(-0.9, -0.9).withinRect(menu), equals(anchor.center));

      await changeSurfaceSize(tester, const Size(600, 600));
      await tester.pump();

      final [ui.Rect flippedMenu] = collectOverlays();
      anchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));
      expect(const Alignment(0.9, -0.9).withinRect(flippedMenu), equals(anchor.center));
    });

    testWidgets('RTL menu position flips to left when overflowing screen right', (
      WidgetTester tester,
    ) async {
      await changeSurfaceSize(tester, const Size(1200, 600));

      await tester.pumpWidget(
        App(
          textDirection: .rtl,
          alignment: const Alignment(0.5, 0),
          BaseMenu(
            positionDelegate: const DefaultMenuPositioningDelegate(
              anchorAttachment: Alignment.center,
              menuAttachment: Alignment(-0.9, -0.9),
            ),
            onCloseRequest: (hideOverlay) {},
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
      ui.Rect anchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));
      expect(const Alignment(-0.9, -0.9).withinRect(menu), equals(anchor.center));

      await changeSurfaceSize(tester, const Size(600, 600));
      await tester.pump();

      final [ui.Rect flippedMenu] = collectOverlays();
      anchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));
      expect(const Alignment(0.9, -0.9).withinRect(flippedMenu), equals(anchor.center));
    });

    testWidgets('LTR menu position flips to right when overflowing screen left', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          alignment: const Alignment(-0.5, 0),
          BaseMenu(
            positionDelegate: const DefaultMenuPositioningDelegate(
              anchorAttachment: Alignment.topLeft,
              menuAttachment: Alignment(0.75, -0.75),
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
            positionDelegate: const DefaultMenuPositioningDelegate(
              anchorAttachment: Alignment.topLeft,
              menuAttachment: Alignment(0.75, -0.75),
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
              positionDelegate: const DefaultMenuPositioningDelegate(
                menuAttachment: Alignment.center,
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

    testWidgets('Menu flips above anchor when overflowing screen bottom', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          alignment: const Alignment(0, 0.5),
          BaseMenu(
            positionDelegate: const DefaultMenuPositioningDelegate(offset: Offset(0, -8)),
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
            positionDelegate: const DefaultMenuPositioningDelegate(
              anchorAttachment: AlignmentDirectional.topStart,
              menuAttachment: AlignmentDirectional.bottomStart,
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

    testWidgets('offset is reflected across anchor when menu flips', (WidgetTester tester) async {
      await tester.pumpWidget(
        App(
          alignment: const Alignment(0.8, 0.8),
          BaseMenu(
            positionDelegate: const DefaultMenuPositioningDelegate(
              anchorAttachment: Alignment.center,
              menuAttachment: Alignment.center,
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
            positionDelegate: const DefaultMenuPositioningDelegate(
              anchorAttachment: AlignmentDirectional.bottomEnd,
              menuAttachment: Alignment.center,
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

    testWidgets('menuAttachment is reflected across anchor when menu flips', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          alignment: const AlignmentDirectional(0.95, 0.95),
          BaseMenu(
            positionDelegate: const DefaultMenuPositioningDelegate(
              anchorAttachment: Alignment.center,
              menuAttachment: AlignmentDirectional.topStart,
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
              positionDelegate: const DefaultMenuPositioningDelegate(
                anchorAttachment: Alignment.topLeft,
                menuAttachment: Alignment.topCenter,
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

    testWidgets('Menus opened with a position ignore offset', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      await tester.pumpWidget(
        App(
          BaseMenu(
            positionDelegate: const DefaultMenuPositioningDelegate(
              offset: Offset(33, 45),
              anchorAttachment: Alignment.topLeft,
              menuAttachment: Alignment.topCenter,
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

      // Get position with offset.
      final ui.Rect control = collectOverlays().first;

      controller.open(position: Offset.zero);
      await tester.pump();

      // Alignment offset should be removed.
      expect(collectOverlays().first, control.shift(const Offset(-33, -45)));
    });

    testWidgets('Menus opened with a position ignore anchorAttachment', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      await tester.pumpWidget(
        App(
          BaseMenu(
            controller: controller,
            positionDelegate: const DefaultMenuPositioningDelegate(
              anchorAttachment: Alignment.bottomRight,
              menuAttachment: Alignment.topLeft,
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

      // Get position with offset.
      final ui.Rect control = collectOverlays().first;

      controller.open(position: Offset.zero);
      await tester.pump();

      // A positioned menu is placed relative to the top left corner of the
      // anchor. The anchor is 100x100, and the alignment is set to
      // bottom-right, so setting the position to
      // Offset.zero should offset the menu by -100 x -100.
      expect(collectOverlays().first, control.shift(const Offset(-100, -100)));
    });

    testWidgets('Menus opened with a position respect the menuAttachment property', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      await tester.pumpWidget(
        App(
          BaseMenu(
            controller: controller,
            positionDelegate: const DefaultMenuPositioningDelegate(
              anchorAttachment: Alignment.topLeft,
              menuAttachment: Alignment.center,
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

      // Get position with offset.
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
      await tester.binding.setSurfaceSize(const Size(800, 600));

      await tester.pumpWidget(
        App(
          BaseMenu(
            controller: controller,
            positionDelegate: const DefaultMenuPositioningDelegate(
              menuAttachment: Alignment.topLeft,
              overlayPadding: EdgeInsets.zero,
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
        positionDelegate: const DefaultMenuPositioningDelegate(
          anchorAttachment: AlignmentDirectional.bottomStart,
          menuAttachment: AlignmentDirectional.topStart,
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
                  positionDelegate: const DefaultMenuPositioningDelegate(
                    anchorAttachment: AlignmentDirectional.topEnd,
                    menuAttachment: AlignmentDirectional.topStart,
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
        positionDelegate: const DefaultMenuPositioningDelegate(
          anchorAttachment: AlignmentDirectional.bottomStart,
          menuAttachment: AlignmentDirectional.topStart,
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
                  positionDelegate: const DefaultMenuPositioningDelegate(
                    anchorAttachment: AlignmentDirectional.topEnd,
                    menuAttachment: AlignmentDirectional.topStart,
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
        positionDelegate: const DefaultMenuPositioningDelegate(
          anchorAttachment: AlignmentDirectional.bottomStart,
          menuAttachment: AlignmentDirectional.topStart,
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
                  positionDelegate: const DefaultMenuPositioningDelegate(
                    anchorAttachment: AlignmentDirectional.topEnd,
                    menuAttachment: AlignmentDirectional.topStart,
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
        positionDelegate: const DefaultMenuPositioningDelegate(
          anchorAttachment: Alignment.topRight,
          menuAttachment: Alignment.topLeft,
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
                positionDelegate: const DefaultMenuPositioningDelegate(
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
                  positionDelegate: const DefaultMenuPositioningDelegate(
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

    testWidgets('Menu is positioned around display features', (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(1200, 600));

      await tester.pumpWidget(
        App(
          MediaQuery(
            data: const MediaQueryData(
              platformBrightness: Brightness.dark,

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
                      positionDelegate: const DefaultMenuPositioningDelegate(
                        anchorAttachment: Alignment.topLeft,
                        menuAttachment: Alignment.topRight,
                        overlayPadding: .zero,
                      ),
                      menu: BaseMenuPanel(
                        orientation: Axis.vertical,
                        children: <Widget>[
                          Container(color: const Color(0xFF00FF00), width: 150, height: 50),
                        ],
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
      expect(tester.getSize(find.byKey(Tag.a.key)), equals(const Size(75, 150)));

      await tester.pumpWidget(
        App(
          BaseMenu(
            menu: BaseMenuPanel(
              orientation: Axis.vertical,
              constraints: const BoxConstraints(minWidth: 75, maxHeight: 100),
              crossAxisAlignment: .start,
              children: <Widget>[
                Container(key: Tag.a.key, color: const Color(0xFFFF0000), height: 150, width: 50),
              ],
            ),
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      );

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
              positionDelegate: DefaultMenuPositioningDelegate(overlayPadding: EdgeInsets.zero),
              menu: ColoredBox(
                color: Color(0xFF0000FF),
                child: BaseMenuPanel(
                  orientation: Axis.vertical,
                  children: <Widget>[
                    BaseMenu(
                      positionDelegate: DefaultMenuPositioningDelegate(
                        anchorAttachment: AlignmentDirectional.bottomStart,
                        menuAttachment: AlignmentDirectional.topStart,
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
                positionDelegate: DefaultMenuPositioningDelegate(overlayPadding: EdgeInsets.zero),
                menu: ColoredBox(
                  color: Color(0xFF0000FF),
                  child: BaseMenuPanel(
                    orientation: Axis.vertical,
                    children: <Widget>[
                      // Nested menus should be placed in the same overlay as their
                      // parent menu, so this menu should be placed in the nearest
                      // overlay instead of the root overlay.
                      BaseMenu(
                        positionDelegate: DefaultMenuPositioningDelegate(
                          overlayPadding: EdgeInsets.zero,
                          menuAttachment: AlignmentDirectional.topStart,
                          anchorAttachment: AlignmentDirectional.bottomStart,
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

    testWidgets('findClosestScreen selects the correct sub-screen in multi-screen environments', (
      WidgetTester tester,
    ) async {
      const surfaceSize = Size(1000, 1000);
      await changeSurfaceSize(tester, surfaceSize);

      // Define two sub-screens separated by a 200px vertical hinge.
      // Screen 1: [0, 0, 400, 1000]
      // Hinge: [400, 0, 600, 1000] (avoidBounds)
      // Screen 2: [600, 0, 1000, 1000]

      Widget buildApp({required Offset anchorPosition, required MenuController controller}) {
        return MediaQuery(
          data: const MediaQueryData(
            size: surfaceSize,
            displayFeatures: <ui.DisplayFeature>[
              ui.DisplayFeature(
                bounds: Rect.fromLTWH(400, 0, 200, 1000),
                type: ui.DisplayFeatureType.hinge,
                state: ui.DisplayFeatureState.unknown,
              ),
            ],
          ),
          child: App(
            textDirection: TextDirection.ltr,
            alignment: Alignment.topLeft,
            Stack(
              children: [
                SizedBox(
                  width: 1000,
                  height: 1000,
                  child: Container(color: const ui.Color.fromARGB(152, 0, 0, 255)),
                ),
                Positioned.fromRect(
                  rect: const Rect.fromLTWH(400, 0, 200, 1000),
                  child: Container(color: const ui.Color.fromARGB(152, 0, 255, 187)),
                ),
                Positioned(
                  left: anchorPosition.dx - 5,
                  top: anchorPosition.dy - 5,
                  child: BaseMenu(
                    controller: controller,
                    positionDelegate: const DefaultMenuPositioningDelegate(
                      anchorAttachment: Alignment.center,
                      menuAttachment: Alignment.topLeft,
                    ),
                    menu: Container(
                      width: 100,
                      height: 100,
                      color: const Color(0xFF0000FF),
                      child: Text(Tag.a.text),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final controller = MenuController();

      await tester.pumpWidget(
        buildApp(anchorPosition: const Offset(200, 500), controller: controller),
      );
      controller.open();
      await tester.pump();

      expect(tester.getRect(find.text(Tag.a.text)).right, lessThanOrEqualTo(400));

      controller.close();
      await tester.pump();

      await tester.pumpWidget(
        buildApp(anchorPosition: const Offset(800, 500), controller: controller),
      );
      controller.open();
      await tester.pump();

      expect(tester.getRect(find.text(Tag.a.text)).left, greaterThanOrEqualTo(600));

      controller.close();
      await tester.pump();

      await tester.pumpWidget(
        buildApp(anchorPosition: const Offset(450, 500), controller: controller),
      );
      controller.open();
      await tester.pump();

      expect(tester.getRect(find.text(Tag.a.text)).right, lessThanOrEqualTo(400));

      controller.close();
      await tester.pump();

      await tester.pumpWidget(
        buildApp(anchorPosition: const Offset(550, 500), controller: controller),
      );
      controller.open();
      await tester.pump();

      expect(tester.getRect(find.text(Tag.a.text)).left, greaterThanOrEqualTo(600));
    });

    testWidgets('findClosestScreen selects closest screen when anchor is outside all bounds', (
      WidgetTester tester,
    ) async {
      const surfaceSize = Size(1000, 1000);
      await changeSurfaceSize(tester, surfaceSize);

      final controller = MenuController();

      // Anchor is far above the surface (-100, -100). Should pick the top screen [0, 0, 1000, 400].
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            displayFeatures: <ui.DisplayFeature>[
              ui.DisplayFeature(
                bounds: Rect.fromLTWH(0, 400, 1000, 200),
                type: ui.DisplayFeatureType.hinge,
                state: ui.DisplayFeatureState.unknown,
              ),
            ],
          ),
          child: App(
            alignment: Alignment.topLeft,
            Stack(
              children: [
                SizedBox(
                  width: 1000,
                  height: 1000,
                  child: Container(color: const ui.Color.fromARGB(152, 0, 0, 255)),
                ),
                Positioned.fromRect(
                  rect: const Rect.fromLTWH(0, 400, 1000, 200),
                  child: Container(color: const ui.Color.fromARGB(152, 0, 255, 187)),
                ),
                Positioned(
                  left: 1100,
                  top: 800,
                  child: BaseMenu(
                    controller: controller,
                    positionDelegate: const DefaultMenuPositioningDelegate(
                      // Force anchor to a specific global position outside the screens
                      anchorAttachment: Alignment.topLeft,
                    ),
                    menu: Container(
                      color: const Color.fromARGB(156, 255, 0, 0),
                      width: 100,
                      height: 100,
                      child: Text(Tag.a.text),
                    ),
                    child: AnchorButton(Tag.anchor, autofocus: true, onPressed: (tag) {}),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      controller.open();
      await tester.pump();

      expect(
        tester.getRect(find.text(Tag.a.text)),
        const Rect.fromLTRB(892.0, 800.0, 992.0, 900.0),
      );
    });

    testWidgets('Resolves and updates layout when positioning properties change', (
      WidgetTester tester,
    ) async {
      final controller = MenuController();
      AlignmentGeometry anchorAttachment = AlignmentDirectional.topStart;
      AlignmentGeometry menuAttachment = AlignmentDirectional.topStart;
      EdgeInsetsGeometry overlayPadding = EdgeInsets.zero;
      EdgeInsetsGeometry padding = EdgeInsets.zero; // Maps to menuPadding
      TextDirection textDirection = TextDirection.ltr;

      late StateSetter setState;

      await tester.pumpWidget(
        App(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setter) {
              setState = setter;
              return Directionality(
                textDirection: textDirection,
                child: Center(
                  child: BaseMenu(
                    controller: controller,
                    positionDelegate: DefaultMenuPositioningDelegate(
                      anchorAttachment: anchorAttachment,
                      menuAttachment: menuAttachment,
                      overlayPadding: overlayPadding,
                      padding: padding,
                      edgeBehavior: const EdgeBehavior(
                        horizontal: EdgeBehaviorStrategy(shift: true),
                        vertical: EdgeBehaviorStrategy(shift: true),
                      ),
                    ),
                    menu: SizedBox(key: Tag.a.key, width: 100, height: 100),
                    child: SizedBox(key: Tag.anchor.key, width: 10, height: 10),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Open the menu to trigger the first layout
      controller.open();
      await tester.pump();

      Offset getMenuOffset() {
        return tester.getTopLeft(find.byKey(Tag.a.key));
      }

      Rect getAnchorRect() {
        return tester.getRect(find.byKey(Tag.anchor.key));
      }

      expect(getMenuOffset(), getAnchorRect().topLeft);

      setState(() {
        anchorAttachment = AlignmentDirectional.bottomEnd;
      });
      await tester.pump();

      expect(getMenuOffset(), getAnchorRect().bottomRight);

      setState(() {
        menuAttachment = AlignmentDirectional.bottomEnd;
      });
      await tester.pump();

      expect(getMenuOffset(), getAnchorRect().bottomRight - const Offset(100, 100));

      setState(() {
        anchorAttachment = AlignmentDirectional.topStart;
        menuAttachment = AlignmentDirectional.topStart;
        textDirection = TextDirection.rtl;
      });
      await tester.pump();

      expect(getMenuOffset().dx, getAnchorRect().right - 100);

      setState(() {
        textDirection = TextDirection.ltr;
        padding = const EdgeInsets.only(left: 20);
      });
      await tester.pump();

      expect(getMenuOffset().dx, getAnchorRect().left - 20);

      setState(() {
        padding = EdgeInsets.zero;
        overlayPadding = EdgeInsets.only(left: getAnchorRect().left + 50);
      });
      await tester.pump();

      expect(getMenuOffset().dx, getAnchorRect().left + 50);
    });

    group('EdgeBehavior', () {
      test('EdgeBehavior equality', () {
        const behaviorA = EdgeBehavior(
          horizontal: EdgeBehaviorStrategy(shift: true, constrain: true),
          vertical: EdgeBehaviorStrategy(flip: true),
        );
        const behaviorB = EdgeBehavior(
          horizontal: EdgeBehaviorStrategy(shift: true, constrain: true),
          vertical: EdgeBehaviorStrategy(flip: true),
        );
        const behaviorC = EdgeBehavior(
          horizontal: EdgeBehaviorStrategy(),
          vertical: EdgeBehaviorStrategy(),
        );

        expect(behaviorA, equals(behaviorB));
        expect(behaviorA.hashCode, equals(behaviorB.hashCode));
        expect(behaviorA, isNot(equals(behaviorC)));
        expect(behaviorA.hashCode, isNot(equals(behaviorC.hashCode)));

        const strategyA = EdgeBehaviorStrategy(shift: true, flip: true);
        const strategyB = EdgeBehaviorStrategy(shift: true, flip: true);
        const strategyC = EdgeBehaviorStrategy();

        expect(strategyA, equals(strategyB));
        expect(strategyA.hashCode, equals(strategyB.hashCode));
        expect(strategyA, isNot(equals(strategyC)));
      });
      testWidgets('Horizontal behavior', (WidgetTester tester) async {
        await changeSurfaceSize(tester, const Size(800, 600));
        const padding = EdgeInsets.all(8.0);
        const menuWidth = 900.0;
        const screenWidth = 800.0;

        Widget buildTest(EdgeBehaviorStrategy horizontalStrategy) {
          return App(
            alignment: const AlignmentDirectional(0.5, 0.0),
            BaseMenu(
              onCloseRequest: (hideOverlay) {},
              positionDelegate: DefaultMenuPositioningDelegate(
                anchorAttachment: AlignmentDirectional.topEnd,
                menuAttachment: AlignmentDirectional.topStart,
                edgeBehavior: EdgeBehavior(
                  horizontal: horizontalStrategy,
                  vertical: const EdgeBehaviorStrategy(),
                ),
              ),
              menu: BaseMenuPanel(
                key: Tag.a.key,
                orientation: Axis.vertical,
                children: <Widget>[
                  Container(
                    width: 900,
                    height: 100,
                    color: const ui.Color.fromARGB(153, 0, 255, 0),
                    child: const Text('visible'),
                  ),
                ],
              ),
              child: const AnchorButton(Tag.anchor),
            ),
          );
        }

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy()));

        await tester.tap(find.text(Tag.anchor.text));
        await tester.pump();

        final Rect anchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));
        Rect menu() => tester.getRect(find.byKey(Tag.a.key));

        expect(menu().left, equals(anchor.right));
        expect(menu().width, equals(menuWidth));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(constrain: true)));

        expect(menu().left, equals(anchor.right));
        expect(menu().width, lessThan(screenWidth - padding.horizontal));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(flip: true)));

        expect(menu().left, equals(anchor.right));
        expect(menu().width, equals(menuWidth));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(shift: true)));

        expect(menu().right, equals(menuWidth + padding.right));
        expect(menu().width, equals(menuWidth));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(constrain: true, flip: true)));

        expect(menu().right, equals(anchor.left));
        expect(menu().width, equals(anchor.left - padding.left));

        await tester.pumpWidget(
          buildTest(const EdgeBehaviorStrategy(constrain: true, shift: true)),
        );

        expect(menu().right, equals(screenWidth - padding.right));
        expect(menu().width, equals(screenWidth - padding.horizontal));
        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(flip: true, shift: true)));

        expect(menu().left, equals(padding.left));
        expect(menu().width, equals(menuWidth));

        await tester.pumpWidget(
          buildTest(const EdgeBehaviorStrategy(shift: true, flip: true, constrain: true)),
        );

        expect(menu().left, equals(padding.left));
        expect(menu().width, equals(screenWidth - padding.horizontal));
      });

      testWidgets('Horizontal behavior (menuAttachment: 0.75, 0.75)', (WidgetTester tester) async {
        await changeSurfaceSize(tester, const Size(800, 600));
        const padding = EdgeInsets.all(8.0);
        const menuWidth = 900.0;
        const screenWidth = 800.0;

        Widget buildTest(EdgeBehaviorStrategy horizontalStrategy) {
          return App(
            alignment: const AlignmentDirectional(0.5, 0.0),
            BaseMenu(
              onCloseRequest: (hideOverlay) {},
              positionDelegate: DefaultMenuPositioningDelegate(
                anchorAttachment: AlignmentDirectional.topEnd,
                menuAttachment: const AlignmentDirectional(0.75, 0.75),
                edgeBehavior: EdgeBehavior(
                  horizontal: horizontalStrategy,
                  vertical: const EdgeBehaviorStrategy(),
                ),
              ),
              menu: BaseMenuPanel(
                key: Tag.a.key,
                orientation: Axis.vertical,
                children: <Widget>[
                  Container(
                    width: 900,
                    height: 100,
                    color: const ui.Color.fromARGB(153, 0, 255, 0),
                    child: const Text('visible'),
                  ),
                ],
              ),
              child: const AnchorButton(Tag.anchor),
            ),
          );
        }

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy()));

        await tester.tap(find.text(Tag.anchor.text));
        await tester.pump();

        final Rect anchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));
        Rect menu() => tester.getRect(find.byKey(Tag.a.key));

        expect(menu().left, equals(anchor.right - 0.875 * menuWidth));
        expect(menu().width, equals(menuWidth));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(constrain: true)));

        // The menu width should be constrained if it overflows the screen edges.
        expect(menu().left, equals(padding.left));
        expect(menu().width, lessThan(menuWidth));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(flip: true)));

        // Verify that the menu correctly flips horizontally when overflowing.
        expect(menu().width, equals(menuWidth));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(shift: true)));

        // Shift should keep the menu within the screen boundaries plus padding.
        expect(menu().left, greaterThanOrEqualTo(padding.left));
        expect(menu().width, equals(menuWidth));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(constrain: true, flip: true)));

        expect(menu().left, greaterThanOrEqualTo(padding.left));
        expect(menu().width, lessThanOrEqualTo(screenWidth - padding.horizontal));

        await tester.pumpWidget(
          buildTest(const EdgeBehaviorStrategy(constrain: true, shift: true)),
        );

        expect(menu().width, equals(screenWidth - padding.horizontal));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(flip: true, shift: true)));

        expect(menu().width, equals(menuWidth));

        await tester.pumpWidget(
          buildTest(const EdgeBehaviorStrategy(shift: true, flip: true, constrain: true)),
        );

        expect(menu().width, equals(screenWidth - padding.horizontal));
      });

      testWidgets('Horizontal behavior (RTL)', (WidgetTester tester) async {
        await changeSurfaceSize(tester, const Size(800, 600));
        const padding = EdgeInsets.all(8.0);
        const menuWidth = 900.0;
        const screenWidth = 800.0;

        Widget buildTest(EdgeBehaviorStrategy horizontalStrategy) {
          return App(
            textDirection: TextDirection.rtl,
            alignment: const AlignmentDirectional(0.5, 0.0),
            BaseMenu(
              onCloseRequest: (hideOverlay) {},
              positionDelegate: DefaultMenuPositioningDelegate(
                anchorAttachment: AlignmentDirectional.topEnd,
                menuAttachment: AlignmentDirectional.topStart,
                edgeBehavior: EdgeBehavior(
                  horizontal: horizontalStrategy,
                  vertical: const EdgeBehaviorStrategy(),
                ),
              ),
              menu: BaseMenuPanel(
                key: Tag.a.key,
                orientation: Axis.vertical,
                children: <Widget>[
                  Container(
                    width: 900,
                    height: 100,
                    color: const ui.Color.fromARGB(153, 0, 255, 0),
                    child: const Text('visible', textDirection: TextDirection.rtl),
                  ),
                ],
              ),
              child: const AnchorButton(Tag.anchor),
            ),
          );
        }

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy()));

        await tester.tap(find.text(Tag.anchor.text));
        await tester.pump();

        final Rect anchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));
        Rect menu() => tester.getRect(find.byKey(Tag.a.key));

        expect(menu().right, equals(anchor.left));
        expect(menu().width, equals(menuWidth));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(constrain: true)));

        expect(menu().right, equals(anchor.left));
        expect(menu().width, equals(anchor.left - padding.left));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(flip: true)));

        expect(menu().right, equals(anchor.left));
        expect(menu().width, equals(menuWidth));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(shift: true)));

        expect(menu().right, equals(screenWidth - padding.right));
        expect(menu().width, equals(menuWidth));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(constrain: true, flip: true)));

        expect(menu().left, equals(anchor.right));
        expect(menu().width, equals(screenWidth - padding.right - anchor.right));

        await tester.pumpWidget(
          buildTest(const EdgeBehaviorStrategy(constrain: true, shift: true)),
        );

        expect(menu().right, equals(screenWidth - padding.right));
        expect(menu().width, equals(screenWidth - padding.horizontal));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(flip: true, shift: true)));

        expect(menu().right, equals(screenWidth - padding.right));
        expect(menu().width, equals(menuWidth));

        await tester.pumpWidget(
          buildTest(const EdgeBehaviorStrategy(shift: true, flip: true, constrain: true)),
        );

        expect(menu().right, equals(screenWidth - padding.right));
        expect(menu().width, equals(screenWidth - padding.horizontal));
      });

      testWidgets('Horizontal behavior (RTL) (menuAttachment: 0.75, 0.75)', (
        WidgetTester tester,
      ) async {
        await changeSurfaceSize(tester, const Size(800, 600));
        const padding = EdgeInsets.all(8.0);
        const menuWidth = 900.0;
        const screenWidth = 800.0;

        Widget buildTest(EdgeBehaviorStrategy horizontalStrategy) {
          return App(
            textDirection: .rtl,
            alignment: const AlignmentDirectional(0.5, 0.0),
            BaseMenu(
              onCloseRequest: (hideOverlay) {},
              positionDelegate: DefaultMenuPositioningDelegate(
                anchorAttachment: AlignmentDirectional.topEnd,
                menuAttachment: const AlignmentDirectional(0.75, 0.75),
                edgeBehavior: EdgeBehavior(
                  horizontal: horizontalStrategy,
                  vertical: const EdgeBehaviorStrategy(),
                ),
              ),
              menu: BaseMenuPanel(
                key: Tag.a.key,
                clipBehavior: .hardEdge,
                orientation: Axis.vertical,
                children: <Widget>[
                  Container(
                    width: 900,
                    height: 100,
                    color: const ui.Color.fromARGB(153, 0, 255, 0),
                    child: const Text('visible', textDirection: TextDirection.rtl),
                  ),
                ],
              ),
              child: const AnchorButton(Tag.anchor),
            ),
          );
        }

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy()));

        await tester.tap(find.text(Tag.anchor.text));
        await tester.pump();

        final Rect anchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));
        Rect menu() => tester.getRect(find.byKey(Tag.a.key));

        // In RTL, Alignment(0.75, 0.75) means the point at 87.5% from the right (start)
        // aligns with the anchor's attachment point (anchor.left for topEnd).
        expect(menu().right, equals(anchor.left + 0.875 * menuWidth));
        expect(menu().width, equals(menuWidth));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(constrain: true)));

        // The menu width should be constrained as it overflows the right screen edge.
        expect(menu().right, equals(screenWidth - padding.right));
        expect(menu().width, lessThan(menuWidth));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(flip: true)));

        // Verify that the menu correctly flips horizontally when overflowing.
        expect(menu().width, equals(menuWidth));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(shift: true)));

        // Shift should keep the menu within the screen boundaries plus padding.
        expect(menu().right, lessThanOrEqualTo(screenWidth - padding.right));
        expect(menu().width, equals(menuWidth));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(constrain: true, flip: true)));

        expect(menu().right, lessThanOrEqualTo(screenWidth - padding.right));
        expect(menu().width, lessThanOrEqualTo(screenWidth - padding.horizontal));

        await tester.pumpWidget(
          buildTest(const EdgeBehaviorStrategy(constrain: true, shift: true)),
        );

        expect(menu().width, equals(screenWidth - padding.horizontal));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(flip: true, shift: true)));

        expect(menu().width, equals(menuWidth));

        await tester.pumpWidget(
          buildTest(const EdgeBehaviorStrategy(shift: true, flip: true, constrain: true)),
        );

        expect(menu().width, equals(screenWidth - padding.horizontal));
      });

      testWidgets('Vertical behavior', (WidgetTester tester) async {
        await changeSurfaceSize(tester, const Size(800, 600));
        const padding = EdgeInsets.all(8.0);
        const menuHeight = 900.0;
        const screenHeight = 600.0;

        Widget buildTest(EdgeBehaviorStrategy verticalStrategy) {
          return App(
            alignment: const Alignment(0.0, 0.5),
            BaseMenu(
              onCloseRequest: (hideOverlay) {},
              positionDelegate: DefaultMenuPositioningDelegate(
                anchorAttachment: Alignment.bottomLeft,
                menuAttachment: Alignment.topLeft,
                edgeBehavior: EdgeBehavior(
                  horizontal: const EdgeBehaviorStrategy(),
                  vertical: verticalStrategy,
                ),
              ),
              menu: BaseMenuPanel(
                key: Tag.a.key,
                clipBehavior: .hardEdge,
                orientation: Axis.vertical,
                children: <Widget>[
                  Container(
                    width: 100,
                    height: 900,
                    color: const Color.fromARGB(153, 0, 255, 0),
                    child: const Text('visible', textDirection: TextDirection.rtl),
                  ),
                ],
              ),
              child: const AnchorButton(Tag.anchor),
            ),
          );
        }

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy()));

        await tester.tap(find.text(Tag.anchor.text));
        await tester.pump();

        final Rect anchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));
        Rect menu() => tester.getRect(find.byKey(Tag.a.key));

        expect(menu().top, equals(anchor.bottom));
        expect(menu().height, equals(menuHeight));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(constrain: true)));

        expect(menu().top, equals(anchor.bottom));
        expect(menu().height, lessThan(screenHeight - padding.vertical));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(flip: true)));

        expect(menu().top, equals(anchor.bottom));
        expect(menu().height, equals(menuHeight));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(shift: true)));

        expect(menu().top, equals(padding.top));
        expect(menu().height, equals(menuHeight));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(constrain: true, flip: true)));

        expect(menu().bottom, equals(anchor.top));
        expect(menu().height, equals(anchor.top - padding.top));

        await tester.pumpWidget(
          buildTest(const EdgeBehaviorStrategy(constrain: true, shift: true)),
        );

        // Account for 8px padding
        expect(menu().bottom, equals(screenHeight - padding.bottom));
        expect(menu().height, equals(screenHeight - padding.vertical));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(flip: true, shift: true)));

        expect(menu().top, equals(padding.top));
        expect(menu().height, equals(menuHeight));

        await tester.pumpWidget(
          buildTest(const EdgeBehaviorStrategy(shift: true, flip: true, constrain: true)),
        );

        expect(menu().top, equals(padding.top));
        expect(menu().height, equals(screenHeight - padding.vertical));
      });

      testWidgets('Vertical behavior (anchor bottom, menuAttachment: 0.75, 0.75)', (
        WidgetTester tester,
      ) async {
        await changeSurfaceSize(tester, const Size(800, 600));
        const padding = EdgeInsets.all(8.0);
        const menuHeight = 900.0;
        const screenHeight = 600.0;

        Widget buildTest(EdgeBehaviorStrategy verticalStrategy) {
          return App(
            alignment: const Alignment(0.0, 0.5),
            BaseMenu(
              onCloseRequest: (hideOverlay) {},
              positionDelegate: DefaultMenuPositioningDelegate(
                anchorAttachment: Alignment.bottomLeft,
                menuAttachment: const Alignment(0.75, 0.75),
                edgeBehavior: EdgeBehavior(
                  horizontal: const EdgeBehaviorStrategy(),
                  vertical: verticalStrategy,
                ),
              ),
              menu: BaseMenuPanel(
                key: Tag.a.key,
                clipBehavior: .hardEdge,
                orientation: Axis.vertical,
                children: <Widget>[
                  Container(
                    width: 100,
                    height: 900,
                    color: const ui.Color.fromARGB(153, 0, 255, 0),
                    child: const Text('visible', textDirection: TextDirection.rtl),
                  ),
                ],
              ),
              child: const AnchorButton(Tag.anchor),
            ),
          );
        }

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy()));

        await tester.tap(find.text(Tag.anchor.text));
        await tester.pump();

        final Rect anchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));
        Rect menu() => tester.getRect(find.byKey(Tag.a.key));

        expect(menu().top, equals(anchor.bottom - 0.875 * menuHeight));
        expect(menu().height, equals(menuHeight));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(constrain: true)));

        expect(menu().top, equals(padding.top));
        expect(menu().height, equals(anchor.bottom - padding.top + 0.125 * menuHeight));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(flip: true)));

        expect(menu().top, equals(anchor.top - 0.125 * menuHeight));
        expect(menu().height, equals(menuHeight));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(shift: true)));

        expect(menu().top, greaterThanOrEqualTo(padding.top));
        expect(menu().height, equals(menuHeight));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(constrain: true, flip: true)));

        expect(menu().top, greaterThanOrEqualTo(padding.top));
        expect(menu().height, lessThanOrEqualTo(screenHeight - padding.vertical));

        await tester.pumpWidget(
          buildTest(const EdgeBehaviorStrategy(constrain: true, shift: true)),
        );

        expect(menu().height, equals(screenHeight - padding.vertical));

        await tester.pumpWidget(buildTest(const EdgeBehaviorStrategy(flip: true, shift: true)));

        expect(menu().height, equals(menuHeight));

        await tester.pumpWidget(
          buildTest(const EdgeBehaviorStrategy(shift: true, flip: true, constrain: true)),
        );

        expect(menu().height, equals(screenHeight - padding.vertical));
      });

      testWidgets('Horizontal LTR: prioritize start edge when menu is wider than screen', (
        WidgetTester tester,
      ) async {
        const surfaceSize = Size(200, 600);
        await changeSurfaceSize(tester, surfaceSize);

        const delegate = DefaultMenuPositioningDelegate(
          anchorAttachment: Alignment.center,
          menuAttachment: Alignment.center,
          edgeBehavior: EdgeBehavior(
            horizontal: EdgeBehaviorStrategy(),
            vertical: EdgeBehaviorStrategy(shift: true, constrain: true),
          ),
        );

        await tester.pumpWidget(
          const App(
            textDirection: TextDirection.ltr,
            BaseMenu(
              positionDelegate: delegate,
              menu: SizedBox(width: 400, height: 50, child: Text('Wide Menu')),
              child: AnchorButton(Tag.anchor),
            ),
          ),
        );

        await tester.tap(find.text(Tag.anchor.text));
        await tester.pump();

        // In LTR, prioritizeStartEdge is true. Should align to boundaryStart (x = 0).
        final Rect menuRect = tester.getRect(find.text('Wide Menu'));
        expect(menuRect.left, delegate.overlayPadding.resolve(.ltr).left);
      });

      testWidgets('Horizontal RTL: prioritize end edge when menu is wider than screen', (
        WidgetTester tester,
      ) async {
        const surfaceSize = Size(200, 600);
        await changeSurfaceSize(tester, surfaceSize);

        const delegate = DefaultMenuPositioningDelegate(
          anchorAttachment: Alignment.center,
          menuAttachment: Alignment.center,
          edgeBehavior: EdgeBehavior(
            horizontal: EdgeBehaviorStrategy(shift: true),
            vertical: EdgeBehaviorStrategy(),
          ),
        );
        await tester.pumpWidget(
          App(
            textDirection: TextDirection.rtl,
            BaseMenu(
              positionDelegate: delegate,
              menu: SizedBox(
                key: Tag.a.key,
                width: 400,
                height: 50,
                child: Text(Tag.a.text, textDirection: TextDirection.rtl),
              ),
              child: const AnchorButton(Tag.anchor),
            ),
          ),
        );

        await tester.tap(find.text(Tag.anchor.text));
        await tester.pump();

        // In RTL, prioritizeStartEdge is false.
        // Returns boundaryEnd = (overlayEnd - childSize) = (200 - 400) = -200.
        final Rect menuRect = tester.getRect(find.byKey(Tag.a.key));
        expect(menuRect.left, -200.0 - delegate.overlayPadding.resolve(.rtl).right);
        expect(
          menuRect.right,
          200.0 - delegate.overlayPadding.resolve(.rtl).right,
        ); // Right edge aligned with screen right edge
      });

      testWidgets('Vertical: prioritize start edge when menu is taller than screen', (
        WidgetTester tester,
      ) async {
        const surfaceSize = Size(600, 200);
        await changeSurfaceSize(tester, surfaceSize);

        const delegate = DefaultMenuPositioningDelegate(
          anchorAttachment: Alignment.center,
          menuAttachment: Alignment.center,
          edgeBehavior: EdgeBehavior(
            horizontal: EdgeBehaviorStrategy(shift: true, constrain: true),
            vertical: EdgeBehaviorStrategy(),
          ),
        );

        await tester.pumpWidget(
          const App(
            BaseMenu(
              positionDelegate: delegate,
              menu: SizedBox(width: 50, height: 400, child: Text('Tall Menu')),
              child: AnchorButton(Tag.anchor),
            ),
          ),
        );

        await tester.tap(find.text(Tag.anchor.text));
        await tester.pump();

        // Vertical prioritizeStartEdge is always true. Should align to boundaryStart (y = 0).
        final Rect menuRect = tester.getRect(find.text('Tall Menu'));
        expect(menuRect.top, delegate.overlayPadding.resolve(.ltr).top);
      });
    });
  });
}
