import 'dart:ui' as ui;

import 'package:base_menu/base_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utilities.dart';

void main() {
  late MenuController controller;

  final intents = <Intent>[];
  final traversalCaptureActions = {
    HorizontalMenuFocusPreviousIntent: CallbackAction<HorizontalMenuFocusPreviousIntent>(
      onInvoke: intents.add,
    ),
    HorizontalMenuFocusNextIntent: CallbackAction<HorizontalMenuFocusNextIntent>(
      onInvoke: intents.add,
    ),
    VerticalMenuFocusPreviousIntent: CallbackAction<VerticalMenuFocusPreviousIntent>(
      onInvoke: intents.add,
    ),
    VerticalMenuFocusNextIntent: CallbackAction<VerticalMenuFocusNextIntent>(onInvoke: intents.add),
  };

  setUp(() {
    controller = MenuController();
  });

  tearDown(() {
    intents.clear();
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

  group('Focus', () {
    testWidgets('anchor maintains highlight when submenu has focus', (WidgetTester tester) async {
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

    testWidgets('closed anchor bubbles traversal intents', (WidgetTester tester) async {
      for (final parentAxis in Axis.values) {
        for (final menuAxis in Axis.values) {
          intents.clear();
          await tester.pumpWidget(
            App(
              Actions(
                actions: traversalCaptureActions,
                child: BaseMenuScope(
                  axis: parentAxis,
                  isSubmenu: true,
                  child: BaseSubmenu(
                    role: null,
                    orientation: menuAxis,
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

          // Invoke all directional intents
          Actions.invoke(primaryFocus!.context!, const VerticalMenuFocusPreviousIntent());
          Actions.invoke(primaryFocus!.context!, const VerticalMenuFocusNextIntent());
          Actions.invoke(primaryFocus!.context!, const HorizontalMenuFocusPreviousIntent());
          Actions.invoke(primaryFocus!.context!, const HorizontalMenuFocusNextIntent());

          await tester.pump();
          expect(
            intents,
            equals([
              isA<VerticalMenuFocusPreviousIntent>(),
              isA<VerticalMenuFocusNextIntent>(),
              isA<HorizontalMenuFocusPreviousIntent>(),
              isA<HorizontalMenuFocusNextIntent>(),
            ]),
            reason:
                'Intents should bubble when closed (parentAxis: $parentAxis, menuAxis: $menuAxis)',
          );
        }
      }
    });

    group('Cross-axis traversal', () {
      late MenuController controller1;
      late MenuController controller2;
      late FocusNode node1;
      late FocusNode node2;
      late FocusNode panelNode1;
      late FocusNode panelNode2;
      setUp(() {
        controller1 = MenuController();
        controller2 = MenuController();
        node1 = FocusNode(debugLabel: 'Anchor 1');
        node2 = FocusNode(debugLabel: 'Anchor 2');
        panelNode1 = FocusNode(debugLabel: 'Panel Item 1');
        panelNode2 = FocusNode(debugLabel: 'Panel Item 2');
      });

      tearDown(() {
        node1.dispose();
        node2.dispose();
        panelNode1.dispose();
        panelNode2.dispose();
      });

      Widget buildTestWidget({
        Axis? parentAxis,
        Axis axis = Axis.vertical,
        bool isSubmenu = false,
        FocusScopeNode? scopeNode, // Add this parameter
      }) {
        Widget child = Column(
          children: [
            BaseSubmenu(
              role: null,
              controller: controller1,
              focusNode: node1,
              orientation: axis,
              menu: Focus(
                focusNode: panelNode1,
                child: Container(color: const ui.Color(0xFFFFBB00), width: 100, height: 100),
              ),
              child: const SubmenuChild(tag: Tag.a),
            ),
            BaseSubmenu(
              role: null,
              controller: controller2,
              focusNode: node2,
              orientation: axis,
              menu: Focus(
                focusNode: panelNode2,
                child: Container(color: const ui.Color(0xFFFF6A00), width: 100, height: 100),
              ),
              child: const SubmenuChild(tag: Tag.b),
            ),
          ],
        );

        if (parentAxis != null) {
          child = BaseMenuBar(orientation: parentAxis, child: child);
        }

        return App(child);
      }

      testWidgets('cross-axis overlay traversal opens and focuses anchor', (
        WidgetTester tester,
      ) async {
        Future<void> run({
          required Axis? parentAxis,
          required Axis axis,
          required Intent intent,
          required FocusNode start,
          required FocusNode end,
          required MenuController startController,
          required MenuController endController,
        }) async {
          await tester.pumpWidget(
            KeyedSubtree(
              key: ValueKey('parentAxis:$parentAxis,axis:$axis,intent:$intent'),
              child: buildTestWidget(parentAxis: parentAxis, axis: axis),
            ),
          );

          startController.open();
          await tester.pump();
          start.requestFocus();
          await tester.pump();

          Actions.invoke(start.context!, intent);
          await tester.pump();

          expect(
            end.hasPrimaryFocus,
            isTrue,
            reason:
                'Expected focus to move to $end node, but it moved to ${FocusManager.instance.primaryFocus}',
          );
          expect(endController.isOpen, isTrue);
        }

        await run(
          parentAxis: Axis.horizontal,
          axis: Axis.vertical,
          intent: const HorizontalMenuFocusPreviousIntent(),
          start: panelNode1,
          end: node2,
          startController: controller1,
          endController: controller2,
        );

        await run(
          parentAxis: Axis.vertical,
          axis: Axis.horizontal,
          intent: const VerticalMenuFocusPreviousIntent(),
          start: panelNode1,
          end: node2,
          startController: controller1,
          endController: controller2,
        );

        await run(
          parentAxis: Axis.horizontal,
          axis: Axis.vertical,
          intent: const HorizontalMenuFocusPreviousIntent(),
          start: panelNode2,
          end: node1,
          startController: controller2,
          endController: controller1,
        );

        await run(
          parentAxis: Axis.vertical,
          axis: Axis.horizontal,
          intent: const VerticalMenuFocusPreviousIntent(),
          start: panelNode2,
          end: node1,
          startController: controller2,
          endController: controller1,
        );

        await run(
          parentAxis: Axis.horizontal,
          axis: Axis.vertical,
          intent: const HorizontalMenuFocusNextIntent(),
          start: panelNode2,
          end: node1,
          startController: controller2,
          endController: controller1,
        );

        await run(
          parentAxis: .vertical,
          axis: .horizontal,
          intent: const VerticalMenuFocusNextIntent(),
          start: panelNode2,
          end: node1,
          startController: controller2,
          endController: controller1,
        );

        await run(
          parentAxis: Axis.horizontal,
          axis: Axis.vertical,
          intent: const HorizontalMenuFocusNextIntent(),
          start: panelNode1,
          end: node2,
          startController: controller1,
          endController: controller2,
        );

        await run(
          parentAxis: Axis.vertical,
          axis: Axis.horizontal,
          intent: const VerticalMenuFocusNextIntent(),
          start: panelNode1,
          end: node2,
          startController: controller1,
          endController: controller2,
        );
      });

      testWidgets('cross-axis anchor traversal opens and focuses sibling anchor when open', (
        WidgetTester tester,
      ) async {
        Future<void> run({
          required Axis? parentAxis,
          required Axis axis,
          required Intent intent,
          required FocusNode start,
          required FocusNode end,
          required MenuController startController,
          required MenuController endController,
        }) async {
          await tester.pumpWidget(
            KeyedSubtree(
              key: ValueKey('parentAxis:$parentAxis,axis:$axis,intent:$intent'),
              child: buildTestWidget(parentAxis: parentAxis, axis: axis),
            ),
          );

          startController.open();
          await tester.pump();
          start.requestFocus();
          await tester.pump();

          Actions.invoke(start.context!, intent);
          await tester.pump();

          expect(end.hasPrimaryFocus, isTrue);
          expect(endController.isOpen, isTrue);
        }

        await run(
          parentAxis: Axis.horizontal,
          axis: Axis.vertical,
          intent: const HorizontalMenuFocusPreviousIntent(),
          start: node1,
          end: node2,
          startController: controller1,
          endController: controller2,
        );

        await run(
          parentAxis: Axis.vertical,
          axis: Axis.horizontal,
          intent: const VerticalMenuFocusPreviousIntent(),
          start: node1,
          end: node2,
          startController: controller1,
          endController: controller2,
        );

        await run(
          parentAxis: Axis.horizontal,
          axis: Axis.vertical,
          intent: const HorizontalMenuFocusPreviousIntent(),
          start: node2,
          end: node1,
          startController: controller2,
          endController: controller1,
        );

        await run(
          parentAxis: Axis.vertical,
          axis: Axis.horizontal,
          intent: const VerticalMenuFocusPreviousIntent(),
          start: node2,
          end: node1,
          startController: controller2,
          endController: controller1,
        );

        await run(
          parentAxis: Axis.horizontal,
          axis: Axis.vertical,
          intent: const HorizontalMenuFocusNextIntent(),
          start: node2,
          end: node1,
          startController: controller2,
          endController: controller1,
        );

        await run(
          parentAxis: .vertical,
          axis: .horizontal,
          intent: const VerticalMenuFocusNextIntent(),
          start: node2,
          end: node1,
          startController: controller2,
          endController: controller1,
        );

        await run(
          parentAxis: Axis.horizontal,
          axis: Axis.vertical,
          intent: const HorizontalMenuFocusNextIntent(),
          start: node1,
          end: node2,
          startController: controller1,
          endController: controller2,
        );

        await run(
          parentAxis: Axis.vertical,
          axis: Axis.horizontal,
          intent: const VerticalMenuFocusNextIntent(),
          start: node1,
          end: node2,
          startController: controller1,
          endController: controller2,
        );
      });

      testWidgets(
        'cross-axis synchronously-closed overlay traversal focuses sibling anchor without opening',
        (WidgetTester tester) async {
          Future<void> run({
            required Axis? parentAxis,
            required Axis axis,
            required Intent intent,
            required FocusNode start,
            required FocusNode end,
            required MenuController startController,
            required MenuController endController,
          }) async {
            await tester.pumpWidget(
              KeyedSubtree(
                key: ValueKey('parentAxis:$parentAxis,axis:$axis,intent:$intent'),
                child: buildTestWidget(parentAxis: parentAxis, axis: axis),
              ),
            );

            startController.open();
            await tester.pump();
            start.requestFocus();
            await tester.pump();
            startController.close();

            Actions.invoke(start.context!, intent);
            await tester.pump();

            expect(end.hasPrimaryFocus, isTrue);
            expect(endController.isOpen, isFalse);
          }

          await run(
            parentAxis: Axis.horizontal,
            axis: Axis.vertical,
            intent: const HorizontalMenuFocusPreviousIntent(),
            start: panelNode1,
            end: node2,
            startController: controller1,
            endController: controller2,
          );

          await run(
            parentAxis: Axis.vertical,
            axis: Axis.horizontal,
            intent: const VerticalMenuFocusPreviousIntent(),
            start: panelNode1,
            end: node2,
            startController: controller1,
            endController: controller2,
          );

          await run(
            parentAxis: Axis.horizontal,
            axis: Axis.vertical,
            intent: const HorizontalMenuFocusPreviousIntent(),
            start: panelNode2,
            end: node1,
            startController: controller2,
            endController: controller1,
          );

          await run(
            parentAxis: Axis.vertical,
            axis: Axis.horizontal,
            intent: const VerticalMenuFocusPreviousIntent(),
            start: panelNode2,
            end: node1,
            startController: controller2,
            endController: controller1,
          );

          await run(
            parentAxis: Axis.horizontal,
            axis: Axis.vertical,
            intent: const HorizontalMenuFocusNextIntent(),
            start: panelNode2,
            end: node1,
            startController: controller2,
            endController: controller1,
          );

          await run(
            parentAxis: .vertical,
            axis: .horizontal,
            intent: const VerticalMenuFocusNextIntent(),
            start: panelNode2,
            end: node1,
            startController: controller2,
            endController: controller1,
          );

          await run(
            parentAxis: Axis.horizontal,
            axis: Axis.vertical,
            intent: const HorizontalMenuFocusNextIntent(),
            start: panelNode1,
            end: node2,
            startController: controller1,
            endController: controller2,
          );

          await run(
            parentAxis: Axis.vertical,
            axis: Axis.horizontal,
            intent: const VerticalMenuFocusNextIntent(),
            start: panelNode1,
            end: node2,
            startController: controller1,
            endController: controller2,
          );
        },
      );

      testWidgets(
        'cross-axis synchronously-closed anchor traversal focuses sibling anchor without opening',
        (WidgetTester tester) async {
          Future<void> run({
            required Axis? parentAxis,
            required Axis axis,
            required Intent intent,
            required FocusNode start,
            required FocusNode end,
            required MenuController startController,
            required MenuController endController,
          }) async {
            await tester.pumpWidget(
              KeyedSubtree(
                key: ValueKey('parentAxis:$parentAxis,axis:$axis,intent:$intent'),
                child: buildTestWidget(parentAxis: parentAxis, axis: axis),
              ),
            );

            startController.open();
            await tester.pump();
            start.requestFocus();
            await tester.pump();
            startController.close();

            Actions.invoke(start.context!, intent);
            await tester.pump();

            expect(end.hasPrimaryFocus, isTrue);
            expect(endController.isOpen, isFalse);
          }

          await run(
            parentAxis: Axis.horizontal,
            axis: Axis.vertical,
            intent: const HorizontalMenuFocusPreviousIntent(),
            start: node1,
            end: node2,
            startController: controller1,
            endController: controller2,
          );

          await run(
            parentAxis: Axis.vertical,
            axis: Axis.horizontal,
            intent: const VerticalMenuFocusPreviousIntent(),
            start: node1,
            end: node2,
            startController: controller1,
            endController: controller2,
          );

          await run(
            parentAxis: Axis.horizontal,
            axis: Axis.vertical,
            intent: const HorizontalMenuFocusPreviousIntent(),
            start: node2,
            end: node1,
            startController: controller2,
            endController: controller1,
          );

          await run(
            parentAxis: Axis.vertical,
            axis: Axis.horizontal,
            intent: const VerticalMenuFocusPreviousIntent(),
            start: node2,
            end: node1,
            startController: controller2,
            endController: controller1,
          );

          await run(
            parentAxis: Axis.horizontal,
            axis: Axis.vertical,
            intent: const HorizontalMenuFocusNextIntent(),
            start: node2,
            end: node1,
            startController: controller2,
            endController: controller1,
          );

          await run(
            parentAxis: .vertical,
            axis: .horizontal,
            intent: const VerticalMenuFocusNextIntent(),
            start: node2,
            end: node1,
            startController: controller2,
            endController: controller1,
          );

          await run(
            parentAxis: Axis.horizontal,
            axis: Axis.vertical,
            intent: const HorizontalMenuFocusNextIntent(),
            start: node1,
            end: node2,
            startController: controller1,
            endController: controller2,
          );

          await run(
            parentAxis: Axis.vertical,
            axis: Axis.horizontal,
            intent: const VerticalMenuFocusNextIntent(),
            start: node1,
            end: node2,
            startController: controller1,
            endController: controller2,
          );
        },
      );

      testWidgets('same-axis overlay: previous intent closes menu', (WidgetTester tester) async {
        await tester.pumpWidget(
          App(
            BaseMenuScope(
              axis: Axis.vertical,
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
          const HorizontalMenuFocusPreviousIntent(),
        );

        await tester.pump();

        expect(controller.isOpen, isFalse);

        await tester.pumpWidget(
          App(
            BaseMenuScope(
              axis: Axis.horizontal,
              isSubmenu: false,
              child: BaseSubmenu(
                role: null,
                orientation: .horizontal,
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
          const VerticalMenuFocusPreviousIntent(),
        );

        await tester.pump();

        expect(controller.isOpen, isFalse);
      });

      testWidgets('same-axis overlay: next intent bubbles', (WidgetTester tester) async {
        await tester.pumpWidget(
          App(
            Actions(
              actions: traversalCaptureActions,
              child: BaseMenuScope(
                axis: Axis.vertical,
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
          ),
        );

        controller.open();
        await tester.pump();
        expect(controller.isOpen, isTrue);

        Actions.invoke(
          tester.element(find.byKey(Tag.a.key)),
          const HorizontalMenuFocusNextIntent(),
        );

        await tester.pump();

        expect(controller.isOpen, isTrue);
        expect(intents, equals([const HorizontalMenuFocusNextIntent()]));
        intents.clear();

        await tester.pumpWidget(
          App(
            Actions(
              actions: traversalCaptureActions,
              child: BaseMenuScope(
                axis: .horizontal,
                isSubmenu: false,
                child: BaseSubmenu(
                  role: null,
                  orientation: .horizontal,
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
          ),
        );

        controller.open();
        await tester.pump();
        expect(controller.isOpen, isTrue);

        Actions.invoke(tester.element(find.byKey(Tag.a.key)), const VerticalMenuFocusNextIntent());

        await tester.pump();

        expect(controller.isOpen, isTrue);
        expect(intents, equals([const VerticalMenuFocusNextIntent()]));
        intents.clear();
      });

      testWidgets('orphan overlay: cross-axis traversal intents bubble', (
        WidgetTester tester,
      ) async {
        final crossAxisIntents = {
          Axis.vertical: [
            const HorizontalMenuFocusPreviousIntent(),
            const HorizontalMenuFocusNextIntent(),
          ],
          Axis.horizontal: [
            const VerticalMenuFocusPreviousIntent(),
            const VerticalMenuFocusNextIntent(),
          ],
        };
        for (final menuAxis in Axis.values) {
          intents.clear();
          await tester.pumpWidget(
            App(
              Actions(
                actions: traversalCaptureActions,
                child: BaseSubmenu(
                  role: null,
                  orientation: menuAxis,
                  controller: controller,
                  menu: Focus(focusNode: panelNode1, child: const SizedBox()),
                  child: Text(Tag.anchor.text),
                ),
              ),
            ),
          );

          await tester.pump();
          controller.open();
          await tester.pump();

          // Invoke all directional intents
          Actions.invoke(panelNode1.context!, const VerticalMenuFocusPreviousIntent());
          Actions.invoke(panelNode1.context!, const VerticalMenuFocusNextIntent());
          Actions.invoke(panelNode1.context!, const HorizontalMenuFocusPreviousIntent());
          Actions.invoke(panelNode1.context!, const HorizontalMenuFocusNextIntent());

          await tester.pump();
          expect(
            intents,
            equals(crossAxisIntents[menuAxis]),
            reason: 'Intents should bubble when closed (parentAxis: null, menuAxis: $menuAxis)',
          );
        }
      });

      testWidgets('same-axis root anchor: cross-axis previous intent closes menu ', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          App(
            BaseMenuScope(
              axis: .horizontal,
              isSubmenu: true,
              child: BaseSubmenu(
                role: null,
                orientation: .horizontal,
                autofocus: true,
                controller: controller,
                menu: const SizedBox(),
                child: Text(Tag.anchor.text),
              ),
            ),
          ),
        );

        controller.open();
        await tester.pump();

        // Invoke all directional intents
        Actions.invoke(primaryFocus!.context!, const VerticalMenuFocusPreviousIntent());

        await tester.pump();
        expect(controller.isOpen, isFalse);

        await tester.pumpWidget(
          App(
            BaseMenuScope(
              axis: .vertical,
              isSubmenu: true,
              child: BaseSubmenu(
                role: null,
                autofocus: true,
                controller: controller,
                menu: const SizedBox(),
                child: Text(Tag.anchor.text),
              ),
            ),
          ),
        );

        controller.open();
        await tester.pump();

        // Invoke all directional intents
        Actions.invoke(primaryFocus!.context!, const HorizontalMenuFocusPreviousIntent());

        await tester.pump();
        expect(controller.isOpen, isFalse);
      });

      testWidgets(
        'same-axis synchronously-closed root anchor: cross-axis previous intent bubbles',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            Actions(
              actions: traversalCaptureActions,
              child: App(
                BaseMenuScope(
                  axis: .horizontal,
                  isSubmenu: true,
                  child: BaseSubmenu(
                    role: null,
                    orientation: .horizontal,
                    autofocus: true,
                    controller: controller,
                    menu: const SizedBox(),
                    child: Text(Tag.anchor.text),
                  ),
                ),
              ),
            ),
          );

          controller.open();
          await tester.pump();
          controller.close();

          // Invoke all directional intents
          Actions.invoke(primaryFocus!.context!, const VerticalMenuFocusPreviousIntent());

          expect(controller.isOpen, isFalse);
          expect(intents, equals([const VerticalMenuFocusPreviousIntent()]));

          intents.clear();

          await tester.pumpWidget(
            Actions(
              actions: traversalCaptureActions,
              child: App(
                BaseMenuScope(
                  axis: .vertical,
                  isSubmenu: true,
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

          controller.open();
          await tester.pump();
          controller.close();

          // Invoke all directional intents
          Actions.invoke(primaryFocus!.context!, const HorizontalMenuFocusPreviousIntent());

          expect(controller.isOpen, isFalse);
          expect(intents, equals([const HorizontalMenuFocusPreviousIntent()]));
        },
      );

      testWidgets('RTL V -> V ArrowLeft triggers focusFirst on submenu', (
        WidgetTester tester,
      ) async {
        final nestedController = MenuController();
        await tester.pumpWidget(
          App(
            textDirection: TextDirection.rtl,
            BaseSubmenu(
              role: null,
              controller: controller,
              menu: BaseSubmenu(
                role: null,
                controller: nestedController,
                menu: Focus(debugLabel: Tag.a.focusNode, child: Text(Tag.a.a.text)),
                child: Text(Tag.a.text),
              ),
              autofocus: true,
              child: Text(Tag.anchor.text),
            ),
          ),
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();

        expect(controller.isOpen, isTrue);
        expect(nestedController.isOpen, isTrue);
        expect(primaryFocus?.debugLabel, contains(Tag.a.focusNode));
      });

      testWidgets('LTR V -> V ArrowRight triggers focusFirst on submenu', (
        WidgetTester tester,
      ) async {
        final nestedController = MenuController();
        await tester.pumpWidget(
          App(
            textDirection: TextDirection.ltr,
            BaseSubmenu(
              role: null,
              controller: controller,
              menu: BaseSubmenu(
                role: null,
                controller: nestedController,
                menu: Focus(debugLabel: Tag.a.focusNode, child: Text(Tag.a.a.text)),
                child: Text(Tag.a.text),
              ),
              autofocus: true,
              child: Text(Tag.anchor.text),
            ),
          ),
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();

        expect(controller.isOpen, isTrue);
        expect(nestedController.isOpen, isTrue);
        expect(primaryFocus?.debugLabel, contains(Tag.a.focusNode));
      });

      testWidgets('RTL V -> H ArrowRight triggers focusLast on submenu', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          App(
            textDirection: TextDirection.rtl,
            BaseMenuBar(
              orientation: Axis.vertical,
              child: BaseSubmenu(
                role: null,
                controller: controller,
                orientation: Axis.horizontal,
                menu: Focus(debugLabel: Tag.a.focusNode, child: Text(Tag.a.text)),
                autofocus: true,
                child: Text(Tag.anchor.text),
              ),
            ),
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();

        expect(controller.isOpen, isTrue);
        expect(primaryFocus?.debugLabel, contains(Tag.a.focusNode));
      });

      testWidgets('LTR V -> H ArrowLeft triggers focusLast on submenu', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          App(
            textDirection: TextDirection.ltr,
            BaseMenuBar(
              orientation: Axis.vertical,
              child: BaseSubmenu(
                role: null,
                controller: controller,
                orientation: Axis.horizontal,
                menu: Focus(debugLabel: Tag.a.focusNode, child: Text(Tag.a.text)),
                autofocus: true,
                child: Text(Tag.anchor.text),
              ),
            ),
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();

        expect(controller.isOpen, isTrue);
        expect(primaryFocus?.debugLabel, contains(Tag.a.focusNode));
      });
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
    const positionDelegate = DefaultMenuPositioningDelegate();
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
      const SingleActivator(LogicalKeyboardKey.keyA): const EnterMenuIntent.focusFirst(),
    };

    await tester.pumpWidget(
      App(
        BaseSubmenu(
          controller: controller,
          onPressed: mockOnPressed,
          onActivate: mockOnActivate,
          onPointerEnter: mockOnPointerEnter,
          onPointerHover: mockOnPointerHover,
          onPointerExit: mockOnPointerLeave,
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
        const EnterMenuIntent.focusFirst(),
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

  testWidgets('Space key activates submenu', (WidgetTester tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      App(
        BaseSubmenu(
          role: null,
          controller: controller,
          focusNode: focusNode,
          menu: const Text('Menu'),
          child: const Text('Anchor'),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(controller.isOpen, isTrue);
  });

  testWidgets('Enter key activates submenu', (WidgetTester tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      App(
        BaseSubmenu(
          role: null,
          controller: controller,
          focusNode: focusNode,
          menu: const Text('Menu'),
          child: const Text('Anchor'),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(controller.isOpen, isTrue);
  });

  testWidgets('custom shortcuts override default submenu shortcuts', (WidgetTester tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      App(
        textDirection: TextDirection.ltr,
        BaseMenuBar(
          orientation: Axis.vertical,
          child: BaseSubmenu(
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.arrowRight): DoNothingAndStopPropagationIntent(),
            },
            controller: controller,
            focusNode: focusNode,
            menu: const Text('Menu'),
            child: const Text('Anchor'),
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();

    // ArrowRight should now do nothing
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(controller.isOpen, isFalse);
  });

  group('Hover + Focus', () {
    testWidgets('keyboard focus inside panel prevents hover close', (WidgetTester tester) async {
      const closeDelay = Duration(milliseconds: 500);
      final panelFocusNode = FocusNode(debugLabel: 'panel item focus');
      addTearDown(panelFocusNode.dispose);

      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            controller: controller,
            hoverCloseDelay: closeDelay,
            menu: Focus(
              focusNode: panelFocusNode,
              child: const SizedBox(key: ValueKey('item'), width: 100, height: 40),
            ),
            child: const SubmenuChild(tag: Tag.anchor),
          ),
        ),
      );

      // Open the submenu overlay.
      controller.open();
      await tester.pump();
      expect(controller.isOpen, isTrue);

      final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: tester.getCenter(find.text(Tag.anchor.text)));
      await tester.pump();

      // Request focus on the internal element using programmatic/keyboard traversal.
      panelFocusNode.requestFocus();
      await tester.pump();
      expect(panelFocusNode.hasFocus, isTrue);

      // Succeeded by the pointer leaving both anchor and panel area (moves to infinity).
      await gesture.moveTo(Offset.infinite);
      await tester.pump();

      // Advance time beyond the hoverCloseDelay.
      await tester.pump(closeDelay + const Duration(milliseconds: 100));

      // The submenu should remain open because focus inside the panel's scope prevents close.
      expect(
        controller.isOpen,
        isTrue,
        reason: 'Keyboard focus inside the panel scope must keep the submenu open.',
      );
    });

    testWidgets('gaining anchor focus cancels active hover close timer', (
      WidgetTester tester,
    ) async {
      const closeDelay = Duration(milliseconds: 500);
      final anchorFocusNode = FocusNode(debugLabel: 'anchor focus');
      final outsideFocusNode = FocusNode(debugLabel: 'outside focus');
      addTearDown(anchorFocusNode.dispose);
      addTearDown(outsideFocusNode.dispose);

      await tester.pumpWidget(
        App(
          Column(
            children: [
              BaseControl(
                onPressed: () {},
                focusNode: outsideFocusNode,
                child: const Text('Outside'),
              ),
              BaseSubmenu(
                role: null,
                controller: controller,
                focusNode: anchorFocusNode,
                hoverCloseDelay: closeDelay,
                menu: Container(color: const ui.Color(0xFFFFBB00), width: 50, height: 50),
                child: const SubmenuChild(tag: Tag.anchor),
              ),
            ],
          ),
        ),
      );

      controller.open();
      await tester.pump();

      final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: tester.getCenter(find.text(Tag.anchor.text)));
      await tester.pump();

      // Shift focus to the outside node so the anchor node does not already have focus.
      outsideFocusNode.requestFocus();
      await tester.pump();

      // Pointer leaves, scheduling a hover close timer.
      await gesture.moveTo(Offset.infinite);
      await tester.pump();

      // Advance time partially (timer is active but not fired).
      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.isOpen, isTrue);

      // Gaining focus via keyboard/programmatic access on the anchor node.
      anchorFocusNode.requestFocus();
      await tester.pump();

      // Advance time outstanding past closeDelay.
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        controller.isOpen,
        isTrue,
        reason: 'Gaining focus on anchor should cancel the active hover close timer.',
      );
    });

    testWidgets('hover open timer is canceled if pointer leaves before delay expires', (
      WidgetTester tester,
    ) async {
      const openDelay = Duration(milliseconds: 500);
      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            controller: controller,
            hoverOpenDelay: openDelay,
            menu: const SizedBox(width: 50, height: 50),
            child: const SubmenuChild(tag: Tag.anchor),
          ),
        ),
      );

      expect(controller.isOpen, isFalse);

      final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text(Tag.anchor.text)));
      await tester.pump();

      // Advance time partially.
      await tester.pump(const Duration(milliseconds: 250));

      expect(controller.isOpen, isFalse);

      // Move pointer away before openDelay ends.
      await gesture.moveTo(Offset.infinite);
      await tester.pump();

      // Advance time past the original hoverOpenDelay duration.
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        controller.isOpen,
        isFalse,
        reason: 'Submenu should not open since the pointer left before delay expired.',
      );
    });

    testWidgets('hover open timer is canceled if focus leaves before delay expires', (
      WidgetTester tester,
    ) async {
      const openDelay = Duration(milliseconds: 500);
      final anchorFocusNode = FocusNode(debugLabel: Tag.anchor.focusNode);
      final outsideFocusNode = FocusNode(debugLabel: Tag.outside.focusNode);
      addTearDown(anchorFocusNode.dispose);
      addTearDown(outsideFocusNode.dispose);

      await tester.pumpWidget(
        App(
          Column(
            children: [
              BaseControl(
                onPressed: () {},
                focusNode: outsideFocusNode,
                child: const Text('Outside'),
              ),
              BaseSubmenu(
                role: null,
                controller: controller,
                focusNode: anchorFocusNode,
                hoverOpenDelay: openDelay,
                menu: const SizedBox(width: 100, height: 100),
                child: const SubmenuChild(tag: Tag.anchor),
              ),
            ],
          ),
        ),
      );

      expect(controller.isOpen, isFalse);

      // Hover the anchor to start the open timer.
      final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text(Tag.anchor.text)));
      await tester.pump();

      expect(anchorFocusNode.hasFocus, isTrue);

      await tester.pump(const Duration(milliseconds: 250));

      expect(controller.isOpen, isFalse);

      outsideFocusNode.requestFocus();
      await tester.pump();

      expect(anchorFocusNode.hasFocus, isFalse);

      await tester.pump(const Duration(milliseconds: 400));

      expect(
        controller.isOpen,
        isFalse,
        reason: 'Submenu should not open since the focus left the anchor before delay expired.',
      );
    });

    testWidgets('rapid enter/leave sequence manages timers correctly without exceptions', (
      WidgetTester tester,
    ) async {
      const delay = Duration(milliseconds: 300);
      final anchorFocusNode = FocusNode(debugLabel: Tag.anchor.focusNode);
      addTearDown(anchorFocusNode.dispose);

      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            controller: controller,
            focusNode: anchorFocusNode,
            hoverOpenDelay: delay,
            hoverCloseDelay: delay,
            menu: Container(
              color: const ui.Color(0xFFFFBB00),
              key: Tag.a.key,
              width: 100,
              height: 100,
            ),
            child: const SubmenuChild(tag: Tag.anchor),
          ),
        ),
      );

      final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);

      await gesture.moveTo(tester.getCenter(find.text(Tag.anchor.text)));
      await tester.pump();

      await gesture.moveTo(Offset.infinite);
      await tester.pump();

      await tester.pump(delay + const Duration(milliseconds: 50));
      expect(controller.isOpen, isFalse);

      controller.open();
      await tester.pump();
      expect(controller.isOpen, isTrue);

      await gesture.moveTo(tester.getCenter(find.text(Tag.anchor.text)));
      await tester.pump();
      await gesture.moveTo(Offset.infinite);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byKey(Tag.a.key)));
      await tester.pump();
      await tester.pump(delay + const Duration(milliseconds: 50));

      expect(controller.isOpen, isTrue);
    });
  });

  group('Hover', () {
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
              BaseControl(
                onPressed: () {},
                focusNode: outsideFocusNode,
                child: Text(Tag.outside.text),
              ),
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
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byKey(Tag.a.key)));
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
      expect(controller.isOpen, isTrue);

      await tester.pump(closeDelay + const Duration(milliseconds: 50));

      expect(controller.isOpen, isTrue);

      outsideFocusNode.requestFocus();
      await tester.pump();

      expect(focusNode.hasFocus, isFalse);

      await gesture.moveTo(Offset.infinite);
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
    });
  });

  group('Disabled', () {
    testWidgets('prevents hover open', (WidgetTester tester) async {
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

    testWidgets('prevents onPressed from being called', (WidgetTester tester) async {
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

    testWidgets('prevents onActivate from being called', (WidgetTester tester) async {
      var onActivateCalled = false;
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        App(
          BaseSubmenu(
            role: null,
            enabled: false,
            focusNode: focusNode,
            onActivate: () {
              onActivateCalled = true;
            },
            controller: controller,
            menu: Button.tag(Tag.a),
            child: const SubmenuChild(tag: Tag.anchor),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(onActivateCalled, isFalse);
      expect(controller.isOpen, isFalse);
    });

    testWidgets('closes when the anchor becomes disabled', (WidgetTester tester) async {
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
}

class MockFocusNode extends FocusNode {
  @override
  bool get hasListeners => super.hasListeners;
}
