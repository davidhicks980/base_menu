Base Menu uses inherited widgets to provide state information to its
descendants. By doing so, most theming can be achieved without the need for
additional state management. 

## 1. Core Concepts: Accessing State

There are two primary ways to access the state of an ancestor control:

1.  **State Selectors**: Methods like `isHoveredOf(context)` or
    `isPressedOf(context)`. These return a boolean and are ideal for simple
    conditional logic.
2.  **State Aggregators**: The `statesOf(context)` method returns a
    `Set<WidgetState>`. This is designed for use with `WidgetStateProperty`,
    similar to how Material 3 components are styled.


## 2. Atomic Controls

### BaseHoverable

`BaseHoverable` tracks hover using a `MouseRegion` and provides two state
selectors, `isHoveredOf(context)` and `isHoverHighlightShownOf(context)`.

Because `isHoveredOf(context)` does not account for platform differences in
hover behavior and does not consider whether the widget is enabled, it is
recommended to use `isHoverHighlightShownOf(context)` when applying visual
feedback.

#### Example: A rectangle that changes color when hovered

```dart
class HoverRectangle extends StatelessWidget {
  const HoverRectangle({
    super.key,
    this.child = const Text('😾', style: TextStyle(fontSize: 32)),
  });
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BaseHoverable(
      child: Builder(
        builder: (context) {
          final bool isHovered = BaseHoverable.isHoverHighlightShownOf(context);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            color: isHovered
                ? const Color(0xFFFF295B)
                : const Color(0xFFD8E2FF),
            alignment: Alignment.center,
            child: child,
          );
        },
      ),
    );
  }
}
```

Usage:
```dart
HoverRectangle();
```
<p align="center">
<video src="/assets/videos/base_hoverable.gif" width="100%" autoplay loop muted></video>
</p>


### BaseFocusable

BaseFocusable tracks focus using a `Focus` widget and provides two state
selectors, `isFocusedOf(context)` and `isFocusHighlightShownOf(context)`.

Similar to hover, `isFocusHighlightShownOf(context)` is preferred over
`isFocusedOf(context)` because the latter does not account for platform
differences in focus behavior. For example, touch devices typically do not show
focus highlights.

#### Example: A rectangle that applies a border when focused

```dart
class FocusRectangle extends StatelessWidget {
  const FocusRectangle({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BaseFocusable(
      child: Builder(
        builder: (context) {
          final bool isFocused = BaseFocusable.isFocusHighlightShownOf(context);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              border: Border.all(
                color: isFocused
                    ? const Color(0xFF445E91)
                    : const Color(0x00D8E2FF),
                width: 2,
              ),
            ),
            child: child,
          );
        },
      ),
    );
  }
}
```

Usage: 
```dart
FocusRectangle(
  child: HoverRectangle(
    child: Builder(
      builder: (context) {
        return Text(
          BaseFocusable.isFocusHighlightShownOf(context) ? '😸' : '😾',
          style: const TextStyle(fontSize: 32),
        );
      },
    ),
  ),
);
```

<p align="center">
<video src="/assets/videos/base_focusable.gif" width="300px" autoplay loop muted></video>
</p>

<br>

## 3. Composite Controls

### BaseControl

BaseControl is a general-purpose pressable widget that combines the state
selectors provided by `BaseFocusable` and `BaseHoverable` with two additional
selectors: `BaseControl.isPressedOf(context)` and
`BaseControl.isDisabledOf(context)`.

Additionally, `BaseControl` provides a state aggregator,
`BaseControl.statesOf(context)`, which returns a `Set<WidgetState>` containing
all the states of the control. This is useful for complex styling scenarios
where multiple states need to be considered simultaneously.

### BaseMenuItem

`BaseMenuItem` wraps `BaseControl` and is designed for use in menus. It provides
the same state selectors and aggregator as `BaseControl`, but also includes
focus-on-hover, dismiss-on-press, and a menu item semantic role.

#### Declarative styles using `WidgetStateProperty.fromMap`
For complex styling, use `WidgetStateProperty` to map states to visual properties like `BoxDecoration`. This is the pattern used in main.dart.

```dart
class MenuItemDemo extends StatelessWidget {
  const MenuItemDemo({super.key});

  static final WidgetStateProperty<Color> _decoration =
      WidgetStateProperty.fromMap({
        WidgetState.pressed: const Color(0xFF003EAA),
        WidgetState.focused: const Color(0xFF0075FF),
        WidgetState.hovered: const Color(0xFF005CFF),
        WidgetState.disabled: const Color(0xFF8D8D8D),
        WidgetState.any: const Color.fromARGB(255, 0, 0, 0),
      });

  @override
  Widget build(BuildContext context) {
    // Prevent the child from rebuilding when the menu item is hovered, focused, or pressed.
    final child = Text(
      'Menu Item',
      style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)),
    );

    return BaseMenuItem(
      role: null,
      requestFocusOnHover: false,
      onPressed: () {},
      child: Builder(
        builder: (context) {
          return Container(
            alignment: AlignmentDirectional.centerStart,
            margin: const EdgeInsets.all(5.0),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            color: _decoration.resolve(BaseMenuItem.statesOf(context)),
            child: child,
          );
        },
      ),
    );
  }
}
```


## 4. Building design systems

### Passing State

Design systems looking to pass state can do so through type specialization
or builder functions.

#### Type Specialization

Type specialization is a pattern where the public API of a design system's
widget exposes state selectors and aggregators that are scoped to a specialized
type. This prevents descendants of the widget from accidentally accessing the
state of a different widget that uses `BaseControl`.

For example, `BaseMenuItem.statesOf(context)` uses `BaseMenuItem` as the type
specialization for `BaseControl`:
```dart
// Definition for BaseMenuItem.statesOf(context)
@optionalTypeArgs
static Set<WidgetState> statesOf<T extends Object?>(BuildContext context) {
  return BaseControl.statesOf<BaseMenuItem<T>>(context);
}
```

This prevents descendants of `BaseMenuItem` from accidentally accessing the
state of an intermediate `BaseControl`.

**Benefits:**
  * Any **descendant** of a control can access state, meaning multiple nested
    styling layers can be applied independently.
  * Each part of a widget can rebuild independently, which can improve
    performance.

**Disadvantages:**
  * The public API of a design system's widget must expose state selectors and
    aggregators, which can make the implementation more verbose.
  * Forgetting to include an ancestor control in the widget tree
    or using the wrong type specialization will result in an assertion error when
    trying to access state.


##### Example

```dart
class Checkbox extends StatefulWidget {
  const Checkbox({
    super.key,
    required this.child,
  });

  final Widget child;

  // Note that _CheckboxState is private, so the public API does not expose any implementation details of BaseControl.
  static bool isPressedOf(BuildContext context) => BaseControl.isPressedOf<_CheckboxState>(context);

  // ...other state selectors ...

  static bool isSelectedOf(BuildContext context) {
    final checkboxScope = context
        .dependOnInheritedWidgetOfExactType<_CheckboxScope>();
    assert(
      checkboxScope != null,
      'Checkbox must be a descendant of a _CheckboxScope.',
    );
    return checkboxScope!.isChecked;
  }

  static Set<WidgetState> statesOf(BuildContext context) {
    return {
      ...BaseControl.statesOf<_CheckboxState>(context),
      if (isSelectedOf(context)) WidgetState.selected,
    };
  }

  @override
  State<Checkbox> createState() => _CheckboxState();
}

class _CheckboxState extends State<Checkbox> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: Semantics(
        checked: _isChecked,
        child: BaseControl<_CheckboxState>(
          onPressed: () {
            setState(() {
              _isChecked = !_isChecked;
            });
          },
          child: _CheckboxScope(isChecked: _isChecked, child: widget.child),
        ),
      ),
    );
  }
}

class _CheckboxScope extends InheritedWidget {
  const _CheckboxScope({required super.child, required this.isChecked});
  final bool isChecked;

  @override
  bool updateShouldNotify(_CheckboxScope oldWidget) {
    return oldWidget.isChecked != isChecked;
  }
}
```

#### Builder

Developers may favor using a builder to pass state to a design system's public
API. 

**Benefits:**
  * Easier to understand, especially for developers who are not familiar with
    inherited widgets.
  * Less prone to errors since the builder function is called with the correct
    state, and there is no need to remember to include an ancestor control in
    the widget tree.

**Disadvantages:**
  * Only the widget that is built by the builder function can access state, which
    can make it difficult to apply multiple nested styling layers.
  * The entire widget built by the builder function will rebuild whenever the
    state changes, which can be less efficient.
  * Providing a builder function instead of a child widget can make usage more
    verbose.

```dart
class CheckboxBuilder extends StatefulWidget {
  const CheckboxBuilder({
    super.key,
    required this.builder,
    this.width = 14,
    this.height = 14,
  });

  final double width;
  final double height;
  final Widget Function(BuildContext context, Set<WidgetState> states) builder;

  @override
  State<CheckboxBuilder> createState() => _CheckboxBuilderState();
}

class _CheckboxBuilderState extends State<CheckboxBuilder> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Semantics(
        checked: _isChecked,
        child: BaseControl<_CheckboxBuilderState>(
          onPressed: () {
            setState(() {
              _isChecked = !_isChecked;
            });
          },
          child: Builder(
            builder: (context) {
              return widget.builder(context, {
                ...BaseControl.statesOf<_CheckboxBuilderState>(context),
                if (_isChecked) WidgetState.selected,
              });
            },
          ),
        ),
      ),
    );
  }
}
```


### Example: Checkbox with Type Specialization

Imagine you are building a checkbox that mimicks `<input type="checkbox">` on
web, but you want the checkbox to adapt to the web engine's native look and
feel. Theming is then a matter of using state selectors to apply different
styles:

<p align="center">
<video src="/assets/videos/checkbox.gif" width="300px" autoplay loop muted></video>
</p>

#### Theming for the Blink browser engine (Chromium):
```dart
class BlinkCheckbox extends StatelessWidget {
  const BlinkCheckbox({super.key});

  static final _background = WidgetStateProperty.fromMap({
    WidgetState.selected & WidgetState.pressed: const Color(0xFF003EAA),
    WidgetState.selected & WidgetState.hovered: const Color(0xFF005CFF),
    WidgetState.selected & WidgetState.focused: const Color(0xFF0075FF),
    WidgetState.selected: const Color(0xFF0075FF),
    WidgetState.pressed: const Color(0xFFFFFFFF),
    WidgetState.hovered: const Color(0xFFFFFFFF),
    WidgetState.any: const Color(0xFFFFFFFF),
  });

  static final _border = WidgetStateProperty.fromMap({
    WidgetState.selected & WidgetState.pressed: Color(0xFF003EAA),
    WidgetState.selected & WidgetState.hovered: Color(0xFF005CFF),
    WidgetState.selected & WidgetState.focused: Color(0xFF0075FF),
    WidgetState.selected: Color(0xFF0075FF),
    WidgetState.pressed: Color(0xFF8D8D8D),
    WidgetState.hovered: Color(0xFF4F4F4F),
    WidgetState.any: Color(0xFF767676),
  });

  @override
  Widget build(BuildContext context) {
    final states = Checkbox.statesOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _background.resolve(states),
        border: Border.fromBorderSide(
          BorderSide(color: _border.resolve(states)),
        ),
        borderRadius: const BorderRadius.all(Radius.circular(2)),
      ),
      child: states.contains(WidgetState.selected) ? const _BlinkCheckmark() : null,
    );
  }
}

class _BlinkCheckmark extends StatelessWidget {
  const _BlinkCheckmark({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _BlinkCheckmarkPainter());
  }
}

class _BlinkCheckmarkPainter extends CustomPainter {
  const _BlinkCheckmarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.miter
      ..strokeCap = StrokeCap.square;

    final path = Path()
      ..moveTo(size.width * 0.22, size.height * (7.0 / 13.0))
      ..lineTo(size.width * 0.4, size.height * (9.5 / 13.0))
      ..lineTo(size.width * 0.78, size.height * 0.25);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BlinkCheckmarkPainter oldDelegate) => false;
}
```

##### Usage: 
```dart
Checkbox(
  child: BlinkCheckbox(),
);
```

#### Theming for the WebKit browser engine (Safari):

```dart
class WebkitCheckbox extends StatelessWidget {
  const WebkitCheckbox({super.key});

  @override
  Widget build(BuildContext context) {
    final states = Checkbox.statesOf(context);
    return CustomPaint(
      painter: _WebkitCheckboxPainter(states: states),
      child: states.contains(WidgetState.selected) ? const _WebkitCheckmark() : null,
    );
  }
}

class _WebkitCheckmark extends StatelessWidget {
  const _WebkitCheckmark();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _WebkitCheckmarkPainter());
  }
}

class _WebkitCheckboxPainter extends CustomPainter {
  _WebkitCheckboxPainter({required this.states});
  final Set<WidgetState> states;

  static const selectedGradient = LinearGradient(
    colors: [Color(0xFF2691FF), Color(0xFF007AFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const selectedPressedGradient = LinearGradient(
    colors: [Color(0xFF147DEB), Color(0xFF0167EB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.width * 0.25);
    final rrect = RRect.fromRectAndRadius(rect, radius);
    if (states.contains(WidgetState.selected)) {
      final gradient = states.contains(WidgetState.pressed)
          ? selectedPressedGradient
          : selectedGradient;
      canvas.drawRRect(
        rrect,
        Paint()..shader = gradient.createShader(rrect.outerRect),
      );
    } else {
      final Paint shadowPaint = Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

      final Path shadowPath = Path()
        ..addRRect(rrect.inflate(5))
        ..addRRect(rrect.shift(const Offset(0, 1.2)))
        ..fillType = PathFillType.evenOdd;

      final backgroundColor = states.contains(WidgetState.pressed)
          ? const Color(0xFFF2F2F2)
          : const Color(0xFFFFFFFF);
      final borderColor = states.contains(WidgetState.pressed)
          ? const Color(0xFFC5C5C5)
          : const Color(0xFFD0D0D0);

      canvas
        ..save()
        ..clipRRect(rrect)
        ..drawColor(backgroundColor, BlendMode.srcOver)
        ..drawPath(shadowPath, shadowPaint)
        ..restore()
        ..drawRRect(
          RRect.fromRectAndRadius(rect.deflate(0.25), radius),
          Paint()
            ..strokeWidth = 0.5
            ..color = borderColor
            ..style = PaintingStyle.stroke,
        );
    }
  }

  @override
  bool shouldRepaint(_WebkitCheckboxPainter oldDelegate) =>
      oldDelegate.states != states;
}

class _WebkitCheckmarkPainter extends CustomPainter {
  const _WebkitCheckmarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = size.width * 0.14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.55)
      ..lineTo(size.width * 0.41, size.height * 0.78)
      ..lineTo(size.width * 0.75, size.height * 0.28);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WebkitCheckmarkPainter oldDelegate) => false;
}
```

##### Usage:

```dart
Checkbox(
  child: WebkitCheckbox(),
);
```


