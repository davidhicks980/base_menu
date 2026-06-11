import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_utilities/menu_utilities.dart';

void main() {
  group('BaseHoverable', () {
    testWidgets('Initial state is not hovered', (WidgetTester tester) async {
      bool? isHovered;
      bool? showsHighlight;

      await tester.pumpWidget(
        App(
          BaseHoverable<void>(
            child: Builder(
              builder: (BuildContext context) {
                isHovered = BaseHoverable.isHoveredOf<void>(context);
                showsHighlight = BaseHoverable.isHoverHighlightShownOf<void>(context);
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
              child: BaseHoverable<void>(
                onEnter: (_) {
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
      expect(BaseHoverable.isHoveredOf<void>(tester.element(find.text(Tag.a.text))), isTrue);
      // Traditional highlight mode (mouse) should show highlight by default on non-web if hovered
      expect(
        BaseHoverable.isHoverHighlightShownOf<void>(tester.element(find.text(Tag.a.text))),
        isTrue,
      );
    });

    testWidgets('onHover triggers callback', (WidgetTester tester) async {
      var hoverCount = 0;
      await tester.pumpWidget(
        App(
          Scaffold(
            body: Center(
              child: BaseHoverable<void>(
                onHover: (_) {
                  hoverCount++;
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

      final Offset center = tester.getCenter(find.text(Tag.a.text));
      await gesture.moveTo(center + const Offset(1, 1));
      await tester.pump();

      expect(hoverCount, greaterThan(0));
    });

    testWidgets('onExit triggers exit and callback', (WidgetTester tester) async {
      var exited = false;
      await tester.pumpWidget(
        App(
          Scaffold(
            body: Center(
              child: BaseHoverable<void>(
                onExit: (_) {
                  exited = true;
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
      expect(BaseHoverable.isHoveredOf<void>(tester.element(find.text(Tag.a.text))), isTrue);

      await gesture.moveTo(Offset.zero);
      await tester.pump();

      expect(exited, isTrue);
      expect(BaseHoverable.isHoveredOf<void>(tester.element(find.text(Tag.a.text))), isFalse);
    });

    testWidgets('disabling BaseHoverable disables callbacks', (WidgetTester tester) async {
      var entered = false;
      await tester.pumpWidget(
        App(
          BaseHoverable<void>(
            enabled: false,
            onEnter: (_) => entered = true,
            onHover: (_) => entered = true,
            onExit: (_) => entered = true,
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
      expect(BaseHoverable.isHoveredOf<void>(tester.element(find.text(Tag.a.text))), isFalse);
    });

    testWidgets('disabling BaseHoverable clears hover state', (WidgetTester tester) async {
      var enabled = true;
      await tester.pumpWidget(
        App(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  BaseHoverable<void>(enabled: enabled, child: Text(Tag.a.text)),
                  ElevatedButton(
                    onPressed: () => setState(() => enabled = false),
                    child: const Text('Disable'),
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
      expect(BaseHoverable.isHoveredOf<void>(tester.element(find.text(Tag.a.text))), isTrue);

      await tester.tap(find.text('Disable'));
      await tester.pump();

      expect(BaseHoverable.isHoveredOf<void>(tester.element(find.text(Tag.a.text))), isFalse);
    });

    testWidgets('BaseHoverable passes properties to MouseRegion', (WidgetTester tester) async {
      const MouseCursor cursor = SystemMouseCursors.click;
      const HitTestBehavior behavior = HitTestBehavior.opaque;

      await tester.pumpWidget(
        App(
          BaseHoverable<void>(
            cursor: cursor,
            behavior: behavior,
            opaque: false,
            enabled: false,
            child: Text(Tag.a.text),
          ),
        ),
      );

      final mouseRegion = tester.widget<MouseRegion>(
        find.descendant(of: find.byType(BaseHoverable<void>), matching: find.byType(MouseRegion)),
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
          BaseHoverable(
            child: Container(
              key: Tag.a.key,
              color: const Color(0xFF0011FF),
              width: 250,
              height: 250,
              alignment: Alignment.center,
              child: BaseHoverable<int>(
                child: Container(
                  key: Tag.b.key,
                  color: const Color(0xFF0011FF),
                  width: 200,
                  height: 200,
                  alignment: Alignment.center,
                  child: BaseHoverable<String>(
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
                              Text('Dynamic: ${BaseHoverable.isHoveredOf(context)}'),
                              Text('Int: ${BaseHoverable.isHoveredOf<int>(context)}'),
                              Text('String: ${BaseHoverable.isHoveredOf<String>(context)}'),
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
              BaseHoverable<int>(
                onEnter: (_) {
                  bottomHovered = true;
                },
                onExit: (_) {
                  bottomHovered = false;
                },
                child: Container(width: 200, height: 200, color: const Color(0xFF0011FF)),
              ),
              BaseHoverable<String>(
                key: Tag.a.key,
                onEnter: (_) {
                  topHovered = true;
                },
                onExit: (_) {
                  topHovered = false;
                },
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
              BaseHoverable<int>(
                onEnter: (_) {
                  bottomHovered = true;
                },
                onExit: (_) {
                  bottomHovered = false;
                },
                child: Container(width: 200, height: 200, color: const Color(0xFF0011FF)),
              ),
              BaseHoverable<String>(
                opaque: false,
                key: Tag.a.key,
                onEnter: (_) {
                  topHovered = true;
                },
                onExit: (_) {
                  topHovered = false;
                },
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
              BaseHoverable<int>(
                behavior: HitTestBehavior.opaque,
                onEnter: (_) => bottomHovered = true,
                child: const SizedBox(width: 200, height: 200),
              ),
              BaseHoverable<String>(
                // opaque is true by default
                behavior: HitTestBehavior.opaque,
                onEnter: (_) => topHovered = true,
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
              BaseHoverable<int>(
                behavior: HitTestBehavior.opaque,
                onEnter: (_) {
                  bottomHovered = true;
                },
                child: const SizedBox(width: 200, height: 200),
              ),
              BaseHoverable<String>(
                // opaque is true by default
                behavior: HitTestBehavior.translucent,
                onEnter: (_) {
                  topHovered = true;
                },
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
              BaseHoverable<int>(
                behavior: HitTestBehavior.opaque,
                onEnter: (_) {
                  bottomHovered = true;
                },
                child: const SizedBox(width: 200, height: 200),
              ),
              BaseHoverable<String>(
                onEnter: (_) {
                  topHovered = true;
                },
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

  group('BaseHoverableStateInjector', () {
    testWidgets('Injects ancestor state', (WidgetTester tester) async {
      await tester.pumpWidget(
        App(
          BaseHoverable<String>(
            child: BaseHoverableStateInjector<String>(
              child: Builder(
                builder: (BuildContext context) {
                  return Text(
                    'Hovered: ${BaseHoverable.isHoveredOf<String>(context)}; Highlight: ${BaseHoverable.isHoverHighlightShownOf<String>(context)}',
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Hovered: false; Highlight: false'), findsOneWidget);

      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);

      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text('Hovered: false; Highlight: false')));
      await tester.pump();

      expect(find.text('Hovered: true; Highlight: true'), findsOneWidget);
    });

    testWidgets('Overrides showHoverHighlight', (WidgetTester tester) async {
      await tester.pumpWidget(
        App(
          BaseHoverable<String>(
            child: BaseHoverableStateInjector<String>(
              showHoverHighlight: true,
              child: Builder(
                builder: (BuildContext context) {
                  return Text(
                    'Highlight: ${BaseHoverable.isHoverHighlightShownOf<String>(context)}',
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Overridden to true even if not hovered
      expect(find.text('Highlight: true'), findsOneWidget);

      await tester.pumpWidget(
        App(
          BaseHoverable<String>(
            child: BaseHoverableStateInjector<String>(
              showHoverHighlight: false,
              child: Builder(
                builder: (BuildContext context) {
                  return Text(
                    'Highlight: ${BaseHoverable.isHoverHighlightShownOf<String>(context)}',
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Highlight: false'), findsOneWidget);
    });

    testWidgets('Falls back to ancestor when override is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        App(
          Scaffold(
            body: Center(
              child: BaseHoverable<String>(
                child: BaseHoverableStateInjector<String>(
                  child: Builder(
                    builder: (BuildContext context) {
                      return Text(
                        'Highlight: ${BaseHoverable.isHoverHighlightShownOf<String>(context)}',
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Highlight: false'), findsOneWidget);

      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);

      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text('Highlight: false')));
      await tester.pump();

      expect(find.text('Highlight: true'), findsOneWidget);
    });

    testWidgets('re-enabling BaseHoverable restores hover state if mouse is still inside', (
      WidgetTester tester,
    ) async {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() {
        FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
      });

      var enabled = true;
      await tester.pumpWidget(
        App(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  BaseHoverable<void>(enabled: enabled, child: Text(Tag.a.text)),
                  BaseControl(
                    onPressed: () {
                      setState(() {
                        enabled = !enabled;
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

      // 1. Hover when enabled
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text(Tag.a.text)));
      await tester.pump();
      final element = tester.element(find.text(Tag.a.text));
      expect(BaseHoverable.isHoverHighlightShownOf<void>(element), isTrue);

      // 2. Disable: highlight should disappear (since it is disabled)
      await tester.tap(find.text(Tag.outside.text));
      await tester.pump();

      expect(BaseHoverable.isHoverHighlightShownOf<void>(element), isFalse);

      await tester.tap(find.text(Tag.outside.text));
      await tester.pump();

      expect(BaseHoverable.isHoverHighlightShownOf<void>(element), isTrue);
    });
  });
  group('BaseHoverable Modes', () {
    testWidgets('[Not Browser] FocusHighlightMode.touch: hides hover highlight', skip: kIsWeb, (
      tester,
    ) async {
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);

      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
      addTearDown(() {
        FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
      });

      await tester.pumpWidget(App(BaseHoverable<void>(child: Text(Tag.a.text))));

      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text(Tag.a.text)));
      await tester.pump();

      final element = tester.element(find.text(Tag.a.text));
      expect(BaseHoverable.isHoveredOf<void>(element), isTrue);

      // On non-web platforms, touch mode hides the hover highlight.
      expect(BaseHoverable.isHoverHighlightShownOf<void>(element), isFalse);
    });

    testWidgets('[Browser] FocusHighlightMode.touch: shows highlight when hovered', skip: !kIsWeb, (
      tester,
    ) async {
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);

      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
      addTearDown(() {
        FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
      });

      await tester.pumpWidget(App(BaseHoverable<void>(child: Text(Tag.a.text))));

      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text(Tag.a.text)));
      await tester.pump();

      final element = tester.element(find.text(Tag.a.text));
      expect(BaseHoverable.isHoveredOf<void>(element), isTrue);

      // On web, hover highlights are shown even in touch mode.
      expect(BaseHoverable.isHoverHighlightShownOf<void>(element), isTrue);
    });

    testWidgets('FocusHighlightMode.traditional: shows hover highlight', (tester) async {
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);

      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() {
        FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
      });

      await tester.pumpWidget(App(BaseHoverable<void>(child: Text(Tag.a.text))));

      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text(Tag.a.text)));
      await tester.pump();

      final element = tester.element(find.text(Tag.a.text));

      expect(BaseHoverable.isHoveredOf<void>(element), isTrue);
      expect(BaseHoverable.isHoverHighlightShownOf<void>(element), isTrue);
    });

    testWidgets(
      '[Not Browser] Updates highlight when FocusManager mode changes at runtime',
      skip: kIsWeb,
      (tester) async {
        final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(gesture.removePointer);

        // Start in touch mode (hidden highlight)
        FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
        addTearDown(
          () => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic,
        );

        await tester.pumpWidget(App(BaseHoverable<void>(child: Text(Tag.a.text))));

        await gesture.addPointer(location: Offset.zero);
        await gesture.moveTo(tester.getCenter(find.text(Tag.a.text)));
        await tester.pump();

        final element = tester.element(find.text(Tag.a.text));

        expect(BaseHoverable.isHoverHighlightShownOf<void>(element), isFalse);

        // Switch to traditional mode (shown highlight)
        FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;

        // Ensure the listener in _BaseHoverableState triggers a rebuild
        await tester.pump();

        expect(BaseHoverable.isHoverHighlightShownOf<void>(element), isTrue);
      },
    );
  });
}
