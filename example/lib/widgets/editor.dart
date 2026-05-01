import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state_manager.dart';
import '../utilities/colors.dart';
import 'editable.dart';
import 'menus/editor_context_menu.dart';
import 'ruler.dart';

class EditorView extends StatefulWidget {
  const EditorView({super.key});

  @override
  State<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  final MenuController contextMenuController = MenuController();
  static const shortcuts = {
    SingleActivator(LogicalKeyboardKey.arrowLeft): DoNothingAndStopPropagationIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight): DoNothingAndStopPropagationIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp): DoNothingAndStopPropagationIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown): DoNothingAndStopPropagationIntent(),
  };

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
      child: Column(
        children: [
          const HorizontalDocumentRuler(),
          Expanded(
            child: CustomPaint(
              painter: _TopLeftBorderPainter(),
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 64),
                    child: Row(
                      children: [
                        const VerticalDocumentRuler(),
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
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
                                              BorderSide(color: FloogleColors.rulerColor),
                                            ),
                                            color: FloogleColors.white,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(64),
                                            child: child,
                                          ),
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
            ),
          ),
        ],
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
      onSecondaryTapDown: (details) {
        MenuController.maybeOf(context)?.open(position: details.globalPosition);
      },
      onSingleLongTapStart: (details) {
        MenuController.maybeOf(context)?.open(position: details.globalPosition);
      },
      onTap: () {
        if (MenuController.maybeIsOpenOf(context) ?? false) {
          MenuController.maybeOf(context)?.close();
        }
      },
      focusNode: AppStateManager.editorFocusNodeOf(context),
      controller: AppStateManager.controllerOf(context),
      textAlign: AppStateManager.selectedTextStyleOf(context)?.textAlign ?? TextAlign.start,
      maxLines: null, // Allows multiline
      expands: true,
    );
  }
}

class _TopLeftBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FloogleColors.rulerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..isAntiAlias = false;
    canvas.drawLine(const Offset(16, 0), Offset(size.width, 0), paint);
    canvas.drawLine(const Offset(16, 0), Offset(16, size.height), paint);
  }

  @override
  bool shouldRepaint(_TopLeftBorderPainter oldDelegate) => false;
}
