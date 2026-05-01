import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../model/model.dart';
import '../../utilities/colors.dart';
import '../tile_group.dart';

class MenuEntryTileGroup<T> extends StatelessWidget {
  const MenuEntryTileGroup({super.key, required this.group});
  final TileGroupMenuEntry<T> group;

  @override
  Widget build(BuildContext context) {
    return TileGroup<T>(
      tileSize: const Size(64, 32),
      tilePadding: const EdgeInsets.all(4),
      value: group.children.first.intent.value,
      onTilePressed: (context, index) {
        final intent = group.children[index].intent;
        Actions.invoke(context, intent);
      },
      columns: group.columns,
      children: [
        for (final item in group.children)
          SizedBox.fromSize(
            size: group.size,
            child: Padding(
              padding: group.padding,
              child: CustomPaint(painter: _TileLinePainter(description: item.tileLines)),
            ),
          ),
      ],
    );
  }
}

class _TileLinePainter extends CustomPainter {
  const _TileLinePainter({required this.description});
  final List<TileLineMenuEntry> description;

  static const double _indentUnit = 16.0;
  static const double gap = 4.0;
  static const double _prefixWidth = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color.fromARGB(255, 203, 203, 203);

    if (description.isEmpty) {
      return;
    }

    final int rowCount = description.length;
    final double rowHeight = size.height / (rowCount + 1);
    final double lineHeight = rowHeight * 0.3;

    for (var i = 0; i < rowCount; i++) {
      final line = description[i];
      final double cy = rowHeight * (i + 1);

      double x = line.indentLevel * _indentUnit;
      final double y = cy - lineHeight / 2;
      final double remainingWidth = size.width - x;
      final double totalGapWidth = gap * (line.columns - 1);
      final double segmentWidth = (remainingWidth - totalGapWidth) / line.columns;
      final double segmentWithGap = segmentWidth + gap;
      for (var col = 0; col < line.columns; col++) {
        final double segX = x + col * segmentWithGap;
        final segRect = Rect.fromLTWH(segX, y, segmentWidth, lineHeight);
        canvas.drawRect(segRect, paint);
        if (description[i].strikeThrough) {
          final strikePaint = Paint()
            ..color = FloogleColors.black
            ..strokeWidth = 1;
          canvas.drawLine(Offset(segX - 2, cy), Offset(segX + segmentWidth + 2, cy), strikePaint);
        }
      }

      if (line.prefix != null) {
        final prefixPaint = Paint()..color = const Color(0xFF000000);
        final rect = Rect.fromCenter(
          center: Offset(x - _prefixWidth * 0.8, cy),
          width: 8,
          height: 8,
        );
        var handled = true;

        switch (line.prefix) {
          case '●':
            canvas.drawCircle(rect.center, 3.5, prefixPaint);
          case '○':
            canvas.drawCircle(
              rect.center,
              3.5,
              prefixPaint
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.66,
            );
          case '◾':
            canvas.drawRect(Rect.fromCenter(center: rect.center, width: 6, height: 6), prefixPaint);
          case '◆':
            final path = Path()
              ..moveTo(rect.center.dx, rect.top)
              ..lineTo(rect.right, rect.center.dy)
              ..lineTo(rect.center.dx, rect.bottom)
              ..lineTo(rect.left, rect.center.dy)
              ..close();
            canvas.drawPath(path, prefixPaint);
          case '➜':
            final path = Path()
              ..moveTo(rect.left, rect.center.dy - 1)
              ..lineTo(rect.center.dx, rect.center.dy - 1)
              ..lineTo(rect.center.dx, rect.top)
              ..lineTo(rect.right, rect.center.dy)
              ..lineTo(rect.center.dx, rect.bottom)
              ..lineTo(rect.center.dx, rect.center.dy + 1)
              ..lineTo(rect.left, rect.center.dy + 1)
              ..close();
            canvas.drawPath(path, prefixPaint);
          case '⮚':
            final topPath = Path()
              ..moveTo(rect.left + 2, rect.center.dy)
              ..lineTo(rect.left, rect.top)
              ..lineTo(rect.right, rect.center.dy)
              ..close();

            canvas.drawPath(topPath, prefixPaint..style = PaintingStyle.fill);

            final bottomPath = Path()
              ..moveTo(rect.left, rect.top)
              ..lineTo(rect.right, rect.center.dy)
              ..lineTo(rect.left, rect.bottom)
              ..lineTo(rect.left + 2, rect.center.dy)
              ..close();

            canvas.drawPath(
              bottomPath,
              prefixPaint
                ..style = PaintingStyle.stroke
                ..strokeJoin = StrokeJoin.round
                ..strokeWidth = 1,
            );
          case '❖':
            canvas.save();
            canvas.translate(rect.center.dx, rect.center.dy);
            canvas.rotate(math.pi / 4);
            const gap = 1.0;
            final half = (rect.width * 0.8 - gap) / 2;

            canvas.drawRect(
              Rect.fromLTWH(-half - gap / 2, -half - gap / 2, half, half),
              prefixPaint,
            );
            canvas.drawRect(Rect.fromLTWH(gap / 2, -half - gap / 2, half, half), prefixPaint);
            canvas.drawRect(Rect.fromLTWH(-half - gap / 2, gap / 2, half, half), prefixPaint);
            canvas.drawRect(Rect.fromLTWH(gap / 2, gap / 2, half, half), prefixPaint);

            canvas.restore();
          case '★':
            canvas.drawPath(_drawStar(rect.center, 5, 4, 2), prefixPaint);
          case '☐':
            canvas.drawRect(
              rect,
              prefixPaint
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.25
                ..strokeJoin = StrokeJoin.round
                ..strokeCap = StrokeCap.round,
            );
          case '☑':
            canvas.drawRect(
              rect,
              prefixPaint
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.25
                ..strokeJoin = StrokeJoin.round
                ..strokeCap = StrokeCap.round,
            );
            final check = Path()
              ..moveTo(rect.center.dx - 2.75, rect.center.dy)
              ..lineTo(rect.center.dx - 0.5, rect.center.dy + 2)
              ..lineTo(rect.center.dx + 2.75, rect.center.dy - 2.5);
            canvas.drawPath(
              check,
              Paint()
                ..color = const Color(0xFF000000)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.2
                ..strokeJoin = StrokeJoin.round,
            );
          default:
            handled = false;
        }

        if (!handled) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: line.prefix,
              style: const TextStyle(
                color: Color(0xFF000000),
                height: 1.0,
                fontFamily: 'RobotoFlex',
                fontSize: 10.0,
                letterSpacing: 1,
                fontWeight: kIsWeb ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout(minWidth: _prefixWidth, maxWidth: 50);
          textPainter.paint(canvas, Offset(x - textPainter.width - 2, cy - textPainter.height / 2));
        }

        x += _prefixWidth + gap;
      }
    }
  }

  Path _drawStar(Offset center, int points, double outerRadius, double innerRadius) {
    final path = Path();
    final double angleStep = math.pi / points;

    for (var i = 0; i < 2 * points; i++) {
      final r = i.isEven ? outerRadius : innerRadius;
      final double angle = i * angleStep - math.pi / 2;
      final double x = center.dx + r * math.cos(angle);
      final double y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_TileLinePainter oldDelegate) {
    return oldDelegate.description != description;
  }
}
