import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_state_manager.dart';
import '../../model/enum.dart';
import '../../model/intents.dart';
import '../../utilities/colors.dart';
import '../checkbox_menu_item.dart';
import '../menu_divider.dart';
import '../menu_item.dart';
import '../menu_panel.dart';
import '../select.dart';
import '../submenu.dart';

class FontMenu extends StatefulWidget {
  const FontMenu({super.key});

  @override
  State<FontMenu> createState() => _FontMenuState();
}

class _FontMenuState extends State<FontMenu> {
  void _handleChanged(FontFamily family, FontWeight weight) {
    Actions.invoke(context, SetFontFamilyIntent(family));
    Actions.invoke(context, FormatTextWeightIntent(weight));
  }

  @override
  Widget build(BuildContext context) {
    final selectedFamily = AppStateManager.selectedTextStyleOf(context)?.fontFamily;
    final family = selectedFamily != null
        ? FontFamily.values.firstWhere(
            (f) => f.label == selectedFamily,
            orElse: () => FontFamily.roboto,
          )
        : FontFamily.inter;
    return ConstrainedBox(
      constraints: const .tightFor(width: 97),
      child: _FontSelector(
        family: family,
        onChanged: _handleChanged,
        child: Select(
          panel: const MenuPanel(
            padding: .symmetric(vertical: 6),
            constraints: .tightFor(width: 272),
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MenuItem(leading: Icon(Symbols.add), child: Text('More fonts')),
                  MenuDivider(padding: EdgeInsets.fromLTRB(12, 8, 12, 8)),
                  MenuSectionHeader(child: Text('RECENT')),
                  _Option(FontFamily.inter, autofocusSelected: false),
                  _Option(FontFamily.lexend, autofocusSelected: false),
                  _Option(FontFamily.merriweather, autofocusSelected: false),
                  MenuDivider(padding: .fromLTRB(12, 8, 12, 8), color: .fromRGBO(196, 199, 197, 1)),
                ],
              ),
              SingleChildScrollView(
                padding: .only(bottom: 6),
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
            ],
          ),
          child: Text(
            family.label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: FloogleColors.selectTextColor),
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
              color: Color(0xFF1f1f1f),
              fontVariations: [FontVariation.weight(550)],
              fontFamily: 'RobotoFlex',
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
      return CheckboxMenuItem(
        autofocus: autofocusSelected && group.isFamilySelected,
        checked: group.isFamilySelected,
        onPressed: () {
          group.select(value, FontWeight.normal);
        },
        child: Text(value.label),
      );
    }

    return _SubmenuOption(value: value, autofocusSelected: autofocusSelected);
  }
}

class _SubmenuOption extends StatelessWidget {
  const _SubmenuOption({required this.value, required this.autofocusSelected});

  final FontFamily value;
  final bool autofocusSelected;

  @override
  Widget build(BuildContext context) {
    final group = _FontSelector.of(context, value);
    final checked = group.isFamilySelected;
    return MergeSemantics(
      child: Semantics(
        checked: checked,
        child: Submenu(
          autofocus: autofocusSelected && checked,
          onPressed: () {
            group.select(value, FontWeight.normal);
          },
          panel: MenuPanel(
            padding: const EdgeInsets.symmetric(vertical: 6),
            children: [
              for (final variant in value.variants)
                Builder(
                  builder: (context) {
                    final group = _FontSelector.of(context, value);
                    final isWeightSelected =
                        AppStateManager.selectedTextStyleOf(context)?.fontWeight == variant;
                    return CheckboxMenuItem(
                      checked: checked && isWeightSelected,
                      onPressed: () {
                        group.select(value, variant);
                      },
                      child: Text(
                        fontWeightToLabelMap[variant]!,
                        style: TextStyle(fontFamily: value.label, fontWeight: variant),
                      ),
                    );
                  },
                ),
            ],
          ),
          leading: checked ? const Icon(Symbols.check, size: 16) : null,
          child: Text(
            value.label,
            style: TextStyle(fontFamily: value.label, fontWeight: FontWeight.normal),
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
