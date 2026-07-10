// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

// import 'package:bada_example/main.dart';

import 'dart:ui';

import 'package:base_menu_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Helper to check if a Label widget indicates focus by having a border.
  // In the example, Label uses BaseMenuItem.isFocusedOf(context) to show a border.
  bool isLabelFocused(WidgetTester tester, String text) {
    final finder = find.ancestor(of: find.text(text), matching: find.byType(DecoratedBox)).first;

    if (!finder.evaluate().isNotEmpty) {
      return false;
    }

    final decoratedBox = tester.widget<DecoratedBox>(finder);
    final decoration = decoratedBox.decoration as BoxDecoration;
    return decoration.border != null;
  }

  group('BaseMenuApp Comprehensive Tests', () {
    testWidgets('Initial state and basic visibility', (WidgetTester tester) async {
      await tester.pumpWidget(const BaseMenuApp());

      // Top-level menu items "File" and "Edit" should be visible
      expect(find.text('File'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);

      // Submenu items like "New" or "Undo" should not be visible initially
      expect(find.text('New'), findsNothing);
      expect(find.text('Undo'), findsNothing);
    });

    testWidgets('Tap-to-open and menu switching behavior', (WidgetTester tester) async {
      await tester.pumpWidget(const BaseMenuApp());

      // 1. Tap "File" to open its menu
      await tester.tap(find.text('File'));
      await tester.pumpAndSettle();

      expect(find.text('New'), findsOneWidget);
      expect(find.text('Open...'), findsOneWidget);

      // 2. Tap "Edit" should automatically close "File" and open "Edit"
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('New'), findsNothing);
      expect(find.text('Undo'), findsOneWidget);
      expect(find.text('Redo'), findsOneWidget);

      // 3. Tap away (in the background) to close the menu
      await tester.tapAt(const Offset(1, 1));
      await tester.pumpAndSettle();

      expect(find.text('Undo'), findsNothing);
      expect(find.text('Redo'), findsNothing);
    });

    testWidgets('Mouse hover behavior', (WidgetTester tester) async {
      await tester.pumpWidget(const BaseMenuApp());

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);

      // 1. Hover over "File" - it should open because requestOpenOnPointerEnter is true by default
      await gesture.moveTo(tester.getCenter(find.text('File')));
      await tester.pumpAndSettle();
      expect(find.text('New'), findsOneWidget);

      // 2. Move mouse to "Edit" - it should switch menus
      await gesture.moveTo(tester.getCenter(find.text('Edit')));
      await tester.pumpAndSettle();
      expect(find.text('New'), findsNothing);
      expect(find.text('Undo'), findsOneWidget);

      // 3. Move mouse away - "Edit" should stay open because requestCloseOnPointerExit is false in the example
      await gesture.moveTo(const Offset(1, 1));
      await tester.pumpAndSettle();
      expect(find.text('Undo'), findsOneWidget);

      await gesture.removePointer();
    });

    testWidgets('Keyboard navigation and focus states', (WidgetTester tester) async {
      await tester.pumpWidget(const BaseMenuApp());

      // 1. Tab into the menu bar - "File" should get focus
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(isLabelFocused(tester, 'File'), isTrue);

      // 2. Open "File" with Enter
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('New'), findsOneWidget);

      // 3. Use ArrowDown to navigate items
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(isLabelFocused(tester, 'New'), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(isLabelFocused(tester, 'Open...'), isTrue);

      // 4. Use ArrowRight to switch to the "Edit" menu from within the open "File" menu
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('New'), findsNothing);
      expect(find.text('Undo'), findsOneWidget);
      expect(isLabelFocused(tester, 'Undo'), isTrue);

      // 5. Close with Escape - menu should close, but "Edit" anchor should stay focused
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Undo'), findsNothing);
      expect(isLabelFocused(tester, 'Edit'), isTrue);
    });

    testWidgets('Menu item selection closes the menu', (WidgetTester tester) async {
      await tester.pumpWidget(const BaseMenuApp());

      // Open "File"
      await tester.tap(find.text('File'));
      await tester.pumpAndSettle();
      expect(find.text('New'), findsOneWidget);

      // Tap "New" item
      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();

      // The menu should close after an item is pressed
      expect(find.text('New'), findsNothing);
      expect(find.text('Open...'), findsNothing);

      // Check for expected debug log if possible, but visibility alone confirms closure.
    });
  });
}
