import 'package:base_menu/base_menu.dart';
import 'package:flutter/widgets.dart';

final checkboxDecoration = {
  WidgetState.selected & WidgetState.pressed: const BoxDecoration(
    color: Color(0xFF003EAA),
    border: Border.fromBorderSide(BorderSide(color: Color(0xFF003EAA))),
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
  WidgetState.selected & WidgetState.hovered: const BoxDecoration(
    color: Color(0xFF005CFF),
    border: Border.fromBorderSide(BorderSide(color: Color(0xFF005CFF))),
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
  WidgetState.selected & WidgetState.focused: const BoxDecoration(
    color: Color(0xFF0075FF),
    border: Border.fromBorderSide(BorderSide(color: Color(0xFF0075FF))),
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
  WidgetState.selected: const BoxDecoration(
    color: Color(0xFF0075FF), // Standard Chromium blue
    border: Border.fromBorderSide(BorderSide(color: Color(0xFF0075FF))),
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
  WidgetState.pressed: const BoxDecoration(
    border: Border.fromBorderSide(BorderSide(color: Color(0xFF8D8D8D))),
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
  WidgetState.hovered: const BoxDecoration(
    color: Color(0xFFFFFFFF),
    border: Border.fromBorderSide(BorderSide(color: Color(0xFF4F4F4F))),
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
  WidgetState.any: const BoxDecoration(
    color: Color(0xFFFFFFFF),
    border: Border.fromBorderSide(BorderSide(color: Color(0xFF767676))),
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
};

/// A menu item that hides BaseMenuItem internals
class WebCheckboxMenuItem extends StatelessWidget {
  const WebCheckboxMenuItem({
    super.key,
    required this.child,
    required this.checkbox,
    required this.isChecked,
    this.onChange,
  });

  final Widget child;
  final Widget checkbox;
  final bool isChecked;
  final ValueChanged<bool>? onChange;

  static Set<WidgetState> statesOf(BuildContext context) {
    return {
      ...BaseMenuItem.statesOf<WebCheckboxMenuItem>(context),
      if (isCheckedOf(context)) WidgetState.selected,
    };
  }

  static bool isCheckedOf(BuildContext context) {
    return _CheckedScope.isCheckedOf<WebCheckboxMenuItem>(context);
  }

  static bool isFocusedOf(BuildContext context) {
    return BaseMenuItem.isFocusedOf<WebCheckboxMenuItem>(context);
  }

  // ... Other state getters ...

  @override
  Widget build(BuildContext context) {
    final body = MergeSemantics(
      child: SizedBox(
        height: 30,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            spacing: 12,
            children: [
              ExcludeFocus(
                child: AbsorbPointer(
                  child: Semantics(
                    checked: isChecked,
                    child: Builder(
                      builder: (context) {
                        final states = statesOf(context);
                        return Container(
                          width: 13,
                          height: 13,
                          decoration: WidgetStateProperty.fromMap(
                            checkboxDecoration,
                          ).resolve(states),
                          child: checkbox,
                        );
                      },
                    ),
                  ),
                ),
              ),
              Padding(padding: const EdgeInsets.only(bottom: 2.0), child: child),
            ],
          ),
        ),
      ),
    );

    return BaseMenuItem<WebCheckboxMenuItem>(
      role: .menuItemCheckbox,
      requestCloseOnActivate: false,
      onPressed: onChange != null
          ? () {
              onChange!(!isChecked);
            }
          : null,
      child: _CheckedScope<WebCheckboxMenuItem>(
        isChecked: isChecked,
        child: Builder(
          builder: (context) {
            return DecoratedBox(
              decoration: isFocusedOf(context)
                  ? const BoxDecoration(color: Color(0xFFEDEDED))
                  : const BoxDecoration(color: Color(0x00000000)),
              child: body,
            );
          },
        ),
      ),
    );
  }
}

class _CheckedScope<T> extends InheritedWidget {
  const _CheckedScope({required super.child, required this.isChecked});

  final bool isChecked;

  static bool isCheckedOf<T>(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_CheckedScope<T>>();
    assert(scope != null, 'No WebCheckboxMenuItem of type $T found in context. \n');
    return scope!.isChecked;
  }

  @override
  bool updateShouldNotify(_CheckedScope<T> oldWidget) {
    return oldWidget.isChecked != isChecked;
  }
}
