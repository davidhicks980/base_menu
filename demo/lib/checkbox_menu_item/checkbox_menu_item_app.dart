import 'package:base_menu/base_menu.dart';
import 'package:flutter/material.dart';

import '../shared/checkbox.dart';
import '../shared/package.dart';
import 'src/checkbox_menu_item.dart';

export 'src/checkbox_menu_item.dart';

class CheckboxMenuItemApp extends StatefulWidget {
  const CheckboxMenuItemApp({super.key});

  @override
  State<CheckboxMenuItemApp> createState() => _CheckboxMenuItemAppState();
}

class _CheckboxMenuItemAppState extends State<CheckboxMenuItemApp> {
  final focusScopeNode = FocusScopeNode();

  @override
  void dispose() {
    focusScopeNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        fontFamily: 'InterVariable',
        package: kPackage,
        fontSize: 14,
        color: Color(0xFF1A1A1A),
        height: 1.5,
        decoration: TextDecoration.none,
        fontWeight: FontWeight.w500,
      ),
      child: Column(
        children: [
          const Spacer(),
          const Text('Todo List', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          BaseMenuBar(
            focusScopeNode: focusScopeNode,
            orientation: .vertical,
            child: BaseMenuPanel(
              onPointerExit: (_) {
                focusScopeNode.requestScopeFocus();
              },
              constraints: const BoxConstraints(minWidth: 100),
              children: const [
                _CheckboxMenuItem(child: Text('Play with cat')),
                _CheckboxMenuItem(child: Text('Pet cat')),
                _CheckboxMenuItem(child: Text('Feed cat')),
                _CheckboxMenuItem(child: Text('Get bit by cat')),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _CheckboxMenuItem extends StatefulWidget {
  const _CheckboxMenuItem({required this.child});
  final Widget child;

  @override
  State<_CheckboxMenuItem> createState() => _CheckboxMenuItemState();
}

class _CheckboxMenuItemState extends State<_CheckboxMenuItem> {
  bool isChecked = false;
  @override
  Widget build(BuildContext context) {
    return WebCheckboxMenuItem(
      checkbox: const WebCheckbox(),
      isChecked: isChecked,
      onChange: (value) {
        setState(() {
          isChecked = value;
        });
      },
      child: widget.child,
    );
  }
}
