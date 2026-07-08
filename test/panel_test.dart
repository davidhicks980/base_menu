import 'dart:ui' as ui;

import 'package:base_menu/base_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utilities.dart';

Finder findWidgetBetween(Type type, {required Type ancestor, required Type descendant}) {
  return find.descendant(
    of: find.byType(ancestor),
    matching: find.ancestor(of: find.byType(descendant), matching: find.byType(type)),
  );
}

void main() {
  testWidgets('basic rendering and defaults', (WidgetTester tester) async {
    await tester.pumpWidget(
      App(BaseMenuPanel(children: <Widget>[Text(Tag.a.text), Text(Tag.b.text)])),
    );

    expect(find.text(Tag.a.text), findsOneWidget);
    expect(find.text(Tag.b.text), findsOneWidget);

    // Default configuration: Vertical, MinAxisSize, Start align, Stretch cross, Down direction, 0 spacing
    final Flex flex = tester.widget(find.byType(Flex));
    expect(flex.direction, Axis.vertical);
    expect(flex.mainAxisSize, MainAxisSize.min);
    expect(flex.mainAxisAlignment, MainAxisAlignment.start);
    expect(flex.crossAxisAlignment, CrossAxisAlignment.stretch);
    expect(flex.verticalDirection, VerticalDirection.down);
    expect(flex.spacing, 0);

    expect(
      find.descendant(of: find.byType(BaseMenuPanel), matching: find.byType(MouseRegion)),
      findsNothing,
    );

    // Default: Scrollable with zero padding
    final SingleChildScrollView scroll = tester.widget(find.byType(SingleChildScrollView));
    expect(scroll.scrollDirection, Axis.vertical);
    expect(scroll.padding, EdgeInsets.zero);
    expect(scroll.clipBehavior, ui.Clip.none);

    expect(
      findWidgetBetween(Padding, ancestor: BaseMenuPanel, descendant: SingleChildScrollView),
      findsOneWidget,
    );
    expect(
      findWidgetBetween(ConstrainedBox, ancestor: BaseMenuPanel, descendant: SingleChildScrollView),
      findsNothing,
    );
    expect(
      findWidgetBetween(IntrinsicWidth, ancestor: BaseMenuPanel, descendant: SingleChildScrollView),
      findsOneWidget,
    );
  });

  testWidgets('properties are applied to Flex', (WidgetTester tester) async {
    await tester.pumpWidget(
      const App(
        BaseMenuPanel(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          verticalDirection: VerticalDirection.up,
          spacing: 10,
          textBaseline: TextBaseline.alphabetic,
          children: [],
        ),
      ),
    );

    final Flex flex = tester.widget(find.byType(Flex));
    expect(flex.mainAxisAlignment, MainAxisAlignment.center);
    expect(flex.mainAxisSize, MainAxisSize.max);
    expect(flex.crossAxisAlignment, CrossAxisAlignment.baseline);
    expect(flex.verticalDirection, VerticalDirection.up);
    expect(flex.textBaseline, TextBaseline.alphabetic);
    expect(flex.spacing, 10);
  });

  testWidgets('orientation and MenuScope inheritance', (WidgetTester tester) async {
    // Explicit orientation property takes precedence
    await tester.pumpWidget(
      const App(
        BaseMenuScope(
          orientation: Axis.vertical,
          isSubmenu: false,
          child: BaseMenuPanel(orientation: Axis.horizontal, children: <Widget>[Text('Item 1')]),
        ),
      ),
    );
    expect(tester.widget<Flex>(find.byType(Flex)).direction, Axis.horizontal);

    // Inherited orientation from MenuScope
    await tester.pumpWidget(
      const App(
        BaseMenuScope(
          isSubmenu: false,
          orientation: Axis.horizontal,
          child: BaseMenuPanel(children: <Widget>[Text('Item 1')]),
        ),
      ),
    );
    expect(tester.widget<Flex>(find.byType(Flex)).direction, Axis.horizontal);
  });

  testWidgets('MouseRegion and interaction', (WidgetTester tester) async {
    var entered = 0;
    var exited = 0;
    var hovered = 0;

    await tester.pumpWidget(
      App(
        BaseMenuPanel(
          onPointerEnter: (_) {
            entered += 1;
          },
          onPointerExit: (_) {
            exited += 1;
          },
          onPointerHover: (_) {
            hovered += 1;
          },
          children: <Widget>[
            Container(
              key: Tag.leading.key,
              width: 100,
              height: 100,
              color: const Color(0xFF0000FF),
            ),
            IgnorePointer(
              child: Container(
                key: Tag.middle.key,
                width: 100,
                height: 100,
                color: const ui.Color(0xFF00FF00),
              ),
            ),
            Container(
              key: Tag.trailing.key,
              width: 100,
              height: 100,
              color: const ui.Color(0xFFFF0000),
            ),
          ],
        ),
      ),
    );

    final topLeft = tester.getTopLeft(find.byType(BaseMenuPanel)).translate(-10, -10);
    final Offset leading = tester.getCenter(find.byKey(Tag.leading.key));
    final Offset center = tester.getCenter(find.byKey(Tag.middle.key));
    final Offset trailing = tester.getCenter(find.byKey(Tag.trailing.key));
    final bottomRight = tester.getBottomRight(find.byType(BaseMenuPanel)).translate(10, 10);

    final gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(topLeft);
    await tester.pump();

    expect(entered, 0);
    expect(exited, 0);

    await gesture.moveTo(leading);
    await tester.pump();

    expect(entered, 1);
    expect(exited, 0);
    expect(hovered, 1);

    await gesture.moveTo(center);
    await tester.pump();

    expect(entered, 1);
    expect(exited, 1);
    expect(hovered, 1);

    await gesture.moveTo(trailing);
    await tester.pump();

    expect(entered, 2);
    expect(exited, 1);
    expect(hovered, 2);

    await gesture.moveTo(bottomRight);
    await tester.pump();

    expect(entered, 2);
    expect(exited, 2);
    expect(hovered, 2);
  });

  testWidgets('clipBehavior', (WidgetTester tester) async {
    // No clip by default
    await tester.pumpWidget(const App(BaseMenuPanel(children: <Widget>[Text('Item 1')])));

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(
      tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView)).clipBehavior,
      ui.Clip.none,
    );

    // ClipRect applied
    await tester.pumpWidget(
      const App(BaseMenuPanel(clipBehavior: ui.Clip.hardEdge, children: <Widget>[Text('Item 1')])),
    );

    final SingleChildScrollView scrollView = tester.widget(find.byType(SingleChildScrollView));
    expect(scrollView.clipBehavior, ui.Clip.hardEdge);

    await tester.pumpWidget(
      const App(
        BaseMenuPanel(clipBehavior: ui.Clip.hardEdge, scrollable: false, children: <Widget>[]),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.widget<ClipRect>(find.byType(ClipRect)).clipBehavior, ui.Clip.hardEdge);

    await tester.pumpWidget(const App(BaseMenuPanel(scrollable: false, children: <Widget>[])));

    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.widget<ClipRect>(find.byType(ClipRect)).clipBehavior, ui.Clip.none);
  });

  testWidgets('constraints and intrinsics (Vertical)', (WidgetTester tester) async {
    // No constraints -> Intrinsic applied
    await tester.pumpWidget(
      App(
        BaseMenuPanel(
          orientation: Axis.vertical,
          children: <Widget>[Container(color: const Color(0xFF0000FF), width: 100, height: 100)],
        ),
      ),
    );

    expect(find.byType(IntrinsicWidth), findsOneWidget);
    expect(find.byType(IntrinsicHeight), findsNothing);
    expect(tester.getSize(find.byType(BaseMenuPanel)), const Size(100, 100));

    // Loose vertical constraints -> Intrinsic applied
    await tester.pumpWidget(
      App(
        BaseMenuPanel(
          orientation: Axis.vertical,
          constraints: const BoxConstraints(maxWidth: 200, maxHeight: 100, minHeight: 100),
          children: <Widget>[Container(color: const Color(0xFF0000FF), width: 100, height: 100)],
        ),
      ),
    );
    expect(find.byType(IntrinsicWidth), findsOneWidget);
    expect(tester.getSize(find.byType(BaseMenuPanel)), const Size(100, 100));

    // Tight constraints -> IntrinsicWidth NOT applied
    await tester.pumpWidget(
      App(
        BaseMenuPanel(
          orientation: Axis.vertical,
          constraints: const BoxConstraints(maxWidth: 200, minWidth: 200, maxHeight: 200),
          children: <Widget>[Container(color: const Color(0xFF0000FF), width: 100, height: 100)],
        ),
      ),
    );
    expect(find.byType(IntrinsicWidth), findsNothing);
    expect(tester.getSize(find.byType(BaseMenuPanel)), const Size(200, 100));

    await tester.pumpWidget(
      App(
        BaseMenuPanel(
          orientation: Axis.vertical,
          constraints: const BoxConstraints.tightFor(width: 20, height: 20),
          children: <Widget>[Container(color: const Color(0xFF0000FF), width: 100, height: 100)],
        ),
      ),
    );
    expect(find.byType(IntrinsicWidth), findsNothing);
    expect(tester.getSize(find.byType(BaseMenuPanel)), const Size(20, 20));
  });

  testWidgets('constraints and intrinsics (Horizontal)', (WidgetTester tester) async {
    // No constraints -> Intrinsic applied
    await tester.pumpWidget(
      App(
        BaseMenuPanel(
          orientation: Axis.horizontal,
          children: <Widget>[Container(color: const Color(0xFF0000FF), width: 100, height: 100)],
        ),
      ),
    );

    expect(find.byType(IntrinsicHeight), findsOneWidget);
    expect(find.byType(IntrinsicWidth), findsNothing);
    expect(tester.getSize(find.byType(BaseMenuPanel)), const Size(100, 100));

    // Loose constraints -> Intrinsic applied
    await tester.pumpWidget(
      App(
        BaseMenuPanel(
          orientation: Axis.horizontal,
          constraints: const BoxConstraints(maxHeight: 200, maxWidth: 100, minWidth: 100),
          children: <Widget>[Container(color: const Color(0xFF0000FF), width: 100, height: 100)],
        ),
      ),
    );
    expect(find.byType(IntrinsicHeight), findsOneWidget);
    expect(tester.getSize(find.byType(BaseMenuPanel)), const Size(100, 100));

    // Tight constraints -> IntrinsicHeight NOT applied
    await tester.pumpWidget(
      App(
        BaseMenuPanel(
          orientation: Axis.horizontal,
          constraints: const BoxConstraints(maxHeight: 200, minHeight: 200, maxWidth: 200),
          children: <Widget>[Container(color: const Color(0xFF0000FF), width: 100, height: 100)],
        ),
      ),
    );
    expect(find.byType(IntrinsicHeight), findsNothing);
    expect(tester.getSize(find.byType(BaseMenuPanel)), const Size(100, 200));

    await tester.pumpWidget(
      App(
        BaseMenuPanel(
          orientation: Axis.horizontal,
          constraints: const BoxConstraints.tightFor(width: 20, height: 20),
          children: <Widget>[Container(color: const Color(0xFF0000FF), width: 100, height: 100)],
        ),
      ),
    );
    expect(find.byType(IntrinsicHeight), findsNothing);
    expect(tester.getSize(find.byType(BaseMenuPanel)), const Size(20, 20));
  });

  testWidgets('diagnostics', (WidgetTester tester) async {
    const Widget childA = Text('A');
    const Widget childB = Text('B');
    final panel = BaseMenuPanel(
      padding: const EdgeInsets.all(8),
      spacing: 5,
      orientation: Axis.horizontal,
      clipBehavior: ui.Clip.antiAlias,
      scrollable: false,
      onPointerEnter: (_) {},
      children: const <Widget>[childA, childB],
    );

    // 1. Test debugFillProperties (Detailed state)
    final builder = DiagnosticPropertiesBuilder();
    panel.debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, contains('padding: EdgeInsets.all(8.0)'));
    expect(description, contains('spacing: 5.0'));
    expect(description, contains('orientation: horizontal'));
    expect(description, contains('clipBehavior: antiAlias'));
    expect(description, contains('non-scrollable'));
    expect(description, contains('has onPointerEnter'));

    // Check that missing listeners are NOT shown (ObjectFlagProperty behavior)
    expect(description, isNot(contains('onPointerExit')));

    // 2. Test defaultValue logic (Noise reduction)
    final defaultBuilder = DiagnosticPropertiesBuilder();
    const BaseMenuPanel(children: []).debugFillProperties(defaultBuilder);

    final List<String> defaultDescription = defaultBuilder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    // These should be omitted because they match the defaults
    expect(defaultDescription, isNot(contains('padding')));
    expect(defaultDescription, isNot(contains('spacing')));
    expect(defaultDescription, isNot(contains('scrollable')));
    expect(defaultDescription, isNot(contains('mainAxisAlignment')));
  });

  testWidgets('debugDescribeChildren', (WidgetTester tester) async {
    const Widget childA = Text('A');
    const Widget childB = Text('B');
    const panel = BaseMenuPanel(children: <Widget>[childA, childB]);

    final List<DiagnosticsNode> children = panel.debugDescribeChildren();
    expect(children.length, 2);
    expect(children[0].name, null); // Children in a list usually don't have individual names
    expect(children[0].value, childA);
    expect(children[1].value, childB);
  });
}
