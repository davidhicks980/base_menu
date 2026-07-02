import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_utilities/menu_utilities.dart';

import 'utilities.dart';

void main() {
  Future<void> runBoundaryTest(
    WidgetTester tester, {
    required MenuAimGeometry geometry,
    required AlignmentGeometry anchorCorner,
    required AlignmentGeometry targetCorner,
    required bool isIntercepting,
  }) async {
    var intercepted = false;

    await tester.pumpWidget(
      App(
        AimTester(
          geometry: geometry,
          onHoverChanged: (hovered) {
            intercepted = !hovered;
          },
          showAnchor: true,
          showTarget: true,
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);

    final anchorAlign = anchorCorner.resolve(TextDirection.ltr);
    final anchorRect = geometry.anchorRect!;
    final anchorStart = anchorAlign.withinRect(anchorRect);
    final targetAlign = targetCorner.resolve(TextDirection.ltr);
    final targetRect = geometry.targetRect!;
    final targetEnd = targetAlign.withinRect(targetRect);
    await gesture.addPointer(location: Offset.zero);
    await tester.pump();

    expect(intercepted, isFalse);

    await gesture.moveTo(anchorStart);
    await tester.pump();

    MenuAimInterceptor.visualizeAim = true;
    await moveMouse(
      gesture,
      tester: tester,
      start: anchorStart,
      end: targetEnd,
      duration: const Duration(milliseconds: 100),
      steps: 5,
    );

    expect(
      intercepted,
      isIntercepting ? isTrue : isFalse,
      reason: isIntercepting
          ? 'Should intercept events when inside the aim cone: anchor=$anchorCorner target=$targetCorner'
          : 'Should not intercept events when outside the aim cone: anchor=$anchorCorner target=$targetCorner',
    );

    await gesture.removePointer();
  }

  testWidgets('intercepts while moving towards target', (WidgetTester tester) async {
    final geometry = MenuAimGeometry()
      ..anchorRect = const Rect.fromLTWH(200, 200, 50, 50)
      ..targetRect = const Rect.fromLTWH(300, 300, 50, 50);

    var intercepted = false;

    await tester.pumpWidget(
      App(
        AimTester(
          geometry: geometry,
          onHoverChanged: (hovered) {
            intercepted = !hovered;
          },
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: const Offset(225, 225));
    await tester.pump();

    await moveMouse(
      gesture,
      tester: tester,
      start: const Offset(225, 225),
      end: const Offset(295, 295),
      duration: const Duration(milliseconds: 50),
      steps: 20,
    );

    expect(intercepted, isTrue);
  });

  testWidgets('intercepts while moving towards flipped target', (WidgetTester tester) async {
    final geometry = MenuAimGeometry()
      ..anchorRect = const Rect.fromLTWH(200, 200, 50, 50)
      ..targetRect = const Rect.fromLTWH(100, 100, 50, 50);

    var intercepted = false;

    await tester.pumpWidget(
      App(
        AimTester(
          geometry: geometry,
          onHoverChanged: (hovered) {
            intercepted = !hovered;
          },
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: const Offset(225, 225));
    await tester.pump();

    await moveMouse(
      gesture,
      tester: tester,
      start: const Offset(225, 225),
      end: const Offset(155, 155),
      duration: const Duration(milliseconds: 50),
      steps: 20,
    );

    expect(intercepted, isTrue);
  });

  testWidgets('does not intercept inside target', (WidgetTester tester) async {
    final geometry = MenuAimGeometry()
      ..anchorRect = const Rect.fromLTWH(0, 0, 50, 50)
      ..targetRect = const Rect.fromLTWH(200, 200, 50, 50);

    var intercepted = false;

    await tester.pumpWidget(
      App(
        AimTester(
          geometry: geometry,
          onHoverChanged: (hovered) {
            intercepted = !hovered;
          },
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: const Offset(25, 25));
    await tester.pump();

    await moveMouse(
      gesture,
      tester: tester,
      start: const Offset(25, 25),
      end: const Offset(210, 210),
      duration: const Duration(milliseconds: 50),
      steps: 20,
    );

    expect(intercepted, isFalse);
  });

  testWidgets('does not intercept inside anchor', (WidgetTester tester) async {
    final geometry = MenuAimGeometry()
      ..anchorRect = const Rect.fromLTWH(0, 0, 50, 50)
      ..targetRect = const Rect.fromLTWH(200, 200, 50, 50);

    var intercepted = false;

    await tester.pumpWidget(
      App(
        AimTester(
          geometry: geometry,
          onHoverChanged: (hovered) {
            intercepted = !hovered;
          },
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: const Offset(25, 25));
    await tester.pump();

    await moveMouse(
      gesture,
      tester: tester,
      start: const Offset(25, 25),
      end: const Offset(55, 55),
      duration: const Duration(milliseconds: 25),
      steps: 5,
    );

    expect(intercepted, isTrue);

    await gesture.moveTo(const Offset(48, 48));

    expect(intercepted, isFalse);
  });

  testWidgets('does not intercept when moving away from target', (WidgetTester tester) async {
    final geometry = MenuAimGeometry()
      ..anchorRect = const Rect.fromLTWH(200, 200, 50, 50)
      ..targetRect = const Rect.fromLTWH(300, 300, 50, 50);

    var intercepted = false;

    await tester.pumpWidget(
      App(
        AimTester(
          geometry: geometry,
          onHoverChanged: (hovered) {
            intercepted = !hovered;
          },
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);

    // Ensure the pointer is cleaned up after the test.
    addTearDown(gesture.removePointer);

    // Initial position.
    await gesture.addPointer(location: const Offset(245, 245));
    await tester.pump();

    expect(intercepted, isFalse);

    await moveMouse(
      gesture,
      tester: tester,
      start: const Offset(245, 245),
      end: const Offset(275, 275),
      duration: const Duration(milliseconds: 100),
      steps: 10,
    );

    expect(intercepted, isTrue);

    await moveMouse(
      gesture,
      tester: tester,
      start: const Offset(275, 275),
      end: const Offset(252, 252),
      duration: const Duration(milliseconds: 100),
      steps: 10,
    );

    expect(intercepted, isFalse);
  });
  testWidgets('does not intercept when moving away from flipped target', (
    WidgetTester tester,
  ) async {
    final geometry = MenuAimGeometry()
      ..anchorRect = const Rect.fromLTWH(200, 200, 50, 50)
      ..targetRect = const Rect.fromLTWH(100, 100, 50, 50);

    var intercepted = false;

    await tester.pumpWidget(
      App(
        AimTester(
          geometry: geometry,
          onHoverChanged: (hovered) {
            intercepted = !hovered;
          },
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);

    // Ensure the pointer is cleaned up after the test.
    addTearDown(gesture.removePointer);

    // Initial position.
    await gesture.addPointer(location: const Offset(205, 205));
    await tester.pump();

    expect(intercepted, isFalse);

    await moveMouse(
      gesture,
      tester: tester,
      start: const Offset(205, 205),
      end: const Offset(175, 175),
      duration: const Duration(milliseconds: 100),
      steps: 10,
    );

    expect(intercepted, isTrue);

    await moveMouse(
      gesture,
      tester: tester,
      start: const Offset(175, 175),
      end: const Offset(198, 198),
      duration: const Duration(milliseconds: 100),
      steps: 10,
    );

    expect(intercepted, isFalse);
  });

  testWidgets('intercepts with fast mouse movement', (WidgetTester tester) async {
    final geometry = MenuAimGeometry()
      ..anchorRect = const Rect.fromLTWH(200, 200, 50, 50)
      ..targetRect = const Rect.fromLTWH(300, 300, 50, 50);

    var intercepted = false;

    await tester.pumpWidget(
      App(
        AimTester(
          geometry: geometry,
          onHoverChanged: (hovered) {
            intercepted = !hovered;
          },
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);

    addTearDown(gesture.removePointer);

    await gesture.addPointer(location: const Offset(245, 245));
    await tester.pump();

    expect(intercepted, isFalse);

    await moveMouse(
      gesture,
      tester: tester,
      start: const Offset(245, 245),
      end: const Offset(275, 275),
      duration: const Duration(milliseconds: 100),
      steps: 140,
    );

    expect(intercepted, isTrue);
  });
  testWidgets('intercepts with fast mouse movement flipped', (WidgetTester tester) async {
    final geometry = MenuAimGeometry()
      ..anchorRect = const Rect.fromLTWH(200, 200, 50, 50)
      ..targetRect = const Rect.fromLTWH(100, 100, 50, 50);

    var intercepted = false;

    await tester.pumpWidget(
      App(
        AimTester(
          geometry: geometry,
          onHoverChanged: (hovered) {
            intercepted = !hovered;
          },
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: const Offset(205, 205));
    await tester.pump();

    expect(intercepted, isFalse);

    await moveMouse(
      gesture,
      tester: tester,
      start: const Offset(205, 205),
      end: const Offset(175, 175),
      duration: const Duration(milliseconds: 100),
      steps: 140,
    );

    expect(intercepted, isTrue);
  });

  testWidgets('does not intercept with slow mouse movement', (WidgetTester tester) async {
    final geometry = MenuAimGeometry()
      ..anchorRect = const Rect.fromLTWH(200, 200, 50, 50)
      ..targetRect = const Rect.fromLTWH(300, 300, 50, 50);

    var intercepted = false;

    await tester.pumpWidget(
      App(
        AimTester(
          geometry: geometry,
          onHoverChanged: (hovered) {
            intercepted = !hovered;
          },
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);

    addTearDown(gesture.removePointer);

    await gesture.addPointer(location: const Offset(245, 245));
    await tester.pump();

    expect(intercepted, isFalse);

    await moveMouse(
      gesture,
      tester: tester,
      start: const Offset(245, 245),
      end: const Offset(275, 275),
      duration: const Duration(milliseconds: 100),
      steps: 150,
    );

    expect(intercepted, isFalse);
  });

  testWidgets('does not intercept with slow mouse movement flipped', (WidgetTester tester) async {
    final geometry = MenuAimGeometry()
      ..anchorRect = const Rect.fromLTWH(200, 200, 50, 50)
      ..targetRect = const Rect.fromLTWH(100, 100, 50, 50);

    var intercepted = false;

    await tester.pumpWidget(
      App(
        AimTester(
          geometry: geometry,
          onHoverChanged: (hovered) {
            intercepted = !hovered;
          },
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);

    addTearDown(gesture.removePointer);

    await gesture.addPointer(location: const Offset(205, 205));
    await tester.pump();

    expect(intercepted, isFalse);

    await moveMouse(
      gesture,
      tester: tester,
      start: const Offset(205, 205),
      end: const Offset(175, 175),
      duration: const Duration(milliseconds: 100),
      steps: 150,
    );

    expect(intercepted, isFalse);
  });

  testWidgets('boundary check', (WidgetTester tester) async {
    final geometry = MenuAimGeometry()
      ..anchorRect = const Rect.fromLTWH(200, 200, 50, 50)
      ..targetRect = const Rect.fromLTWH(350, 350, 100, 100);

    const corners = [Alignment.topRight, Alignment.bottomLeft, Alignment.bottomRight];

    for (final anchorCorner in corners) {
      for (final targetCorner in [Alignment.bottomLeft, Alignment.topRight]) {
        // Test directly to the target corner
        await runBoundaryTest(
          tester,
          geometry: geometry,
          anchorCorner: anchorCorner,
          targetCorner: targetCorner * 0.9,
          isIntercepting: true,
        );

        await runBoundaryTest(
          tester,
          geometry: geometry,
          anchorCorner: anchorCorner,
          targetCorner: targetCorner,
          isIntercepting: false, // Following the behavior of existing selected tests
        );
      }
    }
  });

  testWidgets('boundary check flipped', (WidgetTester tester) async {
    final geometry = MenuAimGeometry()
      ..anchorRect = const Rect.fromLTWH(300, 300, 50, 50)
      ..targetRect = const Rect.fromLTWH(50, 50, 100, 100);

    const corners = [Alignment.topLeft, Alignment.topRight, Alignment.bottomLeft];

    for (final anchorCorner in corners) {
      for (final targetCorner in [Alignment.bottomLeft, Alignment.topRight]) {
        // Test directly to the target corner
        await runBoundaryTest(
          tester,
          geometry: geometry,
          anchorCorner: anchorCorner,
          targetCorner: targetCorner * 0.9,
          isIntercepting: true,
        );

        await runBoundaryTest(
          tester,
          geometry: geometry,
          anchorCorner: anchorCorner,
          targetCorner: targetCorner,
          isIntercepting: false,
        );
      }
    }
  });

  testWidgets('stops intercepting after exitDuration', (WidgetTester tester) async {
    final geometry = MenuAimGeometry()
      ..anchorRect = const Rect.fromLTWH(0, 0, 50, 50)
      ..targetRect = const Rect.fromLTWH(100, 100, 200, 200);

    var intercepted = false;

    await tester.pumpWidget(
      App(
        AimTester(
          geometry: geometry,
          onHoverChanged: (hovered) {
            intercepted = !hovered;
          },
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: const Offset(25, 25));
    await tester.pump();

    await moveMouse(
      gesture,
      tester: tester,
      start: const Offset(25, 25),
      end: const Offset(55, 55),
      duration: const Duration(milliseconds: 1),
      steps: 5,
    );

    expect(intercepted, isTrue);

    await gesture.moveTo(const Offset(60, 60));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(intercepted, isFalse);
  });

  testWidgets('MenuAimScope provides enabled state', (WidgetTester tester) async {
    var isEnabled = false;

    await tester.pumpWidget(
      MenuAimScope(
        enable: true,
        child: Builder(
          builder: (context) {
            isEnabled = MenuAimScope.isEnabledOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(isEnabled, isTrue);

    await tester.pumpWidget(
      MenuAimScope(
        enable: false,
        child: Builder(
          builder: (context) {
            isEnabled = MenuAimScope.isEnabledOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(isEnabled, isFalse);
  });
}

class AimTester extends StatelessWidget {
  const AimTester({
    super.key,
    required this.geometry,
    required this.onHoverChanged,
    this.showAnchor = false,
    this.showTarget = false,
  });

  final MenuAimGeometry geometry;
  final ValueChanged<bool> onHoverChanged;
  final bool showAnchor;
  final bool showTarget;

  @override
  Widget build(BuildContext context) {
    var isHovered = false;
    return SizedBox(
      height: 600,
      width: 800,
      child: Stack(
        children: [
          Positioned(
            child: StatefulBuilder(
              builder: (context, setState) {
                return MouseRegion(
                  onEnter: (_) {
                    onHoverChanged(true);
                    setState(() {
                      isHovered = true;
                    });
                  },
                  onExit: (event) {
                    onHoverChanged(false);
                    setState(() {
                      isHovered = false;
                    });
                  },
                  child: Container(
                    color: isHovered ? const Color(0xFF00FF00) : const Color(0xFF0000FF),
                  ),
                );
              },
            ),
          ),
          if (showAnchor)
            Positioned.fromRect(
              rect: geometry.anchorRect!,
              child: const ColoredBox(color: Color(0xFFFFFF00)),
            ),
          if (showTarget)
            Positioned.fromRect(
              rect: geometry.targetRect!,
              child: const ColoredBox(color: Color.fromARGB(255, 225, 0, 255)),
            ),
          MenuAimInterceptor(geometry: geometry),
        ],
      ),
    );
  }
}
