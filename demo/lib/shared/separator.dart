import 'package:flutter/widgets.dart';

class Separator extends StatelessWidget {
  const Separator.horizontal({super.key, required this.color, required this.thickness})
    : orientation = Axis.horizontal;
  const Separator.vertical({super.key, required this.color, required this.thickness})
    : orientation = Axis.vertical;
  final Axis orientation;
  final Color color;
  final int thickness;

  @override
  Widget build(BuildContext context) {
    return PhysicalPixelDivider(
      orientation: orientation,
      color: color,
      thickness: thickness,
      crossAxisExtent: thickness.toDouble(),
      indent: 0,
      endIndent: 0,
    );
  }
}

class PhysicalPixelDivider extends StatelessWidget {
  const PhysicalPixelDivider({
    super.key,
    required this.orientation,
    required this.color,
    required this.thickness,
    required this.crossAxisExtent,
    required this.indent,
    required this.endIndent,
  });

  final Axis orientation;
  final Color color;
  final int thickness;
  final double crossAxisExtent;
  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    final double pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return SizedBox(
      width: orientation == Axis.vertical ? crossAxisExtent : double.infinity,
      height: orientation == Axis.horizontal ? crossAxisExtent : double.infinity,
      child: CustomPaint(
        painter: _PixelSnapPainter(
          orientation: orientation,
          color: color,
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
    required this.orientation,
    required this.color,
    required this.thickness,
    required this.indent,
    required this.endIndent,
    required this.pixelRatio,
  });

  final Axis orientation;
  final Color color;
  final int thickness;
  final double indent;
  final double endIndent;
  final double pixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;

    final double logicalThickness = thickness / pixelRatio;

    if (orientation == Axis.horizontal) {
      // Horizontal line: Indent affects the X axis (left/right)
      final double top = ((size.height * pixelRatio - thickness) / 2.0).round() / pixelRatio;
      canvas.drawRect(
        Rect.fromLTWH(indent, top, size.width - indent - endIndent, logicalThickness),
        paint,
      );
    } else {
      // Vertical line: Indent affects the Y axis (top/bottom)
      final double left = ((size.width * pixelRatio - thickness) / 2.0).round() / pixelRatio;
      canvas.drawRect(
        Rect.fromLTWH(left, indent, logicalThickness, size.height - indent - endIndent),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PixelSnapPainter old) =>
      old.color != color ||
      old.pixelRatio != pixelRatio ||
      old.orientation != orientation ||
      old.indent != indent ||
      old.endIndent != endIndent;
}
