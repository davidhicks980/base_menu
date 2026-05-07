import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../../app_state_manager.dart';
import '../../model/intents.dart';
import '../adapters/menu_entry_toolbar_button.dart';
import '../combo_box.dart';

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
  double _selectedFontSize = 14;
  double? _highlightValue;
  int? get highlightIndex => _highlightValue != null ? _fontSizes.indexOf(_highlightValue!) : null;

  @override
  void initState() {
    super.initState();
    fontSizeWidgets = [
      for (var i = 0; i < _fontSizes.length; i++)
        ComboBoxOption(index: i, value: _fontSizes[i].toStringAsFixed(0)),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fontSize = AppStateManager.selectedTextStyleOf(context)?.textStyle?.fontSize;
    if (_selectedFontSize != fontSize) {
      _selectedFontSize = fontSize ?? _selectedFontSize;
      _highlightValue = _selectedFontSize;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _emitValue(double fontSize) {
    assert(fontSize >= _fontSizes.first && fontSize <= _fontSizes.last);
    Actions.invoke(context, FormatFontSizeIntent(fontSize));
  }

  void _handleSubmit(String value) {
    final val = double.tryParse(value);
    if (val == null) {
      _focusNode.requestFocus();

      return;
    }

    _emitValue(ui.clampDouble(val, _fontSizes.first, _fontSizes.last));
    _menuController.close();
  }

  void _handleHover(PointerHoverEvent event) {
    if (MenuController.maybeIsOpenOf(context) != true && Focus.of(context).hasFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = MergeSemantics(
      child: DefaultTextStyle(
        textAlign: TextAlign.center,
        style: const TextStyle(height: 1.3),
        child: ComboBox(
          semanticsLabel: 'Font Size',
          alignment: Alignment.center,
          menuController: _menuController,
          onSelect: (value) => _emitValue(double.parse(value)),
          onSubmit: _handleSubmit,
          focusNode: _focusNode,
          inputConstraints: const BoxConstraints(
            minWidth: 26,
            maxWidth: 26,
            minHeight: 24,
            maxHeight: 24,
          ),
          initialOffset: _fontSizes.indexOf(_selectedFontSize) * 30.0,
          selected: _selectedFontSize.toStringAsFixed(0),
          children: fontSizeWidgets,
        ),
      ),
    );
    return Hoverable(
      onEnter: _handleHover,
      mouseCursor: WidgetStateMouseCursor.textable,
      child: Builder(
        builder: (context) {
          return DecoratedBox(
            decoration: Hoverable.isHoveredOf(context) && !FocusScope.of(context).hasFocus
                ? _outlineHovered
                : _outline,
            child: child,
          );
        },
      ),
    );
  }

  static const _outlineHovered = BoxDecoration(
    border: Border.fromBorderSide(BorderSide(color: Color.fromRGBO(25, 25, 25, 1))),
    borderRadius: BorderRadius.all(Radius.circular(4)),
  );

  static const _outline = BoxDecoration(
    border: Border.fromBorderSide(BorderSide(color: Color.fromRGBO(116, 119, 117, 1))),
    borderRadius: BorderRadius.all(Radius.circular(4)),
  );
}

class DecrementFontSizeButton extends StatelessWidget {
  const DecrementFontSizeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolbarIconButton(
      constraints: const BoxConstraints.tightFor(width: 24, height: 24),
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
      onPressed: () {
        Actions.invoke(context, const FormatIncrementFontSizeIntent());
      },
      child: const Icon(Symbols.add, size: 16, opticalSize: 24),
    );
  }
}
