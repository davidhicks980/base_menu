import 'package:base_menu/base_menu.dart';
import 'package:flutter/widgets.dart';

final _checkboxDecoration = {
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
    color: Color(0xFF0075FF),
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

  static bool isHoveredOf(BuildContext context) {
    return BaseMenuItem.isHoveredOf<WebCheckboxMenuItem>(context);
  }

  // ... Other state getters ...

  @override
  Widget build(BuildContext context) {
    final body = SizedBox(
      height: 30,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          spacing: 12,
          children: [
            ExcludeFocus(
              child: AbsorbPointer(
                child: Builder(
                  builder: (context) {
                    final states = statesOf(context);
                    return Container(
                      width: 13,
                      height: 13,
                      decoration: WidgetStateProperty.fromMap(_checkboxDecoration).resolve(states),
                      child: checkbox,
                    );
                  },
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.only(bottom: 2.0), child: child),
          ],
        ),
      ),
    );

    return Semantics(
      checked: isChecked,
      child: BaseMenuItem<WebCheckboxMenuItem>(
        role: .menuItemCheckbox,
        requestCloseOnActivate: false,
        requestFocusOnHover: false,
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
                decoration: isHoveredOf(context)
                    ? BoxDecoration(
                        color: const Color(0xFFEDEDED),
                        border: isFocusedOf(context)
                            ? Border.all(color: const Color(0xFF0075FF), width: 2.0)
                            : null,
                      )
                    : BoxDecoration(
                        color: const Color(0x00000000),
                        border: isFocusedOf(context)
                            ? Border.all(color: const Color(0xFF0075FF), width: 2.0)
                            : null,
                      ),
                child: body,
              );
            },
          ),
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
