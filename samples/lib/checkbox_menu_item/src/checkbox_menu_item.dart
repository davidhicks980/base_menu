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
class WebCheckboxMenuItem extends StatefulWidget {
  const WebCheckboxMenuItem({super.key, required this.child, required this.checkbox});

  final Widget child;
  final Widget checkbox;

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
  State<WebCheckboxMenuItem> createState() => _WebCheckboxMenuItemState();
}

class _WebCheckboxMenuItemState extends State<WebCheckboxMenuItem> {
  bool checked = false;

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
                    checked: checked,
                    child: Builder(
                      builder: (context) {
                        final states = WebCheckboxMenuItem.statesOf(context);
                        return Container(
                          width: 13,
                          height: 13,
                          decoration: WidgetStateProperty.fromMap(
                            checkboxDecoration,
                          ).resolve(states),
                          child: widget.checkbox,
                        );
                      },
                    ),
                  ),
                ),
              ),
              Padding(padding: const EdgeInsets.only(bottom: 2.0), child: widget.child),
            ],
          ),
        ),
      ),
    );

    return BaseMenuItem<WebCheckboxMenuItem>(
      role: .menuItemCheckbox,
      requestCloseOnActivate: false,
      onPressed: () {
        setState(() {
          checked = !checked;
        });
      },
      child: _CheckedScope<WebCheckboxMenuItem>(
        isChecked: checked,
        child: Builder(
          builder: (context) {
            return DecoratedBox(
              decoration: WebCheckboxMenuItem.isFocusedOf(context)
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
    assert(scope != null, 'No DesignSystemCheckbox of type $T found in context. \n');
    return scope!.isChecked;
  }

  @override
  bool updateShouldNotify(_CheckedScope<T> oldWidget) {
    return oldWidget.isChecked != isChecked;
  }
}

class WebCheckboxPainter extends CustomPainter {
  const WebCheckboxPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.miter
      ..strokeCap = StrokeCap.square;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * (7.0 / 13.0))
      ..lineTo(size.width * 0.4, size.height * (9.5 / 13.0))
      ..lineTo(size.width * 0.8, size.height * 0.2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WebCheckboxPainter oldDelegate) => false;
}
