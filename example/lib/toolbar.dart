import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:menu_utilities/menu_utilities.dart';

import 'app_state_manager.dart';
import 'data/entry.dart';
import 'data/menu.dart';
import 'utilities/colors.dart';
import 'widgets/adapters/menu_entry_popup.dart';
import 'widgets/adapters/menu_entry_toolbar_button.dart';
import 'widgets/icon_button.dart';
import 'widgets/menu_divider.dart';
import 'widgets/menus/align_indent.dart';
import 'widgets/menus/bulleted_list_toolbar_menu.dart';
import 'widgets/menus/checklist_toolbar_menu.dart';
import 'widgets/menus/font_size.dart';
import 'widgets/menus/fonts.dart';
import 'widgets/menus/numbered_list.dart';
import 'widgets/menus/paragraph_styles.dart';
import 'widgets/menus/search_menus.dart';
import 'widgets/menus/text_color.dart';
import 'widgets/menus/text_highlight.dart';
import 'widgets/menus/view_mode.dart';
import 'widgets/menus/zoom.dart';
import 'widgets/overflow_toolbar.dart';

class _Group extends StatelessWidget {
  const _Group(this.children);
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.0),
      child: Row(spacing: 2, mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

const _group1 = [
  MenuEntryToolbarButton(item: Entry.undo),
  MenuEntryToolbarButton(item: Entry.redo),
  MenuEntryToolbarButton(item: Entry.print),
  MenuEntryToolbarButton(item: Entry.spellingAndGrammar),
  MenuEntryToolbarButton(item: Entry.paintFormat),
  ZoomMenu(),
  VerticalMenuDivider(),
];
const _group2 = [ParagraphStylesMenu(), VerticalMenuDivider()];
const _group3 = [FontMenu(), VerticalMenuDivider()];

const _group4 = [
  DecrementFontSizeButton(),
  FontSizeMenu(),
  IncrementFontSizeButton(),
  VerticalMenuDivider(),
];

const _group5 = [
  MenuEntryToolbarButton(item: Entry.boldFormat),
  MenuEntryToolbarButton(item: Entry.italicFormat),
  MenuEntryToolbarButton(item: Entry.underlineFormat),
  TextColorButton(),
  TextHighlightButton(),
  VerticalMenuDivider(),
];

const _group6 = [
  MenuEntryToolbarButton(item: Entry.insertLink),
  MenuEntryToolbarButton(
    item: Entry.addComment,
    iconTheme: IconThemeData(opticalSize: 24, size: 20, weight: 320),
  ),
  MenuEntryPopup(model: Menu.image),
  VerticalMenuDivider(),
];

const _group7 = [
  AlignIndentMenu(),
  MenuEntryPopup(model: Menu.lineAndParagraphSpacing),
  ChecklistToolbarMenu(),
  BulletedListToolbarMenu(),
  NumberedListToolbarMenu(),
];

const _group8 = [
  MenuEntryToolbarButton(item: Entry.decreaseIndent),
  MenuEntryToolbarButton(item: Entry.increaseIndent),
  MenuEntryToolbarButton(item: Entry.clearFormatting),
];

const allGroups = [_group1, _group2, _group3, _group4, _group5, _group6, _group7, _group8];

const children = [
  _Group(_group1),
  _Group(_group2),
  _Group(_group3),
  _Group(_group4),
  _Group(_group5),
  _Group(_group6),
  _Group(_group7),
  _Group(_group8),
];

class ToolbarScope extends InheritedWidget {
  const ToolbarScope({super.key, required this.child}) : super(child: child);

  @override
  final Widget child;

  static ToolbarScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ToolbarScope>();
  }

  @override
  bool updateShouldNotify(ToolbarScope oldWidget) {
    return true;
  }
}

class Toolbar extends StatefulWidget {
  const Toolbar({super.key});

  @override
  State<Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends State<Toolbar> {
  final toolbarFocusScopeNode = FocusScopeNode(
    debugLabel: 'Toolbar Focus Scope',
    directionalTraversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );
  final MenuController menuController = MenuController();
  final MenuController overflowMenuController = MenuController();
  final FocusNode overflowButtonFocusNode = FocusNode();
  int _cutoff = children.length;

  Map<Type, Action<Intent>>? _actions;
  late final enterForwardAction = {
    HorizontalMenuNextFocusIntent: CallbackAction<HorizontalMenuNextFocusIntent>(
      onInvoke: (intent) =>
          Actions.invoke(overflowButtonFocusNode.context!, const MenuEnterIntent.focusFirst()),
    ),
  };

  late final enterReverseAction = {
    HorizontalMenuPreviousFocusIntent: CallbackAction<HorizontalMenuPreviousFocusIntent>(
      onInvoke: (intent) =>
          Actions.invoke(overflowButtonFocusNode.context!, const MenuEnterIntent.focusLast()),
    ),
  };

  @override
  void dispose() {
    FocusManager.instance.removeListener(_focusListener);
    overflowButtonFocusNode.dispose();
    toolbarFocusScopeNode.dispose();
    super.dispose();
  }

  void _onFocusChange(bool hasFocus) {
    if (toolbarFocusScopeNode.hasFocus) {
      FocusManager.instance.addListener(_focusListener);
    } else {
      FocusManager.instance.removeListener(_focusListener);
      if (_actions != null) {
        setState(() {
          _actions = null;
        });
      }
    }
  }

  void _focusListener() {
    if (primaryFocus == null) {
      return;
    }

    final descendants = toolbarFocusScopeNode.traversalDescendants;
    if (primaryFocus == descendants.lastOrNull) {
      setState(() {
        _actions = enterForwardAction;
      });
    } else if (primaryFocus == descendants.firstOrNull) {
      setState(() {
        _actions = enterReverseAction;
      });
    } else if (_actions != null) {
      setState(() {
        _actions = null;
      });
    }
  }

  void _focusFirstToolbarItem() {
    toolbarFocusScopeNode.traversalDescendants.firstOrNull?.requestFocus();
  }

  void _focusLastToolbarItem() {
    toolbarFocusScopeNode.traversalDescendants.lastOrNull?.requestFocus();
  }

  void _handleOverflow(int cutoffIndex) {
    _cutoff = cutoffIndex;
    SchedulerBinding.instance.addPostFrameCallback((timestamp) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Widget _buildConditionalTraversal(BuildContext context, Widget? child) {
    return Focus(
      includeSemantics: false,
      canRequestFocus: false,
      skipTraversal: !toolbarFocusScopeNode.hasFocus,
      onFocusChange: _onFocusChange,
      descendantsAreTraversable: true,
      descendantsAreFocusable: true,
      child: child!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cutoffChildren = allGroups.sublist(_cutoff);
    return Container(
      decoration: const BoxDecoration(
        color: FloogleColors.elevatedSurfaceColor,
        borderRadius: BorderRadius.all(Radius.circular(24.0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      constraints: const BoxConstraints(maxHeight: 40),
      child: Row(
        children: [
          const SearchMenu(breakpoint: 1500),
          Flexible(
            child: TapRegion(
              onTapOutside: (event) {
                if (!menuController.isOpen) {
                  toolbarFocusScopeNode.unfocus();
                }
              },
              child: ListenableBuilder(
                listenable: toolbarFocusScopeNode,
                builder: _buildConditionalTraversal,
                child: Row(
                  children: [
                    Flexible(
                      child: BaseMenuBar(
                        controller: menuController,
                        focusScopeNode: toolbarFocusScopeNode,
                        child: Actions(
                          actions: cutoffChildren.isNotEmpty && _actions != null
                              ? _actions!
                              : const {},
                          child: OverflowRow(onOverflow: _handleOverflow, children: children),
                        ),
                      ),
                    ),
                    if (cutoffChildren.isNotEmpty)
                      OverflowButton(
                        onTraverseForward: _focusFirstToolbarItem,
                        onTraverseBackward: _focusLastToolbarItem,
                        buttonFocusNode: overflowButtonFocusNode,
                        controller: overflowMenuController,
                        children: cutoffChildren.expand((group) => group).toList(growable: false),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const ViewModeMenu(breakpoint: 1500),
          const SizedBox(width: 8),
          const VerticalMenuDivider(),
          IconButton(
            onPressed: () {
              AppStateManager.of(context).toggleTitle();
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Builder(
                builder: (context) {
                  return AppStateManager.isHeaderShownOf(context)
                      ? const Icon(Symbols.expand_less, size: 18)
                      : const Icon(Symbols.expand_more, size: 18);
                },
              ),
            ),
          ),
          const SizedBox(width: 2),
        ],
      ),
    );
  }
}

class OverflowButton extends StatefulWidget {
  const OverflowButton({
    super.key,
    required this.children,
    required this.controller,
    required this.buttonFocusNode,
    required this.onTraverseForward,
    required this.onTraverseBackward,
  });
  final List<Widget> children;
  final MenuController controller;
  final FocusNode buttonFocusNode;
  final VoidCallback onTraverseForward;
  final VoidCallback onTraverseBackward;

  @override
  State<OverflowButton> createState() => _OverflowButtonState();
}

class _OverflowButtonState extends State<OverflowButton> with SingleTickerProviderStateMixin {
  late final AnimationController animationController;
  bool isEntered = false;
  AnimationStatus get _animationStatus => animationController.status;

  void _handleMenuOpenRequest(Offset? position, VoidCallback showOverlay) {
    showOverlay();
    if (_animationStatus.isForwardOrCompleted) {
      return;
    }
    animationController.forward();
    setState(() {});
  }

  void _handleMenuCloseRequest(VoidCallback hideOverlay) {
    isEntered = false;
    if (!_animationStatus.isForwardOrCompleted) {
      return;
    }
    animationController.reverse().whenComplete(hideOverlay);
    setState(() {});
  }

  void _handleTrailingFocusChange(bool hasFocus) {
    if (!hasFocus) {
      return;
    }

    if (!isEntered) {
      isEntered = true;
      widget.controller.open();
      primaryFocus?.previousFocus();
      return;
    }

    widget.onTraverseForward.call();
  }

  void _handleLeadingFocusChange(bool hasFocus) {
    if (!hasFocus) {
      return;
    }

    if (!isEntered) {
      isEntered = true;
      widget.controller.open();
      primaryFocus?.nextFocus();
      return;
    }

    widget.onTraverseBackward.call();
  }

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget panel = FadeTransition(
      opacity: animationController,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFFF0F4F9),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.2),
              blurRadius: 6,
              spreadRadius: 2,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: IgnorePointer(
            ignoring: !_animationStatus.isForwardOrCompleted,
            child: _FocusBoundaryHandler(
              onLeadingFocusChange: _handleLeadingFocusChange,
              onTrailingFocusChange: _handleTrailingFocusChange,
              child: Flexible(
                child: Actions(
                  actions: {
                    VerticalMenuPreviousFocusIntent: DoNothingAction(),
                    VerticalMenuNextFocusIntent: DoNothingAction(),
                    NextFocusIntent: NextFocusAction(),
                    PreviousFocusIntent: PreviousFocusAction(),
                  },
                  child: Wrap(
                    runSpacing: 5,
                    spacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: widget.children,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return BaseMenu(
      controller: widget.controller,
      overlayPadding: const EdgeInsets.symmetric(horizontal: 4),
      menuAlignment: AlignmentDirectional.topEnd,
      alignment: AlignmentDirectional.bottomEnd,
      orientation: Axis.horizontal,
      onOpenRequest: _handleMenuOpenRequest,
      onCloseRequest: _handleMenuCloseRequest,
      // onFocusChange: (value) {
      //   if (!value) {
      //     widget.controller.close();
      //   }
      // },
      menu: panel,
      builder: (context, controller, child) {
        return IconButton(
          decoration: _animationStatus.isForwardOrCompleted
              ? WidgetStatePropertyAll(
                  BoxDecoration(
                    color: FloogleColors.selectedButtonBackground,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              : null,
          focusNode: widget.buttonFocusNode,
          onPressed: () {
            if (_animationStatus.isForwardOrCompleted) {
              controller.close();
            } else {
              Actions.invoke(context, const MenuEnterIntent.setFirstFocus());
            }
          },
          child: IconTheme(
            data: IconThemeData(
              color: _animationStatus.isForwardOrCompleted
                  ? FloogleColors.selectedButton
                  : FloogleColors.grey,
              size: 18,
            ),
            child: child!,
          ),
        );
      },
      child: const Icon(Symbols.more_vert, size: 18, opticalSize: 30),
    );
  }
}

class _FocusBoundaryHandler extends StatelessWidget {
  const _FocusBoundaryHandler({
    required this.child,
    required this.onLeadingFocusChange,
    required this.onTrailingFocusChange,
  });
  final Widget child;
  final ValueChanged<bool> onLeadingFocusChange;
  final ValueChanged<bool> onTrailingFocusChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Focus(
          debugLabel: 'START',
          includeSemantics: false,
          onFocusChange: onLeadingFocusChange,
          child: const SizedBox.shrink(),
        ),
        child,
        Focus(
          debugLabel: 'END',
          includeSemantics: false,
          onFocusChange: onTrailingFocusChange,
          child: const SizedBox.shrink(),
        ),
      ],
    );
  }
}
