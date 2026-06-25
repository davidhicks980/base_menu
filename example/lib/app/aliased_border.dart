// ignore_for_file: overridden_fields, unused_element

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

class AliasedBorder extends Border {
  /// Creates a border.
  ///
  /// All the sides of the border default to [BorderSide.none].
  const AliasedBorder({
    this.top = BorderSide.none,
    this.right = BorderSide.none,
    this.bottom = BorderSide.none,
    this.left = BorderSide.none,
  });

  /// Creates a border whose sides are all the same.
  const AliasedBorder.fromBorderSide(BorderSide side)
      : top = side,
        right = side,
        bottom = side,
        left = side;

  /// Creates a border with symmetrical vertical and horizontal sides.
  ///
  /// The `vertical` argument applies to the [left] and [right] sides, and the
  /// `horizontal` argument applies to the [top] and [bottom] sides.
  ///
  /// All arguments default to [BorderSide.none].
  const AliasedBorder.symmetric({
    BorderSide vertical = BorderSide.none,
    BorderSide horizontal = BorderSide.none,
  })  : left = vertical,
        top = horizontal,
        right = vertical,
        bottom = horizontal;

  /// A uniform border with all sides the same color and width.
  ///
  /// The sides default to black solid borders, one logical pixel wide.
  factory AliasedBorder.all({
    Color color = const Color(0xFF000000),
    double width = 1.0,
    BorderStyle style = BorderStyle.solid,
    double strokeAlign = BorderSide.strokeAlignInside,
  }) {
    final BorderSide side = BorderSide(
        color: color, width: width, style: style, strokeAlign: strokeAlign);
    return AliasedBorder.fromBorderSide(side);
  }

  @override
  final BorderSide top;

  /// The right side of this border.
  @override
  final BorderSide right;

  @override
  final BorderSide bottom;

  /// The left side of this border.
  @override
  final BorderSide left;

  /// Creates a [AliasedBorder] that represents the addition of the two given
  /// [AliasedBorder]s.
  ///
  /// It is only valid to call this if [BorderSide.canMerge] returns true for
  /// the pairwise combination of each side on both [AliasedBorder]s.
  static AliasedBorder merge(AliasedBorder a, AliasedBorder b) {
    assert(BorderSide.canMerge(a.top, b.top));
    assert(BorderSide.canMerge(a.right, b.right));
    assert(BorderSide.canMerge(a.bottom, b.bottom));
    assert(BorderSide.canMerge(a.left, b.left));
    return AliasedBorder(
      top: BorderSide.merge(a.top, b.top),
      right: BorderSide.merge(a.right, b.right),
      bottom: BorderSide.merge(a.bottom, b.bottom),
      left: BorderSide.merge(a.left, b.left),
    );
  }

  @override
  EdgeInsetsGeometry get dimensions {
    if (_widthIsUniform) {
      return EdgeInsets.all(top.strokeInset);
    }
    return EdgeInsets.fromLTRB(left.strokeInset, top.strokeInset,
        right.strokeInset, bottom.strokeInset);
  }

  @override
  bool get isUniform =>
      _colorIsUniform &&
      _widthIsUniform &&
      _styleIsUniform &&
      _strokeAlignIsUniform;

  bool get _colorIsUniform {
    final Color topColor = top.color;
    return left.color == topColor &&
        bottom.color == topColor &&
        right.color == topColor;
  }

  bool get _widthIsUniform {
    final double topWidth = top.width;
    return left.width == topWidth &&
        bottom.width == topWidth &&
        right.width == topWidth;
  }

  bool get _styleIsUniform {
    final BorderStyle topStyle = top.style;
    return left.style == topStyle &&
        bottom.style == topStyle &&
        right.style == topStyle;
  }

  bool get _strokeAlignIsUniform {
    final double topStrokeAlign = top.strokeAlign;
    return left.strokeAlign == topStrokeAlign &&
        bottom.strokeAlign == topStrokeAlign &&
        right.strokeAlign == topStrokeAlign;
  }

  Set<Color> _distinctVisibleColors() {
    final Set<Color> distinctVisibleColors = <Color>{};
    if (top.style != BorderStyle.none) {
      distinctVisibleColors.add(top.color);
    }
    if (right.style != BorderStyle.none) {
      distinctVisibleColors.add(right.color);
    }
    if (bottom.style != BorderStyle.none) {
      distinctVisibleColors.add(bottom.color);
    }
    if (left.style != BorderStyle.none) {
      distinctVisibleColors.add(left.color);
    }
    return distinctVisibleColors;
  }

  // [BoxBorder.paintNonUniformBorder] is about 20% faster than [paintBorder],
  // but [paintBorder] is able to draw hairline borders when width is zero
  // and style is [BorderStyle.solid].
  bool get _hasHairlineBorder =>
      (top.style == BorderStyle.solid && top.width == 0.0) ||
      (right.style == BorderStyle.solid && right.width == 0.0) ||
      (bottom.style == BorderStyle.solid && bottom.width == 0.0) ||
      (left.style == BorderStyle.solid && left.width == 0.0);

  @override
  AliasedBorder? add(ShapeBorder other, {bool reversed = false}) {
    if (other is AliasedBorder &&
        BorderSide.canMerge(top, other.top) &&
        BorderSide.canMerge(right, other.right) &&
        BorderSide.canMerge(bottom, other.bottom) &&
        BorderSide.canMerge(left, other.left)) {
      return AliasedBorder.merge(this, other);
    }
    return null;
  }

  @override
  AliasedBorder scale(double t) {
    return AliasedBorder(
      top: top.scale(t),
      right: right.scale(t),
      bottom: bottom.scale(t),
      left: left.scale(t),
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is AliasedBorder) {
      return AliasedBorder.lerp(a, this, t);
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is AliasedBorder) {
      return AliasedBorder.lerp(this, b, t);
    }
    return super.lerpTo(b, t);
  }

  /// Linearly interpolate between two borders.
  ///
  /// If a border is null, it is treated as having four [BorderSide.none]
  /// borders.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static AliasedBorder? lerp(AliasedBorder? a, AliasedBorder? b, double t) {
    if (identical(a, b)) {
      return a;
    }
    if (a == null) {
      return b!.scale(t);
    }
    if (b == null) {
      return a.scale(1.0 - t);
    }
    return AliasedBorder(
      top: BorderSide.lerp(a.top, b.top, t),
      right: BorderSide.lerp(a.right, b.right, t),
      bottom: BorderSide.lerp(a.bottom, b.bottom, t),
      left: BorderSide.lerp(a.left, b.left, t),
    );
  }

  /// Paints the border within the given [Rect] on the given [Canvas].
  ///
  /// Uniform borders and non-uniform borders with similar colors and styles
  /// are more efficient to paint than more complex borders.
  ///
  /// You can provide a [BoxShape] to draw the border on. If the `shape` in
  /// [BoxShape.circle], there is the requirement that the border has uniform
  /// color and style.
  ///
  /// If you specify a rectangular box shape ([BoxShape.rectangle]), then you
  /// may specify a [BorderRadius]. If a `borderRadius` is specified, there is
  /// the requirement that the border has uniform color and style.
  ///
  /// The [getInnerPath] and [getOuterPath] methods do not know about the
  /// `shape` and `borderRadius` arguments.
  ///
  /// The `textDirection` argument is not used by this paint method.
  ///
  /// See also:
  ///
  ///  * [paintBorder], which is used if the border has non-uniform colors or styles and no borderRadius.
  ///  * <https://pub.dev/packages/non_uniform_border>, a package that implements
  ///    a Non-Uniform Border on ShapeBorder, which is used by Material Design
  ///    buttons and other widgets, under the "shape" field.
  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    if (isUniform) {
      switch (top.style) {
        case BorderStyle.none:
          return;
        case BorderStyle.solid:
          switch (shape) {
            case BoxShape.circle:
              assert(borderRadius == null,
                  'A borderRadius cannot be given when shape is a BoxShape.circle.');
              _paintUniformBorderWithCircle(canvas, rect, top);
            case BoxShape.rectangle:
              if (borderRadius != null && borderRadius != BorderRadius.zero) {
                _paintUniformBorderWithRadius(
                  canvas,
                  rect,
                  top,
                  borderRadius,
                );
                return;
              }
              _paintUniformBorderWithRectangle(canvas, rect, top);
          }
          return;
      }
    }

    if (_styleIsUniform && top.style == BorderStyle.none) {
      return;
    }

    // Allow painting non-uniform borders if the visible colors are uniform.
    final Set<Color> visibleColors = _distinctVisibleColors();
    final bool hasHairlineBorder = _hasHairlineBorder;
    // Paint a non uniform border if a single color is visible
    // and (borderRadius is present) or (border is visible and width != 0.0).
    if (visibleColors.length == 1 &&
        !hasHairlineBorder &&
        (shape == BoxShape.circle ||
            (borderRadius != null && borderRadius != BorderRadius.zero))) {
      BoxBorder.paintNonUniformBorder(canvas, rect,
          shape: shape,
          borderRadius: borderRadius,
          textDirection: textDirection,
          top: top.style == BorderStyle.none ? BorderSide.none : top,
          right: right.style == BorderStyle.none ? BorderSide.none : right,
          bottom: bottom.style == BorderStyle.none ? BorderSide.none : bottom,
          left: left.style == BorderStyle.none ? BorderSide.none : left,
          color: visibleColors.first);
      return;
    }

    assert(() {
      if (hasHairlineBorder) {
        assert(borderRadius == null || borderRadius == BorderRadius.zero,
            'A hairline border like `BorderSide(width: 0.0, style: BorderStyle.solid)` can only be drawn when BorderRadius is zero or null.');
      }
      if (borderRadius != null && borderRadius != BorderRadius.zero) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              'A borderRadius can only be given on borders with uniform colors.'),
          ErrorDescription('The following is not uniform:'),
          if (!_colorIsUniform) ErrorDescription('BorderSide.color'),
        ]);
      }
      return true;
    }());
    assert(() {
      if (shape != BoxShape.rectangle) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              'A Border can only be drawn as a circle on borders with uniform colors.'),
          ErrorDescription('The following is not uniform:'),
          if (!_colorIsUniform) ErrorDescription('BorderSide.color'),
        ]);
      }
      return true;
    }());
    assert(() {
      if (!_strokeAlignIsUniform ||
          top.strokeAlign != BorderSide.strokeAlignInside) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              'A Border can only draw strokeAlign different than BorderSide.strokeAlignInside on borders with uniform colors.'),
        ]);
      }
      return true;
    }());

    paintBorder(canvas, rect,
        top: top, right: right, bottom: bottom, left: left);
  }

  static RRect _inflateRRect(RRect rect, EdgeInsets insets) {
    return RRect.fromLTRBAndCorners(
      rect.left - insets.left,
      rect.top - insets.top,
      rect.right + insets.right,
      rect.bottom + insets.bottom,
      topLeft: (rect.tlRadius + Radius.elliptical(insets.left, insets.top))
          .clamp(minimum: Radius.zero),
      topRight: (rect.trRadius + Radius.elliptical(insets.right, insets.top))
          .clamp(minimum: Radius.zero),
      bottomRight:
          (rect.brRadius + Radius.elliptical(insets.right, insets.bottom))
              .clamp(minimum: Radius.zero),
      bottomLeft:
          (rect.blRadius + Radius.elliptical(insets.left, insets.bottom))
              .clamp(minimum: Radius.zero),
    );
  }

  static RRect _deflateRRect(RRect rect, EdgeInsets insets) {
    return RRect.fromLTRBAndCorners(
      rect.left + insets.left,
      rect.top + insets.top,
      rect.right - insets.right,
      rect.bottom - insets.bottom,
      topLeft: (rect.tlRadius - Radius.elliptical(insets.left, insets.top))
          .clamp(minimum: Radius.zero),
      topRight: (rect.trRadius - Radius.elliptical(insets.right, insets.top))
          .clamp(minimum: Radius.zero),
      bottomRight:
          (rect.brRadius - Radius.elliptical(insets.right, insets.bottom))
              .clamp(minimum: Radius.zero),
      bottomLeft:
          (rect.blRadius - Radius.elliptical(insets.left, insets.bottom))
              .clamp(minimum: Radius.zero),
    );
  }

  static void _paintUniformBorderWithCircle(
      Canvas canvas, Rect rect, BorderSide side) {
    assert(side.style != BorderStyle.none);
    final Paint paint = side.toPaint()..isAntiAlias = false;
    final double radius = (rect.shortestSide + side.strokeOffset) / 2;
    canvas.drawCircle(rect.center, radius, paint);
  }

  static void _paintUniformBorderWithRectangle(
      Canvas canvas, Rect rect, BorderSide side) {
    assert(side.style != BorderStyle.none);
    final Paint paint = side.toPaint()..isAntiAlias = false;
    canvas.drawRect(rect.inflate(side.strokeOffset / 2), paint);
  }

  static void _paintUniformBorderWithRadius(
      Canvas canvas, Rect rect, BorderSide side, BorderRadius borderRadius) {
    assert(side.style != BorderStyle.none);
    final Paint paint = Paint()..color = side.color;
    paint.isAntiAlias = false;
    final double width = side.width;
    if (width == 0.0) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.0;
      canvas.drawRRect(borderRadius.toRRect(rect), paint);
    } else {
      final RRect borderRect = borderRadius.toRRect(rect);
      final RRect inner = borderRect.deflate(side.strokeInset);
      final RRect outer = borderRect.inflate(side.strokeOutset);
      canvas.drawDRRect(outer, inner, paint);
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is AliasedBorder &&
        other.top == top &&
        other.right == right &&
        other.bottom == bottom &&
        other.left == left;
  }

  @override
  int get hashCode => Object.hash(top, right, bottom, left);

  @override
  String toString() {
    if (isUniform) {
      return '${objectRuntimeType(this, 'Border')}.all($top)';
    }
    final List<String> arguments = <String>[
      if (top != BorderSide.none) 'top: $top',
      if (right != BorderSide.none) 'right: $right',
      if (bottom != BorderSide.none) 'bottom: $bottom',
      if (left != BorderSide.none) 'left: $left',
    ];
    return '${objectRuntimeType(this, 'Border')}(${arguments.join(", ")})';
  }
}
