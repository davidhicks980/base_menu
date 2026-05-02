import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../utilities/colors.dart';

class HorizontalDocumentRuler extends StatelessWidget {
  const HorizontalDocumentRuler({super.key, this.pageWidth = 96 * 8.5, this.margin = 0.0});

  final double pageWidth;
  final double margin;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      width: double.infinity,
      child: CustomPaint(
        painter: _RulerPainter(pageWidth: pageWidth, margin: margin),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({required this.pageWidth, required this.margin});

  final double pageWidth;
  final double margin;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FloogleColors.separatorColor
      ..style = PaintingStyle.stroke
      ..isAntiAlias = false
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final double totalWidth = size.width;
    final double pageStart =
        clampDouble(totalWidth - pageWidth + 16, 160.0, max(totalWidth, 161)) / 2;
    final double pageEnd = pageStart + pageWidth;
    const pxPerInch = 96.0;
    final contentStart = pageStart;
    final double contentWidth = pageWidth;
    final int numInches = (contentWidth / pxPerInch).ceil() + 1;

    for (var i = 0; i <= numInches * 8; i++) {
      final double xOffset = contentStart + (i * pxPerInch / 8) + (i == 0 ? 0.5 : -0.5);
      if (xOffset < pageStart || xOffset > pageEnd) {
        continue;
      }

      final isInch = i % 8 == 0;
      final isHalfInch = i % 4 == 0;
      final tickHeight = isInch
          ? 6.0
          : isHalfInch
          ? 10.0
          : 4.0;

      canvas.drawLine(
        Offset(xOffset, size.height - tickHeight),
        Offset(xOffset, size.height),
        paint,
      );

      if (isInch) {
        final int inchNum = i ~/ 8;
        textPainter.text = TextSpan(
          text: '$inchNum',
          style: const TextStyle(
            color: FloogleColors.rulerTextColor,
            fontSize: 11,
            fontWeight: kIsWeb ? FontWeight.w500 : FontWeight.w400,

            fontFamily: 'GoogleSansCode',
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(xOffset - textPainter.width / 2, 6));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) =>
      oldDelegate.pageWidth != pageWidth || oldDelegate.margin != margin;
}

class VerticalDocumentRuler extends StatelessWidget {
  const VerticalDocumentRuler({super.key, this.pageHeight = 96 * 11, this.margin = 0.0});

  final double pageHeight;
  final double margin;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: pageHeight,
      child: CustomPaint(
        painter: _VerticalRulerPainter(pageHeight: pageHeight, margin: margin),
      ),
    );
  }
}

class _VerticalRulerPainter extends CustomPainter {
  _VerticalRulerPainter({required this.pageHeight, required this.margin});

  final double pageHeight;
  final double margin;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FloogleColors.separatorColor
      ..style = PaintingStyle.stroke
      ..isAntiAlias = false
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final double totalHeight = size.height;
    final double pageStart = clampDouble(totalHeight - pageHeight, 0, totalHeight) / 2;
    final double pageEnd = pageStart + pageHeight;

    const pxPerInch = 96.0;
    final contentStart = pageStart;
    final double contentHeight = pageHeight;
    final int numInches = (contentHeight / pxPerInch).ceil() + 1;

    for (var i = 0; i <= numInches * 8; i++) {
      final double yOffset = contentStart + (i * pxPerInch / 8);
      if (yOffset < pageStart || yOffset > pageEnd) {
        continue;
      }

      final isInch = i % 8 == 0;
      final isHalfInch = i % 4 == 0;
      final tickWidth = isInch
          ? 4.0
          : isHalfInch
          ? 6.0
          : 4.0;

      canvas.drawLine(Offset(size.width - tickWidth, yOffset), Offset(size.width, yOffset), paint);

      if (isInch) {
        final int inchNum = i ~/ 8;
        textPainter.text = TextSpan(
          text: '$inchNum',
          style: const TextStyle(
            color: FloogleColors.rulerTextColor,
            fontSize: 11,
            fontWeight: kIsWeb ? FontWeight.w500 : FontWeight.w400,
            fontFamily: 'GoogleSansCode',
          ),
        );
        textPainter.layout();
        canvas.save();
        canvas.translate(10, yOffset + textPainter.width / 2);
        canvas.rotate(-1.5708);
        textPainter.paint(canvas, Offset(0, -textPainter.height / 1.25));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalRulerPainter oldDelegate) {
    return oldDelegate.pageHeight != pageHeight || oldDelegate.margin != margin;
  }
}
