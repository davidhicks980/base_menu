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
  static const List<double> _fontSizes = [8, 9, 10, 11, 12, 14, 18, 24, 30, 36, 48];

  double nearestFontSize(double fontSize) {
    double closest = _fontSizes.first;
    for (final size in _fontSizes) {
      if ((size - fontSize).abs() < (closest - fontSize).abs()) {
        closest = size;
      }
    }
    return closest;
  }

  late final _actions = {
    ComboBoxTraversePreviousIntent: CallbackAction<ComboBoxTraversePreviousIntent>(
      onInvoke: _handleMoveUp,
    ),
    ComboBoxTraverseNextIntent: CallbackAction<ComboBoxTraverseNextIntent>(
      onInvoke: _handleMoveDown,
    ),
  };

  final _focusNode = FocusNode();
  final _menuController = MenuController();
  bool _isHovered = false;
  late double _selectedFontSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedFontSize = AppStateManager.selectedTextStyleOf(context)?.textStyle?.fontSize ?? 14;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _emitFontSizeChange(double value) {
    if (value == _selectedFontSize) {
      return;
    }

    Actions.invoke(context, FormatFontSizeIntent(value));
  }

  void _handleMoveDown(ComboBoxTraverseNextIntent intent) {
    if (!_menuController.isOpen) {
      _menuController.open();
      if (!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    }
    int currentIndex = _fontSizes.indexOf(nearestFontSize(_selectedFontSize));
    currentIndex = (currentIndex + 1) % _fontSizes.length;
    _emitFontSizeChange(_fontSizes[currentIndex]);
  }

  void _handleMoveUp(ComboBoxTraversePreviousIntent intent) {
    if (!_menuController.isOpen) {
      _menuController.open();
      if (!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    }
    int currentIndex = _fontSizes.indexOf(nearestFontSize(_selectedFontSize));
    currentIndex = (currentIndex - 1) % _fontSizes.length;
    _emitFontSizeChange(_fontSizes[currentIndex]);
  }

  void _handleSelect(String value) {
    _emitFontSizeChange(double.parse(value));
    _menuController.close();
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
      child: Actions(
        actions: _actions,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: _isHovered
                ? const Border.fromBorderSide(
                    BorderSide(color: Color.from(alpha: 1, red: 0.098, green: 0.098, blue: 0.098)),
                  )
                : const Border.fromBorderSide(
                    BorderSide(color: Color.from(alpha: 1, red: 0.455, green: 0.467, blue: 0.459)),
                  ),
          ),
          child: MergeSemantics(
            child: Semantics(
              label: 'Font Size List',
              value: _selectedFontSize.toString(),
              child: DefaultTextStyle(
                textAlign: TextAlign.center,
                style: const TextStyle(height: 1.3),
                child: ComboBox(
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
                  children: [
                    for (final size in _fontSizes)
                      ComboBoxOption(
                        value: size.toStringAsFixed(0),
                        onPressed: () {
                          _emitFontSizeChange(size);
                          _menuController.close();
                        },
                      ),
                  ],
                ),
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
