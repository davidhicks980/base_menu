import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

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
  final _focusNode = FocusNode();

  String _selectedValue = '100%';
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

    int parseLevel(String level) {
      return int.parse(level.substring(0, level.length - 1));
    }

    int closest = parseLevel(levels.current);
    while (levels.moveNext()) {
      final int current = parseLevel(levels.current);
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
      ComboBoxOption(index: 0, value: zoomLevels.first),
      const MenuDivider(padding: EdgeInsets.only(left: 12)),
      for (var i = 1; i < zoomLevels.length; i++) ComboBoxOption(index: i, value: zoomLevels[i]),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final zoom = AppStateManager.documentStateOf(context)[SelectionKey.zoomLevel]! as String;
    if (_selectedValue != zoom) {
      _selectedValue = zoom;
      _highlightValue = _selectedValue;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSelect(String zoomLevel) {
    assert(zoomLevels.contains(zoomLevel));
    Actions.invoke(context, SetZoomLevelIntent(zoomLevel));
  }

  void _handleSubmit(String value) {
    final index = zoomLevels.indexOf(value);
    if (index != -1) {
      _handleSelect(zoomLevels[index]);
    } else if (findClosestZoomLevel(value) case final String closest) {
      _handleSelect(closest);
    } else {
      return;
    }
    _menuController.close();
  }

  @override
  Widget build(BuildContext context) {
    final child = DefaultTextStyle(
      style: const TextStyle(height: 1.5),
      child: ComboBox(
        semanticsLabel: 'Zoom',
        inputConstraints: const BoxConstraints(
          minHeight: 29.25,
          maxHeight: 29.25,
          minWidth: 68,
          maxWidth: 68,
        ),
        focusNode: _focusNode,
        onSelect: _handleSelect,
        onSubmit: _handleSubmit,
        menuController: _menuController,
        value: _selectedValue,
        trailing: const DropdownArrow(),
        initialOffset: zoomLevels.indexOf(_selectedValue) * 30.0,
        children: zoomWidgets,
      ),
    );
    return BaseHoverable(
      mouseCursor: WidgetStateMouseCursor.textable,
      child: Builder(
        builder: (context) {
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: BaseHoverable.isHoveredOf(context)
                  ? FloogleColors.toolbarItemHoverFocus
                  : FloogleColors.transparent,
            ),
            child: child,
          );
        },
      ),
    );
  }
}
