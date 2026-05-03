import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_state_manager.dart';
import '../../model/intents.dart';
import '../combo_box.dart';
import '../toolbar_icon_button.dart';

class FontSizeMenu extends StatefulWidget {
  const FontSizeMenu({super.key});

  @override
  State<FontSizeMenu> createState() => _FontSizeMenuState();
}

class _FontSizeMenuState extends State<FontSizeMenu> {
  static const List<double> _fontSizes = [8, 9, 10, 11, 12, 14, 18, 24, 30, 36, 48, 60, 72, 96];
  late final List<Widget> fontSizeWidgets;
  final _focusNode = FocusNode();
  final _menuController = MenuController();
  bool _isHovered = false;
  double _selectedFontSize = 14;
  double? _highlightValue;
  int? get highlightIndex => _highlightValue != null ? _fontSizes.indexOf(_highlightValue!) : null;

  @override
  void initState() {
    super.initState();
    fontSizeWidgets = [
      for (final size in _fontSizes) ComboBoxOption(value: size.toStringAsFixed(0)),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fontSize = AppStateManager.selectedTextStyleOf(context)?.textStyle?.fontSize ?? 14;
    if (_selectedFontSize != fontSize) {
      _selectedFontSize = fontSize;
      _highlightValue = fontSize;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleMovePrevious() {
    final int previousIndex;
    if (highlightIndex case final int index) {
      previousIndex = (index - 1) % _fontSizes.length;
    } else {
      previousIndex = _fontSizes.length - 1;
    }
    _emitValue(_fontSizes[previousIndex]);
  }

  void _handleMoveNext() {
    final int nextIndex;
    if (highlightIndex case final int index) {
      nextIndex = (index + 1) % _fontSizes.length;
    } else {
      nextIndex = 0;
    }
    _emitValue(_fontSizes[nextIndex]);
  }

  // ignore: use_setters_to_change_properties
  void _handleHighlight(String? value) {
    if (value == null) {
      _highlightValue = null;
      return;
    }
    _highlightValue = double.parse(value);
  }

  void _handleSelect(String value) {
    _menuController.close();

    final val = double.tryParse(value);
    if (val == null) {
      return;
    }

    _emitValue(ui.clampDouble(val, 1, 96));
  }

  void _emitValue(double fontSize) {
    Actions.invoke(context, FormatFontSizeIntent(fontSize));
  }

  void _handlePointerExit(PointerExitEvent event) {
    setState(() {
      _isHovered = false;
    });
  }

  void _handlePointerEnter(PointerEnterEvent event) {
    setState(() {
      _isHovered = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.text,
      onEnter: _handlePointerEnter,
      onExit: _handlePointerExit,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: _isHovered
              ? const Border.fromBorderSide(BorderSide(color: Color.fromRGBO(25, 25, 25, 1)))
              : const Border.fromBorderSide(BorderSide(color: Color.fromRGBO(116, 119, 117, 1))),
        ),
        child: MergeSemantics(
          child: Semantics(
            label: 'Font Size List',
            value: _selectedFontSize.toString(),
            child: DefaultTextStyle(
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.3),
              child: ComboBox(
                alignment: Alignment.center,
                onTraversePrevious: _handleMovePrevious,
                onTraverseNext: _handleMoveNext,
                onHighlight: _handleHighlight,
                menuController: _menuController,
                onSelect: _handleSelect,
                selected: _selectedFontSize.toStringAsFixed(0),
                focusNode: _focusNode,
                inputConstraints: const BoxConstraints(
                  minWidth: 26,
                  maxWidth: 26,
                  minHeight: 24,
                  maxHeight: 24,
                ),
                children: fontSizeWidgets,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DecrementFontSizeButton extends StatelessWidget {
  const DecrementFontSizeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolbarIconButton(
      constraints: const BoxConstraints.tightFor(width: 24, height: 24),
      shortcut: const SingleActivator(LogicalKeyboardKey.comma, meta: true, shift: true),
      onPressed: () {
        Actions.invoke(context, const FormatDecrementFontSizeIntent());
      },
      child: const Icon(Symbols.remove, size: 16, opticalSize: 24),
    );
  }
}

class IncrementFontSizeButton extends StatelessWidget {
  const IncrementFontSizeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolbarIconButton(
      constraints: const BoxConstraints.tightFor(width: 24, height: 24),
      shortcut: const SingleActivator(LogicalKeyboardKey.period, meta: true, shift: true),
      onPressed: () {
        Actions.invoke(context, const FormatIncrementFontSizeIntent());
      },
      child: const Icon(Symbols.add, size: 16, opticalSize: 24),
    );
  }
}
