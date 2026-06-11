import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
      expect(BaseMenuItem.isHoveredOf<void>(tester.element(find.text(Tag.a.text))), isFalse);
    });
  });

  group('Pressable', () {
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
    testWidgets('[Not Browser] BaseMenuItem default semantics', skip: kIsWeb, (
      WidgetTester tester,
    ) async {
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

    testWidgets('[Browser] BaseMenuItem default semantics', skip: !kIsWeb, (
      WidgetTester tester,
    ) async {
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

  testWidgets('Inherited properties target correct generic type (all states)', (
    WidgetTester tester,
  ) async {
    final nodeVoid = FocusNode();
    final nodeInt = FocusNode();
    final nodeString = FocusNode();
    addTearDown(nodeVoid.dispose);
    addTearDown(nodeInt.dispose);
    addTearDown(nodeString.dispose);

    Set<WidgetState> voidStates = {};
    Set<WidgetState> voidDiscreteStates = {};
    Set<WidgetState> intStates = {};
    Set<WidgetState> intDiscreteStates = {};
    Set<WidgetState> stringStates = {};
    Set<WidgetState> stringDiscreteStates = {};

    void matchDiscreteStates() {
      expect(voidDiscreteStates, equals(voidStates));
      expect(intDiscreteStates, equals(intStates));
      expect(stringDiscreteStates, equals(stringStates));
    }

    var enableVoid = true;

    await tester.pumpWidget(
      App(
        StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                BaseMenuItem<void>(
                  onPressed: enableVoid ? () {} : null,
                  focusNode: nodeVoid,
                  role: null,
                  child: Container(
                    key: Tag.a.key,
                    color: const Color.fromARGB(255, 0, 255, 106),
                    padding: const EdgeInsets.all(50), // Outer zone (Level 0)
                    child: BaseMenuItem<int>(
                      onPressed: () {},
                      focusNode: nodeInt,
                      role: null,
                      child: Container(
                        key: Tag.b.key,
                        color: const Color(0xFF0011FF),
                        padding: const EdgeInsets.all(50), // Inner zone (Level 2)
                        child: BaseMenuItem<String>(
                          onPressed: () {},
                          focusNode: nodeString,
                          role: null,
                          child: Container(
                            key: Tag.c.key,
                            height: 100,
                            width: 100,
                            color: Colors.red,
                            child: Builder(
                              builder: (context) {
                                voidStates = BaseMenuItem.statesOf<void>(context);
                                intStates = BaseMenuItem.statesOf<int>(context);
                                stringStates = BaseMenuItem.statesOf<String>(context);
                                voidDiscreteStates = {
                                  if (BaseMenuItem.isHoveredOf<void>(context)) WidgetState.hovered,
                                  if (BaseMenuItem.isFocusedOf<void>(context)) WidgetState.focused,
                                  if (BaseMenuItem.isPressedOf<void>(context)) WidgetState.pressed,
                                  if (BaseMenuItem.isDisabledOf<void>(context))
                                    WidgetState.disabled,
                                };
                                intDiscreteStates = {
                                  if (BaseMenuItem.isHoveredOf<int>(context)) WidgetState.hovered,
                                  if (BaseMenuItem.isFocusedOf<int>(context)) WidgetState.focused,
                                  if (BaseMenuItem.isPressedOf<int>(context)) WidgetState.pressed,
                                  if (BaseMenuItem.isDisabledOf<int>(context)) WidgetState.disabled,
                                };
                                stringDiscreteStates = {
                                  if (BaseMenuItem.isHoveredOf<String>(context))
                                    WidgetState.hovered,
                                  if (BaseMenuItem.isFocusedOf<String>(context))
                                    WidgetState.focused,
                                  if (BaseMenuItem.isPressedOf<String>(context))
                                    WidgetState.pressed,
                                  if (BaseMenuItem.isDisabledOf<String>(context))
                                    WidgetState.disabled,
                                };
                                return const SizedBox.expand();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Button.tag(
                  Tag.outside,
                  onPressed: () {
                    setState(() {
                      enableVoid = false;
                    });
                  },
                ),
              ],
            );
          },
        ),
      ),
    );

    final greenOuter = tester.getTopLeft(find.byKey(Tag.a.key)) + const Offset(5, 5); // Outer
    final blueMiddle = tester.getTopLeft(find.byKey(Tag.b.key)) + const Offset(5, 5); // Middle
    final redInner = tester.getCenter(find.byKey(Tag.c.key)); // Inner

    expect(voidStates, isEmpty);
    expect(intStates, isEmpty);
    expect(stringStates, isEmpty);
    matchDiscreteStates();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);

    await mouse.moveTo(greenOuter);
    await tester.pump();

    expect(voidStates, contains(WidgetState.hovered));
    expect(intStates, isEmpty);
    expect(stringStates, isEmpty);
    matchDiscreteStates();

    await mouse.moveTo(blueMiddle);
    await tester.pump();

    expect(voidStates, contains(WidgetState.hovered));
    expect(intStates, contains(WidgetState.hovered));
    expect(stringStates, isEmpty);
    matchDiscreteStates();

    await mouse.moveTo(redInner);
    await tester.pump();

    expect(voidStates, contains(WidgetState.hovered));
    expect(intStates, contains(WidgetState.hovered));
    expect(stringStates, contains(WidgetState.hovered));
    matchDiscreteStates();

    await mouse.moveTo(greenOuter);
    await mouse.down(greenOuter);
    await tester.pump();

    expect(voidStates, equals({WidgetState.hovered, WidgetState.pressed, WidgetState.focused}));
    expect(intStates, equals(<WidgetState>{WidgetState.focused}));
    expect(stringStates, equals(<WidgetState>{WidgetState.focused}));
    matchDiscreteStates();

    await mouse.up();
    await mouse.down(redInner);
    await tester.pump(kPressTimeout);

    expect(voidStates, equals({WidgetState.hovered, WidgetState.pressed}));
    expect(intStates, equals({WidgetState.hovered, WidgetState.pressed}));
    expect(stringStates, equals({WidgetState.hovered, WidgetState.pressed}));
    matchDiscreteStates();

    await mouse.up();
    await mouse.moveTo(Offset.zero);
    nodeInt.requestFocus();
    await tester.pump();

    expect(intStates, equals({WidgetState.focused}));
    expect(voidStates, equals({WidgetState.focused}));
    expect(stringStates, equals(<WidgetState>{}));
    matchDiscreteStates();

    nodeVoid.requestFocus();
    await tester.pump();
    await tester.pump();

    expect(voidStates, equals({WidgetState.focused}));
    expect(intStates, equals(<WidgetState>{}));
    expect(stringStates, equals(<WidgetState>{}));
    matchDiscreteStates();

    await tester.tap(find.text(Tag.outside.text));
    await tester.pump(kPressTimeout);

    expect(voidStates, equals({WidgetState.disabled}));
    expect(intStates, equals(<WidgetState>{}));
    expect(stringStates, equals(<WidgetState>{}));
    matchDiscreteStates();
  });

  testWidgets('configures BaseControl properties correctly', (WidgetTester tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    const cursor = WidgetStateMouseCursor.clickable;
    final gestureSemantics = MockSemanticsGestureDelegate();

    void mockCallback([_]) {}

    await tester.pumpWidget(
      App(
        BaseMenuItem<void>(
          onPressed: mockCallback,
          onPointerEnter: mockCallback,
          onPointerHover: mockCallback,
          onPointerLeave: mockCallback,
          onFocusChange: mockCallback,
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
    expect(control.onPressed, mockCallback);
    expect(control.onPointerEnter, mockCallback);
    expect(control.onPointerHover, mockCallback);
    expect(control.onPointerLeave, mockCallback);
    expect(control.onFocusChange, mockCallback);
    expect(control.gestureSemanticsEnabled, isTrue);
    expect(control.gestureSemantics, gestureSemantics);

    await tester.pumpWidget(
      App(BaseMenuItem<void>(role: null, gestureSemanticsEnabled: false, child: Text(Tag.a.text))),
    );

    control = tester.widget<BaseControl<BaseMenuItem<void>>>(controlFinder);
    expect(control.gestureSemanticsEnabled, isFalse);
    expect(control.gestureSemantics, isNull);
  });
}

class MockSemanticsGestureDelegate extends SemanticsGestureDelegate {
  @override
  void assignSemantics(RenderSemanticsGestureHandler renderObject) {}
}
