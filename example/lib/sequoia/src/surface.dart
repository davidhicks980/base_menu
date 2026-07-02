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

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color.fromARGB(191, 50, 50, 50);
    const borderColor = Color(0x38FFFFFF);
    final physicalPixel = 1.0 / View.of(context).devicePixelRatio;

    return CustomPaint(
      painter: _ShadowPainter(borderRadius: borderRadius),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          blendMode: kIsWeb ? .src : .srcOver,
          filterConfig: const .blur(sigmaX: 20.0, sigmaY: 20.0),
          child: Padding(
            // Add 3 physical pixels of padding to ensure the border is not
            // clipped
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

    // Matches SequoiaMenuSurface opacity logic
    const mainOpacity = 0.35;
    const edgeOpacity = 0.1;

    // The mask: A large rectangle with the menu shape cut out.
    // This stops the shadow from being painted underneath the translucent menu.
    final maskPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect.inflate(100.0)) // Enough room for the 20px blur
      ..addRRect(rrect);

    canvas.save();
    canvas.clipPath(maskPath);

    // 1. REPLICATE: BoxShadow(blurRadius: 20.0, offset: Offset(0, 10))
    // Note: sigma = blurRadius / 2
    final mainShadowPaint = Paint()
      ..color = Colors.black.withOpacity(mainOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);

    canvas.drawRRect(rrect.shift(const Offset(0, 10.0)), mainShadowPaint);

    // 2. REPLICATE: BoxShadow(blurRadius: 1.0, spreadRadius: 1.0)
    final edgeShadowPaint = Paint()
      ..color = Colors.black.withOpacity(edgeOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);

    canvas.drawRRect(rrect.inflate(1.0), edgeShadowPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShadowPainter oldDelegate) => oldDelegate.borderRadius != borderRadius;
}
