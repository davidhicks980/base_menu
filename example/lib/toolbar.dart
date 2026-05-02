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
import 'widgets/toolbar_icon_button.dart';

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

class Toolbar extends StatefulWidget {
  const Toolbar({super.key});

  @override
  State<Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends State<Toolbar> {
  final MenuController overflowController = MenuController();
  final MenuController menuController = MenuController();
  int _cutoff = children.length;
  final scopeNode = FocusScopeNode(traversalEdgeBehavior: TraversalEdgeBehavior.stop);

  @override
  void dispose() {
    scopeNode.dispose();
    super.dispose();
  }

  Widget _buildConditionalTraversal(BuildContext context, Widget? child) {
    return Focus(
      includeSemantics: false,
      canRequestFocus: false,
      skipTraversal: !scopeNode.hasFocus,
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
            child: ListenableBuilder(
              listenable: scopeNode,
              builder: _buildConditionalTraversal,
              child: CoreMenuBar(
                controller: menuController,
                focusScopeNode: scopeNode,
                child: Row(
                  children: [
                    Flexible(
                      child: OverflowRow(
                        onOverflow: (int cutoffIndex) {
                          _cutoff = cutoffIndex;
                          SchedulerBinding.instance.addPostFrameCallback((timestamp) {
                            if (mounted) {
                              setState(() {});
                            }
                          });
                        },
                        children: children,
                      ),
                    ),
                    if (cutoffChildren.isNotEmpty)
                      OverflowButton(
                        controller: overflowController,
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
          ToolbarIconButton(
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
  const OverflowButton({super.key, required this.children, required this.controller});
  final List<Widget> children;
  final MenuController controller;

  @override
  State<OverflowButton> createState() => _OverflowButtonState();
}

class _OverflowButtonState extends State<OverflowButton> with SingleTickerProviderStateMixin {
  late final FocusNode focusNode = FocusNode();
  late final AnimationController animationController;
  AnimationStatus get _animationStatus => animationController.status;
  // Key and lock for keeping the panel size while closing

  void _handleMenuOpenRequest(Offset? position, VoidCallback showOverlay) {
    // Mount or reposition the menu before animating the menu open.
    showOverlay();

    if (_animationStatus.isForwardOrCompleted) {
      // If the menu is already open or opening, the animation is already
      // running forward.
      return;
    }

    // Animate the menu into view.
    animationController.forward();
  }

  void _handleMenuCloseRequest(VoidCallback hideOverlay) {
    if (!_animationStatus.isForwardOrCompleted) {
      // If the menu is already closed or closing, do nothing.
      return;
    }

    // Animate the menu out of view.
    animationController.reverse().whenComplete(hideOverlay);
  }

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      if (focusNode.hasPrimaryFocus && widget.controller.isOpen) {
        widget.controller.close();
      }
    });
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    focusNode.dispose();
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
            BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.2), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Wrap(
            runSpacing: 5,
            spacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: widget.children,
          ),
        ),
      ),
    );

    return CoreMenu(
      controller: widget.controller,
      overlayPadding: const EdgeInsets.symmetric(horizontal: 4),
      menuAlignment: AlignmentDirectional.topEnd,
      alignment: AlignmentDirectional.bottomEnd,
      axis: Axis.horizontal,
      onOpenRequest: _handleMenuOpenRequest,
      onCloseRequest: _handleMenuCloseRequest,
      panel: panel,
      child: ToolbarIconButton(
        focusNode: focusNode,
        requestCloseOnActivate: false,
        onPressed: () {
          if (widget.controller.isOpen) {
            widget.controller.close();
          } else {
            widget.controller.open();
            focusNode.requestFocus();
          }
        },
        child: const Icon(Symbols.more_vert, size: 18, opticalSize: 30),
      ),
    );
  }
}
