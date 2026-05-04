import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../../app_state_manager.dart';
import '../../model/enum.dart';
import '../../model/intents.dart';
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

  final _menuController = MenuController();
  late List<Widget> zoomWidgets;
  bool _isHovered = false;
  String _selectedValue = '';
  String? _highlightValue;
  int? get highlightIndex => _highlightValue != null ? zoomLevels.indexOf(_highlightValue!) : null;

  String? findClosestZoomLevel(String zoomLevel) {
    final int? zoom = int.tryParse(zoomLevel.replaceAll('%', ''));
    if (zoom == null) {
      return null;
    }

    final levels = zoomLevels.skip(1).iterator;
    if (!levels.moveNext()) {
      return null;
    }

    int levelValue(String level) {
      return int.parse(level.substring(0, level.length - 1));
    }

    int closest = levelValue(levels.current);
    while (levels.moveNext()) {
      final int current = levelValue(levels.current);
      if ((current - zoom).abs() < (closest - zoom).abs()) {
        closest = current;
      } else {
        // Since the list is sorted, we can stop once we start getting farther away.
        break;
      }
    }
    // Return the closest level with '%' appended, or the original if no levels are found.
    return '$closest%';
  }

  @override
  void initState() {
    super.initState();
    zoomWidgets = [
      ComboBoxOption(value: zoomLevels.first),
      const MenuDivider(padding: EdgeInsets.only(left: 12)),
      for (var i = 1; i < zoomLevels.length; i++) ComboBoxOption(value: zoomLevels[i]),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final zoom = AppStateManager.documentStateOf(context)[SelectionKey.zoomLevel]! as String;
    if (_selectedValue != zoom) {
      _selectedValue = zoom;
      _highlightValue = zoom;
    }
  }

  void _handleMovePrevious() {
    final int previousIndex;
    if (highlightIndex case final int index) {
      previousIndex = (index - 1) % zoomLevels.length;
    } else {
      previousIndex = zoomLevels.length - 1;
    }
    _emitValue(zoomLevels[previousIndex]);
  }

  void _handleMoveNext() {
    final int nextIndex;
    if (highlightIndex case final int index) {
      nextIndex = (index + 1) % zoomLevels.length;
    } else {
      nextIndex = 0;
    }
    _emitValue(zoomLevels[nextIndex]);
  }

  // ignore: use_setters_to_change_properties
  void _handleHighlight(String? value) {
    _highlightValue = value;
  }

  void _emitValue(String zoomLevel) {
    Actions.invoke(context, SetZoomLevelIntent(zoomLevel));
  }

  void _handleSelect(String value) {
    final index = zoomLevels.indexOf(value);
    if (index != -1) {
      _emitValue(zoomLevels[index]);
    } else if (findClosestZoomLevel(value) case final String closest) {
      _emitValue(closest);
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
              value: _selectedValue,
              child: ComboBox(
                onTraversePrevious: _handleMovePrevious,
                onTraverseNext: _handleMoveNext,
                onHighlight: _handleHighlight,
                inputConstraints: const BoxConstraints(
                  minHeight: 29.25,
                  maxHeight: 29.25,
                  minWidth: 68,
                  maxWidth: 68,
                ),
                onSelect: _handleSelect,
                menuController: _menuController,
                selected: _selectedValue,

                trailing: const DropdownArrow(),
                children: zoomWidgets,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
