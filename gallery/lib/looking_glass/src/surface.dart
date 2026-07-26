import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class LookingGlassSurface extends StatelessWidget {
  const LookingGlassSurface({super.key});

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color.fromARGB(172, 25, 29, 33);
    final physicalPixel = 1.0 / View.of(context).devicePixelRatio;

    return CustomPaint(
      painter: const _ShadowPainter(borderRadius: BorderRadius.all(Radius.circular(14))),
      child: LiquidGlass.withOwnLayer(
        clipBehavior: Clip.antiAlias,
        settings: const LiquidGlassSettings(highlightColor: Color(0x00000000)),
        shape: const LiquidRoundedSuperellipse(borderRadius: 14),
        child: Padding(
          padding: EdgeInsets.all(3.0 * physicalPixel),
          child: CustomPaint(
            painter: _BorderPainter(
              physicalPixel: physicalPixel,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              backgroundColor: backgroundColor,
              outerColor: Colors.black,
              color: const Color.fromARGB(150, 255, 255, 255),
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
    final rect = Rect.fromLTWH(
      -padding,
      -padding,
      size.width + 2 * padding,
      size.height + 2 * padding,
    );

    final baseRadius = borderRadius.topLeft.x;
    final outerRadius = baseRadius + padding;
    final outerBorderRadius = BorderRadius.all(Radius.circular(outerRadius));
    final outerRRect = outerBorderRadius.toRSuperellipse(rect);

    // Draw background
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRSuperellipse(outerRRect, backgroundPaint);

    // Draw inner border (deflated by 2.0 * physicalPixel)
    _drawHybridBorder(
      canvas: canvas,
      rect: rect.deflate(2.0 * physicalPixel),
      radius: outerRadius - 2.0 * physicalPixel,
      color: color,
      strokeWidth: physicalPixel * 2,
      blendMode: BlendMode.overlay,
    );
    _drawHybridBorder(
      canvas: canvas,
      rect: rect.deflate(2.0 * physicalPixel),
      radius: outerRadius - 2.0 * physicalPixel,
      color: color,
      strokeWidth: physicalPixel * 2,
      blendMode: BlendMode.overlay,
    );

    // Draw outer border (deflated by 0.5 * physicalPixel)
    _drawHybridBorder(
      canvas: canvas,
      rect: rect.deflate(0.5 * physicalPixel),
      radius: outerRadius - 0.5 * physicalPixel,
      color: outerColor,
      strokeWidth: physicalPixel,
    );
  }

  void _drawHybridBorder({
    required Canvas canvas,
    required Rect rect,
    required double radius,
    required Color color,
    required double strokeWidth,
    BlendMode blendMode = BlendMode.srcOver,
  }) {
    final l = rect.left;
    final t = rect.top;
    final r = rect.right;
    final b = rect.bottom;

    // 1. Straight edges (Non-antialiased)
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = false
      ..blendMode = blendMode;

    canvas.drawLine(Offset(l + radius, t), Offset(r - radius, t), linePaint); // Top edge
    canvas.drawLine(Offset(r, t + radius), Offset(r, b - radius), linePaint); // Right edge
    canvas.drawLine(Offset(r - radius, b), Offset(l + radius, b), linePaint); // Bottom edge
    canvas.drawLine(Offset(l, b - radius), Offset(l, t + radius), linePaint); // Left edge

    // 2. Corner arcs (Antialiased)
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.1
      ..isAntiAlias = true
      ..blendMode = blendMode;

    final diameter = radius * 2;

    // Top-Right Corner
    canvas.drawArc(
      Rect.fromLTWH(r - diameter, t, diameter, diameter),
      -math.pi / 2,
      math.pi / 2,
      false,
      arcPaint,
    );
    // Bottom-Right Corner
    canvas.drawArc(
      Rect.fromLTWH(r - diameter, b - diameter, diameter, diameter),
      0,
      math.pi / 2,
      false,
      arcPaint,
    );
    // Bottom-Left Corner
    canvas.drawArc(
      Rect.fromLTWH(l, b - diameter, diameter, diameter),
      math.pi / 2,
      math.pi / 2,
      false,
      arcPaint,
    );
    // Top-Left Corner
    canvas.drawArc(Rect.fromLTWH(l, t, diameter, diameter), math.pi, math.pi / 2, false, arcPaint);
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
    final rrect = borderRadius.toRSuperellipse(rect);

    const mainOpacity = 0.35;
    const edgeOpacity = 0.1;

    final maskPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect.inflate(100.0))
      ..addRSuperellipse(rrect);

    canvas.save();
    canvas.clipPath(maskPath);

    final mainShadowPaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: mainOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);

    canvas.drawRSuperellipse(rrect.shift(const Offset(0, 10.0)), mainShadowPaint);

    final edgeShadowPaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: edgeOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);

    canvas.drawRSuperellipse(rrect.inflate(1.0), edgeShadowPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShadowPainter oldDelegate) => oldDelegate.borderRadius != borderRadius;
}
