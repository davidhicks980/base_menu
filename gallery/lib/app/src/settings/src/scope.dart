import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'model.dart';

class _SettingsScope extends InheritedNotifier<SettingsController> {
  const _SettingsScope({super.key, required super.notifier, required super.child});
}

class SettingsScope extends StatefulWidget {
  const SettingsScope({super.key, required this.child});
  final Widget child;

  static SettingsController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_SettingsScope>()!.notifier!;
  }

  static SettingsModel settingsOf(BuildContext context) => of(context).settings;

  static SettingsController read(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_SettingsScope>()!.notifier!;
  }

  static SettingsModel readSettings(BuildContext context) => read(context).settings;

  @override
  State<SettingsScope> createState() => _SettingsScopeState();
}

class _SettingsScopeState extends State<SettingsScope> {
  final SettingsController _controller = SettingsController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SettingsScope(notifier: _controller, child: widget.child);
}
