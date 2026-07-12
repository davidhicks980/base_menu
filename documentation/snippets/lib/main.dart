import 'package:base_menu/base_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math_64.dart';

const Color kSeedColor = Color(0xFF445E91); // Primary
const Color kPressedColor = Color(0xFF2B4678); // onPrimaryContainer
const Color kDarkPressedColor = Color(0xFF1B2E55); // Darker version of primary
const Color kHoverBg = Color(0xFFD8E2FF); // primaryContainer
const Color kFocusBg = Color(0xFFDBE2F9); // secondaryContainer
const Color kDefaultText = Color(0xFF1A1B20); // onSurface
const Color kDisabledText = Color(0xFF74777F); // outline
const Color kTransparent = Color(0x00000000);
const Color kTransparentLight = Color(0x00FFFFFF);
const Color kBlack = Color(0xFF000000);
const Color kWhite = Color(0xFFFFFFFF);

void main(List<String> args) {
  runApp(
    MaterialApp(
      home: Builder(
        builder: (context) {
          return Zoomer(
            minScale: 1,
            maxScale: 4,
            constrained: true,
            child: Scaffold(
              backgroundColor: Color.fromARGB(255, 255, 255, 255),
              body: Center(child: CustomizedMenu()),
            ),
          );
        },
      ),
    ),
  );
}

/// A menu item that changes its background color when hovered, focused, or pressed.
class MenuItem extends StatelessWidget {
  const MenuItem({
    super.key,
    required this.child,
    required this.onPressed,
    required this.suffix,
  });
  final Widget child;
  final Widget suffix;
  final VoidCallback? onPressed;

  static final WidgetStateProperty<BoxDecoration> decoration =
      WidgetStateProperty.fromMap({
        WidgetState.pressed: BoxDecoration(border: Border.all(width: 2)),
        WidgetState.focused: BoxDecoration(border: Border.all(width: 1.5)),
        WidgetState.hovered: BoxDecoration(border: Border.all()),
        WidgetState.any: BoxDecoration(color: const Color(0x00000000)),
      });

  @override
  Widget build(BuildContext context) {
    final Widget body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Row(
        spacing: 12,
        mainAxisAlignment: .spaceBetween,
        children: [child, suffix],
      ),
    );

    return BaseMenuItem(
      role: null,
      onPressed: onPressed,
      child: Builder(
        builder: (context) {
          // Rebuilds any time any states changes (hovered, focused, pressed,
          // disabled).
          return DecoratedBox(
            decoration: decoration.resolve(BaseMenuItem.statesOf(context)),
            child: body,
          );
        },
      ),
    );
  }
}

/// Rebuilds when a pointer enters or exits its menu item ancestor.
class Suffix extends StatelessWidget {
  const Suffix({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: BaseMenuItem.isHoveredOf(context)
          ? const Color(0xFF445E91)
          : const Color(0xFF000000),
      child: const SizedBox.square(dimension: 20),
    );
  }
}

/// Rebuilds when a pointer enters or exits itself.
class IsolatedSuffix extends StatelessWidget {
  const IsolatedSuffix({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseHoverable(
      child: Builder(
        builder: (context) {
          return ColoredBox(
            color: BaseHoverable.isHoveredOf(context)
                ? const Color(0xFF445E91)
                : const Color(0xFF000000),
            child: const SizedBox.square(dimension: 20),
          );
        },
      ),
    );
  }
}

/// Uses type specialization to prevent state collisions with other
/// [BaseHoverable] instances and avoid leaking [BaseHoverable] implementation
/// details.
class SpecializedSuffix extends StatelessWidget {
  const SpecializedSuffix({super.key, required this.child});
  final Widget child;

  static bool isHoveredOf(BuildContext context) {
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

class CustomizedMenu extends StatelessWidget {
  const CustomizedMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseMenuPanel(
      spacing: 24,
      children: [
        Row(
          spacing: 12,
          mainAxisAlignment: .start,
          children: [
            Checkbox(child: WebkitCheckbox(checkmark: _WebkitCheckmark())),
            Text(
              'Webkit',
              style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
            ),
          ],
        ),
        Row(
          spacing: 12,
          mainAxisAlignment: .start,
          children: [
            Checkbox(child: BlinkCheckbox(checkmark: BlinkCheckmark())),
            Text(
              'Blink',
              style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
            ),
          ],
        ),
        BaseControl(
          onPressed: () {},
          child: Builder(
            builder: (context) {
              return Container(
                decoration: BoxDecoration(
                  color: kHoverBg,

                  border: Border.all(
                    color: BaseControl.isFocusedOf(context)
                        ? const Color(0xFF2B4678)
                        : const Color(0x00000000),
                    width: 2,
                  ),
                ),
                alignment: .center,
                padding: const EdgeInsets.all(8),
                child: Text(
                  "Before",
                  style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
                ),
              );
            },
          ),
        ),
        MenuItemDemo(),
        BaseControl(
          onPressed: () {},
          child: Builder(
            builder: (context) {
              return Container(
                decoration: BoxDecoration(
                  color: kHoverBg,

                  border: Border.all(
                    color: BaseControl.isFocusedOf(context)
                        ? const Color(0xFF2B4678)
                        : const Color(0x00000000),
                    width: 2,
                  ),
                ),
                alignment: .center,
                padding: const EdgeInsets.all(8),
                child: Text(
                  "After",
                  style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
                ),
              );
            },
          ),
        ),
        FocusRectangle(
          child: HoverRectangle(
            child: Builder(
              builder: (context) {
                return Text(
                  BaseFocusable.isFocusedOf(context) ? '😸' : '😾',
                  style: const TextStyle(fontSize: 32),
                );
              },
            ),
          ),
        ),
        BaseControl(
          onPressed: () {},
          child: Builder(
            builder: (context) {
              return Container(
                decoration: BoxDecoration(
                  color: kHoverBg,

                  border: Border.all(
                    color: BaseControl.isFocusedOf(context)
                        ? const Color(0xFF2B4678)
                        : const Color(0x00000000),
                    width: 2,
                  ),
                ),
                alignment: .center,

                padding: const EdgeInsets.all(8),
                child: Text(
                  "After",
                  style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
                ),
              );
            },
          ),
        ),
        HoverRectangle(),
        MenuItem(
          onPressed: () {},
          suffix: const IsolatedSuffix(),
          child: const Text('Isolated'),
        ),
        MenuItem(
          onPressed: () {},
          suffix: SpecializedSuffix(
            child: Builder(
              builder: (context) {
                return ColoredBox(
                  color: SpecializedSuffix.isHoveredOf(context)
                      ? const Color(0xFF445E91)
                      : const Color(0xFF000000),
                );
              },
            ),
          ),
          child: const Text('Specialized'),
        ),
      ],
    );
  }
}

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

class Checkbox extends StatefulWidget {
  const Checkbox({
    super.key,
    required this.child,
    this.width = 14,
    this.height = 14,
  });

  final Widget child;
  final double width;
  final double height;

  static bool isPressedOf(BuildContext context) =>
      BaseControl.isPressedOf<_CheckboxState>(context);

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
      width: widget.width,
      height: widget.height,
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

class _CheckboxScope extends InheritedWidget {
  const _CheckboxScope({required super.child, required this.isChecked});
  final bool isChecked;

  @override
  bool updateShouldNotify(_CheckboxScope oldWidget) {
    return oldWidget.isChecked != isChecked;
  }
}

class BlinkCheckbox extends StatelessWidget {
  const BlinkCheckbox({super.key, required this.checkmark});
  final Widget checkmark;

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
      child: states.contains(WidgetState.selected) ? checkmark : null,
    );
  }
}

class BlinkCheckmark extends StatelessWidget {
  const BlinkCheckmark({super.key});

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

class WebkitCheckbox extends StatelessWidget {
  const WebkitCheckbox({super.key});

  @override
  Widget build(BuildContext context) {
    final states = Checkbox.statesOf(context);
    return CustomPaint(
      painter: _WebkitCheckboxPainter(states: states),
      child: states.contains(WidgetState.selected)
          ? const _WebkitCheckmark()
          : null,
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

// Not used because the Zoomer interferes with scrolling on some devices.
class Zoomer extends StatefulWidget {
  const Zoomer({
    super.key,
    required this.child,
    required this.minScale,
    required this.maxScale,
    required this.constrained,
  });

  final Widget child;
  final double maxScale;
  final double minScale;
  final bool constrained;

  @override
  State<Zoomer> createState() => _ZoomerState();
}

class _ZoomerState extends State<Zoomer> {
  final TransformationController _transformController =
      TransformationController();
  final GlobalKey _viewerKey = GlobalKey();
  final FocusNode _focusNode = FocusNode();
  bool _isPanEnabled = true;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_handleFocusChange);
  }

  @override
  void reassemble() {
    super.reassemble();
    FocusManager.instance.removeListener(_handleFocusChange);
    FocusManager.instance.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    FocusManager.instance.removeListener(_handleFocusChange);
    _transformController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (FocusManager.instance.highlightMode != FocusHighlightMode.traditional) {
      return;
    }

    if (_transformController.value.isIdentity()) {
      return;
    }

    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      return;
    }

    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext == null || !focusContext.mounted || !_focusNode.hasFocus) {
      return;
    }

    final focusedBox = focusContext.findRenderObject() as RenderBox?;
    final viewerBox =
        _viewerKey.currentContext?.findRenderObject() as RenderBox?;

    if (focusedBox == null || viewerBox == null) {
      return;
    }

    if (!focusedBox.hasSize || !viewerBox.hasSize) {
      return;
    }

    final Offset topLeft = focusedBox.localToGlobal(
      const Offset(2, 2),
      ancestor: viewerBox,
    );
    final Offset bottomRight =
        (topLeft & focusedBox.size).bottomRight - const Offset(4, 4);
    final itemRect = Rect.fromPoints(topLeft, bottomRight);
    final Rect viewerRect = Offset.zero & viewerBox.size;

    // Only move if the item is NOT fully visible.
    if (viewerRect.contains(topLeft) || viewerRect.contains(bottomRight)) {
      return;
    }

    // Calculate the Delta required to center the item
    final Offset itemCenter = itemRect.center;
    final Offset viewerCenter = viewerRect.center;
    final Offset delta = viewerCenter - itemCenter;

    // Apply Delta to the Current Translation
    final Vector3 currentTranslationVec = _transformController.value
        .getTranslation();
    final double targetX = currentTranslationVec.x + delta.dx;
    final double targetY = currentTranslationVec.y + delta.dy;

    final double scale = _transformController.value.getMaxScaleOnAxis();

    // Calculate the valid range for translation (x, y)
    // These bounds ensure the viewport is always filled by the content (assuming content >= viewport)
    final double minX = viewerBox.size.width - (viewerBox.size.width * scale);
    const maxX = 0.0;
    final double minY = viewerBox.size.height - (viewerBox.size.height * scale);
    const maxY = 0.0;

    // Clamp the target translation safely handling cases where scale < 1
    final double clampedX = (minX < maxX)
        ? targetX.clamp(minX, maxX)
        : targetX.clamp(maxX, minX);
    final double clampedY = (minY < maxY)
        ? targetY.clamp(minY, maxY)
        : targetY.clamp(maxY, minY);

    _transformController.value = Matrix4.identity()
      ..translateByDouble(clampedX, clampedY, 0, 0)
      ..scaleByDouble(scale, scale, 1.0, 1.0);
  }

  void _handleInteractionEnd(ScaleEndDetails details) {
    final enablePan = !_transformController.value.isIdentity();
    if (_isPanEnabled != enablePan) {
      setState(() {
        _isPanEnabled = enablePan;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      canRequestFocus: false,
      descendantsAreFocusable: true,
      descendantsAreTraversable: true,
      child: SizedBox(
        key: _viewerKey,
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: InteractiveViewer(
          clipBehavior: Clip.none,
          panEnabled: !_isPanEnabled,
          onInteractionEnd: _handleInteractionEnd,
          transformationController: _transformController,
          minScale: widget.minScale,
          maxScale: widget.maxScale,
          constrained: widget.constrained,
          child: widget.child,
        ),
      ),
    );
  }
}
