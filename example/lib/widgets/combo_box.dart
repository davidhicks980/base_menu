import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../utilities/colors.dart';
import 'editable.dart';
import 'menu_action_label.dart';
import 'menu_panel.dart';

class _MovePreviousIntent extends Intent {
  const _MovePreviousIntent();
}

class _MoveNextIntent extends Intent {
  const _MoveNextIntent();
}

class _MoveFirstIntent extends Intent {
  const _MoveFirstIntent();
}

class _MoveLastIntent extends Intent {
  const _MoveLastIntent();
}

class _ComboBoxHighlight extends InheritedWidget {
  const _ComboBoxHighlight({
    required super.child,
    required this.highlight,
    required this.value,
    required this.state,
    required this.alignment,
  });

  final _ComboBoxBehavior state;
  final Alignment alignment;
  final String? highlight;
  final String value;

  static String valueOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ComboBoxHighlight>()!.value;
  }

  static String? highlightedValueOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ComboBoxHighlight>()!.highlight;
  }

  static Alignment alignmentOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ComboBoxHighlight>()!.alignment;
  }

  static _ComboBoxBehavior stateOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_ComboBoxHighlight>()!.state;
  }

  @override
  bool updateShouldNotify(_ComboBoxHighlight oldWidget) {
    return highlight != oldWidget.highlight ||
        state != oldWidget.state ||
        alignment != oldWidget.alignment ||
        value != oldWidget.value;
  }
}

class ComboBoxOption extends StatefulWidget {
  const ComboBoxOption({
    super.key,
    required this.value,
    required this.index,
    this.constraints = const BoxConstraints(minHeight: 30, maxHeight: 30),
  });
  final String value;
  final int index;
  final BoxConstraints constraints;

  @override
  State<ComboBoxOption> createState() => _ComboBoxOptionState();
}

class _ComboBoxOptionState extends State<ComboBoxOption> {
  _ComboBoxBehavior? state;
  bool _isSelected = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newState = _ComboBoxHighlight.stateOf(context);
    if (state != newState) {
      state?.unregister(widget.index);
      state = newState;
      state?.register(widget.index, widget.value);
    }
  }

  @override
  void dispose() {
    state?.unregister(widget.index);
    super.dispose();
  }

  void showOnScreen() {
    final renderObject = context.findRenderObject();
    if (renderObject != null) {
      renderObject.showOnScreen();
    }
  }

  void _handleSelect() {
    state?.select(widget.value);
    MenuController.maybeOf(context)?.close();
  }

  void _handlePointerLeave(PointerExitEvent event) {
    state!.removeHighlight(widget.value);
  }

  void _handlePointerEnter(PointerHoverEvent event) {
    state!.highlight(widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Align(
        alignment: _ComboBoxHighlight.alignmentOf(context),
        child: Text(widget.value, style: MenuActionLabel.labelTextStyle),
      ),
    );
    // This should be a SemanticsRole.option, but this is currently not
    // supported by Flutter's semantics system.
    final body = BaseMenuItem(
      requestFocusOnHover: false,
      onPointerEnter: _handlePointerEnter,
      onPointerLeave: _handlePointerLeave,
      onTap: _handleSelect,
      child: ConstrainedBox(
        constraints: widget.constraints,
        child: Builder(
          builder: (context) {
            final highlightedValue = _ComboBoxHighlight.highlightedValueOf(context);
            return ColoredBox(
              color: highlightedValue == widget.value
                  ? const Color(0xFFf2f2f2)
                  : FloogleColors.transparent,
              child: child,
            );
          },
        ),
      ),
    );
    return Builder(
      builder: (context) {
        final isSelected = _ComboBoxHighlight.valueOf(context) == widget.value;
        if (_isSelected != isSelected) {
          _isSelected = isSelected;
          if (_isSelected) {
            showOnScreen();
          }
        }

        return Semantics.fromProperties(
          properties: SemanticsProperties(
            selected: isSelected,
            inMutuallyExclusiveGroup: true,
            onTap: _handleSelect,
            enabled: true,
            label: widget.value,
            textDirection: Directionality.of(context),
          ),
          child: ExcludeSemantics(child: body),
        );
      },
    );
  }
}

abstract interface class _ComboBoxBehavior {
  void highlight(String value);
  void removeHighlight(String value);
  void select(String value);
  void register(int key, String value);
  void unregister(int value);
}

class ComboBox extends StatefulWidget {
  const ComboBox({
    super.key,
    required this.children,
    this.onSelect,
    this.onSubmit,
    this.trailing,
    this.inputConstraints = const BoxConstraints(minHeight: 28, maxHeight: 28),
    required this.selected,
    this.focusNode,
    this.textStyle = const TextStyle(
      fontFamily: 'GoogleSans',
      fontSize: 14,
      color: FloogleColors.grey,
      decoration: TextDecoration.none,
      fontWeight: kIsWeb ? FontWeight.w500 : FontWeight.w400,
    ),
    required this.menuController,
    this.alignment = AlignmentDirectional.centerStart,
    this.initialOffset = 0,
    this.semanticsLabel = 'Combo Box',
  });

  final List<Widget> children;
  final ValueChanged<String>? onSelect;
  final ValueChanged<String>? onSubmit;
  final String selected;
  final Widget? trailing;
  final BoxConstraints inputConstraints;
  final FocusNode? focusNode;
  final MenuController menuController;
  final TextStyle textStyle;
  final AlignmentGeometry alignment;
  final double initialOffset;

  final String semanticsLabel;

  @override
  State<ComboBox> createState() => _ComboBoxState();
}

class _ComboBoxState extends State<ComboBox> implements _ComboBoxBehavior {
  FocusNode? _internalFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;
  String? _highlightValue;
  late final actions = {
    _MoveNextIntent: CallbackAction<_MoveNextIntent>(onInvoke: _handleMoveNext),
    _MovePreviousIntent: CallbackAction<_MovePreviousIntent>(onInvoke: _handleMovePrevious),
    _MoveFirstIntent: CallbackAction<_MoveFirstIntent>(onInvoke: _handleMoveFirst),
    _MoveLastIntent: CallbackAction<_MoveLastIntent>(onInvoke: _handleMoveLast),
  };

  late ScrollController _scrollController;
  late final TextEditingController _textController;
  final SplayTreeMap<int, String> _indexToValue = SplayTreeMap<int, String>();

  @override
  void register(int key, String value) {
    _indexToValue[key] = value;
  }

  @override
  void unregister(int key) {
    _indexToValue.remove(key);
  }

  @override
  void highlight(String value) {
    if (_highlightValue == value) {
      return;
    }
    setState(() {
      _highlightValue = value;
    });
  }

  @override
  void removeHighlight(String value) {
    if (_highlightValue != value) {
      return;
    }
    setState(() {
      _highlightValue = null;
    });
  }

  @override
  void select(String value) {
    widget.onSelect?.call(value);
  }

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.selected);
    _highlightValue = widget.selected;
    _scrollController = ScrollController(initialScrollOffset: widget.initialOffset);
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }
  }

  @override
  void didUpdateWidget(ComboBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    _textController.text = widget.selected;
    _highlightValue = widget.selected;
    if (oldWidget.focusNode != widget.focusNode) {
      if (widget.focusNode == null) {
        _internalFocusNode = FocusNode();
      } else {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _openMenuAndFocusButton() {
    if (!widget.menuController.isOpen) {
      widget.menuController.open();
      if (!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    }
  }

  void _traversalSelect(int index) {
    final newValue = _indexToValue[index]!;
    SemanticsService.announce(newValue, Directionality.of(context));
    widget.onSelect?.call(newValue);
  }

  void _handleMovePrevious(_MovePreviousIntent intent) {
    if (!widget.menuController.isOpen) {
      _openMenuAndFocusButton();
      return;
    }
    final int previousIndex;
    final keys = _indexToValue.keys.toList();
    if (_highlightValue != null) {
      final int index = keys.indexWhere((i) => _indexToValue[i] == _highlightValue);
      previousIndex = (index - 1) % keys.length;
    } else {
      previousIndex = keys.length - 1;
    }

    _traversalSelect(keys[previousIndex]);
  }

  void _handleMoveNext(_MoveNextIntent intent) {
    if (!widget.menuController.isOpen) {
      _openMenuAndFocusButton();
      return;
    }
    final int nextIndex;
    final keys = _indexToValue.keys.toList();
    if (_highlightValue != null) {
      final int index = keys.indexWhere((i) => _indexToValue[i] == _highlightValue);
      nextIndex = (index + 1) % keys.length;
    } else {
      nextIndex = 0;
    }

    _traversalSelect(keys[nextIndex]);
  }

  void _handleMoveFirst(_MoveFirstIntent intent) {
    if (_indexToValue.isEmpty) {
      return;
    }

    _traversalSelect(_indexToValue.firstKey()!);
  }

  void _handleMoveLast(_MoveLastIntent intent) {
    if (!widget.menuController.isOpen) {
      _openMenuAndFocusButton();
      return;
    }

    if (_indexToValue.isEmpty) {
      return;
    }

    _traversalSelect(_indexToValue.lastKey()!);
  }

  @override
  Widget build(BuildContext context) {
    final alignment = widget.alignment.resolve(Directionality.of(context));
    return Actions(
      actions: actions,
      child: BaseMenu(
        menuAlignment: Alignment(alignment.x, -1),
        alignment: Alignment(alignment.x, 1),
        controller: widget.menuController,
        padding: MenuPanel.defaultPadding,
        alignmentOffset: const Offset(0, 7),
        panel: _ComboBoxHighlight(
          value: widget.selected,
          highlight: _highlightValue,
          alignment: alignment,
          state: this,
          child: PrimaryScrollController(
            controller: _scrollController,
            automaticallyInheritForPlatforms: const {
              TargetPlatform.macOS,
              TargetPlatform.windows,
              TargetPlatform.linux,
              TargetPlatform.fuchsia,
              TargetPlatform.android,
              TargetPlatform.iOS,
            },
            child: MenuPanel(children: widget.children),
          ),
        ),
        builder: (BuildContext context, MenuController controller, Widget? child) {
          return _Anchor(
            focusNode: _focusNode,
            textController: _textController,
            constraints: widget.inputConstraints,
            menuController: controller,
            trailing: widget.trailing,
            onSubmit: widget.onSubmit,
            selected: widget.selected,
            textStyle: widget.textStyle,
            semanticsLabel: widget.semanticsLabel,
          );
        },
      ),
    );
  }
}

class _Anchor extends StatelessWidget {
  const _Anchor({
    required this.focusNode,
    required this.textController,
    required this.constraints,
    required this.menuController,
    this.trailing,
    this.onSubmit,
    required this.textStyle,
    required this.selected,
    required this.semanticsLabel,
  });
  final FocusNode focusNode;
  final TextEditingController textController;
  final MenuController menuController;
  final BoxConstraints constraints;
  final Widget? trailing;
  final ValueChanged<String>? onSubmit;
  final String selected;
  final String semanticsLabel;
  final TextStyle textStyle;

  static const _shortcuts = {
    SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp): _MovePreviousIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown): _MoveNextIntent(),
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

  static const _shortcutsWhenOpen = {
    ..._shortcuts,
    SingleActivator(LogicalKeyboardKey.home): _MoveFirstIntent(),
    SingleActivator(LogicalKeyboardKey.end): _MoveLastIntent(),
  };

  @override
  Widget build(BuildContext context) {
    final isOpen = MenuController.maybeIsOpenOf(context) ?? false;
    final defaultTextStyle = DefaultTextStyle.of(context).style;
    Widget field = isOpen
        ? Editable(
            autofocus: true,
            focusNode: focusNode,
            controller: textController,
            textAlign: TextAlign.center,
            textInputAction: TextInputAction.done,
            onSubmitted: onSubmit,
            blurredSelectionColor: FloogleColors.transparent,
            style: defaultTextStyle.copyWith(
              color: FloogleColors.darkGray,
              decoration: TextDecoration.none,
              fontWeight: const FontWeight(450),
            ),
            selectionColor: const Color.fromRGBO(211, 227, 253, 1),
          )
        : Padding(
            padding: const EdgeInsets.only(right: 3),
            child: ExcludeSemantics(child: Text(selected, style: defaultTextStyle)),
          );

    field = Padding(
      padding: const EdgeInsetsDirectional.only(start: 3),
      child: Center(child: field),
    );

    if (trailing != null) {
      field = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [field, trailing!],
      );
    }

    field = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: isOpen
            ? Border.all(color: const Color.fromARGB(255, 10, 86, 207), width: 2)
            : Border.all(color: FloogleColors.transparent, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ConstrainedBox(constraints: constraints, child: field),
      ),
    );

    Widget listenable;
    if (!isOpen) {
      listenable = BaseControl(
        child: Builder(
          builder: (context) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: BaseControl.isFocusedOf(context) ? const Color.fromARGB(15, 0, 0, 0) : null,
                borderRadius: BorderRadius.circular(4),
              ),
              child: field,
            );
          },
        ),
        onTap: () {
          menuController.open();
          focusNode.requestFocus();
        },
      );
    } else {
      listenable = GestureDetector(
        excludeFromSemantics: true,
        onTap: () {
          menuController.close();
        },
        behavior: HitTestBehavior.opaque,
        child: field,
      );
    }

    return ListenableBuilder(
      listenable: focusNode,
      child: Shortcuts(
        shortcuts: isOpen ? _shortcutsWhenOpen : _shortcuts,
        child: DefaultTextStyle.merge(
          style: textStyle,
          overflow: TextOverflow.ellipsis,
          child: listenable,
        ),
      ),
      builder: (context, child) {
        return Semantics.fromProperties(
          properties: SemanticsProperties(
            focusable: true,
            focused: focusNode.hasFocus,
            expanded: isOpen,
            button: !isOpen,
            textField: isOpen,
            readOnly: !isOpen,
            hint: defaultTargetPlatform == TargetPlatform.iOS
                ? isOpen
                      ? 'Collapse'
                      : 'Expand'
                : null,
            onExpand: isOpen ? null : () => menuController.open(),
            onCollapse: isOpen ? () => menuController.close() : null,
            textDirection: Directionality.of(context),
            label: semanticsLabel,
            onTap: () {
              if (isOpen) {
                menuController.close();
              } else {
                menuController.open();
                focusNode.requestFocus();
              }
            },
          ),
          child: child,
        );
      },
    );
  }
}
