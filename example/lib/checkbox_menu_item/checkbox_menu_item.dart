import 'package:flutter/material.dart';
import 'package:menu_utilities/menu_utilities.dart';

import 'src/checkbox_menu_item.dart';

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
        package: 'example',

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
                WebCheckboxMenuItem(checkbox: _Checkbox(), child: Text('Play with cat')),
                WebCheckboxMenuItem(checkbox: _Checkbox(), child: Text('Pet cat')),
                WebCheckboxMenuItem(checkbox: _Checkbox(), child: Text('Feed cat')),
                WebCheckboxMenuItem(checkbox: _Checkbox(), child: Text('Get bit by cat')),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox();

  @override
  Widget build(BuildContext context) {
    final bool isChecked = WebCheckboxMenuItem.isCheckedOf(context);
    return isChecked ? const CustomPaint(painter: WebCheckboxPainter()) : const SizedBox();
  }
}
