import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_utilities/menu_utilities.dart';

void main() {
  group('BaseMenuItem', () {
    testWidgets('Initial state is idle', (WidgetTester tester) async {
      await tester.pumpWidget(
        App(BaseMenuItem<void>(onPressed: () {}, role: null, child: Text(Tag.a.text))),
      );

      final element = tester.element(find.text(Tag.a.text));
      expect(BaseMenuItem.statesOf<void>(element), isEmpty);
      expect(BaseMenuItem.isDisabledOf<void>(element), isFalse);
      expect(BaseMenuItem.isHoveredOf<void>(element), isFalse);
      expect(BaseMenuItem.isPressedOf<void>(element), isFalse);
      expect(BaseMenuItem.isFocusedOf<void>(element), isFalse);
    });

    testWidgets('Disabled state when onPressed is null', (WidgetTester tester) async {
      Set<WidgetState>? states;

      await tester.pumpWidget(
        App(
          BaseMenuItem<void>(
            role: null,
            child: Builder(
              builder: (BuildContext context) {
                states = BaseMenuItem.statesOf<void>(context);
                return Text(Tag.a.text);
              },
            ),
          ),
        ),
      );

      expect(states, contains(WidgetState.disabled));
      final element = tester.element(find.text(Tag.a.text));

      expect(BaseMenuItem.isDisabledOf<void>(element), isTrue);
    });
  });

  group('Hover', () {
    testWidgets('requests focus if requestFocusOnHover is true', (WidgetTester tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        App(
          BaseMenuItem<void>(
            role: null,
            onPressed: () {},
            focusNode: node,
            child: Text(Tag.a.text),
          ),
        ),
      );

      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);

      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text(Tag.a.text)));
      await tester.pump();

      expect(node.hasFocus, isTrue);
      expect(BaseMenuItem.isHoveredOf<void>(tester.element(find.text(Tag.a.text))), isTrue);
    });

    testWidgets('does not request focus if requestFocusOnHover is false', (
      WidgetTester tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        App(
          BaseMenuItem<void>(
            onPressed: () {},
            focusNode: node,
            role: null,
            requestFocusOnHover: false,
            child: Text(Tag.a.text),
          ),
        ),
      );

      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);

      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text(Tag.a.text)));
      await tester.pump();

      expect(node.hasFocus, isFalse);
      expect(BaseMenuItem.isHoveredOf<void>(tester.element(find.text(Tag.a.text))), isTrue);
    });

    testWidgets('does not request focus if disabled', (WidgetTester tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        App(BaseMenuItem<void>(focusNode: node, role: null, child: Text(Tag.a.text))),
      );

      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);

      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text(Tag.a.text)));
      await tester.pump();

      expect(node.hasFocus, isFalse);
      expect(BaseMenuItem.isFocusedOf<void>(tester.element(find.text(Tag.a.text))), isFalse);
    });
  });

  group('Press', () {
    testWidgets('onPressed invokes DismissIntent if requestCloseOnActivate is true', (
      WidgetTester tester,
    ) async {
      var pressedCount = 0;
      var dismissIntentInvoked = false;
      final controller = MenuController();

      await tester.pumpWidget(
        App(
          BaseMenu(
            controller: controller,
            menu: Actions(
              actions: <Type, Action<Intent>>{
                DismissIntent: CallbackAction<DismissIntent>(
                  onInvoke: (DismissIntent intent) {
                    dismissIntentInvoked = true;
                    return null;
                  },
                ),
              },
              child: BaseMenuItem<void>(
                onPressed: () {
                  pressedCount++;
                },
                child: Text(Tag.b.text),
              ),
            ),
          ),
        ),
      );

      controller.open();
      await tester.pump();

      // Tap on the item inside the menu
      await tester.tap(find.text(Tag.b.text));
      await tester.pump();

      expect(pressedCount, 1);
      expect(dismissIntentInvoked, isTrue);
    });

    testWidgets('onPressed does not invoke DismissIntent if requestCloseOnActivate is false', (
      WidgetTester tester,
    ) async {
      var pressedCount = 0;
      var dismissIntentInvoked = false;
      final controller = MenuController();

      await tester.pumpWidget(
        App(
          BaseMenu(
            controller: controller,
            menu: Actions(
              actions: <Type, Action<Intent>>{
                DismissIntent: CallbackAction<DismissIntent>(
                  onInvoke: (DismissIntent intent) {
                    dismissIntentInvoked = true;
                    return null;
                  },
                ),
              },
              child: BaseMenuItem<void>(
                requestCloseOnActivate: false,
                onPressed: () {
                  pressedCount++;
                },
                child: Text(Tag.b.text),
              ),
            ),
          ),
        ),
      );

      controller.open();
      await tester.pump();

      // Tap on the item inside the menu
      await tester.tap(find.text(Tag.b.text));
      await tester.pump();

      expect(pressedCount, 1);
      expect(dismissIntentInvoked, isFalse);
    });

    testWidgets('onPressed does not invoke DismissIntent if menu is not open', (
      WidgetTester tester,
    ) async {
      var pressedCount = 0;
      var dismissIntentInvoked = false;

      await tester.pumpWidget(
        App(
          Actions(
            actions: <Type, Action<Intent>>{
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (DismissIntent intent) {
                  dismissIntentInvoked = true;
                  return null;
                },
              ),
            },
            child: BaseMenuItem<void>(
              role: null,
              onPressed: () {
                pressedCount++;
              },
              child: Text(Tag.a.text),
            ),
          ),
        ),
      );

      await tester.tap(find.text(Tag.a.text));
      await tester.pump();

      expect(pressedCount, 1);
      expect(dismissIntentInvoked, isFalse);
    });
  });

  group('Focus', () {
    testWidgets('uses provided focusNode', (WidgetTester tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        App(
          Column(
            children: [
              BaseControl(onPressed: () {}, autofocus: true, child: Text(Tag.a.text)),
              BaseMenuItem<dynamic>(
                onPressed: () {},
                role: null,
                focusNode: node,
                child: Text(Tag.a.text),
              ),
            ],
          ),
        ),
      );

      expect(node.hasFocus, isFalse);

      node.requestFocus();
      await tester.pump();

      expect(node.hasFocus, isTrue);
    });

    testWidgets('creates internal focusNode if none is provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        App(BaseMenuItem<void>(onPressed: () {}, role: null, child: Text(Tag.a.text))),
      );

      final finder = find
          .descendant(
            of: find.byType(BaseFocusable<BaseMenuItem<void>>),
            matching: find.byType(Focus),
          )
          .first;

      final FocusNode? focusNode = tester.widget<Focus>(finder).focusNode;
      expect(focusNode, isNotNull);
      expect(focusNode?.hasFocus, isFalse);

      await tester.pumpWidget(
        App(
          BaseMenuItem<void>(
            onPressed: () {},
            autofocus: true,
            role: null,
            child: Text(Tag.a.text),
          ),
        ),
      );

      expect(focusNode?.hasFocus, isTrue);
    });

    testWidgets('creates internal focusNode if provided node is removed', (
      WidgetTester tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        App(
          BaseMenuItem<void>(
            focusNode: node,
            onPressed: () {},
            role: null,
            child: Text(Tag.a.text),
          ),
        ),
      );

      final finder = find
          .descendant(
            of: find.byType(BaseFocusable<BaseMenuItem<void>>),
            matching: find.byType(Focus),
          )
          .first;

      FocusNode? focusNode = tester.widget<Focus>(finder).focusNode;
      expect(focusNode, equals(node));

      await tester.pumpWidget(
        App(
          BaseMenuItem<void>(
            onPressed: () {},
            autofocus: true,
            role: null,
            child: Text(Tag.a.text),
          ),
        ),
      );

      focusNode = tester.widget<Focus>(finder).focusNode;
      expect(focusNode, isNot(node));
      expect(focusNode!.hasFocus, isTrue);
    });

    testWidgets('does not throw when switching from an external focusNode to internal', (
      WidgetTester tester,
    ) async {
      final externalOneNode = FocusNode();
      final externalTwoNode = FocusNode();
      addTearDown(externalOneNode.dispose);
      addTearDown(externalTwoNode.dispose);

      await tester.pumpWidget(
        App(
          BaseMenuItem<void>(
            focusNode: externalOneNode,
            onPressed: () {},
            role: null,
            child: Text(Tag.a.text),
          ),
        ),
      );

      await tester.pumpWidget(
        App(
          BaseMenuItem<void>(
            focusNode: externalTwoNode,
            onPressed: () {},
            role: null,
            child: Text(Tag.a.text),
          ),
        ),
      );

      await tester.pumpWidget(
        App(
          BaseMenuItem<void>(
            onPressed: () {},
            autofocus: true,
            role: null,
            child: Text(Tag.a.text),
          ),
        ),
      );
    });

    testWidgets('disposes of internal focusNode if node is added', (WidgetTester tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        App(BaseMenuItem<void>(onPressed: () {}, role: null, child: Text(Tag.a.text))),
      );

      final finder = find
          .descendant(
            of: find.byType(BaseFocusable<BaseMenuItem<void>>),
            matching: find.byType(Focus),
          )
          .first;

      final FocusNode? focusNode = tester.widget<Focus>(finder).focusNode;
      expect(focusNode, isNotNull);

      await tester.pumpWidget(
        App(
          BaseMenuItem<void>(
            focusNode: node,
            onPressed: () {},
            autofocus: true,
            role: null,
            child: Text(Tag.a.text),
          ),
        ),
      );

      expect(focusNode, isNot(node));
      expect(node.hasFocus, isTrue);
      expect(() => focusNode!.addListener(() {}), throwsA(isA<AssertionError>()));
    });

    testWidgets('disposes internal focusNode when widget is removed', (WidgetTester tester) async {
      await tester.pumpWidget(
        App(BaseMenuItem<void>(onPressed: () {}, role: null, child: Text(Tag.a.text))),
      );

      final finder = find
          .descendant(
            of: find.byType(BaseFocusable<BaseMenuItem<void>>),
            matching: find.byType(Focus),
          )
          .first;

      final FocusNode? focusNode = tester.widget<Focus>(finder).focusNode;
      expect(focusNode, isNotNull);
      expect(focusNode!.hasFocus, isFalse);

      await tester.pumpWidget(const App(SizedBox()));

      expect(() => focusNode.addListener(() {}), throwsA(isA<AssertionError>()));
    });
  });

  group('Semantics', () {
    testWidgets('default semantics [Not Web]', skip: kIsWeb, (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        App(
          Semantics(
            role: .menu,
            child: BaseMenuItem<void>(onPressed: () {}, child: Text(Tag.a.text)),
          ),
        ),
      );

      final semantics = tester.widget<Semantics>(
        find
            .descendant(of: find.byType(BaseMenuItem<void>), matching: find.byType(Semantics))
            .first,
      );

      expect(semantics.properties.role, SemanticsRole.menuItem);
      expect(
        tester.getSemantics(find.byType(BaseMenuItem<void>)),
        matchesSemantics(
          label: Tag.a.text,
          hasTapAction: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          hasFocusAction: true,
          textDirection: .ltr,
        ),
      );

      handle.dispose();
    });

    testWidgets('default semantics [Web]', skip: !kIsWeb, (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        App(
          Semantics(
            role: .menu,
            child: BaseMenuItem<void>(onPressed: () {}, child: Text(Tag.a.text)),
          ),
        ),
      );

      final semantics = tester.widget<Semantics>(
        find
            .descendant(of: find.byType(BaseMenuItem<void>), matching: find.byType(Semantics))
            .first,
      );

      expect(semantics.properties.role, SemanticsRole.menuItem);
      expect(
        tester.getSemantics(find.byType(BaseMenuItem<void>)),
        matchesSemantics(
          label: Tag.a.text,
          hasTapAction: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          hasFocusAction: true,
          textDirection: .ltr,
        ),
      );

      handle.dispose();
    });
  });

  testWidgets('role can be changed', skip: !kIsWeb, (WidgetTester tester) async {
    await tester.pumpWidget(
      App(BaseMenuItem<void>(onPressed: () {}, role: null, child: Text(Tag.a.text))),
    );

    final semantics = tester.widget<Semantics>(
      find.descendant(of: find.byType(BaseMenuItem<void>), matching: find.byType(Semantics)).first,
    );

    expect(semantics.properties.role, isNull);
  });

  group('Inheritance', () {
    late FocusNode objectNode;
    late FocusNode intNode;
    late FocusNode stringNode;

    setUp(() {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      objectNode = FocusNode(debugLabel: 'focusNodeObject');
      intNode = FocusNode(debugLabel: 'focusNodeInt');
      stringNode = FocusNode(debugLabel: 'focusNodeString');
    });

    tearDown(() {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
      objectNode.dispose();
      intNode.dispose();
      stringNode.dispose();
    });

    void verifyStates<T extends Object?>(WidgetTester tester, Set<WidgetState> expected) {
      final context = tester.element(find.byKey(Tag.c.key));
      expect(BaseMenuItem.statesOf<T>(context), equals(expected));
      expect(BaseMenuItem.isHoveredOf<T>(context), expected.contains(WidgetState.hovered));
      expect(BaseMenuItem.isFocusedOf<T>(context), expected.contains(WidgetState.focused));
      expect(BaseMenuItem.isPressedOf<T>(context), expected.contains(WidgetState.pressed));
      expect(BaseMenuItem.isDisabledOf<T>(context), expected.contains(WidgetState.disabled));
    }

    Widget buildTest({bool enabled = true, bool requestFocusOnHover = true}) {
      return App(
        BaseMenuItem(
          onPressed: enabled ? () {} : null,
          focusNode: objectNode,
          role: null,
          requestFocusOnHover: requestFocusOnHover,
          child: Container(
            key: Tag.a.key,
            padding: const EdgeInsets.all(50),
            color: const Color.fromARGB(255, 0, 255, 106),
            child: BaseMenuItem<int>(
              onPressed: enabled ? () {} : null,
              focusNode: intNode,
              role: null,
              requestFocusOnHover: requestFocusOnHover,
              child: Container(
                key: Tag.b.key,
                padding: const EdgeInsets.all(50),
                color: const Color(0xFF0011FF),
                child: BaseMenuItem<String>(
                  onPressed: enabled ? () {} : null,
                  focusNode: stringNode,
                  role: null,
                  requestFocusOnHover: requestFocusOnHover,
                  child: Container(key: Tag.c.key, height: 100, width: 100, color: Colors.red),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('hover state', (WidgetTester tester) async {
      await tester.pumpWidget(buildTest(requestFocusOnHover: false));

      final greenOuter = tester.getTopLeft(find.byKey(Tag.a.key)) + const Offset(5, 5);
      final blueMiddle = tester.getTopLeft(find.byKey(Tag.b.key)) + const Offset(5, 5);
      final redInner = tester.getCenter(find.byKey(Tag.c.key));

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);

      // Initial state
      verifyStates(tester, {});
      verifyStates<int>(tester, {});
      verifyStates<String>(tester, {});

      // Hover outer (Object?)
      await mouse.moveTo(greenOuter);
      await tester.pump();

      verifyStates(tester, {WidgetState.hovered});
      verifyStates<int>(tester, {});
      verifyStates<String>(tester, {});

      // Hover middle (int)
      await mouse.moveTo(blueMiddle);
      await tester.pump();

      verifyStates(tester, {WidgetState.hovered});
      verifyStates<int>(tester, {WidgetState.hovered});
      verifyStates<String>(tester, {});

      // Hover inner (String)
      await mouse.moveTo(redInner);
      await tester.pump();

      verifyStates(tester, {WidgetState.hovered});
      verifyStates<int>(tester, {WidgetState.hovered});
      verifyStates<String>(tester, {WidgetState.hovered});
    });

    testWidgets('pressed state', (WidgetTester tester) async {
      await tester.pumpWidget(buildTest());

      final greenOuter = tester.getTopLeft(find.byKey(Tag.a.key)) + const Offset(5, 5);
      final redInner = tester.getCenter(find.byKey(Tag.c.key));

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);

      // Press outer (Object?)
      await mouse.moveTo(greenOuter);
      await mouse.down(greenOuter);
      await tester.pump();

      verifyStates(tester, {WidgetState.hovered, WidgetState.pressed, WidgetState.focused});
      verifyStates<int>(tester, {});
      verifyStates<String>(tester, {});

      // Press inner (String)
      await mouse.up();
      await mouse.down(redInner);
      await tester.pump(kPressTimeout);

      verifyStates(tester, {WidgetState.hovered, WidgetState.pressed, WidgetState.focused});
      verifyStates<int>(tester, {WidgetState.hovered, WidgetState.pressed, WidgetState.focused});
      verifyStates<String>(tester, {WidgetState.hovered, WidgetState.pressed, WidgetState.focused});

      await mouse.up();
    });

    testWidgets('focus state', (WidgetTester tester) async {
      await tester.pumpWidget(buildTest());

      // Focus Middle (int)
      intNode.requestFocus();
      await tester.pump();

      verifyStates(tester, {WidgetState.focused});
      verifyStates<int>(tester, {WidgetState.focused});
      verifyStates<String>(tester, {});

      // Focus Outer (Object?)
      intNode.unfocus();
      await tester.pump();
      objectNode.requestFocus();
      await tester.pump();

      verifyStates(tester, {WidgetState.focused});
      verifyStates<int>(tester, {});
      verifyStates<String>(tester, {});
    });

    testWidgets('disabled state', (WidgetTester tester) async {
      await tester.pumpWidget(buildTest());

      intNode.requestFocus();
      await tester.pump();

      verifyStates(tester, {WidgetState.focused});
      verifyStates<int>(tester, {WidgetState.focused});
      verifyStates<String>(tester, {});

      await tester.pumpWidget(buildTest(enabled: false));
      await tester.pump();

      verifyStates(tester, {WidgetState.disabled});
      verifyStates<int>(tester, {WidgetState.disabled});
      verifyStates<String>(tester, {WidgetState.disabled});
    });
  });

  testWidgets('configures BaseControl properties correctly', (WidgetTester tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    const cursor = WidgetStateMouseCursor.clickable;
    final gestureSemantics = MockSemanticsGestureDelegate();
    var didCallOnPressed = false;
    var didCallOnActivate = false;

    void mockOnPressed() {
      expect(didCallOnPressed, isFalse, reason: 'onPressed should only be called once');
      didCallOnPressed = true;
    }

    void mockOnActivate() {
      expect(didCallOnActivate, isFalse, reason: 'onActivate should only be called once');
      didCallOnActivate = true;
    }

    void mockOnPointerEnter(PointerEnterEvent event) {}
    void mockOnPointerHover(PointerHoverEvent event) {}
    void mockOnPointerLeave(PointerExitEvent event) {}
    void mockOnFocusChange(bool focused) {}

    await tester.pumpWidget(
      App(
        BaseMenuItem<void>(
          onPressed: mockOnPressed,
          onActivate: mockOnActivate,
          onPointerEnter: mockOnPointerEnter,
          onPointerHover: mockOnPointerHover,
          onPointerLeave: mockOnPointerLeave,
          onFocusChange: mockOnFocusChange,
          role: null,
          focusNode: node,
          autofocus: true,
          behavior: HitTestBehavior.opaque,
          mouseCursor: cursor,
          requestCloseOnActivate: false,
          requestFocusOnHover: false,
          gestureSemantics: gestureSemantics,
          child: Text(Tag.a.text),
        ),
      ),
    );

    final controlFinder = find.byType(BaseControl<BaseMenuItem<void>>);
    var control = tester.widget<BaseControl<BaseMenuItem<void>>>(controlFinder);

    expect(control.focusNode, node);
    expect(control.autofocus, isTrue);
    expect(control.behavior, HitTestBehavior.opaque);
    expect(control.mouseCursor, cursor);
    expect(control.onPointerEnter, mockOnPointerEnter);
    expect(control.onPointerHover, mockOnPointerHover);
    expect(control.onPointerLeave, mockOnPointerLeave);
    expect(control.onFocusChange, mockOnFocusChange);
    expect(control.gestureSemanticsEnabled, isTrue);
    expect(control.gestureSemantics, gestureSemantics);

    await tester.tap(find.text(Tag.a.text));
    expect(didCallOnPressed, isTrue);
    expect(didCallOnActivate, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(didCallOnActivate, isTrue);

    await tester.pumpWidget(
      App(BaseMenuItem<void>(role: null, gestureSemanticsEnabled: false, child: Text(Tag.a.text))),
    );

    control = tester.widget<BaseControl<BaseMenuItem<void>>>(controlFinder);
    expect(control.gestureSemanticsEnabled, isFalse);
    expect(control.gestureSemantics, isNull);
  });
}
