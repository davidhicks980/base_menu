import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class SequoiaLiquidMenuSurface extends StatelessWidget {
  const SequoiaLiquidMenuSurface({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xA82F3133);
    const borderColor = Color(0x38FFFFFF);
    final physicalPixel = 1.0 / View.of(context).devicePixelRatio;

    return CustomPaint(
      painter: const _ShadowPainter(borderRadius: BorderRadius.all(Radius.circular(16))),
      child: LiquidGlass.withOwnLayer(
        clipBehavior: Clip.antiAlias,
        shape: const LiquidRoundedSuperellipse(borderRadius: 16),
        child: Padding(
          padding: EdgeInsets.all(3.0 * physicalPixel),
          child: CustomPaint(
            painter: _BorderPainter(
              physicalPixel: physicalPixel,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              backgroundColor: backgroundColor,
              outerColor: Colors.black,
              color: borderColor,
            ),
            child: child,
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

    // final backgroundPaint = Paint()
    //   ..color = backgroundColor
    //   ..style = PaintingStyle.fill;
    // canvas.drawRRect(outerRRect, backgroundPaint);

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
