import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_utilities/menu_utilities.dart';

void main() {
  group('BaseFocusable', () {
    testWidgets('Initial state is not focused', (WidgetTester tester) async {
      bool? isFocused;
      bool? showsHighlight;

      await tester.pumpWidget(
        App(
          BaseFocusable<void>(
            child: Builder(
              builder: (BuildContext context) {
                isFocused = BaseFocusable.isFocusedOf<void>(context);
                showsHighlight = BaseFocusable.isFocusHighlightShownOf<void>(context);
                return Text(Tag.a.text);
              },
            ),
          ),
        ),
      );

      expect(isFocused, isFalse);
      expect(showsHighlight, isFalse);
    });

    testWidgets('autofocus triggers focus state and callback', (WidgetTester tester) async {
      var focusCount = 0;
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() {
        FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
      });

      await tester.pumpWidget(
        App(
          BaseFocusable<void>(
            autofocus: true,
            onFocusChange: (bool focused) {
              if (focused) {
                focusCount++;
              }
            },
            child: Text(Tag.a.text),
          ),
        ),
      );

      await tester.pump(); // Allow autofocus to take effect

      expect(focusCount, 1);

      final element = tester.element(find.text(Tag.a.text));
      expect(BaseFocusable.isFocusedOf<void>(element), isTrue);
      // Traditional highlight mode (mouse/keyboard) should show highlight by default in tests
      expect(BaseFocusable.isFocusHighlightShownOf<void>(element), isTrue);
    });

    testWidgets('onFocusChange triggers callback when focus node changes', (
      WidgetTester tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      var isFocused = false;

      await tester.pumpWidget(
        App(
          BaseFocusable<void>(
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
      expect(BaseFocusable.isFocusedOf<void>(tester.element(find.text(Tag.a.text))), isTrue);

      node.unfocus();
      await tester.pump();

      expect(isFocused, isFalse);
      expect(BaseFocusable.isFocusedOf<void>(tester.element(find.text(Tag.a.text))), isTrue);

      // Wait a frame since the focus state is reliant on the widget rebuilding after focus changes.
      await tester.pump();

      expect(BaseFocusable.isFocusedOf<void>(tester.element(find.text(Tag.a.text))), isFalse);
    });

    testWidgets('disabled BaseFocusable does not request focus', (WidgetTester tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        App(BaseFocusable<void>(enabled: false, focusNode: node, child: Text(Tag.a.text))),
      );

      node.requestFocus();
      await tester.pump();

      expect(node.hasFocus, isFalse);
      expect(BaseFocusable.isFocusedOf<void>(tester.element(find.text(Tag.a.text))), isFalse);
      expect(
        BaseFocusable.isFocusHighlightShownOf<void>(tester.element(find.text(Tag.a.text))),
        isFalse,
      );
    });

    testWidgets('disabling BaseFocusable clears focus state', (WidgetTester tester) async {
      var enabled = true;
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        App(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  BaseFocusable<void>(enabled: enabled, focusNode: node, child: Text(Tag.a.text)),
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
      expect(BaseFocusable.isFocusedOf<void>(tester.element(find.text(Tag.a.text))), isTrue);

      await tester.tap(find.text(Tag.b.text));
      await tester.pump();
      await tester.pump();

      expect(node.hasFocus, isFalse);
      expect(BaseFocusable.isFocusedOf<void>(tester.element(find.text(Tag.a.text))), isFalse);
    });

    testWidgets('disposes internal focusNode when widget is removed', (WidgetTester tester) async {
      await tester.pumpWidget(App(BaseFocusable<void>(child: Text(Tag.a.text))));

      // Find the focus node created by the internal Focus widget
      final element = tester.element(find.text(Tag.a.text));
      final focusNode = Focus.of(element, scopeOk: true);

      // Remove the widget from the tree
      await tester.pumpWidget(const App(SizedBox.shrink()));

      // In Flutter, calling addListener on a disposed FocusNode
      // throws an AssertionError in debug mode.
      expect(() => focusNode.addListener(() {}), throwsAssertionError);
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
          BaseFocusable(
            focusNode: nodeA,
            child: Container(
              key: Tag.a.key,
              child: BaseFocusable<int>(
                focusNode: nodeB,
                child: Container(
                  key: Tag.b.key,
                  child: BaseFocusable<String>(
                    focusNode: nodeC,
                    child: Container(
                      key: Tag.c.key,
                      child: Builder(
                        builder: (BuildContext context) {
                          return Column(
                            children: [
                              Text('Dynamic: ${BaseFocusable.isFocusedOf(context)}'),
                              Text('Int: ${BaseFocusable.isFocusedOf<int>(context)}'),
                              Text('String: ${BaseFocusable.isFocusedOf<String>(context)}'),
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

    testWidgets('onFocusChange(false) called when disabled', (WidgetTester tester) async {
      var enabled = true;
      bool? lastFocusState;
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        App(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  BaseFocusable<void>(
                    enabled: enabled,
                    focusNode: node,
                    onFocusChange: (val) {
                      lastFocusState = val;
                    },
                    child: Text(Tag.a.text),
                  ),
                  BaseControl(
                    onPressed: () {
                      setState(() {
                        enabled = false;
                      });
                    },
                    child: const Text('Disable'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      node.requestFocus();
      await tester.pump();
      expect(lastFocusState, isTrue);

      // Tapping disable will trigger didUpdateWidget and disable focusability
      await tester.tap(find.text('Disable'));
      await tester.pump();

      // The callback must be fired with false
      expect(lastFocusState, isFalse);
    });
  });

  group('BaseFocusableStateInjector', () {
    testWidgets('Injects ancestor state', (WidgetTester tester) async {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() {
        FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
      });
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        App(
          BaseFocusable<String>(
            focusNode: node,
            child: BaseFocusableStateInjector<String>(
              child: Builder(
                builder: (BuildContext context) {
                  return Text(
                    'Focused: ${BaseFocusable.isFocusedOf<String>(context)}; Highlight: ${BaseFocusable.isFocusHighlightShownOf<String>(context)}',
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Focused: false; Highlight: false'), findsOneWidget);

      node.requestFocus();
      await tester.pump();

      expect(find.text('Focused: true; Highlight: true'), findsOneWidget);
    });

    testWidgets('Overrides showFocusHighlight', (WidgetTester tester) async {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
      addTearDown(() {
        FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
      });

      await tester.pumpWidget(
        App(
          BaseFocusable<String>(
            child: BaseFocusableStateInjector<String>(
              showFocusHighlight: true,
              child: Builder(
                builder: (BuildContext context) {
                  return Text(
                    'Highlight: ${BaseFocusable.isFocusHighlightShownOf<String>(context)}',
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Highlight: true'), findsOneWidget);

      await tester.pumpWidget(
        App(
          BaseFocusable<String>(
            child: BaseFocusableStateInjector<String>(
              showFocusHighlight: false,
              child: Builder(
                builder: (BuildContext context) {
                  return Text(
                    'Highlight: ${BaseFocusable.isFocusHighlightShownOf<String>(context)}',
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
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() {
        FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
      });

      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        App(
          BaseFocusable<String>(
            focusNode: node,
            child: BaseFocusableStateInjector<String>(
              child: Builder(
                builder: (BuildContext context) {
                  return Text(
                    'Highlight: ${BaseFocusable.isFocusHighlightShownOf<String>(context)}',
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Highlight: false'), findsOneWidget);

      node.requestFocus();
      await tester.pump();

      expect(find.text('Highlight: true'), findsOneWidget);
    });
  });

  group('BaseFocusable Modes', () {
    testWidgets('NavigationMode.directional: disabled widget can request focus', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        App(
          MediaQuery(
            data: const MediaQueryData(navigationMode: NavigationMode.directional),
            child: BaseFocusable<void>(enabled: false, focusNode: node, child: Text(Tag.a.text)),
          ),
        ),
      );

      node.requestFocus();
      await tester.pump();

      // In directional mode, focus is allowed even if disabled
      expect(node.hasFocus, isTrue);
      expect(BaseFocusable.isFocusedOf<void>(tester.element(find.text(Tag.a.text))), isTrue);
    });

    testWidgets('NavigationMode.directional: disabling widget while focused retains focus', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      var enabled = true;

      // Force Traditional highlight to see the highlight state
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() {
        FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
      });

      await tester.pumpWidget(
        App(
          StatefulBuilder(
            builder: (context, setState) {
              return MediaQuery(
                data: const MediaQueryData(navigationMode: NavigationMode.directional),
                child: Column(
                  children: [
                    BaseFocusable<void>(enabled: enabled, focusNode: node, child: Text(Tag.a.text)),
                    BaseControl(
                      onPressed: () => setState(() => enabled = false),
                      child: Text(Tag.outside.text),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      node.requestFocus();
      await tester.pump();

      final element = tester.element(find.text(Tag.a.text));

      expect(node.hasFocus, isTrue);
      expect(BaseFocusable.isFocusedOf<void>(element), isTrue);
      expect(BaseFocusable.isFocusHighlightShownOf<void>(element), isTrue);

      await tester.tap(find.text(Tag.outside.text));
      await tester.pump();

      expect(node.hasFocus, isTrue);
      expect(BaseFocusable.isFocusedOf<void>(element), isTrue);
      expect(BaseFocusable.isFocusHighlightShownOf<void>(element), isTrue);
    });

    testWidgets('NavigationMode.traditional: disabled widget cannot request focus', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        App(
          MediaQuery(
            data: const MediaQueryData(),
            child: BaseFocusable<void>(enabled: false, focusNode: node, child: Text(Tag.a.text)),
          ),
        ),
      );

      node.requestFocus();
      await tester.pump();

      expect(node.hasFocus, isFalse);
    });

    testWidgets(
      'Updating NavigationMode from directional to traditional while disabled removes focus',
      (tester) async {
        final node = FocusNode();
        addTearDown(node.dispose);
        var mode = NavigationMode.directional;

        await tester.pumpWidget(
          App(
            StatefulBuilder(
              builder: (context, setState) {
                return MediaQuery(
                  data: MediaQueryData(navigationMode: mode),
                  child: Column(
                    children: [
                      BaseFocusable<void>(enabled: false, focusNode: node, child: Text(Tag.a.text)),
                      BaseControl(
                        onPressed: () {
                          setState(() {
                            mode = NavigationMode.traditional;
                          });
                        },
                        child: Text(Tag.outside.text),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );

        final element = tester.element(find.text(Tag.a.text));

        node.requestFocus();
        await tester.pump();

        expect(node.hasFocus, isTrue);

        await tester.tap(find.text(Tag.outside.text));
        await tester.pump();

        expect(node.hasFocus, isFalse);

        await tester.pump();

        expect(BaseFocusable.isFocusedOf<void>(element), isFalse);
      },
    );

    testWidgets('FocusHighlightMode.traditional: shows focus highlight', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);

      // Force Traditional mode (Keyboard/Mouse)
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() {
        FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
      });

      await tester.pumpWidget(App(BaseFocusable<void>(focusNode: node, child: Text(Tag.a.text))));

      node.requestFocus();
      await tester.pump();

      expect(
        BaseFocusable.isFocusHighlightShownOf<void>(tester.element(find.text(Tag.a.text))),
        isTrue,
      );
    });

    testWidgets('FocusHighlightMode.touch: hides highlight [Not Web]', skip: kIsWeb, (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);

      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
      addTearDown(() {
        FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
      });

      await tester.pumpWidget(App(BaseFocusable<void>(focusNode: node, child: Text(Tag.a.text))));

      node.requestFocus();
      await tester.pump();

      expect(node.hasFocus, isTrue);
      expect(BaseFocusable.isFocusedOf<void>(tester.element(find.text(Tag.a.text))), isTrue);

      // On non-web, touch mode should hide the highlight
      expect(
        BaseFocusable.isFocusHighlightShownOf<void>(tester.element(find.text(Tag.a.text))),
        isFalse,
      );
    });

    testWidgets('FocusHighlightMode.touch: shows highlight when focused [Web]', skip: !kIsWeb, (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);

      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
      addTearDown(() {
        FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
      });

      await tester.pumpWidget(App(BaseFocusable<void>(focusNode: node, child: Text(Tag.a.text))));

      node.requestFocus();
      await tester.pump();

      expect(node.hasFocus, isTrue);
      expect(BaseFocusable.isFocusedOf<void>(tester.element(find.text(Tag.a.text))), isTrue);

      // On web, it's always shown if focused (per implementation in focusable.dart)
      expect(
        BaseFocusable.isFocusHighlightShownOf<void>(tester.element(find.text(Tag.a.text))),
        isTrue,
      );
    });

    testWidgets('Changing FocusHighlightMode notifies dependents', skip: kIsWeb, (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);

      // Start in touch
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
      addTearDown(() {
        FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
      });

      await tester.pumpWidget(App(BaseFocusable<void>(focusNode: node, child: Text(Tag.a.text))));

      node.requestFocus();
      await tester.pump();

      expect(
        BaseFocusable.isFocusHighlightShownOf<void>(tester.element(find.text(Tag.a.text))),
        isFalse,
      );

      // Switch highlight mode mid-test
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;

      // The listener in _BaseFocusableState should call setState
      await tester.pump();

      expect(
        BaseFocusable.isFocusHighlightShownOf<void>(tester.element(find.text(Tag.a.text))),
        isTrue,
      );
    });

    testWidgets(
      'FocusHighlightMode.touch: isFocused is true and showFocusHighlight is false ',
      skip: kIsWeb,
      (tester) async {
        final node = FocusNode();
        addTearDown(node.dispose);

        // Force touch mode
        FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
        addTearDown(() {
          FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
        });

        await tester.pumpWidget(
          App(
            BaseFocusable<void>(
              focusNode: node,
              child: Builder(
                builder: (BuildContext context) {
                  final isFocused = BaseFocusable.isFocusedOf<void>(context);
                  final showsHighlight = BaseFocusable.isFocusHighlightShownOf<void>(context);
                  return Text('Focused: $isFocused; Highlight: $showsHighlight');
                },
              ),
            ),
          ),
        );

        node.requestFocus();
        await tester.pump();

        expect(find.text('Focused: true; Highlight: false'), findsOneWidget);
      },
    );
  });
}
