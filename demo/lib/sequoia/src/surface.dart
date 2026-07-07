import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SequoiaMenuSurface extends StatelessWidget {
  const SequoiaMenuSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(6.0)),
  });

  final Widget child;
  final BorderRadius borderRadius;

  // The [ColorFilter] matrix used to saturate widgets underlying a
  // [CupertinoPopupSurface] when the ambient [CupertinoThemeData.brightness] is
  // [Brightness.dark].
  //
  // To derive this matrix, the saturation matrix was taken from
  // https://docs.rainmeter.net/tips/colormatrix-guide/ and was tweaked to
  // resemble the iOS 17 simulator.
  //
  // The matrix can be derived from the following function:
  // static List<double> get _darkSaturationMatrix {
  //    const double additive = 0.3;
  //    const double darkLumR = 0.45;
  //    const double darkLumG = 0.8;
  //    const double darkLumB = 0.16;
  //    const double saturation = 1.7;
  //    const double sr = (1 - saturation) * darkLumR;
  //    const double sg = (1 - saturation) * darkLumG;
  //    const double sb = (1 - saturation) * darkLumB;
  //    return <double>[
  //      sr + saturation, sg, sb, 0.0, additive,
  //      sr, sg + saturation, sb, 0.0, additive,
  //      sr, sg, sb + saturation, 0.0, additive,
  //      0.0, 0.0, 0.0, 1.0, 0.0,
  //    ];
  //  }
  static const List<double> _darkSaturationMatrix = <double>[
    1.39,
    -0.56,
    -0.11,
    0.00,
    0.30,
    -0.32,
    1.14,
    -0.11,
    0.00,
    0.30,
    -0.32,
    -0.56,
    1.59,
    0.00,
    0.30,
    0.00,
    0.00,
    0.00,
    1.00,
    0.00,
  ];

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xA82F3133);
    const borderColor = Color(0x38FFFFFF);
    final physicalPixel = 1.0 / View.of(context).devicePixelRatio;

    return CustomPaint(
      painter: _ShadowPainter(borderRadius: borderRadius),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          blendMode: kIsWeb ? .src : .srcOver,
          filterConfig: const ImageFilterConfig.compose(
            inner: ImageFilterConfig(ColorFilter.matrix(_darkSaturationMatrix)),
            outer: ImageFilterConfig.blur(sigmaX: 20, sigmaY: 20),
          ),
          child: Padding(
            padding: EdgeInsets.all(3.0 * physicalPixel),
            child: CustomPaint(
              painter: _BorderPainter(
                physicalPixel: physicalPixel,
                borderRadius: borderRadius,
                backgroundColor: backgroundColor,
                outerColor: Colors.black,
                color: borderColor,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _BorderPainter extends CustomPainter {
  const _BorderPainter({
    required this.physicalPixel,
    required this.borderRadius,
    required this.outerColor,
    required this.color,
    required this.backgroundColor,
  });
  final double physicalPixel;
  final BorderRadius borderRadius;
  final Color outerColor;
  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 3.0 * physicalPixel;
    final outerRRect = borderRadius.toRRect(
      Rect.fromLTWH(-padding, -padding, size.width + 2 * padding, size.height + 2 * padding),
    );

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(outerRRect, backgroundPaint);

    final innerBorderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = physicalPixel * 2
      ..isAntiAlias = false;
    canvas.drawRRect(outerRRect.deflate(2.0 * physicalPixel), innerBorderPaint);

    final outerBorderPaint = Paint()
      ..color = outerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = physicalPixel
      ..isAntiAlias = false;
    canvas.drawRRect(outerRRect.deflate(0.5 * physicalPixel), outerBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _BorderPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.color != color ||
      oldDelegate.outerColor != outerColor ||
      oldDelegate.backgroundColor != backgroundColor;
}

class _ShadowPainter extends CustomPainter {
  const _ShadowPainter({required this.borderRadius});

  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    const mainOpacity = 0.35;
    const edgeOpacity = 0.1;

    final maskPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect.inflate(100.0))
      ..addRRect(rrect);

    canvas.save();
    canvas.clipPath(maskPath);

    final mainShadowPaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: mainOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);

    canvas.drawRRect(rrect.shift(const Offset(0, 10.0)), mainShadowPaint);

    final edgeShadowPaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: edgeOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);

    canvas.drawRRect(rrect.inflate(1.0), edgeShadowPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShadowPainter oldDelegate) => oldDelegate.borderRadius != borderRadius;
}
