import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/browser_context_menu_blocker.dart';
import '../model/enum.dart';
import '../theme/colors.dart';
import 'app_state_manager.dart';
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
        final bool isOpen = MenuController.maybeIsOpenOf(context) ?? false;
        return Shortcuts(shortcuts: isOpen ? {} : shortcuts, child: editor);
      },
    );
    return ContextMenuBlockerRegion(
      child: EditorContextMenu(
        menuController: contextMenuController,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SingleChildScrollView(
              hitTestBehavior: HitTestBehavior.translucent,
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              child: Stack(
                clipBehavior: .none,
                children: [
                  const Positioned(
                    top: 24,
                    left: 16,
                    right: -1000,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: FloogleColors.separatorColor),
                          left: BorderSide(color: FloogleColors.separatorColor),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: math.max(MediaQuery.sizeOf(context).width, 96 * 8.5 + 128),
                    child: Stack(
                      clipBehavior: .none,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 25),
                          child: _Disclaimer(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              hitTestBehavior: HitTestBehavior.translucent,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 16, bottom: 64),
                                child: Row(
                                  textDirection: .ltr,
                                  children: [
                                    const VerticalDocumentRuler(),
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: Padding(
                                          padding: const EdgeInsetsDirectional.only(start: 64),
                                          child: Align(
                                            child: UnconstrainedBox(
                                              clipBehavior: Clip.hardEdge,
                                              constrainedAxis: Axis.vertical,
                                              alignment: Alignment.topLeft,
                                              child: Padding(
                                                padding: const EdgeInsetsDirectional.only(end: 64),
                                                child: SizedBox(
                                                  width: 96 * 8.5,
                                                  height: 96 * 11,
                                                  child: DecoratedBox(
                                                    decoration: const BoxDecoration(
                                                      border: Border.fromBorderSide(
                                                        BorderSide(
                                                          color: FloogleColors.separatorColor,
                                                        ),
                                                      ),
                                                      color: FloogleColors.white,
                                                    ),
                                                    // This is where the margins of
                                                    // the text editor can be edited.
                                                    child: Builder(
                                                      builder: (context) {
                                                        final Map<SelectionKey, Object>
                                                        editorState =
                                                            AppStateManager.documentStateOf(
                                                              context,
                                                            );
                                                        return Padding(
                                                          padding: EdgeInsets.fromLTRB(
                                                            editorState[SelectionKey.leftMargin]!
                                                                as double,
                                                            editorState[SelectionKey.topMargin]!
                                                                as double,
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
                        ),
                        const HorizontalDocumentRuler(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Builder(
                builder: (context) {
                  return ExcludeSemantics(
                    child: Listener(
                      onPointerDown: (event) {
                        EditorContextMenu.showMenuAtPointer(context, event);
                      },
                      behavior: .translucent,
                      child: const SizedBox.expand(),
                    ),
                  );
                },
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
      focusNode: AppStateManager.editorFocusNodeOf(context),
      textController: AppStateManager.controllerOf(context),
      textAlign: AppStateManager.selectedTextStyleOf(context)?.textAlign ?? TextAlign.start,
      maxLines: null, // Allows multiline
      expands: true,
    );
  }
}

// I've been asked more than once if this is affiliated with an organization, so
// let's make it clear that it is not.
class _Disclaimer extends StatelessWidget {
  const _Disclaimer({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        const Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: Center(
            child: Text(
              'This project is not affiliated with any organization.',
              style: TextStyle(
                fontSize: 12,
                color: FloogleColors.rulerTextColor,
                fontWeight: .w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
