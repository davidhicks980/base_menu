import 'package:base_menu/base_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../extensions/string.dart';
import '../../model/enum.dart';
import '../../model/intents.dart';
import '../../theme/colors.dart';
import '../app_state_manager.dart';
import '../menu_action_label.dart';
import '../menu_divider.dart';
import '../menu_item.dart';
import '../menu_panel.dart';
import '../select.dart';
import '../selectable_menu_item.dart';
import '../tooltip.dart';
import '../web_label.dart';

class FontMenu extends StatefulWidget {
  const FontMenu({super.key});

  @override
  State<FontMenu> createState() => _FontMenuState();
}

class _FontMenuState extends State<FontMenu> {
  final FocusNode _focusNode = FocusNode();
  final MenuController controller = MenuController();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleChanged(FontFamily family, FontWeight weight) {
    Actions.invoke(context, SetFontFamilyIntent((family: family, weight: weight)));
  }

  void _handleSurfaceExit(PointerExitEvent event) {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedFamily = AppStateManager.selectedTextStyleOf(
      context,
    )?.textStyle?.fontFamily?.withSpaceAfterCapitals.split('_').first;

    final family = selectedFamily != null
        ? FontFamily.values.firstWhere(
            (f) => f.label == selectedFamily,
            orElse: () => FontFamily.roboto,
          )
        : FontFamily.roboto;

    return ConstrainedBox(
      constraints: const .tightFor(width: 97),
      child: _FontSelector(
        family: family,
        onChanged: _handleChanged,
        child: MenuTooltip(
          enableSemantics: false,
          message: const TextSpan(text: 'Font'),
          child: Select(
            menuController: controller,
            focusNode: _focusNode,
            panel: MenuPanel(
              clipBehavior: Clip.hardEdge,
              onSurfaceExit: _handleSurfaceExit,
              padding: const .symmetric(vertical: 6),
              constraints: const .tightFor(width: 272),
              scrollable: false,
              children: const [
                MenuItem(leading: Icon(Symbols.brand_family), child: Text('More fonts')),
                MenuDivider(padding: EdgeInsets.fromLTRB(12, 8, 12, 8)),
                MenuSectionHeader(child: Text('RECENT')),
                _Option(FontFamily.inter, autofocusSelected: false),
                _Option(FontFamily.lexend, autofocusSelected: false),
                _Option(FontFamily.merriweather, autofocusSelected: false),
                MenuDivider(padding: .fromLTRB(12, 8, 12, 8)),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Option(FontFamily.amaticSc),
                        _Option(FontFamily.caveat),
                        _Option(FontFamily.comfortaa),
                        _Option(FontFamily.ebGaramond),
                        _Option(FontFamily.inter),
                        _Option(FontFamily.lato),
                        _Option(FontFamily.lexend),
                        _Option(FontFamily.libreBaskerville),
                        _Option(FontFamily.lora),
                        _Option(FontFamily.merriweather),
                        _Option(FontFamily.montserrat),
                        _Option(FontFamily.nunito),
                        _Option(FontFamily.oswald),
                        _Option(FontFamily.pacifico),
                        _Option(FontFamily.playfairDisplay),
                        _Option(FontFamily.raleway),
                        _Option(FontFamily.roboto),
                        _Option(FontFamily.robotoMono),
                        _Option(FontFamily.robotoSerif),
                        _Option(FontFamily.robotoSlab),
                        _Option(FontFamily.sourceSansPro),
                        _Option(FontFamily.ubuntu),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            child: kIsWeb
                ? WebLabel(
                    label: family.label,
                    textStyle: const TextStyle(
                      color: FloogleColors.selectTextColor,
                      fontSize: 14.2,
                      fontWeight: FontWeight(550),
                      overflow: TextOverflow.ellipsis,
                      letterSpacing: -0.1,

                      fontVariations: [FontVariation.width(95), FontVariation.opticalSize(14.2)],
                    ),
                    uppercaseTextStyle: const TextStyle(
                      color: FloogleColors.selectTextColor,
                      fontSize: 14.5,
                      fontWeight: FontWeight(550),
                      letterSpacing: -0.1,

                      overflow: TextOverflow.ellipsis,
                      fontVariations: [FontVariation.opticalSize(14)],
                    ),
                  )
                : Text(
                    family.label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: FloogleColors.selectTextColor),
                  ),
          ),
        ),
      ),
    );
  }
}

class MenuSectionHeader extends StatelessWidget {
  const MenuSectionHeader({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 32, maxHeight: 32),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 0.2,
              color: FloogleColors.darkGray,
              fontVariations: [FontVariation.weight(550)],
              fontFamily: 'RobotoFlex',
              package: 'example',
              decoration: TextDecoration.none,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option(this.value, {this.autofocusSelected = true});
  final FontFamily value;
  final bool autofocusSelected;

  @override
  Widget build(BuildContext context) {
    if (value.variants.isEmpty) {
      final group = _FontSelector.of(context, value);
      return SelectableMenuItem(
        autofocus: autofocusSelected && group.isFamilySelected,
        selected: group.isFamilySelected,
        onPressed: () {
          group.select(value, FontWeight.normal);
        },
        child: Text(value.label),
      );
    }

    return _SubmenuOption(value: value, autofocusSelected: autofocusSelected);
  }
}

class _SubmenuOption extends StatefulWidget {
  const _SubmenuOption({required this.value, required this.autofocusSelected});

  final FontFamily value;
  final bool autofocusSelected;

  @override
  State<_SubmenuOption> createState() => _SubmenuOptionState();
}

class _SubmenuOptionState extends State<_SubmenuOption> {
  final FocusNode _focusNode = FocusNode();
  final MenuController controller = MenuController();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = _FontSelector.of(context, widget.value);
    final checked = group.isFamilySelected;
    return MergeSemantics(
      child: Semantics(
        checked: checked,
        child: BaseSubmenu(
          controller: controller,
          focusNode: _focusNode,
          positionDelegate: const DefaultMenuPositioningDelegate(
            padding: EdgeInsetsDirectional.symmetric(vertical: 6),
            offset: Offset(-8, 0),
          ),
          autofocus: widget.autofocusSelected && checked,
          onPressed: () {
            group.select(widget.value, FontWeight.normal);
            MenuController.maybeOf(context)?.close();
          },
          menu: MenuPanel(
            onSurfaceExit: (event) {
              if (!_focusNode.hasFocus) {
                _focusNode.requestFocus();
              }
            },
            padding: const EdgeInsets.symmetric(vertical: 6),
            children: [
              for (final variant in widget.value.variants)
                Builder(
                  builder: (context) {
                    final group = _FontSelector.of(context, widget.value);
                    final isWeightSelected =
                        (AppStateManager.selectedTextStyleOf(context)?.textStyle?.fontWeight ??
                            FontWeight.normal) ==
                        variant;
                    return SelectableMenuItem(
                      selected: checked && isWeightSelected,
                      onPressed: () {
                        group.select(widget.value, variant);
                      },
                      child: Text(
                        fontWeightToLabelMap[variant]!,
                        style: TextStyle(
                          fontFamily: widget.value.label,
                          package: 'example',
                          fontWeight: variant,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),

          child: SubmenuActionLabel(
            axis: Axis.vertical,
            leading: checked ? const Icon(Symbols.check, size: 16) : null,
            child: Text(
              widget.value.label,
              style: TextStyle(
                fontFamily: widget.value.label,
                package: 'example',
                fontWeight: kIsWeb ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension type _FontSelection(({FontFamily selected, _FontSelector model}) _data) {
  bool get isFamilySelected => _data.model.family == _data.selected;
  void select(FontFamily font, FontWeight weight) => _data.model.onChanged(font, weight);
}

class _FontSelector extends InheritedModel<FontFamily> {
  const _FontSelector({required super.child, required this.family, required this.onChanged});
  final FontFamily family;
  final void Function(FontFamily, FontWeight) onChanged;

  static _FontSelection of(BuildContext context, FontFamily font) {
    final model = InheritedModel.inheritFrom<_FontSelector>(context, aspect: font)!;
    return _FontSelection((selected: font, model: model));
  }

  @override
  bool updateShouldNotify(_FontSelector oldWidget) {
    return oldWidget.family != family || oldWidget.onChanged != onChanged;
  }

  @override
  bool updateShouldNotifyDependent(
    covariant _FontSelector oldWidget,
    Set<FontFamily> dependencies,
  ) {
    return dependencies.contains(family) && oldWidget.family != family;
  }
}
