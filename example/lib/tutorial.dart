import 'package:flutter/material.dart';
import 'package:menu_utilities/menu_utilities.dart';

/// A menu item that changes color when hovered, focused, or pressed.
class MenuItem extends StatelessWidget {
  const MenuItem({super.key, required this.child, required this.onPressed, this.suffix});
  final Widget child;
  final Widget? suffix;
  final VoidCallback? onPressed;

  static const WidgetStateProperty<BoxDecoration> decoration = WidgetStateProperty.fromMap({
    WidgetState.pressed: BoxDecoration(color: Color(0xFFE9E9E9)),
    WidgetState.hovered: BoxDecoration(color: Color(0xFFEDEDED)),
    WidgetState.focused: BoxDecoration(color: Color(0xFFEDEDED)),
    WidgetState.any: BoxDecoration(color: Color(0x00000000)),
  });

  @override
  Widget build(BuildContext context) {
    final Widget body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: suffix != null
          ? Row(spacing: 12, mainAxisAlignment: .spaceBetween, children: [child, suffix!])
          : child,
    );

    return BaseMenuItem(
      onPressed: () {},
      child: Builder(
        builder: (context) {
          // Rebuilds any time the menu item is hovered, focused, pressed, or
          // disabled.
          return DecoratedBox(
            decoration: decoration.resolve(BaseMenuItem.statesOf(context)),
            child: body,
          );
        },
      ),
    );
  }
}

/// A suffix that changes color when its parent menu item is hovered.
class Suffix extends StatelessWidget {
  const Suffix({super.key});

  @override
  Widget build(BuildContext context) {
    const box = SizedBox.square(dimension: 20);
    // Rebuilds only when the parent menu item is hovered.
    if (BaseMenuItem.isHoveredOf(context)) {
      return const ColoredBox(color: Color(0xFFFF0000), child: box);
    } else {
      return const ColoredBox(color: Color(0xFF000000), child: box);
    }
  }
}

/// A suffix that changes color it is hovered, but not when its parent menu item
/// is hovered.
class HoverableSuffix extends StatelessWidget {
  const HoverableSuffix({super.key});

  @override
  Widget build(BuildContext context) {
    const box = SizedBox.square(dimension: 20);
    return BaseHoverable(
      child: Builder(
        builder: (context) {
          // Rebuilds only when this widget is hovered.
          if (BaseHoverable.isHoveredOf(context)) {
            return const ColoredBox(color: Color(0xFFFF0000), child: box);
          } else {
            return const ColoredBox(color: Color(0xFF000000), child: box);
          }
        },
      ),
    );
  }
}

/// A suffix that passes its hover state to its child.
class SpecializedSuffix extends StatelessWidget {
  const SpecializedSuffix({super.key, required this.child});
  final Widget child;

  static bool isHovered(BuildContext context) {
    return BaseHoverable.isHoveredOf<SpecializedSuffix>(context);
  }

  @override
  Widget build(BuildContext context) {
    return BaseHoverable<SpecializedSuffix>(
      child: ConstrainedBox(
        constraints: const BoxConstraints.tightFor(width: 20, height: 20),
        child: child,
      ),
    );
  }
}

class SpecializedSuffixChild extends StatelessWidget {
  const SpecializedSuffixChild({super.key});

  @override
  Widget build(BuildContext context) {
    return SpecializedSuffix(
      child: Builder(
        builder: (context) {
          // The child can now use SpecializedSuffix.isHovered(context) to determine
          // if it is hovered.
          if (SpecializedSuffix.isHovered(context)) {
            return const ColoredBox(color: Color(0xFFFF0000));
          } else {
            return const ColoredBox(color: Color(0xFF000000));
          }
        },
      ),
    );
  }
}

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
class DesignSystemCheckboxMenuItem extends StatefulWidget {
  const DesignSystemCheckboxMenuItem({super.key, required this.child, required this.checkbox});

  final Widget child;
  final Widget checkbox;

  static Set<WidgetState> statesOf(BuildContext context) {
    return {
      ...BaseMenuItem.statesOf<DesignSystemCheckboxMenuItem>(context),
      if (isCheckedOf(context)) WidgetState.selected,
    };
  }

  static bool isCheckedOf(BuildContext context) {
    return _CheckedScope.isCheckedOf<DesignSystemCheckboxMenuItem>(context);
  }

  static bool isFocusedOf(BuildContext context) {
    return BaseMenuItem.isFocusedOf<DesignSystemCheckboxMenuItem>(context);
  }

  // ... Other state getters ...

  @override
  State<DesignSystemCheckboxMenuItem> createState() => _DesignSystemCheckboxMenuItemState();
}

class _DesignSystemCheckboxMenuItemState extends State<DesignSystemCheckboxMenuItem> {
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
            mainAxisAlignment: .spaceBetween,
            children: [
              ExcludeFocus(
                child: AbsorbPointer(
                  child: Semantics(
                    checked: checked,
                    child: Builder(
                      builder: (context) {
                        final states = DesignSystemCheckboxMenuItem.statesOf(context);
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

    return BaseMenuItem<DesignSystemCheckboxMenuItem>(
      role: .menuItemCheckbox,
      requestCloseOnActivate: false,
      onPressed: () {
        setState(() {
          checked = !checked;
        });
      },
      child: _CheckedScope<DesignSystemCheckboxMenuItem>(
        isChecked: checked,
        child: Builder(
          builder: (context) {
            return DecoratedBox(
              decoration: DesignSystemCheckboxMenuItem.isFocusedOf(context)
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
