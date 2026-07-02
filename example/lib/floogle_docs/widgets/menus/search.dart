import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../../data/entry.dart';
import '../../data/menu.dart';
import '../../model/model.dart';
import '../../utilities/colors.dart';
import '../adapters/menu_entry_toolbar_button.dart';
import '../app_state_manager.dart';
import '../editable.dart';
import '../menu_action_label.dart';

const defaultStyle = TextStyle(
  fontFamily: 'RobotoFlex',
  fontSize: kIsWeb ? 13 : 14,
  color: placeholderColor,
  height: 1.2,
  letterSpacing: 0.4,
  fontVariations: kIsWeb ? [FontVariation.weight(400)] : [FontVariation.weight(300)],
);

class _TraversePreviousIntent extends Intent {
  const _TraversePreviousIntent();
}

class _TraverseNextIntent extends Intent {
  const _TraverseNextIntent();
}

const _shortcuts = {
  SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.arrowUp): _TraversePreviousIntent(),
  SingleActivator(LogicalKeyboardKey.arrowDown): _TraverseNextIntent(),
  SingleActivator(LogicalKeyboardKey.arrowLeft): ExtendSelectionByCharacterIntent(
    forward: false,
    collapseSelection: true,
  ),
  SingleActivator(LogicalKeyboardKey.arrowRight): ExtendSelectionByCharacterIntent(
    forward: true,
    collapseSelection: true,
  ),
  SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): ExtendSelectionByCharacterIntent(
    forward: false,
    collapseSelection: false,
  ),
  SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): ExtendSelectionByCharacterIntent(
    forward: true,
    collapseSelection: false,
  ),
};

const textColor = Color(0xFF1f1f1f);
const placeholderColor = Color.fromARGB(255, 69, 71, 70);

class SearchMenu extends StatelessWidget {
  const SearchMenu({super.key, required this.breakpoint});
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return _SearchMenuPopup(
      child: Builder(
        builder: (context) {
          return MediaQuery.widthOf(context) < breakpoint
              ? const Padding(
                  padding: EdgeInsetsDirectional.only(start: 4, end: 2),
                  child: MenuEntryToolbarButton(item: Entry.searchMenus),
                )
              : BaseControl(
                  mouseCursor: WidgetStateMouseCursor.textable,
                  onPressed: () {
                    MenuController.maybeOf(context)?.open();
                  },
                  child: const Padding(
                    padding: EdgeInsetsDirectional.only(start: 1),
                    child: SizedBox(
                      width: 100,
                      height: 28,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          color: FloogleColors.white,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 36,
                              child: Center(
                                child: Icon(Symbols.search, size: 18, color: placeholderColor),
                              ),
                            ),
                            Expanded(child: Text('Menus', style: defaultStyle)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
        },
      ),
    );
  }
}

class _SearchMenuPopup extends StatefulWidget {
  const _SearchMenuPopup({required this.child});
  final Widget child;

  @override
  State<_SearchMenuPopup> createState() => _SearchMenuPopupState();
}

class _SearchMenuPopupState extends State<_SearchMenuPopup> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<MenuEntryWithIntent> _searchResults = [];
  Iterable<MenuEntryWithIntent> _allEntries = [];
  int selectedIndex = 0;
  final List<MenuEntryWithIntent> _selectionHistory = [
    Entry.pageSetup,
    Entry.accessibility,
    Entry.findInDocument,
  ];

  late final Map<Type, Action<Intent>> _editorActions = {
    _TraversePreviousIntent: CallbackAction<_TraversePreviousIntent>(onInvoke: _handleMoveUp),
    _TraverseNextIntent: CallbackAction<_TraverseNextIntent>(onInvoke: _handleMoveDown),
    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _handleActivate),
  };
  late MenuController menuController;

  @override
  void initState() {
    super.initState();
    _allEntries = _extractEntries(Menu.main.children);
    _textController.addListener(_handleTextChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    menuController = AppStateManager.searchMenuControllerOf(context);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<MenuEntryWithIntent> _extractEntries(List<BaseMenuEntry> entries) {
    final List<MenuEntryWithIntent> result = [];
    for (final entry in entries) {
      switch (entry) {
        case final MenuEntryWithIntent item:
          result.add(item);
        case SubmenuEntry<BaseMenuEntry>(:final List<BaseMenuEntry> children):
        case TileGroupMenuEntry(:final List<BaseMenuEntry> children):
          result.addAll(_extractEntries(children));
        case MenuEntry():
        case SeparatorMenuEntry():
          continue;
      }
    }
    return result;
  }

  void _handleTextChange() {
    final String query = _textController.text;
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    _query = query.toLowerCase();
    final newSearchResults = _filterEntries();
    setState(() {
      _searchResults = newSearchResults.toList();
    });

    if (!menuController.isOpen) {
      menuController.open();
    }
  }

  Iterable<MenuEntryWithIntent> _filterEntries() {
    final Set<MenuEntryWithIntent> entries = _allEntries
        .where((entry) => entry.label.toLowerCase().startsWith(_query))
        .toSet();

    if (entries.length >= 8) {
      return entries;
    }

    for (final entry in _allEntries) {
      if (entries.contains(entry)) {
        continue;
      }

      if (entry.label.toLowerCase().contains(_query)) {
        entries.add(entry);
        if (entries.length >= 8) {
          return entries;
        }
      }
    }

    return entries;
  }

  void _selectEntry(MenuEntryWithIntent entry) {
    menuController.close();
    _selectionHistory.remove(entry);
    if (_selectionHistory.length >= 5) {
      _selectionHistory.removeLast();
    }

    _selectionHistory.insert(0, entry);
    Actions.maybeInvoke(context, entry.intent);
  }

  List<MenuEntryWithIntent> get entries {
    return _searchResults.isNotEmpty ? _searchResults : _selectionHistory;
  }

  String _query = '';

  void _handleMoveUp(_TraversePreviousIntent intent) {
    if (!menuController.isOpen) {
      menuController.open();
    }
    final currentIndex = (selectedIndex - 1) % entries.length;
    setState(() {
      selectedIndex = currentIndex;
    });
  }

  void _handleMoveDown(_TraverseNextIntent intent) {
    if (!menuController.isOpen) {
      menuController.open();
      if (!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    }
    final currentIndex = (selectedIndex + 1) % entries.length;
    setState(() {
      selectedIndex = currentIndex;
    });
  }

  void _handleActivate(ActivateIntent intent) {
    if (entries.isNotEmpty && selectedIndex < entries.length) {
      _selectEntry(entries[selectedIndex]);
    }
  }

  void _handleClose() {
    setState(() {
      menuController.close();
      _textController.clear();
      selectedIndex = 0;
      _searchResults.clear();
      _query = '';
    });
  }

  void _handleFocusChange(bool focused) {
    if (!focused) {
      menuController.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseMenu(
      controller: menuController,
      positionDelegate: const DefaultMenuPositioningDelegate(
        overlayPadding: .zero,
        anchorAlignment: .topStart,
        menuAlignment: .topStart,
      ),
      onClose: _handleClose,
      onFocusChange: _handleFocusChange,
      menu: BaseMenuPanel(
        constraints: const BoxConstraints(minWidth: 348),
        orientation: Axis.vertical,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              color: FloogleColors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border.fromBorderSide(BorderSide(color: FloogleColors.white)),
            ),

            child: SizedBox(
              height: 28,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 36,
                    child: Align(child: Icon(Symbols.search, size: 18, color: placeholderColor)),
                  ),
                  Flexible(
                    child: _InlineLabelWrapper(
                      hint: Text(
                        'Menus (Option+/)',
                        style: defaultStyle.copyWith(color: placeholderColor),
                      ),
                      controller: _textController,
                      child: Shortcuts(
                        shortcuts: _shortcuts,
                        child: Actions(
                          actions: _editorActions,
                          child: Editable(
                            autofocus: true,
                            cursorHeight: 14,
                            cursorWidth: 1,
                            forceLine: true,
                            textController: _textController,
                            focusNode: _focusNode,
                            textInputAction: TextInputAction.go,
                            style: defaultStyle.copyWith(color: textColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(bottom: 6, top: 6),
            decoration: const BoxDecoration(
              color: FloogleColors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              border: Border.fromBorderSide(BorderSide(color: FloogleColors.white)),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.28),
                  blurRadius: 6,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                for (var i = 0; i < entries.length; i++)
                  _SearchEntry(
                    key: ValueKey(entries[i]),
                    entry: entries[i],
                    query: _textController.text,
                    onPressed: () => _selectEntry(entries[i]),
                    onEntered: (_) {
                      setState(() {
                        selectedIndex = i;
                      });
                    },
                    selected: i == selectedIndex,
                  ),
              ],
            ),
          ),
        ],
      ),
      child: widget.child,
    );
  }
}

class _QueryLabel extends StatelessWidget {
  const _QueryLabel({required this.label, required this.query});
  final String label;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(label);
    }

    final lowerLabel = label.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matchIndex = lowerLabel.indexOf(lowerQuery);

    if (matchIndex == -1) {
      return Text(label);
    }

    final before = label.substring(0, matchIndex);
    final match = label.substring(matchIndex, matchIndex + query.length);
    final after = label.substring(matchIndex + query.length);

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          if (before.isNotEmpty) TextSpan(text: before),
          TextSpan(
            text: match,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontVariations: [FontVariation.weight(500)],
            ),
          ),
          if (after.isNotEmpty) TextSpan(text: after),
        ],
      ),
    );
  }
}

class _InlineLabelWrapper extends StatelessWidget {
  const _InlineLabelWrapper({required this.child, required this.controller, required this.hint});

  final Widget child;
  final TextEditingController controller;

  final Widget hint;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.centerStart,
      children: [
        child,
        ListenableBuilder(
          listenable: controller,
          builder: (context, child) {
            if (controller.text.isNotEmpty) {
              return const SizedBox.shrink();
            }
            return IgnorePointer(child: hint);
          },
        ),
      ],
    );
  }
}

class _SearchEntry extends StatelessWidget {
  const _SearchEntry({
    super.key,
    required this.entry,
    required this.query,
    required this.onPressed,
    required this.onEntered,
    required this.selected,
  });
  final MenuEntryWithIntent entry;
  final String query;
  final VoidCallback onPressed;
  final PointerEnterEventListener? onEntered;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Semantics(
          selected: selected,
          child: BaseMenuItem(
            onPressed: onPressed,
            onPointerEnter: onEntered,
            requestFocusOnHover: false,
            child: MenuActionLabel(
              decoration: selected
                  ? const WidgetStatePropertyAll(
                      BoxDecoration(
                        color: Color.from(alpha: 1, red: 0.929726, blue: 0.929726, green: 0.929726),
                      ),
                    )
                  : null,
              shortcut: entry.shortcut,
              leading: entry.icon != null
                  ? Icon(entry.icon, size: 18, color: placeholderColor)
                  : null,
              leadingWidth: 32,
              leadingMidpointAlignment: const AlignmentDirectional(0.05, 0),
              child: DefaultTextStyle.merge(
                style: const TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  letterSpacing: 0.2,
                  fontFamily: 'RobotoFlex',
                  color: textColor,
                  fontVariations: kIsWeb
                      ? [FontVariation.weight(450)]
                      : [FontVariation.weight(350)],
                ),
                child: _QueryLabel(label: entry.label, query: query),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
