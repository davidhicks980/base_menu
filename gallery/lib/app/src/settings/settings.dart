import 'package:base_menu/base_menu.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../shared/theme.dart';
import '../../app.dart' hide DrawerHeader;
import '../navigation_menu.dart';
import 'src/scope.dart';

export 'src/controller.dart';
export 'src/model.dart';
export 'src/scope.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = SettingsScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: NavigationMenuGroup(
        header: const DrawerHeader(child: Text('Settings')),
        groupLabel: 'Settings',
        children: [
          _SettingsToggle(
            label: 'Right-to-Left',
            icon: const Icon(Symbols.format_textdirection_r_to_l),
            value: scope.settings.directionality == TextDirection.rtl,
            onChanged: (bool value) => scope.updateDirectionality(
              scope.settings.directionality == TextDirection.rtl
                  ? TextDirection.ltr
                  : TextDirection.rtl,
            ),
          ),
          _SettingsToggle(
            label: 'Aim Assist',
            icon: const Icon(Symbols.magic_button),
            value: scope.settings.aimAssist,
            onChanged: scope.updateAimAssist,
          ),
          _SettingsToggle(
            label: 'Visualize Aim',
            icon: const Icon(Symbols.visibility),
            value: scope.settings.visualizeAimAssist,
            onChanged: scope.updateVisualizeAimAssist,
          ),
        ],
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.icon,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppColorScheme.of(context);
    final brightness = colorScheme.brightness;

    return RepaintBoundary(
      child: BaseControl(
        onPressed: () => onChanged(!value),
        child: Builder(
          builder: (context) {
            final states = BaseControl.statesOf(context);
            final isFocused = states.contains(WidgetState.focused);

            final Color itemColor = colorScheme.onSurface;
            final Color backgroundColor = switch (brightness) {
              Brightness.dark => darkBackgroundColor.resolve(states),
              Brightness.light => lightBackgroundColor.resolve(states),
            };

            return Container(
              height: 40,
              width: 232,
              padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(
                  color: isFocused ? colorScheme.primary : kTransparentLight,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  IconTheme.merge(
                    data: IconThemeData(size: 24, color: itemColor),
                    child: icon,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 12),
                      child: Text(
                        label,
                        style: sidebarTextStyle.resolve(states).copyWith(color: itemColor),
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: 0.8,
                    child: Transform.scale(
                      scale: 0.7,
                      child: Switch(
                        value: value,
                        onChanged: onChanged,
                        activeThumbColor: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
