import 'package:flutter/widgets.dart';

class CupertinoMenuDivider extends StatelessWidget {
  const CupertinoMenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: PhysicalPixelDivider(thickness: 2, crossAxisExtent: 10, indent: 10, endIndent: 10),
    );
  }
}

class PhysicalPixelDivider extends StatelessWidget {
  const PhysicalPixelDivider({
    super.key,
    required this.thickness,
    required this.crossAxisExtent,
    required this.indent,
    required this.endIndent,
  });

  final int thickness;
  final double crossAxisExtent;
  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    final double pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return SizedBox(
      height: crossAxisExtent,
      width: double.infinity,
      child: CustomPaint(
        painter: _PixelSnapPainter(
          thickness: thickness,
          indent: indent,
          endIndent: endIndent,
          pixelRatio: pixelRatio,
        ),
      ),
    );
  }
}

class _PixelSnapPainter extends CustomPainter {
  const _PixelSnapPainter({
    required this.thickness,
    required this.indent,
    required this.endIndent,
    required this.pixelRatio,
  });

  final int thickness;
  final double indent;
  final double endIndent;
  final double pixelRatio;

  static const Color kOverlayColor = Color.fromRGBO(255, 255, 255, 0.14);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kOverlayColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = false;

    // final overlayPaint = Paint()
    //   ..color = kOverlayColor
    //   ..style = PaintingStyle.fill
    //   ..blendMode = BlendMode.overlay
    //   ..isAntiAlias = false;

    final double logicalThickness = thickness / pixelRatio;

    // Vertical line: Indent affects the Y axis (top/bottom)
    final double top = ((size.height * pixelRatio - thickness) / 2.0).round() / pixelRatio;
    final rect = Rect.fromLTWH(indent, top, size.width - indent - endIndent, logicalThickness);

    // canvas.drawRect(rect, overlayPaint);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_PixelSnapPainter old) {
    return old.pixelRatio != pixelRatio ||
        old.indent != indent ||
        old.endIndent != endIndent ||
        old.thickness != thickness;
  }
}
