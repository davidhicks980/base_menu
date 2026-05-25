import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state_manager.dart';
import '../model/enum.dart';
import '../utilities/colors.dart';
import 'editable.dart';
import 'menus/context_menu.dart';
import 'ruler.dart';

class EditorView extends StatefulWidget {
  const EditorView({super.key});

  @override
  State<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  final MenuController contextMenuController = MenuController();
  final horizontalScrollController = ScrollController();
  static const shortcuts = {
    SingleActivator(LogicalKeyboardKey.arrowLeft): DoNothingAndStopPropagationIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight): DoNothingAndStopPropagationIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp): DoNothingAndStopPropagationIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown): DoNothingAndStopPropagationIntent(),
  };

  @override
  void dispose() {
    horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const editor = _EditorWidget();
    final child = Builder(
      builder: (context) {
        final isOpen = MenuController.maybeIsOpenOf(context) ?? false;
        return Shortcuts(shortcuts: isOpen ? {} : shortcuts, child: editor);
      },
    );
    return EditorContextMenuWrapper(
      menuController: contextMenuController,
      child: SingleChildScrollView(
        hitTestBehavior: HitTestBehavior.translucent,
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        clipBehavior: .none,
        child: Stack(
          clipBehavior: .none,
          children: [
            const Positioned(
              top: 24,
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomPaint(painter: _TopLeftBorderPainter()),
            ),
            SizedBox(
              width: math.max(MediaQuery.sizeOf(context).width, 96 * 8.5 + 128),
              child: Stack(
                clipBehavior: .none,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 25),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      hitTestBehavior: HitTestBehavior.translucent,
                      clipBehavior: .none,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 64),
                        child: Row(
                          children: [
                            const VerticalDocumentRuler(),
                            Expanded(
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 64),
                                  child: Align(
                                    child: UnconstrainedBox(
                                      clipBehavior: Clip.hardEdge,
                                      constrainedAxis: Axis.vertical,
                                      alignment: Alignment.topLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 64),
                                        child: SizedBox(
                                          width: 96 * 8.5,
                                          height: 96 * 11,
                                          child: DecoratedBox(
                                            decoration: const BoxDecoration(
                                              border: Border.fromBorderSide(
                                                BorderSide(color: FloogleColors.separatorColor),
                                              ),
                                              color: FloogleColors.white,
                                            ),
                                            // This is where the margins of
                                            // the text editor can be edited.
                                            child: Builder(
                                              builder: (context) {
                                                final editorState = AppStateManager.documentStateOf(
                                                  context,
                                                );
                                                return Padding(
                                                  padding: EdgeInsets.fromLTRB(
                                                    editorState[SelectionKey.leftMargin]! as double,
                                                    editorState[SelectionKey.topMargin]! as double,
                                                    editorState[SelectionKey.rightMargin]!
                                                        as double,
                                                    editorState[SelectionKey.bottomMargin]!
                                                        as double,
                                                  ),
                                                  child: child,
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
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const HorizontalDocumentRuler(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorWidget extends StatelessWidget {
  const _EditorWidget();

  @override
  Widget build(BuildContext context) {
    return Editable(
      textInputAction: TextInputAction.newline,
      keyboardType: TextInputType.multiline,
      onTapAlwaysCalled: true,
      forceLine: true,
      enableInteractiveSelection: true,
      autofocus: true,
      onTapOutside: (event) {
        MenuController.maybeOf(context)?.close();
      },
      onSingleLongTapStart: (details) {
        if (kIsWeb && BrowserContextMenu.enabled) {
          return;
        }
        MenuController.maybeOf(context)?.open(position: details.globalPosition);
      },
      onTap: () {
        MenuController.maybeOf(context)?.close();
      },
      focusNode: AppStateManager.editorFocusNodeOf(context),
      textController: AppStateManager.controllerOf(context),
      textAlign: AppStateManager.selectedTextStyleOf(context)?.textAlign ?? TextAlign.start,
      maxLines: null, // Allows multiline
      expands: true,
    );
  }
}

class _TopLeftBorderPainter extends CustomPainter {
  const _TopLeftBorderPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FloogleColors.separatorColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..isAntiAlias = false;
    canvas.drawLine(const Offset(16, 0), Offset(size.width, 0), paint);
    canvas.drawLine(const Offset(16, 0), Offset(16, size.height), paint);
  }

  @override
  bool shouldRepaint(_TopLeftBorderPainter oldDelegate) => false;
}
