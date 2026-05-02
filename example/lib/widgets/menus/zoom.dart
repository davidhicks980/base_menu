import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../../utilities/colors.dart';
import '../combo_box.dart';
import '../dropdown_arrow.dart';
import '../menu_divider.dart';

class ZoomMenu extends StatefulWidget {
  const ZoomMenu({super.key});

  @override
  State<ZoomMenu> createState() => _ZoomMenuState();
}

class _ZoomMenuState extends State<ZoomMenu> {
  static const zoomLevels = ['Fit', '50%', '75%', '90%', '100%', '125%', '150%', '200%'];
  final _focusNode = FocusNode();
  final _menuController = MenuController();
  late final _actions = {
    ComboBoxTraversePreviousIntent: CallbackAction<ComboBoxTraversePreviousIntent>(
      onInvoke: _handleMoveUp,
    ),

    ComboBoxTraverseNextIntent: CallbackAction<ComboBoxTraverseNextIntent>(
      onInvoke: _handleMoveDown,
    ),
  };

  bool _isHovered = false;
  String _selectedZoom = '100%';
  late List<Widget> zoomWidgets;

  @override
  void initState() {
    super.initState();
    zoomWidgets = [
      ComboBoxOption(
        value: zoomLevels.first,
        onPressed: () {
          setState(() {
            _selectedZoom = zoomLevels.first;
          });
          _menuController.close();
        },
      ),
      const MenuDivider(padding: EdgeInsets.only(left: 16)),
      for (var i = 1; i < zoomLevels.length; i++)
        ComboBoxOption(
          value: zoomLevels[i],
          onPressed: () {
            setState(() {
              _selectedZoom = zoomLevels[i];
            });
            _menuController.close();
          },
        ),
    ];
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Object? _handleMoveUp(ComboBoxTraversePreviousIntent intent) {
    if (!_menuController.isOpen) {
      _menuController.open();
      if (!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    }
    final currentIndex = (zoomLevels.indexOf(_selectedZoom) - 1) % zoomLevels.length;
    setState(() {
      _selectedZoom = zoomLevels[currentIndex];
    });
    return null;
  }

  Object? _handleMoveDown(ComboBoxTraverseNextIntent intent) {
    if (!_menuController.isOpen) {
      _menuController.open();
      if (!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    }
    final currentIndex = (zoomLevels.indexOf(_selectedZoom) + 1) % zoomLevels.length;
    setState(() {
      _selectedZoom = zoomLevels[currentIndex];
    });
    return null;
  }

  void _handleSelect(String value) {
    if (zoomLevels.contains(value)) {
      setState(() {
        _selectedZoom = value;
      });
    }
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
            color: _isHovered ? FloogleColors.zoomHoverColor : FloogleColors.transparent,
          ),
          child: DefaultTextStyle(
            style: const TextStyle(height: 1.5),
            child: MergeSemantics(
              child: Semantics(
                label: 'Zoom',
                value: _selectedZoom,
                child: ComboBox(
                  inputConstraints: const BoxConstraints(
                    minHeight: 29.25,
                    maxHeight: 29.25,
                    minWidth: 68,
                    maxWidth: 68,
                  ),
                  onSelect: _handleSelect,
                  menuController: _menuController,
                  selected: _selectedZoom,
                  focusNode: _focusNode,
                  trailing: const DropdownArrow(),
                  children: zoomWidgets,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
