import 'package:base_menu/base_menu.dart';
import 'package:base_menu_gallery/sequoia/sequoia_app.dart';
import 'package:base_menu_gallery/shared/browser_context_menu_blocker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Cupertino menu opens when mounted directly', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: ContextMenuBlocker(child: SequoiaApp())));
    await tester.pumpAndSettle();

    expect(find.text('Code'), findsOneWidget);
    await tester.tap(find.text('Code'));
    await tester.pump();

    expect(find.text('About Code'), findsOneWidget);
  });

  testWidgets('Cupertino menu opens from keyboard activation', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: ContextMenuBlocker(child: SequoiaApp())));
    await tester.pumpAndSettle();

    final codeMenuItem = tester.widget<BaseMenuItem>(
      find.ancestor(of: find.text('Code'), matching: find.byType(BaseMenuItem)).first,
    );
    codeMenuItem.focusNode!.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(find.text('About Code'), findsOneWidget);
  });
}
