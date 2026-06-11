import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_utilities/menu_utilities.dart';

void main() {
  group('BaseControl', () {
    testWidgets('Initial state is idle', (WidgetTester tester) async {
      Set<WidgetState>? states;

      await tester.pumpWidget(
        App(
          BaseControl<void>(
            onPressed: () {},
            child: Builder(
              builder: (BuildContext context) {
                states = BaseControl.statesOf<void>(context);
                return Text(Tag.a.text);
              },
            ),
          ),
        ),
      );

      expect(states, isEmpty);
      final element = tester.element(find.text(Tag.a.text));
      expect(BaseControl.isDisabledOf<void>(element), isFalse);
      expect(BaseControl.isHoveredOf<void>(element), isFalse);
      expect(BaseControl.isPressedOf<void>(element), isFalse);
      expect(BaseControl.isFocusedOf<void>(element), isFalse);
      expect(BaseControl.isFocusHighlightShownOf<void>(element), isFalse);
      expect(BaseControl.isHoverHighlightShownOf<void>(element), isFalse);
    });

    testWidgets('Disabled state when onPressed is null', (WidgetTester tester) async {
      Set<WidgetState>? states;

      await tester.pumpWidget(
        App(
          BaseControl<void>(
            child: Builder(
              builder: (BuildContext context) {
                states = BaseControl.statesOf<void>(context);
                return Text(Tag.a.text);
              },
            ),
          ),
        ),
      );

      expect(states, contains(WidgetState.disabled));
      final element = tester.element(find.text(Tag.a.text));

      expect(BaseControl.isDisabledOf<void>(element), isTrue);
    });
  });

  group('Hover', () {
    testWidgets('Initial state is not hovered', (WidgetTester tester) async {
      bool? isHovered;
      bool? showsHighlight;

      await tester.pumpWidget(
        App(
          BaseControl<void>(
            onPressed: () {},
            child: Builder(
              builder: (BuildContext context) {
                isHovered = BaseControl.isHoveredOf<void>(context);
                showsHighlight = BaseControl.isHoverHighlightShownOf<void>(context);
                return Text(Tag.a.text);
              },
            ),
          ),
        ),
      );

      expect(isHovered, isFalse);
      expect(showsHighlight, isFalse);
    });

    testWidgets('onEnter triggers hover state and callback', (WidgetTester tester) async {
      var entered = false;
      await tester.pumpWidget(
        App(
          Scaffold(
            body: Center(
              child: BaseControl<void>(
                onPressed: () {},
                onPointerEnter: (_) {
                  entered = true;
                },
                child: Text(Tag.a.text),
              ),
            ),
          ),
        ),
      );

      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text(Tag.a.text)));
      await tester.pump();

      expect(entered, isTrue);
      expect(BaseControl.isHoveredOf<void>(tester.element(find.text(Tag.a.text))), isTrue);
      // Traditional highlight mode (mouse) should show highlight by default on non-web if hovered
      expect(
        BaseControl.isHoverHighlightShownOf<void>(tester.element(find.text(Tag.a.text))),
        isTrue,
      );
    });

    testWidgets('onHover triggers callback', (WidgetTester tester) async {
      var hoverCount = 0;
      await tester.pumpWidget(
        App(
          BaseControl<void>(
            onPressed: () {},
            onPointerHover: (_) {
              hoverCount++;
            },
            child: Text(Tag.a.text),
          ),
        ),
      );

      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);

      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text(Tag.a.text)));
      await tester.pump();

      final Offset center = tester.getCenter(find.text(Tag.a.text));
      await gesture.moveTo(center + const Offset(1, 1));
      await tester.pump();

      expect(hoverCount, greaterThan(0));
    });

    testWidgets('onExit triggers exit and callback', (WidgetTester tester) async {
      var exited = false;
      await tester.pumpWidget(
        App(
          BaseControl<void>(
            onPressed: () {},
            onPointerLeave: (_) {
              exited = true;
            },
            child: Text(Tag.a.text),
          ),
        ),
      );

      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);

      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text(Tag.a.text)));
      await tester.pump();

      final element = tester.element(find.text(Tag.a.text));
      expect(BaseControl.isHoveredOf<void>(element), isTrue);

      await gesture.moveTo(Offset.zero);
      await tester.pump();

      expect(exited, isTrue);
      expect(BaseControl.isHoveredOf<void>(element), isFalse);
    });

    testWidgets('disabling BaseControl disables callbacks', (WidgetTester tester) async {
      var entered = false;
      await tester.pumpWidget(
        App(
          BaseControl<void>(
            onPointerEnter: (_) {
              entered = true;
            },
            onPointerHover: (_) {
              entered = true;
            },
            onPointerLeave: (_) {
              entered = true;
            },
            child: Text(Tag.a.text),
          ),
        ),
      );

      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);

      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text(Tag.a.text)));
      await tester.pump();

      expect(entered, isFalse);

      final element = tester.element(find.text(Tag.a.text));
      expect(BaseControl.isHoveredOf<void>(element), isFalse);
    });

    testWidgets('disabling BaseControl clears hover state', (WidgetTester tester) async {
      var enabled = true;
      await tester.pumpWidget(
        App(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  BaseControl<void>(onPressed: enabled ? () {} : null, child: Text(Tag.a.text)),
                  BaseControl(
                    onPressed: () {
                      setState(() {
                        enabled = false;
                      });
                    },
                    child: Text(Tag.outside.text),
                  ),
                ],
              );
            },
          ),
        ),
      );

      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);

      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text(Tag.a.text)));
      await tester.pump();

      final element = tester.element(find.text(Tag.a.text));

      expect(BaseControl.isHoveredOf<void>(element), isTrue);

      await tester.tap(find.text(Tag.outside.text));
      await tester.pump();

      expect(BaseControl.isHoveredOf<void>(element), isFalse);
    });

    testWidgets('BaseControl passes properties to MouseRegion', (WidgetTester tester) async {
      const MouseCursor cursor = SystemMouseCursors.click;
      const HitTestBehavior behavior = HitTestBehavior.opaque;

      await tester.pumpWidget(
        App(
          BaseControl<void>(
            mouseCursor: WidgetStateProperty.all(cursor),
            behavior: behavior,
            opaque: false,
            child: Text(Tag.a.text),
          ),
        ),
      );

      final mouseRegion = tester.widget<MouseRegion>(
        find.descendant(of: find.byType(BaseControl<void>), matching: find.byType(MouseRegion)),
      );
      expect(mouseRegion.cursor, cursor);
      expect(mouseRegion.hitTestBehavior, behavior);
      expect(mouseRegion.opaque, isFalse);
      expect(mouseRegion.onEnter, isNull);
      expect(mouseRegion.onHover, isNull);
      expect(mouseRegion.onExit, isNull);
    });

    testWidgets('Generic type scoping identifies correct ancestor', (WidgetTester tester) async {
      await tester.pumpWidget(
        App(
          BaseControl(
            onPressed: () {},
            child: Container(
              key: Tag.a.key,
              color: const Color(0xFF0011FF),
              width: 250,
              height: 250,
              alignment: Alignment.center,
              child: BaseControl<int>(
                onPressed: () {},
                child: Container(
                  key: Tag.b.key,
                  color: const Color(0xFF0011FF),
                  width: 200,
                  height: 200,
                  alignment: Alignment.center,
                  child: BaseControl<String>(
                    onPressed: () {},
                    child: Container(
                      key: Tag.c.key,
                      color: const Color(0xFFFF1100),
                      width: 100,
                      height: 100,
                      child: Builder(
                        builder: (BuildContext context) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Dynamic: ${BaseControl.isHoveredOf(context)}'),
                              Text('Int: ${BaseControl.isHoveredOf<int>(context)}'),
                              Text('String: ${BaseControl.isHoveredOf<String>(context)}'),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);

      await gesture.addPointer(location: Offset.zero);
      await tester.pump();

      expect(find.text('Dynamic: false'), findsOneWidget);
      expect(find.text('Int: false'), findsOneWidget);
      expect(find.text('String: false'), findsOneWidget);

      // Hover only outer (Int)
      await gesture.moveTo(tester.getTopLeft(find.byKey(Tag.a.key)) + const Offset(10, 10));
      await tester.pump();

      expect(find.text('Dynamic: true'), findsOneWidget);
      expect(find.text('Int: false'), findsOneWidget);
      expect(find.text('String: false'), findsOneWidget);

      // Hover inner (String) - since child is opaque by default, usually only inner or both depending on implementation
      // In BaseHoverable, each wraps child in a MouseRegion.
      await gesture.moveTo(tester.getTopLeft(find.byKey(Tag.b.key)) + const Offset(10, 10));
      await tester.pump();

      expect(find.text('Dynamic: true'), findsOneWidget);
      expect(find.text('Int: true'), findsOneWidget);
      expect(find.text('String: false'), findsOneWidget);

      await gesture.moveTo(tester.getCenter(find.byKey(Tag.c.key)));
      await tester.pump();

      expect(find.text('Dynamic: true'), findsOneWidget);
      expect(find.text('Int: true'), findsOneWidget);
      expect(find.text('String: true'), findsOneWidget);
    });

    testWidgets('opaque: true', (WidgetTester tester) async {
      var bottomHovered = false;
      var topHovered = false;

      await tester.pumpWidget(
        App(
          Stack(
            children: [
              BaseControl<int>(
                onPointerEnter: (_) {
                  bottomHovered = true;
                },
                onPointerLeave: (_) {
                  bottomHovered = false;
                },
                onPressed: () {},
                child: Container(width: 200, height: 200, color: const Color(0xFF0011FF)),
              ),
              BaseControl<String>(
                key: Tag.a.key,
                onPointerEnter: (_) {
                  topHovered = true;
                },
                onPointerLeave: (_) {
                  topHovered = false;
                },
                onPressed: () {},
                child: Container(width: 200, height: 200, color: const Color(0xFFFF1100)),
              ),
            ],
          ),
        ),
      );

      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);

      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.byKey(Tag.a.key)));
      await tester.pump();

      expect(topHovered, isTrue);

      // Because the top BaseHoverable is opaque, the hit test stops there
      // and does not reach the sibling underneath it in the Stack.
      expect(bottomHovered, isFalse);
    });

    testWidgets('opaque: false', (WidgetTester tester) async {
      var bottomHovered = false;
      var topHovered = false;

      await tester.pumpWidget(
        App(
          Stack(
            children: [
              BaseControl<int>(
                onPointerEnter: (_) {
                  bottomHovered = true;
                },
                onPointerLeave: (_) {
                  bottomHovered = false;
                },
                onPressed: () {},
                child: Container(width: 200, height: 200, color: const Color(0xFF0011FF)),
              ),
              BaseControl<String>(
                opaque: false,
                key: Tag.a.key,
                onPointerEnter: (_) {
                  topHovered = true;
                },
                onPointerLeave: (_) {
                  topHovered = false;
                },
                onPressed: () {},
                child: Container(width: 200, height: 200, color: const Color(0xFFFF1100)),
              ),
            ],
          ),
        ),
      );

      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);

      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.byKey(Tag.a.key)));
      await tester.pump();

      expect(topHovered, isTrue);

      // Because the top BaseHoverable is opaque, the hit test stops there
      // and does not reach the sibling underneath it in the Stack.
      expect(bottomHovered, isTrue);
    });

    testWidgets('behavior: opaque', (WidgetTester tester) async {
      var bottomHovered = false;
      var topHovered = false;

      await tester.pumpWidget(
        App(
          Stack(
            children: [
              BaseControl<int>(
                behavior: HitTestBehavior.opaque,
                onPointerEnter: (_) => bottomHovered = true,
                onPressed: () {},
                child: const SizedBox(width: 200, height: 200),
              ),
              BaseControl<String>(
                // opaque is true by default
                behavior: HitTestBehavior.opaque,
                onPointerEnter: (_) => topHovered = true,
                onPressed: () {},
                child: SizedBox(key: Tag.a.key, width: 200, height: 200),
              ),
            ],
          ),
        ),
      );

      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);

      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.byKey(Tag.a.key)));
      await tester.pump();

      expect(topHovered, isTrue);
      expect(bottomHovered, isFalse);
    });

    testWidgets('behavior: translucent', (WidgetTester tester) async {
      var bottomHovered = false;
      var topHovered = false;

      await tester.pumpWidget(
        App(
          Stack(
            children: [
              BaseControl<int>(
                behavior: HitTestBehavior.opaque,
                onPointerEnter: (_) {
                  bottomHovered = true;
                },
                onPressed: () {},
                child: const SizedBox(width: 200, height: 200),
              ),
              BaseControl<String>(
                // opaque is true by default
                behavior: HitTestBehavior.translucent,
                onPointerEnter: (_) {
                  topHovered = true;
                },
                onPressed: () {},
                child: SizedBox(key: Tag.a.key, width: 200, height: 200),
              ),
            ],
          ),
        ),
      );

      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);

      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.byKey(Tag.a.key)));
      await tester.pump();

      expect(topHovered, isTrue);
      expect(bottomHovered, isTrue);
    });

    testWidgets('behavior: deferToChild captures hover and blocks siblings in a Stack', (
      WidgetTester tester,
    ) async {
      var bottomHovered = false;
      var topHovered = false;

      await tester.pumpWidget(
        App(
          Stack(
            children: [
              BaseControl<int>(
                behavior: HitTestBehavior.opaque,
                onPointerEnter: (_) {
                  bottomHovered = true;
                },
                onPressed: () {},
                child: const SizedBox(width: 200, height: 200),
              ),
              BaseControl<String>(
                onPointerEnter: (_) {
                  topHovered = true;
                },
                onPressed: () {},
                child: SizedBox(key: Tag.a.key, width: 200, height: 200),
              ),
            ],
          ),
        ),
      );

      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);

      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.byKey(Tag.a.key)));
      await tester.pump();

      expect(topHovered, isFalse);
      expect(bottomHovered, isTrue);
    });
  });

  group('BaseControl - Pressable', () {
    testWidgets('Press state on tap down and up', (WidgetTester tester) async {
      var pressedCount = 0;
      await tester.pumpWidget(
        App(
          BaseControl<void>(
            onPressed: () {
              pressedCount++;
            },
            child: Text(Tag.a.text),
          ),
        ),
      );

      Element element() => tester.element(find.text(Tag.a.text));

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.text(Tag.a.text)),
      );
      await tester.pump();

      expect(BaseControl.isPressedOf<void>(element()), isTrue);
      expect(BaseControl.statesOf<void>(element()), contains(WidgetState.pressed));

      await gesture.up();
      await tester.pump();

      expect(BaseControl.isPressedOf<void>(element()), isFalse);
      expect(BaseControl.statesOf<void>(element()), isNot(contains(WidgetState.pressed)));
      expect(pressedCount, 1);
    });
    testWidgets('Space triggers onPressed', (WidgetTester tester) async {
      var pressedCount = 0;
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        App(
          BaseControl<void>(
            onPressed: () => pressedCount++,
            focusNode: node,
            child: Text(Tag.a.text),
          ),
        ),
      );

      node.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(pressedCount, 1);
    });

    testWidgets('Enter triggers onPressed', (WidgetTester tester) async {
      var pressedCount = 0;
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        App(
          BaseControl<void>(
            onPressed: () => pressedCount++,
            focusNode: node,
            child: Text(Tag.a.text),
          ),
        ),
      );

      node.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(pressedCount, 1);
    });

    testWidgets('Press state cleared on tap cancel', (WidgetTester tester) async {
      var pressedCount = 0;
      await tester.pumpWidget(
        App(
          Center(
            child: BaseControl<void>(
              onPressed: () => pressedCount++,
              child: SizedBox(width: 100, height: 100, child: Text(Tag.a.text)),
            ),
          ),
        ),
      );

      Element element() => tester.element(find.text(Tag.a.text));

      // 1. Start gesture: Without competition from ListView, onTapDown triggers immediately
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.text(Tag.a.text)),
      );
      await tester.pump();

      expect(BaseControl.isPressedOf<void>(element()), isTrue);

      // 2. Move away: Exceeding the tap slop (threshold) cancels the tap
      await gesture.moveBy(const Offset(200, 200));
      await tester.pump();

      expect(BaseControl.isPressedOf<void>(element()), isFalse);

      // 3. Release: No onPressed should be called
      await gesture.up();
      await tester.pump();

      expect(pressedCount, 0);
    });

    testWidgets('gestureSemanticsEnabled and gestureSemantics work', (WidgetTester tester) async {
      final delegate = MockSemanticsGestureDelegate();

      await tester.pumpWidget(
        App(
          BaseControl<void>(
            onPressed: () {},
            gestureSemanticsEnabled: false,
            gestureSemantics: delegate,
            child: Text(Tag.a.text),
          ),
        ),
      );

      final rawGestureDetector = tester.widget<RawGestureDetector>(
        find.descendant(
          of: find.byType(BaseControl<void>),
          matching: find.byType(RawGestureDetector),
        ),
      );

      expect(rawGestureDetector.excludeFromSemantics, isTrue);
      expect(rawGestureDetector.semantics, delegate);
    });

    testWidgets('isPressed is cleared when control is disabled', (WidgetTester tester) async {
      var enabled = true;
      var isPressed = false;
      await tester.pumpWidget(
        App(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  BaseControl<void>(
                    onPressed: enabled ? () {} : null,
                    child: Builder(
                      builder: (context) {
                        isPressed = BaseControl.isPressedOf<void>(context);
                        return Text(Tag.a.text);
                      },
                    ),
                  ),
                  Button.tag(
                    Tag.b,
                    autofocus: true,
                    onPressed: () {
                      setState(() {
                        enabled = false;
                      });
                    },
                  ),
                ],
              );
            },
          ),
        ),
      );

      // Start the gesture
      final gesture = await tester.startGesture(tester.getCenter(find.text(Tag.a.text)));
      await tester.pump();
      expect(isPressed, isTrue);

      // Disable the control
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      // Verify isPressed is cleared
      expect(isPressed, isFalse);

      await gesture.up();
      await tester.pump();
    });
  });
  group('Focus', () {
    testWidgets('Initial state is not focused', (WidgetTester tester) async {
      bool? isFocused;
      bool? showsHighlight;

      await tester.pumpWidget(
        App(
          BaseControl<void>(
            onPressed: () {},
            child: Builder(
              builder: (BuildContext context) {
                isFocused = BaseControl.isFocusedOf<void>(context);
                showsHighlight = BaseControl.isFocusHighlightShownOf<void>(context);
                return Text(Tag.a.text);
              },
            ),
          ),
        ),
      );

      expect(isFocused, isFalse);
      expect(showsHighlight, isFalse);
    });

    testWidgets('BaseControl uses provided focusNode', (WidgetTester tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        App(BaseControl<void>(onPressed: () {}, focusNode: node, child: Text(Tag.a.text))),
      );

      final finder = find
          .descendant(of: find.byType(BaseFocusable<void>), matching: find.byType(Focus))
          .first;

      expect(tester.widget<Focus>(finder).focusNode, node);

      await tester.pumpWidget(App(BaseControl<void>(onPressed: () {}, child: Text(Tag.a.text))));

      expect(tester.widget<Focus>(finder).focusNode, isNot(equals(node)));

      await tester.pumpWidget(
        App(BaseControl<void>(onPressed: () {}, focusNode: node, child: Text(Tag.a.text))),
      );

      expect(tester.widget<Focus>(finder).focusNode, node);
    });

    testWidgets('onFocusChange triggers callback when focus node changes', (
      WidgetTester tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      var isFocused = false;

      await tester.pumpWidget(
        App(
          BaseControl<void>(
            onPressed: () {},
            focusNode: node,
            onFocusChange: (bool focused) {
              isFocused = focused;
            },
            child: Text(Tag.a.text),
          ),
        ),
      );

      expect(isFocused, isFalse);

      node.requestFocus();
      await tester.pump();

      expect(isFocused, isTrue);
      expect(BaseControl.isFocusedOf<void>(tester.element(find.text(Tag.a.text))), isTrue);

      node.unfocus();
      await tester.pump();
      await tester.pump();

      expect(isFocused, isFalse);
      expect(BaseControl.isFocusedOf<void>(tester.element(find.text(Tag.a.text))), isFalse);
    });

    testWidgets('Autofocus focuses automatically', (WidgetTester tester) async {
      var focusCount = 0;

      await tester.pumpWidget(
        App(
          BaseControl<void>(
            onPressed: () {},
            autofocus: true,
            onFocusChange: (focused) {
              if (focused) {
                focusCount++;
              }
            },
            child: Text(Tag.a.text),
          ),
        ),
      );

      await tester.pump(); // wait for autofocus

      expect(focusCount, 1);
      final element = tester.element(find.text(Tag.a.text));

      expect(BaseControl.isFocusedOf<void>(element), isTrue);
    });

    testWidgets('disabled BaseControl does not request focus', (WidgetTester tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(App(BaseControl<void>(focusNode: node, child: Text(Tag.a.text))));

      node.requestFocus();
      await tester.pump();

      final element = tester.element(find.text(Tag.a.text));
      expect(node.hasFocus, isFalse);
      expect(BaseControl.isFocusedOf<void>(element), isFalse);
      expect(BaseControl.isFocusHighlightShownOf<void>(element), isFalse);
    });

    testWidgets('disabling BaseControl clears focus state', (WidgetTester tester) async {
      var enabled = true;
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        App(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  BaseControl<void>(
                    onPressed: enabled ? () {} : null,
                    focusNode: node,
                    child: Text(Tag.a.text),
                  ),
                  Button.tag(
                    Tag.b,
                    onPressed: () {
                      setState(() {
                        enabled = false;
                      });
                    },
                  ),
                ],
              );
            },
          ),
        ),
      );

      node.requestFocus();
      await tester.pump();
      expect(BaseControl.isFocusedOf<void>(tester.element(find.text(Tag.a.text))), isTrue);

      await tester.tap(find.text(Tag.b.text));
      await tester.pump();

      expect(node.hasFocus, isFalse);
      expect(BaseControl.isFocusedOf<void>(tester.element(find.text(Tag.a.text))), isFalse);
    });

    testWidgets('Generic type scoping identifies correct ancestor', (WidgetTester tester) async {
      final nodeA = FocusNode();
      final nodeB = FocusNode();
      final nodeC = FocusNode();
      addTearDown(nodeA.dispose);
      addTearDown(nodeB.dispose);
      addTearDown(nodeC.dispose);

      await tester.pumpWidget(
        App(
          BaseControl(
            onPressed: () {},
            focusNode: nodeA,
            child: Container(
              key: Tag.a.key,
              child: BaseControl<int>(
                onPressed: () {},
                focusNode: nodeB,
                child: Container(
                  key: Tag.b.key,
                  child: BaseControl<String>(
                    onPressed: () {},
                    focusNode: nodeC,
                    child: Container(
                      key: Tag.c.key,
                      child: Builder(
                        builder: (BuildContext context) {
                          return Column(
                            children: [
                              Text('Dynamic: ${BaseControl.isFocusedOf(context)}'),
                              Text('Int: ${BaseControl.isFocusedOf<int>(context)}'),
                              Text('String: ${BaseControl.isFocusedOf<String>(context)}'),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Dynamic: false'), findsOneWidget);
      expect(find.text('Int: false'), findsOneWidget);
      expect(find.text('String: false'), findsOneWidget);

      nodeA.requestFocus();
      await tester.pump();
      expect(find.text('Dynamic: true'), findsOneWidget);
      expect(find.text('Int: false'), findsOneWidget);
      expect(find.text('String: false'), findsOneWidget);

      nodeB.requestFocus();
      await tester.pump();
      await tester.pump();
      expect(find.text('Dynamic: true'), findsOneWidget);
      expect(find.text('Int: true'), findsOneWidget);
      expect(find.text('String: false'), findsOneWidget);

      nodeC.requestFocus();
      await tester.pump();
      await tester.pump();
      expect(find.text('Dynamic: true'), findsOneWidget);
      expect(find.text('Int: true'), findsOneWidget);
      expect(find.text('String: true'), findsOneWidget);

      nodeA.requestFocus();
      await tester.pump();
      await tester.pump();
      expect(find.text('Dynamic: true'), findsOneWidget);
      expect(find.text('Int: false'), findsOneWidget);
      expect(find.text('String: false'), findsOneWidget);
    });
  });

  testWidgets('MouseCursor resolves states correctly', (WidgetTester tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);

    const cursor = WidgetStateProperty.fromMap({
      WidgetState.disabled: SystemMouseCursors.forbidden,
      WidgetState.pressed: SystemMouseCursors.grabbing,
      WidgetState.hovered: SystemMouseCursors.grab,
      WidgetState.focused: SystemMouseCursors.click,
      WidgetState.any: SystemMouseCursors.basic,
    });

    await tester.pumpWidget(
      App(
        BaseControl<void>(
          onPressed: () {},
          focusNode: node,
          mouseCursor: cursor,
          child: Text(Tag.a.text),
        ),
      ),
    );

    MouseRegion getMouseRegion() => tester.widget<MouseRegion>(
      find.descendant(of: find.byType(BaseControl<void>), matching: find.byType(MouseRegion)),
    );

    // 1. Basic state
    expect(getMouseRegion().cursor, SystemMouseCursors.basic);

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: Offset.zero);

    // 2. Hovered state
    await gesture.moveTo(tester.getCenter(find.text(Tag.a.text)));
    await tester.pump();
    expect(getMouseRegion().cursor, SystemMouseCursors.grab);

    // 3. Pressed state (taking precedence over hovered)
    await gesture.down(tester.getCenter(find.text(Tag.a.text)));
    await tester.pump();
    expect(getMouseRegion().cursor, SystemMouseCursors.grabbing);

    await gesture.up();
    await tester.pump();

    // 4. Focused state (node has focus, but not hovered)
    await gesture.moveTo(Offset.zero);
    node.requestFocus();
    await tester.pump();
    expect(getMouseRegion().cursor, SystemMouseCursors.click);

    // 5. Disabled state (taking precedence over all)
    await tester.pumpWidget(
      App(BaseControl<void>(focusNode: node, mouseCursor: cursor, child: Text(Tag.a.text))),
    );
    expect(getMouseRegion().cursor, SystemMouseCursors.forbidden);
  });

  group('BaseControl - Semantics', () {
    testWidgets('Disabled control has proper semantics', (WidgetTester tester) async {
      await tester.pumpWidget(App(BaseControl<void>(child: Text(Tag.a.text))));

      final semantics = tester.getSemantics(find.byType(BaseControl<void>));
      expect(semantics.hasFlag(SemanticsFlag.isEnabled), isFalse);
    });

    testWidgets('Enabled control has proper semantics', (WidgetTester tester) async {
      await tester.pumpWidget(App(BaseControl<void>(onPressed: () {}, child: Text(Tag.a.text))));

      final semantics = tester.getSemantics(find.byType(BaseControl<void>));
      expect(semantics.hasFlag(SemanticsFlag.isEnabled), isTrue);
    });

    testWidgets('gestureSemanticsEnabled excludes semantics when false', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          BaseControl<void>(
            onPressed: () {},
            gestureSemanticsEnabled: false,
            child: Text(Tag.a.text),
          ),
        ),
      );

      final rawGestureDetector = tester.widget<RawGestureDetector>(
        find.descendant(
          of: find.byType(BaseControl<void>),
          matching: find.byType(RawGestureDetector),
        ),
      );

      expect(rawGestureDetector.excludeFromSemantics, isTrue);
    });
  });

  testWidgets('Default semantics', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      App(BaseControl<void>(onPressed: () {}, child: const Text('Action Label'))),
    );

    // Verify label is picked up from child and onTap action is present
    expect(
      tester.getSemantics(find.byType(BaseControl<void>)),
      matchesSemantics(
        label: 'Action Label',
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

  testWidgets('Semantics tap action', (WidgetTester tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    final SemanticsHandle handle = tester.ensureSemantics();
    var isPressed = false;
    await tester.pumpWidget(
      App(
        BaseControl<void>(
          focusNode: focusNode,
          onPressed: () {
            isPressed = true;
          },
          child: Text(Tag.a.text),
        ),
      ),
    );

    final FinderBase<SemanticsNode> finder = find.semantics.byLabel(Tag.a.text);
    tester.semantics.tap(finder);
    expect(isPressed, isTrue);

    handle.dispose();
  });

  testWidgets('Semantics focus action', (WidgetTester tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    final SemanticsHandle handle = tester.ensureSemantics();
    var isFocused = false;
    await tester.pumpWidget(
      App(
        BaseControl<void>(
          focusNode: focusNode,
          onPressed: () {},
          onFocusChange: (focused) {
            isFocused = focused;
          },
          child: Text(Tag.a.text),
        ),
      ),
    );

    final element = tester.element(find.text(Tag.a.text));

    expect(isFocused, isFalse);
    expect(BaseControl.isFocusedOf<void>(element), isFalse);
    expect(focusNode.hasFocus, isFalse);

    final FinderBase<SemanticsNode> finder = find.semantics.byLabel(Tag.a.text);
    tester.semantics.performAction(finder, SemanticsAction.focus);
    await tester.pump();

    expect(isFocused, isTrue);
    expect(BaseControl.isFocusedOf<void>(element), isTrue);
    expect(focusNode.hasFocus, isTrue);

    handle.dispose();
  });

  testWidgets('Disabled control removes tap action and sets isEnabled flag', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(App(BaseControl<void>(child: Text(Tag.a.text))));

    expect(
      tester.getSemantics(find.byType(BaseControl<void>)),
      matchesSemantics(label: Tag.a.text, hasEnabledState: true, textDirection: TextDirection.ltr),
    );

    handle.dispose();
  });

  testWidgets('MergeSemantics integrates label and BaseControl actions', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      App(
        MergeSemantics(
          child: Row(
            children: [
              BaseControl<void>(
                onPressed: () {},
                child: const Icon(null, semanticLabel: 'Add'),
              ),
              const Text('Item'),
            ],
          ),
        ),
      ),
    );

    // Verify that the Row's children are merged into a single semantic node
    expect(
      tester.getSemantics(find.byType(MergeSemantics)),
      matchesSemantics(
        label: 'Add\nItem', // Merged labels usually separated by newline
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

  testWidgets('External Semantics properties merge with BaseControl', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      App(
        Semantics(
          button: true,
          child: BaseControl<void>(onPressed: () {}, child: Text(Tag.a.text)),
        ),
      ),
    );

    // Verify the external 'button' property merges with the 'enabled' and 'onTap' from BaseControl
    expect(
      tester.getSemantics(find.byType(BaseControl<void>)),
      matchesSemantics(
        label: Tag.a.text,
        isButton: true,
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
    Set<WidgetState> intStates = {};
    Set<WidgetState> stringStates = {};
    var enableVoid = true;

    await tester.pumpWidget(
      App(
        StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                BaseControl<void>(
                  onPressed: enableVoid ? () {} : null,
                  focusNode: nodeVoid,
                  child: Container(
                    key: Tag.a.key,
                    color: const Color.fromARGB(255, 0, 255, 106),
                    padding: const EdgeInsets.all(50), // Outer zone (Level 0)
                    child: BaseControl<int>(
                      onPressed: () {},
                      focusNode: nodeInt,
                      child: Container(
                        key: Tag.b.key,
                        color: const Color(0xFF0011FF),
                        padding: const EdgeInsets.all(50), // Inner zone (Level 2)
                        child: BaseControl<String>(
                          onPressed: () {},
                          focusNode: nodeString,
                          child: Container(
                            key: Tag.c.key,
                            height: 100,
                            width: 100,
                            color: Colors.red,
                            child: Builder(
                              builder: (context) {
                                voidStates = BaseControl.statesOf<void>(context);
                                intStates = BaseControl.statesOf<int>(context);
                                stringStates = BaseControl.statesOf<String>(context);
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

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);

    await mouse.moveTo(greenOuter);
    await tester.pump();
    expect(voidStates, contains(WidgetState.hovered));
    expect(intStates, isEmpty);
    expect(stringStates, isEmpty);

    await mouse.moveTo(blueMiddle);
    await tester.pump();
    expect(voidStates, contains(WidgetState.hovered));
    expect(intStates, contains(WidgetState.hovered));
    expect(stringStates, isEmpty);

    await mouse.moveTo(redInner);
    await tester.pump();
    expect(voidStates, contains(WidgetState.hovered));
    expect(intStates, contains(WidgetState.hovered));
    expect(stringStates, contains(WidgetState.hovered));

    await mouse.moveTo(greenOuter);
    await mouse.down(greenOuter);
    await tester.pump();

    expect(voidStates, equals({WidgetState.hovered, WidgetState.pressed}));
    expect(intStates, equals(<WidgetState>{}));
    expect(stringStates, equals(<WidgetState>{}));

    await mouse.up();
    await mouse.down(redInner);
    await tester.pump(kPressTimeout);

    expect(voidStates, equals({WidgetState.hovered, WidgetState.pressed}));
    expect(intStates, equals({WidgetState.hovered, WidgetState.pressed}));
    expect(stringStates, equals({WidgetState.hovered, WidgetState.pressed}));

    await mouse.up();
    await mouse.moveTo(Offset.zero);
    nodeInt.requestFocus();
    await tester.pump();

    expect(intStates, equals({WidgetState.focused}));
    expect(voidStates, equals({WidgetState.focused}));
    expect(stringStates, equals(<WidgetState>{}));

    nodeVoid.requestFocus();
    await tester.pump();
    await tester.pump();

    expect(voidStates, equals({WidgetState.focused}));
    expect(intStates, equals(<WidgetState>{}));
    expect(stringStates, equals(<WidgetState>{}));

    await tester.tap(find.text(Tag.outside.text));
    await tester.pump(kPressTimeout);

    expect(voidStates, equals({WidgetState.disabled}));
    expect(intStates, equals(<WidgetState>{}));
    expect(stringStates, equals(<WidgetState>{}));
  });
}

class MockSemanticsGestureDelegate extends SemanticsGestureDelegate {
  @override
  void assignSemantics(RenderSemanticsGestureHandler renderObject) {}
}
