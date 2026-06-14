import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_utilities/menu_utilities.dart';

void main() {
  testWidgets('initial state is idle', (WidgetTester tester) async {
    await tester.pumpWidget(App(BaseControl<void>(onPressed: () {}, child: Text(Tag.a.text))));

    final element = tester.element(find.text(Tag.a.text));
    expect(BaseControl.statesOf<void>(element), isEmpty);
    expect(BaseControl.isDisabledOf<void>(element), isFalse);
    expect(BaseControl.isHoveredOf<void>(element), isFalse);
    expect(BaseControl.isPressedOf<void>(element), isFalse);
    expect(BaseControl.isFocusedOf<void>(element), isFalse);
    expect(BaseControl.isFocusHighlightShownOf<void>(element), isFalse);
    expect(BaseControl.isHoverHighlightShownOf<void>(element), isFalse);
  });

  testWidgets('enabled when onPressed is not null', (WidgetTester tester) async {
    await tester.pumpWidget(App(BaseControl<void>(onPressed: () {}, child: Text(Tag.a.text))));

    final element = tester.element(find.text(Tag.a.text));
    expect(BaseControl.statesOf<void>(element), isEmpty);
    expect(BaseControl.isDisabledOf<void>(element), isFalse);
    expect(tester.widget<BaseControl<void>>(find.byType(BaseControl<void>)).enabled, isTrue);
  });

  testWidgets('disabled when onPressed is null', (WidgetTester tester) async {
    await tester.pumpWidget(App(BaseControl<void>(child: Text(Tag.a.text))));

    final element = tester.element(find.text(Tag.a.text));
    expect(BaseControl.statesOf<void>(element), {WidgetState.disabled});
    expect(BaseControl.isDisabledOf<void>(element), isTrue);
    expect(tester.widget<BaseControl<void>>(find.byType(BaseControl<void>)).enabled, isFalse);
  });

  testWidgets('passes properties to BaseFocusable', (WidgetTester tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    var focusChanged = false;

    await tester.pumpWidget(
      App(
        BaseControl<void>(
          onPressed: () {},
          focusNode: focusNode,
          autofocus: true,
          onFocusChange: (bool focused) {
            focusChanged = focused;
          },
          child: Text(Tag.a.text),
        ),
      ),
    );

    final focusable = tester.widget<BaseFocusable<void>>(find.byType(BaseFocusable<void>));
    expect(focusable.enabled, isTrue);
    expect(focusable.focusNode, focusNode);
    expect(focusable.autofocus, isTrue);
    expect(focusable.onFocusChange, isNotNull);

    focusNode.requestFocus();
    await tester.pump();

    expect(focusChanged, isTrue);

    await tester.pumpWidget(
      App(
        BaseControl<void>(
          focusNode: focusNode,
          onFocusChange: (bool focused) {
            focusChanged = focused;
          },
          child: Text(Tag.a.text),
        ),
      ),
    );

    await tester.pump();
    focusNode.requestFocus();
    await tester.pump();

    expect(focusable.enabled, isTrue);
    expect(focusable.focusNode, focusNode);
    expect(focusable.autofocus, isTrue);
    expect(focusable.onFocusChange, isNotNull);
    expect(focusChanged, isFalse);
  });

  testWidgets('passes properties to BaseHoverable', (WidgetTester tester) async {
    const MouseCursor cursor = SystemMouseCursors.click;
    const HitTestBehavior behavior = HitTestBehavior.opaque;
    var hovered = false;
    var entered = false;
    var exited = false;

    await tester.pumpWidget(
      App(
        BaseControl<void>(
          onPressed: () {},
          mouseCursor: WidgetStateProperty.all(cursor),
          behavior: behavior,
          opaque: false,
          onPointerHover: (_) => hovered = true,
          onPointerEnter: (_) => entered = true,
          onPointerLeave: (_) => exited = true,
          child: Text(Tag.a.text),
        ),
      ),
    );

    BaseHoverable<void> hoverable() =>
        tester.widget<BaseHoverable<void>>(find.byType(BaseHoverable<void>));

    expect(hoverable().enabled, isTrue);
    expect(hoverable().cursor, cursor);
    expect(hoverable().behavior, behavior);
    expect(hoverable().opaque, isFalse);

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(find.text(Tag.a.text)));
    await tester.pump();

    expect(entered, isTrue);
    expect(hovered, isTrue);
    expect(exited, isFalse);

    await gesture.moveTo(Offset.zero);
    await tester.pump();

    expect(exited, isTrue);

    entered = hovered = exited = false;

    await tester.pumpWidget(
      App(
        BaseControl<void>(
          mouseCursor: WidgetStateProperty.all(cursor),
          behavior: behavior,
          opaque: false,
          onPointerHover: (_) => hovered = true,
          onPointerEnter: (_) => entered = true,
          onPointerLeave: (_) => exited = true,
          child: Text(Tag.a.text),
        ),
      ),
    );

    await gesture.moveTo(tester.getCenter(find.text(Tag.a.text)));
    await tester.pump();

    expect(entered, isFalse);
    expect(hovered, isFalse);

    await gesture.moveTo(Offset.zero);

    expect(exited, isFalse);

    expect(hoverable().enabled, isFalse);
    expect(hoverable().cursor, cursor);
    expect(hoverable().behavior, behavior);
    expect(hoverable().opaque, isFalse);
  });

  testWidgets('requests focus when enabled', (WidgetTester tester) async {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
    });

    await tester.pumpWidget(
      App(BaseControl<void>(autofocus: true, onPressed: () {}, child: Text(Tag.a.text))),
    );

    await tester.pump();

    final element = tester.element(find.text(Tag.a.text));
    expect(BaseControl.isFocusedOf<void>(element), isTrue);
    expect(BaseControl.isFocusHighlightShownOf<void>(element), isTrue);
  });

  testWidgets('does not request focus when disabled', (WidgetTester tester) async {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
    });

    await tester.pumpWidget(App(BaseControl<void>(autofocus: true, child: Text(Tag.a.text))));
    await tester.pump();

    final element = tester.element(find.text(Tag.a.text));
    expect(BaseControl.isFocusedOf<void>(element), isFalse);
    expect(BaseControl.isFocusHighlightShownOf<void>(element), isFalse);
  });

  testWidgets('opaque: true', (WidgetTester tester) async {
    var bottomHovered = false;
    var topHovered = false;

    await tester.pumpWidget(
      App(
        Stack(
          children: [
            MouseRegion(
              onEnter: (event) {
                bottomHovered = true;
              },
              child: Container(width: 200, height: 200, color: const Color(0xFF0011FF)),
            ),
            BaseControl<String>(
              key: Tag.a.key,
              onPointerEnter: (_) {
                topHovered = true;
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
            MouseRegion(
              onEnter: (event) {
                bottomHovered = true;
              },
              child: Container(width: 200, height: 200, color: const Color(0xFF0011FF)),
            ),
            BaseControl<String>(
              opaque: false,
              key: Tag.a.key,
              onPointerEnter: (_) {
                topHovered = true;
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
            MouseRegion(
              onEnter: (event) {
                bottomHovered = true;
              },
              child: Container(width: 200, height: 200, color: const Color(0xFF0011FF)),
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
            MouseRegion(
              onEnter: (event) {
                bottomHovered = true;
              },
              child: Container(width: 200, height: 200, color: const Color(0xFF0011FF)),
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

  testWidgets('behavior: deferToChild captures hover and blocks siblings', (
    WidgetTester tester,
  ) async {
    var bottomHovered = false;
    var topHovered = false;

    await tester.pumpWidget(
      App(
        Stack(
          children: [
            MouseRegion(
              onEnter: (event) {
                bottomHovered = true;
              },
              child: Container(width: 200, height: 200, color: const Color(0xFF0011FF)),
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

  testWidgets('isPressedOf is toggled by tap', (WidgetTester tester) async {
    await tester.pumpWidget(App(BaseControl<void>(onPressed: () {}, child: Text(Tag.a.text))));

    Element element() => tester.element(find.text(Tag.a.text));

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text(Tag.a.text)));
    await tester.pump();

    expect(BaseControl.isPressedOf<void>(element()), isTrue);
    expect(BaseControl.statesOf<void>(element()), contains(WidgetState.pressed));

    await gesture.up();
    await tester.pump();

    expect(BaseControl.isPressedOf<void>(element()), isFalse);
    expect(BaseControl.statesOf<void>(element()), isNot(contains(WidgetState.pressed)));
  });

  testWidgets('isPressedOf is toggled by Space', (WidgetTester tester) async {
    var pressedCount = 0;

    await tester.pumpWidget(
      App(
        BaseControl<void>(
          onPressed: () => pressedCount++,
          autofocus: true,
          child: Text(Tag.a.text),
        ),
      ),
    );

    Element element() => tester.element(find.text(Tag.a.text));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(BaseControl.isPressedOf<void>(element()), isTrue);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(BaseControl.isPressedOf<void>(element()), isFalse);
  });

  testWidgets('isPressedOf is cleared on tap cancel', (WidgetTester tester) async {
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

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text(Tag.a.text)));
    addTearDown(gesture.removePointer);

    await tester.pump();

    expect(BaseControl.isPressedOf<void>(element()), isTrue);

    await gesture.moveBy(const Offset(200, 200));
    await tester.pump();

    expect(BaseControl.isPressedOf<void>(element()), isFalse);

    await gesture.up();
    await tester.pump();

    expect(pressedCount, 0);
  });

  testWidgets('onPressed is triggered by tap up', (WidgetTester tester) async {
    var pressedCount = 0;

    await tester.pumpWidget(
      App(
        BaseControl<void>(
          onPressed: () => pressedCount++,
          autofocus: true,
          child: Text(Tag.a.text),
        ),
      ),
    );

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text(Tag.a.text)));
    addTearDown(gesture.removePointer);
    await tester.pump();

    expect(pressedCount, 0);

    await gesture.up();
    await tester.pump();

    expect(pressedCount, 1);
  });

  testWidgets('onPressed is triggered by Space key up', (WidgetTester tester) async {
    var pressedCount = 0;

    await tester.pumpWidget(
      App(
        BaseControl<void>(
          onPressed: () => pressedCount++,
          autofocus: true,
          child: Text(Tag.a.text),
        ),
      ),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(pressedCount, 0);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(pressedCount, 1);
  });

  testWidgets('onPressed is triggered by Enter key down', (WidgetTester tester) async {
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

    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(pressedCount, 1);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(pressedCount, 1);
  });

  testWidgets('onPressed is NOT triggered by tap cancel', (WidgetTester tester) async {
    var pressedCount = 0;

    await tester.pumpWidget(
      App(
        BaseControl<void>(
          onPressed: () => pressedCount++,
          autofocus: true,
          child: Text(Tag.a.text),
        ),
      ),
    );

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text(Tag.a.text)));
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveBy(const Offset(500, 500));
    await tester.pump();

    expect(pressedCount, 0);
  });

  testWidgets('only primary pointer triggers onPressed', (WidgetTester tester) async {
    var pressedCount = 0;
    await tester.pumpWidget(
      App(BaseControl<void>(onPressed: () => pressedCount++, child: Text(Tag.a.text))),
    );

    final center = tester.getCenter(find.text(Tag.a.text));

    // begin primary
    final firstGesture = await tester.startGesture(center, pointer: 1);
    addTearDown(firstGesture.removePointer);
    await tester.pump();

    expect(BaseControl.isPressedOf<void>(tester.element(find.text(Tag.a.text))), isTrue);

    // begin secondary
    final secondGesture = await tester.startGesture(center, pointer: 2);
    addTearDown(secondGesture.removePointer);
    await tester.pump();
    await secondGesture.up();
    await tester.pump();

    // second pointer does not trigger onPressed, and primary pointer is still active
    expect(pressedCount, 0);

    await firstGesture.up();
    await tester.pump();

    // onPressed should have fired exactly once from the primary pointer.
    expect(pressedCount, 1);
  });

  testWidgets('pointer activation blocks keyboard activation', (WidgetTester tester) async {
    var pressedCount = 0;
    final node = FocusNode();
    addTearDown(node.dispose);

    await tester.pumpWidget(
      App(
        BaseControl<void>(
          focusNode: node,
          onPressed: () => pressedCount++,
          child: Text(Tag.a.text),
        ),
      ),
    );

    node.requestFocus();
    await tester.pump();

    // 1. Mouse down: sets lock to .tap
    final gesture = await tester.startGesture(tester.getCenter(find.text(Tag.a.text)));
    await tester.pump();

    // 2. Press Enter: should be ignored because .tap lock is held
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(pressedCount, 0);

    // 3. Mouse up: triggers onPressed
    await gesture.up();
    await tester.pump();
    expect(pressedCount, 1);
  });

  testWidgets('keyboard activation blocks pointer activation', (WidgetTester tester) async {
    var pressedCount = 0;
    await tester.pumpWidget(
      App(
        BaseControl<void>(
          autofocus: true,
          onPressed: () => pressedCount++,
          child: Text(Tag.a.text),
        ),
      ),
    );
    await tester.pump();

    // sets lock to .keyboard
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pump();

    // click should be ignored because .keyboard lock is held
    await tester.tap(find.text(Tag.a.text));
    await tester.pump();
    expect(pressedCount, 0);

    // triggers onPressed
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(pressedCount, 1);

    // click should now work
    await tester.tap(find.text(Tag.a.text));
    await tester.pump();
    expect(pressedCount, 2);
  });

  testWidgets('tap cancel resets activation lock', (WidgetTester tester) async {
    var pressedCount = 0;

    await tester.pumpWidget(
      App(
        BaseControl<void>(
          autofocus: true,
          onPressed: () => pressedCount++,
          child: Text(Tag.a.text),
        ),
      ),
    );

    // set lock to .tap
    final gesture = await tester.startGesture(tester.getCenter(find.text(Tag.a.text)));
    await tester.pump();

    // should be ignored because .tap lock is held
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(pressedCount, 0);

    // cancel the tap
    await gesture.moveBy(const Offset(500, 500));
    await tester.pump();

    // should now fire onPressed
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(pressedCount, 1);

    await gesture.up();
    await tester.pump();
  });

  testWidgets('disabling resets keyboard lock', (WidgetTester tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    var pressedCount = 0;

    await tester.pumpWidget(
      App(
        BaseControl<void>(
          focusNode: node,
          onPressed: () => pressedCount++,
          child: Text(Tag.a.text),
        ),
      ),
    );

    node.requestFocus();
    await tester.pump();

    // set lock to .tap
    final gesture = await tester.startGesture(tester.getCenter(find.text(Tag.a.text)));
    await tester.pump();
    await tester.pumpWidget(App(BaseControl<void>(child: Text(Tag.a.text))));
    await tester.pump();

    expect(pressedCount, 0);

    await tester.pumpWidget(
      App(
        BaseControl<void>(
          focusNode: node,
          onPressed: () => pressedCount++,
          child: Text(Tag.a.text),
        ),
      ),
    );

    await tester.pump();
    node.requestFocus();
    await tester.pump();

    // lock cleared, should fire onPressed
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(pressedCount, 1);

    await gesture.up();
    await tester.pump();
  });

  testWidgets('disabling resets keyboard lock', (WidgetTester tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    var pressedCount = 0;

    await tester.pumpWidget(
      App(
        BaseControl<void>(
          focusNode: node,
          onPressed: () => pressedCount++,
          child: Text(Tag.a.text),
        ),
      ),
    );

    node.requestFocus();

    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(pressedCount, 0);

    await tester.pumpWidget(App(BaseControl<void>(child: Text(Tag.a.text))));
    await tester.pump();

    await tester.pumpWidget(
      App(
        BaseControl<void>(
          focusNode: node,
          onPressed: () => pressedCount++,
          child: Text(Tag.a.text),
        ),
      ),
    );

    await tester.tap(find.text(Tag.a.text));
    await tester.pump();

    expect(pressedCount, 1);
  });

  testWidgets('gestureSemantics can be overridden', (WidgetTester tester) async {
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

    expect(rawGestureDetector.semantics, delegate);
  });

  testWidgets('isPressedOf is cleared when control is disabled', (WidgetTester tester) async {
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

  testWidgets('disposal during pointer activation does not throw', (WidgetTester tester) async {
    await tester.pumpWidget(App(BaseControl<void>(onPressed: () {}, child: Text(Tag.a.text))));

    // start gesture to set isPressed to true
    final gesture = await tester.startGesture(tester.getCenter(find.text(Tag.a.text)));
    await tester.pump();

    final element = tester.element(find.text(Tag.a.text));
    expect(BaseControl.isPressedOf<void>(element), isTrue);

    // remove widget
    await tester.pumpWidget(const App(SizedBox.shrink()));

    // complete the gesture to ensure any pending state changes are processed
    await gesture.up();
    await tester.pump();
  });

  testWidgets('disposal during keyboard activation does not throw', (WidgetTester tester) async {
    await tester.pumpWidget(
      App(BaseControl<void>(autofocus: true, onPressed: () {}, child: Text(Tag.a.text))),
    );
    await tester.pump();

    // set isPressed to true
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pump();

    final element = tester.element(find.text(Tag.a.text));
    expect(BaseControl.isPressedOf<void>(element), isTrue);

    // remove while the key is still down
    await tester.pumpWidget(const App(SizedBox.shrink()));

    // release the key
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pump();
  });

  testWidgets('actions are overrideable', skip: kIsWeb, (WidgetTester tester) async {
    Intent? lastIntent;

    await tester.pumpWidget(
      App(
        shortcuts: const {},
        actions: const {},
        Actions(
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (intent) {
                expect(lastIntent, isNull);
                lastIntent = intent;
                return null;
              },
            ),
            ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
              onInvoke: (intent) {
                fail('ButtonActivateIntent should not be triggered on non-web platforms');
              },
            ),
          },
          child: BaseControl<void>(
            autofocus: true,
            onPressed: () {
              fail('onPressed should not be called when shortcut is overridden');
            },
            child: Text(Tag.a.text),
          ),
        ),
      ),
    );

    // Enter usually triggers ActivateIntent in BaseControl,
    // but the inner Shortcuts widget redefines it to CustomIntent.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(lastIntent, isA<ActivateIntent>());

    lastIntent = null;

    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(lastIntent, isNull);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(lastIntent, isA<ActivateIntent>());
  });

  testWidgets('can override ActivateIntent action [Not Web]', skip: kIsWeb, (
    WidgetTester tester,
  ) async {
    var invocations = 0;

    await tester.pumpWidget(
      App(
        shortcuts: const {},
        actions: const {},
        Actions(
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (intent) {
                invocations++;
                return null;
              },
            ),
          },
          child: BaseControl<void>(
            autofocus: true,
            onPressed: () {
              fail('onPressed should not be called when shortcut is overridden');
            },
            child: Text(Tag.a.text),
          ),
        ),
      ),
    );

    // Enter usually triggers ActivateIntent in BaseControl,
    // but the inner Shortcuts widget redefines it to CustomIntent.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(invocations, 1);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(invocations, 1);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(invocations, 2);
  });

  testWidgets('does not fire ButtonActivateIntent action [Not Web]', skip: kIsWeb, (
    WidgetTester tester,
  ) async {
    var invocations = 0;

    await tester.pumpWidget(
      App(
        shortcuts: const {},
        actions: const {},
        Actions(
          actions: <Type, Action<Intent>>{
            ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
              onInvoke: (intent) {
                invocations++;
                return null;
              },
            ),
          },
          child: BaseControl<void>(autofocus: true, onPressed: () {}, child: Text(Tag.a.text)),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(invocations, 0);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(invocations, 0);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(invocations, 0);
  });

  testWidgets('can override ActivateIntent action [Web]', skip: !kIsWeb, (
    WidgetTester tester,
  ) async {
    var invocations = 0;

    await tester.pumpWidget(
      App(
        shortcuts: const {},
        actions: const {},
        Actions(
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (intent) {
                invocations++;
                return null;
              },
            ),
          },
          child: BaseControl<void>(
            autofocus: true,
            onPressed: () {
              fail('onPressed should not be called when shortcut is overridden');
            },
            child: Text(Tag.a.text),
          ),
        ),
      ),
    );

    // Enter usually triggers ActivateIntent in BaseControl,
    // but the inner Shortcuts widget redefines it to CustomIntent.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(invocations, 0);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(invocations, 0);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(invocations, 1);
  });

  testWidgets('can override ButtonActivateIntent action [Web]', skip: !kIsWeb, (
    WidgetTester tester,
  ) async {
    var invocations = 0;

    await tester.pumpWidget(
      App(
        shortcuts: const {},
        actions: const {},
        Actions(
          actions: <Type, Action<Intent>>{
            ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
              onInvoke: (intent) {
                invocations++;
                return null;
              },
            ),
          },
          child: BaseControl<void>(
            autofocus: true,
            onPressed: () {
              fail('onPressed should not be called when shortcut is overridden');
            },
            child: Text(Tag.a.text),
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(invocations, 1);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(invocations, 1);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(invocations, 1);
  });

  testWidgets('shortcuts can be overridden', (WidgetTester tester) async {
    var pressedCount = 0;
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      App(
        BaseControl<void>(
          autofocus: true,
          onPressed: () => pressedCount++,
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          child: Text(Tag.a.text),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(pressedCount, 1);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(pressedCount, 1);
  });

  testWidgets('shortcuts and actions are empty when control is disabled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(App(BaseControl<void>(child: Text(Tag.a.text))));
    await tester.pump();

    final shortcuts = tester.widget<Shortcuts>(
      find.descendant(of: find.byType(BaseControl<void>), matching: find.byType(Shortcuts)),
    );
    expect(shortcuts.shortcuts, isEmpty);

    final actions = tester.widget<Actions>(
      find.descendant(of: find.byType(BaseControl<void>), matching: find.byType(Actions)),
    );
    expect(actions.actions, isEmpty);
  });

  testWidgets('shortcuts and actions are present when control is enabled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(App(BaseControl<void>(onPressed: () {}, child: Text(Tag.a.text))));
    await tester.pump();

    final shortcuts = tester.widget<Shortcuts>(
      find.descendant(of: find.byType(BaseControl<void>), matching: find.byType(Shortcuts)),
    );
    expect(shortcuts.shortcuts, isNotEmpty);
    expect(shortcuts.shortcuts, contains(const SingleActivator(LogicalKeyboardKey.space)));

    final actions = tester.widget<Actions>(
      find.descendant(of: find.byType(BaseControl<void>), matching: find.byType(Actions)),
    );
    expect(actions.actions, isNotEmpty);
    expect(actions.actions.keys, contains(ActivateIntent));
  });

  testWidgets('cursor resolves states correctly', (WidgetTester tester) async {
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

    expect(getMouseRegion().cursor, SystemMouseCursors.basic);

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);

    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(find.text(Tag.a.text)));
    await tester.pump();

    expect(getMouseRegion().cursor, SystemMouseCursors.grab);

    await gesture.down(tester.getCenter(find.text(Tag.a.text)));
    await tester.pump();

    expect(getMouseRegion().cursor, SystemMouseCursors.grabbing);

    await gesture.up();
    await tester.pump();
    await gesture.moveTo(Offset.zero);

    node.requestFocus();

    await tester.pump();

    expect(getMouseRegion().cursor, SystemMouseCursors.click);

    await tester.pumpWidget(
      App(BaseControl<void>(focusNode: node, mouseCursor: cursor, child: Text(Tag.a.text))),
    );

    expect(getMouseRegion().cursor, SystemMouseCursors.forbidden);
  });

  testWidgets('inherited properties target correct generic type (all states)', (
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

    final greenOuter = tester.getTopLeft(find.byKey(Tag.a.key)) + const Offset(5, 5);
    final blueMiddle = tester.getTopLeft(find.byKey(Tag.b.key)) + const Offset(5, 5);
    final redInner = tester.getCenter(find.byKey(Tag.c.key));

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

  group('semantics', () {
    testWidgets('enabled', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(App(BaseControl<void>(onPressed: () {}, child: Text(Tag.a.text))));

      // Verify label is picked up from child and onTap action is present
      expect(
        tester.getSemantics(find.byType(BaseControl<void>)),
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
    testWidgets('disabled', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(App(BaseControl<void>(child: Text(Tag.a.text))));

      // Verify label is picked up from child and onTap action is present
      expect(
        tester.getSemantics(find.byType(BaseControl<void>)),
        isSemantics(
          label: Tag.a.text,
          hasTapAction: false,
          hasEnabledState: true,
          isEnabled: false,
          isFocusable: false,
          hasFocusAction: false,
          textDirection: .ltr,
        ),
      );

      handle.dispose();
    });

    testWidgets('gestureSemanticsEnabled', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
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

      // Verify label is picked up from child and onTap action is present
      expect(
        tester.getSemantics(find.byType(BaseControl<void>)),
        isSemantics(
          label: Tag.a.text,
          hasTapAction: false,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasFocusAction: true,
          textDirection: .ltr,
        ),
      );

      handle.dispose();
    });

    testWidgets('tap action', (WidgetTester tester) async {
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

    testWidgets('focus action', (WidgetTester tester) async {
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

    testWidgets('can merge semantic label and BaseControl actions', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        App(
          Semantics(
            key: Tag.a.key,
            button: true,
            child: Row(
              children: [
                BaseControl<void>(
                  onPressed: () {},
                  child: Icon(null, semanticLabel: Tag.leading.text),
                ),
                Text(Tag.trailing.text),
              ],
            ),
          ),
        ),
      );

      // Verify that the Row's children are merged into a single semantic node
      expect(
        tester.getSemantics(find.byKey(Tag.a.key)),
        matchesSemantics(
          label:
              '${Tag.leading.text}\n${Tag.trailing.text}', // Merged labels are usually separated by newline
          hasTapAction: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          hasFocusAction: true,
          isButton: true,
          textDirection: .ltr,
        ),
      );

      handle.dispose();
    });
  });
}

class MockSemanticsGestureDelegate extends SemanticsGestureDelegate {
  @override
  void assignSemantics(RenderSemanticsGestureHandler renderObject) {}
}
