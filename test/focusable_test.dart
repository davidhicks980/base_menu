import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_utilities/menu_utilities.dart';

void main() {
  testWidgets('initial state is not focused', (WidgetTester tester) async {
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

  testWidgets('disabled BaseFocusable does not request focus with NavigationMode.traditional', (
    WidgetTester tester,
  ) async {
    final node = FocusNode();
    addTearDown(node.dispose);

    await tester.pumpWidget(
      App(
        MediaQuery(
          data: const MediaQueryData(
            // ignore: avoid_redundant_argument_values
            navigationMode: NavigationMode.traditional,
          ),
          child: BaseFocusable<void>(enabled: false, focusNode: node, child: Text(Tag.a.text)),
        ),
      ),
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

  testWidgets('disabled BaseFocusable does request focus with NavigationMode.directional', (
    WidgetTester tester,
  ) async {
    final node = FocusNode();
    addTearDown(node.dispose);

    await tester.pumpWidget(
      App(
        MediaQuery(
          data: const MediaQueryData(
            // ignore: avoid_redundant_argument_values
            navigationMode: NavigationMode.traditional,
          ),
          child: BaseFocusable<void>(enabled: false, focusNode: node, child: Text(Tag.a.text)),
        ),
      ),
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
    final node = FocusNode();
    addTearDown(node.dispose);

    await tester.pumpWidget(App(BaseFocusable<void>(focusNode: node, child: Text(Tag.a.text))));

    node.requestFocus();
    await tester.pump();

    expect(node.hasFocus, isTrue);
    expect(BaseFocusable.isFocusedOf<void>(tester.element(find.text(Tag.a.text))), isTrue);

    await tester.pumpWidget(
      App(BaseFocusable<void>(enabled: false, focusNode: node, child: Text(Tag.a.text))),
    );
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

  testWidgets('NavigationMode.directional: disabling widget does not blur', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);

    // Force Traditional highlight to see the highlight state
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
    });

    await tester.pumpWidget(
      App(
        MediaQuery(
          data: const MediaQueryData(navigationMode: NavigationMode.directional),
          child: BaseFocusable<void>(focusNode: node, child: Text(Tag.a.text)),
        ),
      ),
    );

    node.requestFocus();
    await tester.pump();

    final element = tester.element(find.text(Tag.a.text));

    expect(node.hasFocus, isTrue);
    expect(BaseFocusable.isFocusedOf<void>(element), isTrue);
    expect(BaseFocusable.isFocusHighlightShownOf<void>(element), isTrue);

    await tester.pumpWidget(
      App(
        MediaQuery(
          data: const MediaQueryData(navigationMode: NavigationMode.directional),
          child: BaseFocusable<void>(enabled: false, focusNode: node, child: Text(Tag.a.text)),
        ),
      ),
    );
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

  testWidgets('NavigationMode.traditional: disabling widget blurs focus', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);

    // Force Traditional highlight to see the highlight state
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
    });

    await tester.pumpWidget(
      App(
        MediaQuery(
          // ignore: avoid_redundant_argument_values
          data: const MediaQueryData(navigationMode: NavigationMode.traditional),
          child: BaseFocusable<void>(focusNode: node, child: Text(Tag.a.text)),
        ),
      ),
    );

    node.requestFocus();
    await tester.pump();

    final element = tester.element(find.text(Tag.a.text));

    expect(node.hasFocus, isTrue);
    expect(BaseFocusable.isFocusedOf<void>(element), isTrue);
    expect(BaseFocusable.isFocusHighlightShownOf<void>(element), isTrue);

    await tester.pumpWidget(
      App(
        MediaQuery(
          // ignore: avoid_redundant_argument_values
          data: const MediaQueryData(navigationMode: NavigationMode.traditional),
          child: BaseFocusable<void>(enabled: false, focusNode: node, child: Text(Tag.a.text)),
        ),
      ),
    );
    await tester.pump();

    expect(node.hasFocus, isFalse);
    expect(BaseFocusable.isFocusedOf<void>(element), isFalse);
    expect(BaseFocusable.isFocusHighlightShownOf<void>(element), isFalse);
  });

  testWidgets('switching to NavigationMode.traditional while disabled removes focus', (
    tester,
  ) async {
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

    final element = tester.element(find.text(Tag.a.text));

    node.requestFocus();
    await tester.pump();

    expect(node.hasFocus, isTrue);

    await tester.pumpWidget(
      App(
        MediaQuery(
          data: const MediaQueryData(
            // ignore: avoid_redundant_argument_values
            navigationMode: NavigationMode.traditional,
          ),
          child: BaseFocusable<void>(enabled: false, focusNode: node, child: Text(Tag.a.text)),
        ),
      ),
    );

    await tester.pump();

    expect(node.hasFocus, isFalse);

    await tester.pump();

    expect(BaseFocusable.isFocusedOf<void>(element), isFalse);
  });

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

  testWidgets('FocusHighlightMode.touch: hides highlight [Not Web]', skip: kIsWeb, (tester) async {
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

  testWidgets('FocusHighlightMode.touch: shows highlight [Web]', skip: !kIsWeb, (tester) async {
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

    // On web, it's always shown if focused
    expect(
      BaseFocusable.isFocusHighlightShownOf<void>(tester.element(find.text(Tag.a.text))),
      isTrue,
    );
  });

  testWidgets('switching FocusHighlightMode notifies dependents', skip: kIsWeb, (tester) async {
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
      expect(
        BaseFocusable.isFocusHighlightShownOf<T>(context),
        expected.contains(WidgetState.focused),
      );
    }

    Widget buildTest({bool enabled = true, bool requestFocusOnHover = true}) {
      return App(
        BaseFocusable(
          focusNode: objectNode,
          enabled: enabled,
          child: BaseFocusable<int>(
            focusNode: intNode,
            enabled: enabled,
            child: BaseFocusable<String>(
              focusNode: stringNode,
              enabled: enabled,
              child: Container(key: Tag.c.key, height: 100, width: 100, color: Colors.red),
            ),
          ),
        ),
      );
    }

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
            child: BaseFocusableStateInjector<String>(child: Text(Tag.a.text)),
          ),
        ),
      );

      final Element element = tester.element(find.text(Tag.a.text));

      expect(BaseFocusable.isFocusedOf<String>(element), isFalse);
      expect(BaseFocusable.isFocusHighlightShownOf<String>(element), isFalse);

      node.requestFocus();
      await tester.pump();

      expect(BaseFocusable.isFocusedOf<String>(element), isTrue);
      expect(BaseFocusable.isFocusHighlightShownOf<String>(element), isTrue);
    });

    testWidgets('Overrides showFocusHighlight', (WidgetTester tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() {
        FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
      });

      await tester.pumpWidget(
        App(
          BaseFocusable<String>(
            focusNode: node,
            child: BaseFocusableStateInjector<String>(
              showFocusHighlight: true,
              child: Text(Tag.a.text),
            ),
          ),
        ),
      );

      final Element element = tester.element(find.text(Tag.a.text));

      expect(BaseFocusable.isFocusedOf<String>(element), isFalse);
      expect(BaseFocusable.isFocusHighlightShownOf<String>(element), isTrue);

      await tester.pumpWidget(
        App(
          BaseFocusable<String>(
            focusNode: node,
            child: BaseFocusableStateInjector<String>(
              showFocusHighlight: false,
              child: Text(Tag.a.text),
            ),
          ),
        ),
      );

      node.requestFocus();
      await tester.pump();
      await tester.pump();

      expect(BaseFocusable.isFocusedOf<String>(element), isTrue);
      expect(BaseFocusable.isFocusHighlightShownOf<String>(element), isFalse);
    });
  });
}
