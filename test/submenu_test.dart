import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_utilities/menu_utilities.dart';

void main() {
  late MenuController controller;

  setUp(() {
    controller = MenuController();
  });

  testWidgets('opens and closes using default request callbacks', (WidgetTester tester) async {
    await tester.pumpWidget(
      App(
        BaseSubmenu(
          role: null,
          controller: controller,
          menu: SizedBox(key: Tag.a.key),
          child: const SubmenuChild(tag: Tag.anchor),
        ),
      ),
    );

    expect(controller.isOpen, isFalse);
    expect(find.byKey(Tag.a.key), findsNothing);

    controller.open();
    await tester.pump();

    expect(controller.isOpen, isTrue);
    expect(find.byKey(Tag.a.key), findsOneWidget);

    controller.close();
    await tester.pump();

    expect(controller.isOpen, isFalse);
    expect(find.byKey(Tag.a.key), findsNothing);
  });

  testWidgets('pointer enter/exit panel manages close timer and requests focus', (
    WidgetTester tester,
  ) async {
    const closeDelay = Duration(milliseconds: 500);
    final focusNode = FocusNode();
    final outsideFocusNode = FocusNode();
    addTearDown(outsideFocusNode.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      App(
        Column(
          children: [
            Focus(focusNode: outsideFocusNode, child: const SizedBox()),
            BaseSubmenu(
              role: null,
              focusNode: focusNode,
              controller: controller,
              hoverCloseDelay: closeDelay,
              menu: Container(
                color: const Color(0xff000000),
                key: Tag.a.key,
                width: 100,
                height: 100,
              ),
              child: const SubmenuChild(tag: Tag.anchor),
            ),
          ],
        ),
      ),
    );

    controller.open();
    await tester.pump();

    final gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: tester.getCenter(find.text(Tag.anchor.text)));
    await tester.pump();

    await gesture.moveTo(Offset.infinite);
    await tester.pump(); // Starts close timer

    // Enter panel
    await gesture.moveTo(tester.getCenter(find.byKey(Tag.a.key)));
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);
    expect(controller.isOpen, isTrue);

    // Verify timer was cancelled
    await tester.pump(closeDelay + const Duration(milliseconds: 50));
    expect(controller.isOpen, isTrue);

    outsideFocusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);

    // Exit panel should request focus back to anchor focusNode
    await gesture.moveTo(Offset.infinite);
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
  });

  group('Focus', () {
    testWidgets('creates internal focusNode if provided node is removed', (
      WidgetTester tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            focusNode: node,
            menu: const SizedBox.shrink(),
            controller: controller,
            child: Text(Tag.a.text),
          ),
        ),
      );

      var menuItem = tester.widget<BaseMenuItem>(find.byType(BaseMenuItem));
      var focusNode = menuItem.focusNode;
      expect(focusNode, equals(node));

      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            menu: const SizedBox.shrink(),
            controller: controller,
            child: Text(Tag.a.text),
          ),
        ),
      );

      menuItem = tester.widget<BaseMenuItem>(find.byType(BaseMenuItem));
      focusNode = menuItem.focusNode;
      expect(focusNode, isNot(node));
    });

    testWidgets('does not throw when switching from an external focusNode to internal', (
      WidgetTester tester,
    ) async {
      final nodeOne = FocusNode();
      final nodeTwo = FocusNode();
      addTearDown(nodeOne.dispose);
      addTearDown(nodeTwo.dispose);

      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            focusNode: nodeOne,
            menu: const SizedBox.shrink(),
            controller: controller,
            child: Text(Tag.a.text),
          ),
        ),
      );

      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            focusNode: nodeTwo,
            menu: const SizedBox.shrink(),
            controller: controller,
            child: Text(Tag.a.text),
          ),
        ),
      );

      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            menu: const SizedBox.shrink(),
            controller: controller,
            child: Text(Tag.a.text),
          ),
        ),
      );

      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            focusNode: nodeOne,
            menu: const SizedBox.shrink(),
            controller: controller,
            child: Text(Tag.a.text),
          ),
        ),
      );
    });

    testWidgets('manages focusNode listeners on update', (WidgetTester tester) async {
      final focusNode1 = MockFocusNode();
      final focusNode2 = MockFocusNode();
      addTearDown(focusNode1.dispose);
      addTearDown(focusNode2.dispose);

      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            controller: controller,
            menu: const SizedBox(),
            child: const SubmenuChild(tag: Tag.anchor),
          ),
        ),
      );

      var menuItem = tester.widget<BaseMenuItem>(find.byType(BaseMenuItem));
      final internalFocusNode1 = menuItem.focusNode;
      expect(internalFocusNode1, isNotNull);
      // ignore: invalid_use_of_protected_member
      expect(internalFocusNode1!.hasListeners, isTrue);

      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            focusNode: focusNode1,
            controller: controller,
            menu: const SizedBox(),
            child: const SubmenuChild(tag: Tag.anchor),
          ),
        ),
      );

      menuItem = tester.widget<BaseMenuItem>(find.byType(BaseMenuItem));
      expect(focusNode1, equals(menuItem.focusNode));
      expect(focusNode1.hasListeners, isTrue);
      expect(() => internalFocusNode1.addListener(() {}), throwsAssertionError);

      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            focusNode: focusNode2,
            controller: controller,
            menu: const SizedBox(),
            child: const SubmenuChild(tag: Tag.anchor),
          ),
        ),
      );

      expect(focusNode1.hasListeners, isFalse);
      expect(focusNode2.hasListeners, isTrue);

      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            controller: controller,
            menu: const SizedBox(),
            child: const SubmenuChild(tag: Tag.anchor),
          ),
        ),
      );

      expect(focusNode2.hasListeners, isFalse);

      // Find the internal focus node being used
      menuItem = tester.widget<BaseMenuItem>(find.byType(BaseMenuItem));
      final internalFocusNode2 = menuItem.focusNode;
      expect(internalFocusNode2, isNotNull);
      expect(internalFocusNode2, isNot(internalFocusNode1));
      expect(internalFocusNode2, isNot(focusNode1));
      expect(internalFocusNode2, isNot(focusNode2));
    });

    testWidgets('disposes listeners on external focusNode', (WidgetTester tester) async {
      final focusNode1 = MockFocusNode();
      addTearDown(focusNode1.dispose);

      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            focusNode: focusNode1,
            controller: controller,
            menu: const SizedBox(),
            child: const SubmenuChild(tag: Tag.anchor),
          ),
        ),
      );

      expect(focusNode1.hasListeners, isTrue);

      await tester.pumpWidget(const App(SizedBox()));

      expect(focusNode1.hasListeners, isFalse);
    });

    testWidgets('manages internal focusNode creation and destruction', (WidgetTester tester) async {
      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            controller: controller,
            menu: const SizedBox(),
            child: const SubmenuChild(tag: Tag.anchor),
          ),
        ),
      );

      final menuItem = tester.widget<BaseMenuItem>(find.byType(BaseMenuItem));
      final focusNode = menuItem.focusNode;

      // ignore: invalid_use_of_protected_member
      expect(focusNode!.hasListeners, isTrue);

      await tester.pumpWidget(const App(SizedBox()));

      expect(() => focusNode.addListener(() {}), throwsAssertionError);
    });
  });

  testWidgets('configures BaseMenu', (WidgetTester tester) async {
    final aFocusNode = FocusNode(debugLabel: Tag.a.focusNode);
    addTearDown(aFocusNode.dispose);
    var onOpenCalled = false;
    var onCloseCalled = false;
    var onOpenRequestCalled = false;
    var onCloseRequestCalled = false;
    var isScopeFocused = false;

    const semanticProperties = SemanticsProperties(
      label: 'Custom Submenu Label',
      role: SemanticsRole.menu,
    );
    const positionDelegate = DefaultBaseMenuPositioningDelegate();
    const orientation = Axis.horizontal;
    const edgeBehavior = TraversalEdgeBehavior.closedLoop;

    void onOpenRequest(Offset? offset, VoidCallback showMenu) {
      onOpenRequestCalled = true;
      showMenu();
    }

    void onCloseRequest(VoidCallback closeMenu) {
      onCloseRequestCalled = true;
      closeMenu();
    }

    void onOpen() {
      onOpenCalled = true;
    }

    void onClose() {
      onCloseCalled = true;
    }

    await tester.pumpWidget(
      App(
        BaseSubmenu(
          focusNode: aFocusNode,
          role: SemanticsRole.none,
          controller: controller,
          onOpen: onOpen,
          onClose: onClose,
          onOpenRequest: onOpenRequest,
          onCloseRequest: onCloseRequest,
          onFocusChange: (focused) {
            isScopeFocused = focused;
          },
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          semanticProperties: semanticProperties,
          orientation: orientation,
          directionalFocusEdgeBehavior: edgeBehavior,
          consumeOutsideTaps: true,
          useRootOverlay: true,
          menu: Button.tag(Tag.a, focusNode: aFocusNode),
          child: const SubmenuChild(tag: Tag.anchor),
        ),
      ),
    );

    final baseMenuFinder = find.byType(BaseMenu);
    expect(baseMenuFinder, findsOneWidget);

    final baseMenu = tester.widget<BaseMenu>(baseMenuFinder);

    // Validate simple property pass-through
    expect(baseMenu.controller, controller);
    expect(baseMenu.consumeOutsideTaps, isTrue);
    expect(baseMenu.useRootOverlay, isTrue);
    expect(baseMenu.semanticProperties, semanticProperties);
    expect(baseMenu.positionDelegate, positionDelegate);
    expect(baseMenu.orientation, orientation);
    expect(baseMenu.directionalFocusEdgeBehavior, edgeBehavior);

    // Validate callback pass-through (onOpen)
    await tester.tap(find.text(Tag.anchor.text));

    expect(onOpenRequestCalled, isTrue);
    expect(onOpenCalled, isTrue);

    await tester.pump();

    expect(controller.isOpen, isTrue);
    expect(isScopeFocused, isFalse);

    aFocusNode.requestFocus();
    await tester.pump();

    expect(isScopeFocused, isTrue);

    await tester.tap(find.text(Tag.anchor.text));

    expect(onCloseRequestCalled, isTrue);
    expect(onCloseCalled, isTrue);

    await tester.pump();

    expect(controller.isOpen, isFalse);
    expect(isScopeFocused, isFalse);
  });

  testWidgets('configures BaseMenuItem', (WidgetTester tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    const cursor = WidgetStateMouseCursor.clickable;
    final gestureSemantics = MockSemanticsGestureDelegate();
    var didCallOnPressed = false;
    var didCallOnActivate = false;
    var didCallOnPointerEnter = false;
    var didCallOnPointerLeave = false;
    var didCallOnPointerHover = false;

    void mockOnPressed() {
      assert(!didCallOnPressed, 'onPressed should only be called once.');
      didCallOnPressed = true;
    }

    void mockOnActivate() {
      assert(!didCallOnActivate, 'onActivate should only be called once.');
      didCallOnActivate = true;
    }

    void mockOnPointerEnter(PointerEnterEvent event) {
      assert(!didCallOnPointerEnter, 'onPointerEnter should only be called once.');
      didCallOnPointerEnter = true;
    }

    void mockOnPointerHover(PointerHoverEvent event) {
      didCallOnPointerHover = true;
    }

    void mockOnPointerLeave(PointerExitEvent event) {
      assert(!didCallOnPointerLeave, 'onPointerLeave should only be called once.');
      didCallOnPointerLeave = true;
    }

    final shortcuts = {
      const SingleActivator(LogicalKeyboardKey.keyA): const BaseMenuEnterIntent.focusFirst(),
    };

    await tester.pumpWidget(
      App(
        BaseSubmenu(
          controller: controller,
          onPressed: mockOnPressed,
          onActivate: mockOnActivate,
          onPointerEnter: mockOnPointerEnter,
          onPointerHover: mockOnPointerHover,
          onPointerLeave: mockOnPointerLeave,
          focusNode: node,
          autofocus: true,
          behavior: HitTestBehavior.opaque,
          mouseCursor: cursor,
          gestureSemantics: gestureSemantics,
          shortcuts: shortcuts,
          role: SemanticsRole.none,
          menu: Text(Tag.a.text),
          child: const SubmenuChild(tag: Tag.anchor),
        ),
      ),
    );

    final menuItemFinder = find.byType(BaseMenuItem);
    expect(menuItemFinder, findsOneWidget);

    final menuItem = tester.widget<BaseMenuItem>(menuItemFinder);

    // Simple pass-throughs
    expect(menuItem.focusNode, node);
    expect(menuItem.autofocus, isTrue);
    expect(menuItem.onPressed, mockOnPressed);
    expect(menuItem.onPointerHover, mockOnPointerHover);
    expect(menuItem.behavior, HitTestBehavior.opaque);
    expect(menuItem.mouseCursor, cursor);
    expect(menuItem.role, SemanticsRole.none);
    expect(menuItem.gestureSemanticsEnabled, isTrue);
    expect(menuItem.gestureSemantics, gestureSemantics);

    // Shortcuts are merged - we check if our custom shortcut is present
    expect(
      menuItem.shortcuts,
      containsPair(
        const SingleActivator(LogicalKeyboardKey.keyA),
        const BaseMenuEnterIntent.focusFirst(),
      ),
    );

    // Verify Submenu-specific constants for the base item
    expect(menuItem.requestCloseOnActivate, isFalse);
    expect(menuItem.requestFocusOnHover, isTrue);

    // Validate pointer event wrappers correctly call the original callbacks
    final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(find.text(Tag.anchor.text)));
    await tester.pump();

    expect(didCallOnPointerEnter, isTrue);
    expect(didCallOnPointerHover, isTrue);

    await gesture.moveTo(Offset.infinite);
    await tester.pump();

    expect(didCallOnPointerLeave, isTrue);

    // Trigger onPressed through the menu item
    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();
    expect(didCallOnPressed, isTrue);

    // Trigger onActivate through the menu item
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(didCallOnActivate, isTrue);
  });

  testWidgets('wraps overlay with builder', (WidgetTester tester) async {
    await tester.pumpWidget(
      App(
        BaseSubmenu(
          controller: controller,
          role: null,
          overlayChildBuilder: (BuildContext context, Widget child) {
            return SizedBox(key: Tag.overlay.key, child: child);
          },
          menu: Text(Tag.a.text),
          child: const SubmenuChild(tag: Tag.anchor),
        ),
      ),
    );

    expect(find.byKey(Tag.overlay.key), findsNothing);
    expect(find.byKey(Tag.a.key), findsNothing);

    controller.open();
    await tester.pump();

    expect(find.byKey(Tag.overlay.key), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(Tag.overlay.key), matching: find.text(Tag.a.text)),
      findsOneWidget,
    );
  });

  testWidgets('passes request callbacks and overlay builder', (WidgetTester tester) async {
    var onOpenRequestCalled = false;
    var onCloseRequestCalled = false;

    void onOpenRequest(Offset? offset, VoidCallback showMenu) {
      onOpenRequestCalled = true;
      showMenu();
    }

    void onCloseRequest(VoidCallback closeMenu) {
      onCloseRequestCalled = true;
      closeMenu();
    }

    Widget overlayChildBuilder(BuildContext context, Widget child) {
      return SizedBox(key: Tag.overlay.key, child: child);
    }

    await tester.pumpWidget(
      App(
        BaseSubmenu(
          controller: controller,
          role: null,
          onOpenRequest: onOpenRequest,
          onCloseRequest: onCloseRequest,
          onPressed: () {
            controller.open();
          },
          overlayChildBuilder: overlayChildBuilder,
          menu: Text(Tag.a.text),
          child: const SubmenuChild(tag: Tag.anchor),
        ),
      ),
    );

    final baseMenu = tester.widget<BaseMenu>(find.byType(BaseMenu));

    expect(baseMenu.onOpenRequest, onOpenRequest);
    expect(baseMenu.onCloseRequest, onCloseRequest);

    // Open the menu to trigger the overlay builder
    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    expect(onOpenRequestCalled, isTrue);
    expect(find.byKey(Tag.overlay.key), findsOneWidget);

    // Close to trigger close request
    controller.close();
    await tester.pump();

    expect(onCloseRequestCalled, isTrue);
  });

  group('BaseSubmenu Hover Dynamics', () {
    testWidgets('opens after hoverOpenDelay', (WidgetTester tester) async {
      const delay = Duration(milliseconds: 500);
      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            controller: controller,
            hoverOpenDelay: delay,
            menu: Button.tag(Tag.a),
            child: const SubmenuChild(tag: Tag.anchor),
          ),
        ),
      );

      final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text(Tag.anchor.text)));
      await tester.pump();

      expect(controller.isOpen, isFalse);

      // Advance half the delay
      await tester.pump(const Duration(milliseconds: 250));
      expect(controller.isOpen, isFalse);

      // Advance past the delay
      await tester.pump(const Duration(milliseconds: 251));
      expect(controller.isOpen, isTrue);
      await gesture.removePointer();
    });

    testWidgets('closes after hoverCloseDelay', (WidgetTester tester) async {
      const delay = Duration(milliseconds: 500);
      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,

            controller: controller,
            hoverCloseDelay: delay,
            menu: Button.tag(Tag.a),
            child: const SubmenuChild(tag: Tag.anchor),
          ),
        ),
      );

      controller.open();
      await tester.pump();
      expect(controller.isOpen, isTrue);

      final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
      await gesture.addPointer(location: tester.getCenter(find.text(Tag.anchor.text)));
      await tester.pump();

      // Exit anchor
      await gesture.moveTo(Offset.infinite);
      await tester.pump();

      expect(controller.isOpen, isTrue);
      await tester.pump(const Duration(milliseconds: 501));
      expect(controller.isOpen, isFalse);
      await gesture.removePointer();
    });

    testWidgets('moving from anchor to panel cancels close timer', (WidgetTester tester) async {
      const delay = Duration(milliseconds: 500);
      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            controller: controller,
            hoverCloseDelay: delay,
            menu: Button.tag(Tag.a, key: Tag.a.key),
            child: const SubmenuChild(tag: Tag.anchor),
          ),
        ),
      );

      controller.open();
      await tester.pump();

      final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
      await gesture.addPointer(location: tester.getCenter(find.text(Tag.anchor.text)));
      await tester.pump();

      // Leave anchor, entering the void briefly
      await gesture.moveTo(Offset.infinite);
      await tester.pump(const Duration(milliseconds: 250));

      // Enter the submenu panel
      await gesture.moveTo(tester.getCenter(find.byKey(Tag.a.key)));
      await tester.pump();

      // Wait past the original close delay
      await tester.pump(const Duration(milliseconds: 300));
      expect(controller.isOpen, isTrue, reason: 'Panel hover should have cancelled close timer');
      await gesture.removePointer();
    });
  });

  group('BaseSubmenu Focus & Highlighting', () {
    testWidgets('anchor maintains highlight when submenu has focus (Pseudo-focus)', (
      WidgetTester tester,
    ) async {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() {
        FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
      });
      final nestedController = MenuController();
      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            controller: controller,
            autofocus: true,
            menu: BaseSubmenu(
              role: null,
              controller: nestedController,
              menu: Button.tag(Tag.a.a),
              child: Text(Tag.a.text),
            ),
            child: const SubmenuChild(tag: Tag.anchor),
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(controller.isOpen, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(nestedController.isOpen, isTrue);

      final element = tester.element(find.text(Tag.anchor.text));

      expect(BaseMenuItem.isFocusHighlightShownOf(element), isTrue);
    });

    testWidgets('hovering panel requests focus', (WidgetTester tester) async {
      final anchorFocus = FocusNode();
      addTearDown(anchorFocus.dispose);

      await tester.pumpWidget(
        App(
          Column(
            children: [
              Button.text('Outside', autofocus: true),
              BaseSubmenu(
                role: null,

                focusNode: anchorFocus,
                controller: controller,
                menu: Button.tag(Tag.a, key: Tag.a.key),
                child: const SubmenuChild(tag: Tag.anchor),
              ),
            ],
          ),
        ),
      );

      controller.open();
      await tester.pump();
      expect(anchorFocus.hasFocus, isFalse);

      final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
      await gesture.addPointer(location: tester.getCenter(find.byKey(Tag.a.key)));
      await tester.pump();

      expect(
        anchorFocus.hasFocus,
        isTrue,
        reason: 'Hovering panel should cause anchor to request focus',
      );
      await gesture.removePointer();
    });
  });

  group('BaseSubmenu Integration', () {
    testWidgets('Disabled state prevents hover open', (WidgetTester tester) async {
      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            enabled: false,
            controller: controller,
            menu: Button.tag(Tag.a),
            child: const SubmenuChild(tag: Tag.anchor),
          ),
        ),
      );

      final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text(Tag.anchor.text)));
      await tester.pump(const Duration(seconds: 1));

      expect(controller.isOpen, isFalse);
    });

    testWidgets('Disabled state prevents onPressed from being called', (WidgetTester tester) async {
      var onPressedCalled = false;
      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            enabled: false,
            onPressed: () => onPressedCalled = true,
            controller: controller,
            menu: Button.tag(Tag.a),
            child: const SubmenuChild(tag: Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();

      expect(onPressedCalled, isFalse);
      expect(controller.isOpen, isFalse);
    });

    testWidgets('Disabled state prevents onActivate from being called', (
      WidgetTester tester,
    ) async {
      var onActivateCalled = false;
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            enabled: false,
            focusNode: focusNode,
            // Provide a custom onActivate to catch the call
            onActivate: () => onActivateCalled = true,
            controller: controller,
            menu: Button.tag(Tag.a),
            child: const SubmenuChild(tag: Tag.anchor),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();

      // Send the activation key (Enter/Space typically trigger BaseMenuItem activation)
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(onActivateCalled, isFalse);
      expect(controller.isOpen, isFalse);
    });

    testWidgets('Submenu closes when the anchor becomes disabled', (WidgetTester tester) async {
      var onCloseCalled = false;
      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            controller: controller,
            menu: SizedBox(key: Tag.a.key),
            child: const SubmenuChild(tag: Tag.anchor),
          ),
        ),
      );

      controller.open();
      await tester.pump();

      expect(controller.isOpen, isTrue);
      expect(find.byKey(Tag.a.key), findsOneWidget);

      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            enabled: false,
            onClose: () {
              onCloseCalled = true;
            },
            controller: controller,
            menu: SizedBox(key: Tag.a.key),
            child: const SubmenuChild(tag: Tag.anchor),
          ),
        ),
      );
      await tester.pump();

      expect(controller.isOpen, isFalse, reason: 'Menu should close when anchor is disabled');
      expect(find.byKey(Tag.a.key), findsNothing);
      expect(
        onCloseCalled,
        isTrue,
        reason: 'onClose should be called when menu closes due to anchor being disabled',
      );
    });
  });

  group('Directional Navigation Cross-Axis', () {
    late MenuController controller1;
    late MenuController controller2;
    late FocusNode focusNode1;
    late FocusNode focusNode2;
    late FocusNode panelItemFocus1;
    late FocusNode panelItemFocus2;
    final intents = <Intent>[];
    final traversalCaptureActions = {
      BaseMenuHorizontalFocusPreviousIntent: CallbackAction<BaseMenuHorizontalFocusPreviousIntent>(
        onInvoke: intents.add,
      ),
      BaseMenuHorizontalFocusNextIntent: CallbackAction<BaseMenuHorizontalFocusNextIntent>(
        onInvoke: intents.add,
      ),
      BaseMenuVerticalFocusPreviousIntent: CallbackAction<BaseMenuVerticalFocusPreviousIntent>(
        onInvoke: intents.add,
      ),
      BaseMenuVerticalFocusNextIntent: CallbackAction<BaseMenuVerticalFocusNextIntent>(
        onInvoke: intents.add,
      ),
    };
    setUp(() {
      controller1 = MenuController();
      controller2 = MenuController();
      focusNode1 = FocusNode();
      focusNode2 = FocusNode();
      panelItemFocus1 = FocusNode();
      panelItemFocus2 = FocusNode();
    });

    tearDown(() {
      focusNode1.dispose();
      focusNode2.dispose();
      panelItemFocus1.dispose();
      panelItemFocus2.dispose();
      intents.clear();
    });
    testWidgets('H -> H OverlayPrevious: closes menu when orientations match and open', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          MenuScope(
            orientation: Axis.horizontal,
            isSubmenu: false,
            child: BaseSubmenu(
              role: null,
              controller: controller,
              orientation: Axis.horizontal,
              menu: Container(
                key: Tag.a.key,
                color: const ui.Color(0xFFFFBB00),
                width: 100,
                height: 100,
              ),
              child: const SubmenuChild(tag: Tag.anchor),
            ),
          ),
        ),
      );
      controller.open();
      await tester.pump();
      expect(controller.isOpen, isTrue);

      Actions.invoke(
        tester.element(find.byKey(Tag.a.key)),
        const BaseMenuVerticalFocusPreviousIntent(),
      );

      await tester.pump();
      await tester.pump();
      expect(controller.isOpen, isFalse);
    });

    testWidgets('V -> V OverlayPrevious: closes menu when orientations match and open', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          MenuScope(
            orientation: Axis.vertical,
            isSubmenu: false,
            child: BaseSubmenu(
              role: null,
              controller: controller,
              menu: Container(
                key: Tag.a.key,
                color: const ui.Color(0xFFFFBB00),
                width: 100,
                height: 100,
              ),
              child: const SubmenuChild(tag: Tag.anchor),
            ),
          ),
        ),
      );
      controller.open();
      await tester.pump();
      expect(controller.isOpen, isTrue);

      Actions.invoke(
        tester.element(find.byKey(Tag.a.key)),
        const BaseMenuHorizontalFocusPreviousIntent(),
      );

      await tester.pump();
      await tester.pump();
      expect(controller.isOpen, isFalse);
    });

    testWidgets('Anchor: propagates intent when closed', (WidgetTester tester) async {
      await tester.pumpWidget(
        App(
          Actions(
            actions: traversalCaptureActions,
            child: MenuScope(
              orientation: Axis.horizontal,
              isSubmenu: false,
              child: BaseSubmenu(
                role: null,
                autofocus: true,
                controller: controller,
                menu: const SizedBox(),
                child: Text(Tag.anchor.text),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      Actions.invoke(primaryFocus!.context!, const BaseMenuVerticalFocusPreviousIntent());
      Actions.invoke(primaryFocus!.context!, const BaseMenuVerticalFocusNextIntent());
      Actions.invoke(primaryFocus!.context!, const BaseMenuHorizontalFocusPreviousIntent());
      Actions.invoke(primaryFocus!.context!, const BaseMenuHorizontalFocusNextIntent());

      await tester.pump();
      expect(
        intents,
        equals([
          isA<BaseMenuVerticalFocusPreviousIntent>(),
          isA<BaseMenuVerticalFocusNextIntent>(),
          isA<BaseMenuHorizontalFocusPreviousIntent>(),
          isA<BaseMenuHorizontalFocusNextIntent>(),
        ]),
      );
    });

    testWidgets('H -> V OverlayPrevious: wraps to last item when at first item', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          MenuScope(
            orientation: Axis.horizontal,
            isSubmenu: false,
            child: Column(
              children: [
                BaseSubmenu(
                  role: null,
                  controller: controller1,
                  focusNode: focusNode1,
                  menu: Focus(
                    focusNode: panelItemFocus1,
                    child: Container(color: const Color(0xFFFFBB00), height: 20, width: 20),
                  ),
                  child: const SubmenuChild(tag: Tag.a),
                ),
                BaseSubmenu(
                  role: null,
                  controller: controller2,
                  focusNode: focusNode2,
                  menu: Focus(
                    focusNode: panelItemFocus2,
                    child: Container(color: const ui.Color(0xFFFF6A00), height: 20, width: 20),
                  ),
                  child: const SubmenuChild(tag: Tag.b),
                ),
              ],
            ),
          ),
        ),
      );

      controller1.open();
      await tester.pump();
      panelItemFocus1.requestFocus();
      await tester.pump();

      Actions.invoke<BaseMenuHorizontalFocusPreviousIntent>(
        panelItemFocus1.context!,
        const BaseMenuHorizontalFocusPreviousIntent(),
      );

      await tester.pump();
      expect(focusNode2.hasPrimaryFocus, isTrue);
    });

    testWidgets('V -> H OverlayPrevious: wraps to last item when at first item', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          MenuScope(
            orientation: Axis.vertical,
            isSubmenu: false,
            child: Column(
              children: [
                BaseSubmenu(
                  role: null,
                  controller: controller1,
                  focusNode: focusNode1,
                  orientation: Axis.horizontal,
                  menu: Focus(
                    focusNode: panelItemFocus1,
                    child: Container(color: const Color(0xFFFFBB00), height: 20, width: 20),
                  ),
                  child: const SubmenuChild(tag: Tag.a),
                ),
                BaseSubmenu(
                  role: null,
                  controller: controller2,
                  focusNode: focusNode2,
                  orientation: Axis.horizontal,
                  menu: Focus(
                    focusNode: panelItemFocus2,
                    child: Container(color: const ui.Color(0xFFFF6A00), height: 20, width: 20),
                  ),
                  child: const SubmenuChild(tag: Tag.b),
                ),
              ],
            ),
          ),
        ),
      );

      controller1.open();
      await tester.pump();
      panelItemFocus1.requestFocus();
      await tester.pump();

      Actions.invoke<BaseMenuVerticalFocusPreviousIntent>(
        panelItemFocus1.context!,
        const BaseMenuVerticalFocusPreviousIntent(),
      );

      await tester.pump();
      expect(focusNode2.hasPrimaryFocus, isTrue);
    });

    testWidgets('H -> V OverlayPrevious: moves to previous', (WidgetTester tester) async {
      await tester.pumpWidget(
        App(
          MenuScope(
            orientation: Axis.horizontal,
            isSubmenu: false,
            child: Column(
              children: [
                BaseSubmenu(
                  role: null,
                  controller: controller1,
                  focusNode: focusNode1,
                  menu: Focus(
                    key: Tag.a.key,
                    focusNode: panelItemFocus1,
                    child: Container(color: const Color(0xFFFFBB00), height: 20, width: 20),
                  ),
                  child: const SubmenuChild(tag: Tag.a),
                ),
                BaseSubmenu(
                  role: null,
                  controller: controller2,
                  focusNode: focusNode2,
                  menu: Focus(
                    focusNode: panelItemFocus2,
                    child: Container(color: const ui.Color(0xFFFF6A00), height: 20, width: 20),
                  ),
                  child: const SubmenuChild(tag: Tag.b),
                ),
              ],
            ),
          ),
        ),
      );

      controller2.open();
      await tester.pump();

      Actions.invoke<BaseMenuHorizontalFocusPreviousIntent>(
        panelItemFocus2.context!,
        const BaseMenuHorizontalFocusPreviousIntent(),
      );

      await tester.pump();

      expect(focusNode1.hasPrimaryFocus, isTrue);
      expect(find.byKey(Tag.a.key), findsOneWidget);
    });

    testWidgets('V -> H OverlayPrevious: moves to previous', (WidgetTester tester) async {
      await tester.pumpWidget(
        App(
          MenuScope(
            orientation: Axis.vertical,
            isSubmenu: false,
            child: Column(
              children: [
                BaseSubmenu(
                  role: null,
                  controller: controller1,
                  focusNode: focusNode1,
                  orientation: Axis.horizontal,
                  menu: Focus(
                    key: Tag.a.key,
                    focusNode: panelItemFocus1,
                    child: Container(color: const Color(0xFFFFBB00), height: 20, width: 20),
                  ),
                  child: const SubmenuChild(tag: Tag.a),
                ),
                BaseSubmenu(
                  role: null,
                  controller: controller2,
                  focusNode: focusNode2,
                  orientation: Axis.horizontal,
                  menu: Focus(
                    focusNode: panelItemFocus2,
                    child: Container(color: const ui.Color(0xFFFF6A00), height: 20, width: 20),
                  ),
                  child: const SubmenuChild(tag: Tag.b),
                ),
              ],
            ),
          ),
        ),
      );

      controller2.open();
      await tester.pump();
      panelItemFocus2.requestFocus();

      Actions.invoke<BaseMenuVerticalFocusPreviousIntent>(
        panelItemFocus2.context!,
        const BaseMenuVerticalFocusPreviousIntent(),
      );

      await tester.pump();

      expect(focusNode1.hasPrimaryFocus, isTrue);
      expect(find.byKey(Tag.a.key), findsOneWidget);
    });

    testWidgets('V OverlayPrevious: propagates intent if no ancestor exists', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          Actions(
            actions: traversalCaptureActions,
            child: BaseSubmenu(
              role: null,
              controller: controller,
              focusNode: focusNode1,
              menu: Focus(focusNode: panelItemFocus1, child: const SizedBox()),
              child: Text(Tag.anchor.text),
            ),
          ),
        ),
      );

      controller.open();
      await tester.pump();

      Actions.invoke(panelItemFocus1.context!, const BaseMenuHorizontalFocusPreviousIntent());
      Actions.invoke(panelItemFocus1.context!, const BaseMenuHorizontalFocusNextIntent());
      Actions.invoke(panelItemFocus1.context!, const BaseMenuVerticalFocusPreviousIntent());
      Actions.invoke(panelItemFocus1.context!, const BaseMenuVerticalFocusNextIntent());

      expect(
        intents,
        equals([
          const BaseMenuHorizontalFocusPreviousIntent(),
          const BaseMenuHorizontalFocusNextIntent(),
        ]),
      );
    });

    testWidgets('H OverlayPrevious: propagates intent if no ancestor exists', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          Actions(
            actions: traversalCaptureActions,
            child: BaseSubmenu(
              role: null,
              controller: controller,
              focusNode: focusNode1,
              menu: Focus(focusNode: panelItemFocus1, child: const SizedBox()),
              child: Text(Tag.anchor.text),
            ),
          ),
        ),
      );
      controller.open();
      await tester.pump();

      Actions.invoke(panelItemFocus1.context!, const BaseMenuHorizontalFocusPreviousIntent());
      Actions.invoke(panelItemFocus1.context!, const BaseMenuHorizontalFocusNextIntent());
      Actions.invoke(panelItemFocus1.context!, const BaseMenuVerticalFocusPreviousIntent());
      Actions.invoke(panelItemFocus1.context!, const BaseMenuVerticalFocusNextIntent());

      expect(
        intents,
        equals([
          const BaseMenuHorizontalFocusPreviousIntent(),
          const BaseMenuHorizontalFocusNextIntent(),
        ]),
      );
    });

    testWidgets('H -> V OverlayNext: wraps to first item when at last item', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          MenuScope(
            orientation: Axis.horizontal,
            isSubmenu: false,
            child: Column(
              children: [
                BaseSubmenu(
                  role: null,
                  controller: controller1,
                  focusNode: focusNode1,
                  menu: Focus(
                    focusNode: panelItemFocus1,
                    child: const SizedBox(height: 20, width: 20),
                  ),
                  child: Text(Tag.a.text),
                ),
                BaseSubmenu(
                  role: null,
                  controller: controller2,
                  focusNode: focusNode2,
                  menu: Focus(
                    focusNode: panelItemFocus2,
                    child: const SizedBox(height: 20, width: 20),
                  ),
                  child: Text(Tag.b.text),
                ),
              ],
            ),
          ),
        ),
      );
      controller2.open();
      await tester.pump();
      panelItemFocus2.requestFocus();
      await tester.pump();

      Actions.invoke(panelItemFocus2.context!, const BaseMenuHorizontalFocusNextIntent());

      await tester.pump();
      expect(focusNode1.hasFocus, isTrue);
      expect(controller1.isOpen, isTrue);
    });

    testWidgets('V -> H OverlayNext: wraps to first item when at last item', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          MenuScope(
            orientation: Axis.vertical,
            isSubmenu: false,
            child: Column(
              children: [
                BaseSubmenu(
                  role: null,
                  controller: controller1,
                  focusNode: focusNode1,
                  orientation: Axis.horizontal,
                  menu: Focus(
                    focusNode: panelItemFocus1,
                    child: const SizedBox(height: 20, width: 20),
                  ),
                  child: Text(Tag.a.text),
                ),
                BaseSubmenu(
                  role: null,
                  controller: controller2,
                  focusNode: focusNode2,
                  orientation: Axis.horizontal,
                  menu: Focus(
                    focusNode: panelItemFocus2,
                    child: const SizedBox(height: 20, width: 20),
                  ),
                  child: Text(Tag.b.text),
                ),
              ],
            ),
          ),
        ),
      );

      controller2.open();
      await tester.pump();
      panelItemFocus2.requestFocus();
      await tester.pump();

      Actions.invoke(panelItemFocus2.context!, const BaseMenuVerticalFocusNextIntent());

      await tester.pump();

      expect(focusNode1.hasFocus, isTrue);
      expect(controller1.isOpen, isTrue);
    });

    testWidgets(
      'H -> V OverlayNext: moves to next item when not at last item (focus inside overlay)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          App(
            MenuScope(
              orientation: Axis.horizontal,
              isSubmenu: false,
              child: Column(
                children: [
                  BaseSubmenu(
                    role: null,
                    controller: controller1,
                    focusNode: focusNode1,
                    menu: Focus(
                      focusNode: panelItemFocus1,
                      child: const SizedBox(height: 20, width: 20),
                    ),
                    child: Text(Tag.a.text),
                  ),
                  BaseSubmenu(
                    role: null,
                    controller: controller2,
                    focusNode: focusNode2,
                    menu: Focus(
                      focusNode: panelItemFocus2,
                      child: const SizedBox(height: 20, width: 20),
                    ),
                    child: Text(Tag.b.text),
                  ),
                ],
              ),
            ),
          ),
        );
        controller1.open();
        await tester.pump();
        panelItemFocus1.requestFocus();
        await tester.pump();
        Actions.invoke(panelItemFocus1.context!, const BaseMenuHorizontalFocusNextIntent());
        await tester.pump();

        expect(focusNode2.hasFocus, isTrue);
        expect(controller2.isOpen, isTrue);
      },
    );

    testWidgets(
      'V -> H OverlayNext: moves to next item when not at last item (focus inside overlay)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          App(
            MenuScope(
              orientation: Axis.vertical,
              isSubmenu: false,
              child: Column(
                children: [
                  BaseSubmenu(
                    role: null,
                    orientation: Axis.horizontal,
                    controller: controller1,
                    focusNode: focusNode1,
                    menu: Focus(
                      focusNode: panelItemFocus1,
                      child: const SizedBox(height: 20, width: 20),
                    ),
                    child: Text(Tag.a.text),
                  ),
                  BaseSubmenu(
                    role: null,
                    orientation: Axis.horizontal,
                    controller: controller2,
                    focusNode: focusNode2,
                    menu: Focus(
                      focusNode: panelItemFocus2,
                      child: const SizedBox(height: 20, width: 20),
                    ),
                    child: Text(Tag.b.text),
                  ),
                ],
              ),
            ),
          ),
        );
        controller1.open();
        await tester.pump();
        panelItemFocus1.requestFocus();
        await tester.pump();
        Actions.invoke(panelItemFocus1.context!, const BaseMenuVerticalFocusNextIntent());
        await tester.pump();
        expect(focusNode2.hasFocus, isTrue);
        expect(controller2.isOpen, isTrue);
      },
    );

    testWidgets(
      'V -> H OverlayNext: moves to next item when not at last item (focus inside overlay)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          App(
            MenuScope(
              orientation: Axis.vertical,
              isSubmenu: false,
              child: Column(
                children: [
                  BaseSubmenu(
                    role: null,
                    orientation: Axis.horizontal,
                    controller: controller1,
                    focusNode: focusNode1,
                    menu: Focus(
                      focusNode: panelItemFocus1,
                      child: const SizedBox(height: 20, width: 20),
                    ),
                    child: Text(Tag.a.text),
                  ),
                  BaseSubmenu(
                    role: null,
                    orientation: Axis.horizontal,
                    controller: controller2,
                    focusNode: focusNode2,
                    menu: Focus(
                      focusNode: panelItemFocus2,
                      child: const SizedBox(height: 20, width: 20),
                    ),
                    child: Text(Tag.b.text),
                  ),
                ],
              ),
            ),
          ),
        );
        controller1.open();
        await tester.pump();
        panelItemFocus1.requestFocus();
        await tester.pump();
        Actions.invoke(panelItemFocus1.context!, const BaseMenuVerticalFocusNextIntent());
        await tester.pump();
        expect(focusNode2.hasFocus, isTrue);
        expect(controller2.isOpen, isTrue);
      },
    );

    testWidgets('V -> V AnchorPrevious: closes menu inside nested submenu', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            controller: controller1,
            focusNode: focusNode1,
            menu: BaseSubmenu(
              role: null,
              controller: controller2,
              focusNode: focusNode2,
              menu: Text(Tag.a.a.text),
              child: Text(Tag.a.text),
            ),
            child: Text(Tag.anchor.text),
          ),
        ),
      );
      controller1.open();
      await tester.pump();
      controller2.open();
      await tester.pump();

      Actions.invoke(
        tester.element(find.text(Tag.a.text)),
        const BaseMenuHorizontalFocusPreviousIntent(),
      );

      await tester.pump();
      expect(controller2.isOpen, isFalse);
    });

    testWidgets('H -> H AnchorPrevious: closes menu inside nested submenu', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            controller: controller1,
            focusNode: focusNode1,
            orientation: Axis.horizontal,
            menu: BaseSubmenu(
              role: null,
              controller: controller2,
              focusNode: focusNode2,
              orientation: Axis.horizontal,
              menu: Text(Tag.a.a.text),
              child: Text(Tag.a.text),
            ),
            child: Text(Tag.anchor.text),
          ),
        ),
      );
      controller1.open();
      await tester.pump();
      controller2.open();
      await tester.pump();

      Actions.invoke(
        tester.element(find.text(Tag.a.text)),
        const BaseMenuVerticalFocusPreviousIntent(),
      );

      await tester.pump();
      expect(controller2.isOpen, isFalse);
    });

    testWidgets('V -> V AnchorPrevious: propagates inside nested submenu anchor when closed', (
      WidgetTester tester,
    ) async {
      var parentActionCalled = false;
      await tester.pumpWidget(
        App(
          Actions(
            actions: {
              BaseMenuHorizontalFocusPreviousIntent:
                  CallbackAction<BaseMenuHorizontalFocusPreviousIntent>(
                    onInvoke: (_) {
                      parentActionCalled = true;
                      return null;
                    },
                  ),
            },
            child: BaseSubmenu(
              role: null,
              controller: controller1,
              focusNode: focusNode1,
              menu: BaseSubmenu(
                role: null,
                controller: controller2,
                focusNode: focusNode2,
                menu: Text(Tag.a.a.text),
                child: Text(Tag.a.text),
              ),
              child: Text(Tag.anchor.text),
            ),
          ),
        ),
      );
      controller1.open();
      await tester.pump();
      controller2.open();
      await tester.pump();
      controller2.close();
      await tester.pump();

      Actions.invoke(
        tester.element(find.text(Tag.a.text)),
        const BaseMenuHorizontalFocusPreviousIntent(),
      );

      await tester.pump();
      expect(parentActionCalled, isTrue);
    });

    testWidgets('H -> H AnchorPrevious: propagates inside nested submenu when closed', (
      WidgetTester tester,
    ) async {
      var parentActionCalled = false;
      await tester.pumpWidget(
        App(
          Actions(
            actions: {
              BaseMenuVerticalFocusPreviousIntent:
                  CallbackAction<BaseMenuVerticalFocusPreviousIntent>(
                    onInvoke: (_) {
                      parentActionCalled = true;
                      return null;
                    },
                  ),
            },
            child: BaseSubmenu(
              role: null,
              controller: controller1,
              orientation: Axis.horizontal,
              focusNode: focusNode1,
              menu: BaseSubmenu(
                role: null,
                controller: controller2,
                orientation: Axis.horizontal,
                focusNode: focusNode2,
                menu: Text(Tag.a.a.text),
                child: Text(Tag.a.text),
              ),
              child: Text(Tag.anchor.text),
            ),
          ),
        ),
      );
      controller1.open();
      await tester.pump();
      controller2.open();
      await tester.pump();
      controller2.close();
      await tester.pump();

      Actions.invoke(
        tester.element(find.text(Tag.a.text)),
        const BaseMenuVerticalFocusPreviousIntent(),
      );

      await tester.pump();
      expect(parentActionCalled, isTrue);
    });

    testWidgets('V AnchorPrevious: focuses and opens previous anchor when open', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          Column(
            children: [
              BaseSubmenu(
                role: null,
                controller: controller1,
                focusNode: focusNode1,
                menu: Text(Tag.a.a.text),
                child: Text(Tag.a.text),
              ),
              BaseSubmenu(
                role: null,
                controller: controller2,
                focusNode: focusNode2,
                menu: Text(Tag.b.a.text),
                child: Text(Tag.b.text),
              ),
            ],
          ),
        ),
      );
      focusNode1.requestFocus();
      controller1.open();
      await tester.pump();
      Actions.invoke(focusNode1.context!, const BaseMenuHorizontalFocusPreviousIntent());
      await tester.pump();

      expect(focusNode2.hasFocus, isTrue);
      expect(controller2.isOpen, isTrue);
    });

    testWidgets('H AnchorPrevious: focuses and opens previous anchor when open', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          Column(
            children: [
              BaseSubmenu(
                role: null,
                orientation: Axis.horizontal,
                controller: controller1,
                focusNode: focusNode1,
                menu: Text(Tag.a.a.text),
                child: Text(Tag.a.text),
              ),
              BaseSubmenu(
                role: null,
                orientation: Axis.horizontal,
                controller: controller2,
                focusNode: focusNode2,
                menu: Text(Tag.b.a.text),
                child: Text(Tag.b.text),
              ),
            ],
          ),
        ),
      );

      focusNode1.requestFocus();
      controller1.open();
      await tester.pump();
      Actions.invoke(focusNode1.context!, const BaseMenuVerticalFocusPreviousIntent());
      await tester.pump();

      expect(focusNode2.hasFocus, isTrue);
      expect(controller2.isOpen, isTrue);
    });

    testWidgets('H -> V AnchorPrevious: focuses and opens previous anchor when open', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          MenuScope(
            orientation: Axis.horizontal,
            isSubmenu: false,
            child: Column(
              children: [
                BaseSubmenu(
                  role: null,
                  controller: controller1,
                  focusNode: focusNode1,
                  menu: Text(Tag.a.a.text),
                  child: Text(Tag.a.text),
                ),
                BaseSubmenu(
                  role: null,
                  controller: controller2,
                  focusNode: focusNode2,
                  menu: Text(Tag.b.a.text),
                  child: Text(Tag.b.text),
                ),
              ],
            ),
          ),
        ),
      );

      focusNode1.requestFocus();
      controller1.open();
      await tester.pump();
      Actions.invoke(focusNode1.context!, const BaseMenuHorizontalFocusNextIntent());
      await tester.pump();

      expect(focusNode2.hasFocus, isTrue);
      expect(controller2.isOpen, isTrue);
    });

    testWidgets('V -> H AnchorCrossAxisNext: focuses and opens next anchor when open', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          MenuScope(
            orientation: Axis.vertical,
            isSubmenu: false,
            child: Column(
              children: [
                BaseSubmenu(
                  role: null,
                  orientation: Axis.horizontal,
                  controller: controller1,
                  focusNode: focusNode1,
                  menu: Text(Tag.a.a.text),
                  child: Text(Tag.a.text),
                ),
                BaseSubmenu(
                  role: null,
                  orientation: Axis.horizontal,
                  controller: controller2,
                  focusNode: focusNode2,
                  menu: Text(Tag.b.a.text),
                  child: Text(Tag.b.text),
                ),
              ],
            ),
          ),
        ),
      );

      focusNode1.requestFocus();
      controller1.open();
      await tester.pump();
      Actions.invoke(focusNode1.context!, const BaseMenuVerticalFocusNextIntent());
      await tester.pump();

      expect(focusNode2.hasFocus, isTrue);
      expect(controller2.isOpen, isTrue);
    });
  });

  group('Orientation & RTL', () {
    testWidgets('Horizontal submenus handle vertical intents in overlay', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,

            controller: controller,
            orientation: Axis.horizontal,
            menu: const Text('Vertical Item'),
            child: const Text('Anchor'),
          ),
        ),
      );
      controller.open();
      await tester.pump();
      final panel = find.byType(BaseMenuPanel).evaluate().single;

      final resultNext = Actions.maybeInvoke(panel, const BaseMenuVerticalFocusNextIntent());
      expect(resultNext, isNotNull);
      final resultPrev = Actions.maybeInvoke(panel, const BaseMenuVerticalFocusPreviousIntent());
      expect(resultPrev, isNotNull);
    });
    testWidgets('RTL layouts swap focusFirst shortcut to ArrowLeft', (WidgetTester tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        App(
          textDirection: TextDirection.rtl,
          BaseMenuBar(
            child: BaseSubmenu(
              role: null,

              controller: controller,
              focusNode: focusNode,
              menu: const Text('RTL Item'),
              child: const Text('Anchor'),
            ),
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(controller.isOpen, isTrue);
    });
    testWidgets('LTR layouts swap focusFirst shortcut to ArrowRight', (WidgetTester tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        App(
          textDirection: TextDirection.ltr,
          BaseMenuBar(
            child: BaseSubmenu(
              role: null,

              controller: controller,
              focusNode: focusNode,
              menu: const Text('LTR Item'),
              child: const Text('Anchor'),
            ),
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(controller.isOpen, isTrue);
    });
    testWidgets('RTL layouts: focusLast uses Right Arrow in cross-orientation', (
      WidgetTester tester,
    ) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        App(
          textDirection: TextDirection.rtl,
          BaseMenuBar(
            axis: Axis.vertical,
            child: BaseSubmenu(
              role: null,

              controller: controller,
              focusNode: focusNode,
              orientation: Axis.horizontal,
              menu: const Text('Target'),
              child: const Text('Anchor'),
            ),
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(controller.isOpen, isTrue);
    });
    testWidgets('LTR layouts: focusLast uses Left Arrow in cross-orientation', (
      WidgetTester tester,
    ) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        App(
          textDirection: TextDirection.ltr,
          BaseMenuBar(
            axis: Axis.vertical,
            child: BaseSubmenu(
              role: null,

              controller: controller,
              focusNode: focusNode,
              orientation: Axis.horizontal,
              menu: const Text('Target'),
              child: const Text('Anchor'),
            ),
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(controller.isOpen, isTrue);
    });
  });
  group('Edge Case Coverage', () {
    testWidgets('Delayed hover close when scope focus is lost without direct anchor focus', (
      WidgetTester tester,
    ) async {
      const closeDelay = Duration(milliseconds: 100);
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,

            controller: controller,
            focusNode: focusNode,
            hoverCloseDelay: closeDelay,
            menu: const Text('Menu'),
            child: const Text('Anchor'),
          ),
        ),
      );
      controller.open();
      await tester.pump();
      final baseMenu = tester.widget<BaseMenu>(find.byType(BaseMenu));
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      baseMenu.onFocusChange!(false);
      await tester.pump();
      expect(controller.isOpen, isTrue);
      await tester.pump(closeDelay + const Duration(milliseconds: 10));
      expect(controller.isOpen, isFalse);
    });
    testWidgets('Submenu didUpdateWidget does not close when already closed or disabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            enabled: false,
            controller: controller,
            menu: const SizedBox(),
            child: const Text('Anchor'),
          ),
        ),
      );
      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            enabled: false,
            controller: controller,
            menu: const SizedBox(),
            child: const Text('Anchor'),
          ),
        ),
      );
      await tester.pump();
      expect(controller.isOpen, isFalse);
    });
  });
}

class MockFocusNode extends FocusNode {
  @override
  bool get hasListeners => super.hasListeners;
}
