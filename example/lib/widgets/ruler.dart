import 'dart:math' as math;
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../app_state_manager.dart';
import '../model/enum.dart';
import '../model/intents.dart';
import '../utilities/colors.dart';

const double pixelsPerInch = 96.0;
const double pixelsPerTick = pixelsPerInch / 8.0;
final lightPaint = Paint()
  ..color = FloogleColors.separatorColor
  ..style = PaintingStyle.stroke
  ..isAntiAlias = false
  ..strokeWidth = 1.0;

final darkPaint = Paint()
  ..color = FloogleColors.greyOutline
  ..style = PaintingStyle.stroke
  ..isAntiAlias = false
  ..strokeWidth = 1.0;

final textPainter = TextPainter(textDirection: TextDirection.ltr);

const tickSize = 4.0;
const mediumTickSize = 6.0;
const longTickSize = 8.0;

/// Returns the nearest multiple of `to` to `value`.
double _quantize(double value, {required double to}) {
  if (to == 0) {
    return value;
  }
  return (value / to).round() * to;
}

class HorizontalDocumentRuler extends StatelessWidget {
  const HorizontalDocumentRuler({super.key, this.pageWidth = pixelsPerInch * 8.5});

  final double pageWidth;

  @override
  Widget build(BuildContext context) {
    var totalLDelta = 0.0;
    var totalRDelta = 0.0;

    final double totalWidth = MediaQuery.widthOf(context);
    final double pageStart =
        ui.clampDouble(totalWidth - pageWidth + 16, 160.0, math.max(totalWidth, 161)) / 2;

    final double leftMargin =
        AppStateManager.documentStateOf(context)[SelectionKey.leftMargin] as double? ??
        pixelsPerInch;

    final double rightMargin =
        AppStateManager.documentStateOf(context)[SelectionKey.rightMargin] as double? ??
        pixelsPerInch;

    final double minimumRightMargin = pageWidth - leftMargin - 2 * pixelsPerInch;
    final double minimumLeftMargin = pageWidth - rightMargin - 2 * pixelsPerInch;
    return SizedBox(
      height: 24,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RulerPainter(
                pageWidth: pageWidth,
                leftMargin: leftMargin,
                rightMargin: rightMargin,
              ),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: pageStart,
            width: math.max(leftMargin, pixelsPerTick * 2),
            child: BaseHoverable(
              mouseCursor: SystemMouseCursors.resizeRight,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  totalLDelta += details.delta.dx;
                  final quantized = _quantize(totalLDelta + leftMargin, to: pixelsPerTick);
                  if (quantized != leftMargin) {
                    final value = ui.clampDouble(quantized, 0.0, minimumLeftMargin);
                    Actions.maybeInvoke(context, SetDocumentLeftMarginIntent(value));
                  }
                },
                child: const ColoredBox(color: Color(0x00000000)),
              ),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: pageStart + pageWidth - math.max(rightMargin, pixelsPerTick * 2),
            width: math.max(rightMargin, pixelsPerTick * 2),
            child: BaseHoverable(
              mouseCursor: SystemMouseCursors.resizeLeft,
              child: GestureDetector(
                onHorizontalDragUpdate: (DragUpdateDetails details) {
                  totalRDelta -= details.delta.dx;
                  final quantized = _quantize(totalRDelta + rightMargin, to: pixelsPerTick);
                  if (quantized != rightMargin) {
                    final value = ui.clampDouble(quantized, 0.0, minimumRightMargin);
                    Actions.maybeInvoke(context, SetDocumentRightMarginIntent(value));
                  }
                },
                child: const ColoredBox(color: Color(0x00000000)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({required this.pageWidth, required this.leftMargin, required this.rightMargin});

  final double pageWidth;
  final double leftMargin;
  final double rightMargin;

  @override
  void paint(Canvas canvas, Size size) {
    final double totalWidth = size.width;
    final double pageStart =
        clampDouble(totalWidth - pageWidth + 16, 160.0, max(totalWidth, 161)) / 2;
    final double pageEnd = pageStart + pageWidth;

    final int startTick = (-leftMargin / pixelsPerTick).ceil();
    final int endTick = ((pageEnd - pageStart - leftMargin) / pixelsPerTick).floor();

    for (var i = startTick; i <= endTick; i++) {
      double xOffset = pageStart + leftMargin + (i * pixelsPerTick);

      assert(
        xOffset >= pageStart && xOffset <= pageEnd,
        'xOffset out of bounds: $xOffset not in [$pageStart, $pageEnd]',
      );

      final bool isRightOfMargin = xOffset >= pageEnd - rightMargin;
      final tickInchIndex = i % 8;
      final tickHeight = tickInchIndex == 4 ? longTickSize : tickSize;
      final tickPaint = i <= 0 || isRightOfMargin ? darkPaint : lightPaint;

      if (i == startTick) {
        xOffset += 0.5; // Adjust the first tick to align with the edge of the page
      } else if (i == endTick) {
        xOffset -= 0.5; // Adjust the last tick to align with the edge of the page
      }

      canvas.drawLine(
        Offset(xOffset, size.height - tickHeight),
        Offset(xOffset, size.height),
        tickPaint,
      );

      if (tickInchIndex == 0) {
        final int inchNum = (i / 8).round().abs();
        if (inchNum == 0) {
          continue;
        }

        textPainter.text = TextSpan(
          text: '$inchNum',
          style: const TextStyle(
            color: FloogleColors.grey,
            fontSize: 11,
            fontWeight: kIsWeb ? FontWeight.w500 : FontWeight.w400,
            fontFamily: 'GoogleSansCode',
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(xOffset - textPainter.width / 2 - 0.5, 6));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) =>
      oldDelegate.pageWidth != pageWidth ||
      oldDelegate.leftMargin != leftMargin ||
      oldDelegate.rightMargin != rightMargin;
}

class VerticalDocumentRuler extends StatelessWidget {
  const VerticalDocumentRuler({super.key, this.pageHeight = pixelsPerInch * 11});
  final double pageHeight;

  @override
  Widget build(BuildContext context) {
    var totalTDelta = 0.0;
    var totalBDelta = 0.0;
    final double topMargin =
        AppStateManager.documentStateOf(context)[SelectionKey.topMargin] as double? ??
        pixelsPerInch;
    final double bottomMargin =
        AppStateManager.documentStateOf(context)[SelectionKey.bottomMargin] as double? ??
        pixelsPerInch;

    final double minimumBottomMargin = pageHeight - topMargin - 2 * pixelsPerInch;
    final double minimumTopMargin = pageHeight - bottomMargin - 2 * pixelsPerInch;
    return SizedBox(
      width: 16,
      height: pageHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _VerticalRulerPainter(
                pageHeight: pageHeight,
                topMargin: topMargin,
                bottomMargin: bottomMargin,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: math.max(bottomMargin, pixelsPerTick * 2),
            child: BaseHoverable(
              mouseCursor: SystemMouseCursors.resizeUp,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  totalBDelta -= details.delta.dy;
                  final quantized = _quantize(totalBDelta + bottomMargin, to: pixelsPerTick);
                  if (quantized != bottomMargin) {
                    final value = ui.clampDouble(quantized, 0.0, minimumBottomMargin);
                    Actions.maybeInvoke(context, SetDocumentBottomMarginIntent(value));
                  }
                },
                child: const ColoredBox(color: Color(0x0ff00000)),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: math.max(topMargin, pixelsPerTick * 2),
            child: BaseHoverable(
              mouseCursor: SystemMouseCursors.resizeDown,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  totalTDelta += details.delta.dy;
                  final quantized = _quantize(totalTDelta + topMargin, to: pixelsPerTick);
                  if (quantized != topMargin) {
                    final value = ui.clampDouble(quantized, 0.0, minimumTopMargin);
                    Actions.maybeInvoke(context, SetDocumentTopMarginIntent(value));
                  }
                },
                child: const ColoredBox(color: Color(0x0ff00000)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalRulerPainter extends CustomPainter {
  const _VerticalRulerPainter({
    required this.pageHeight,
    required this.topMargin,
    required this.bottomMargin,
  });

  final double pageHeight;
  final double topMargin;
  final double bottomMargin;

  @override
  void paint(Canvas canvas, Size size) {
    final double pageStart = clampDouble(size.height - pageHeight, 0, size.height) / 2;
    final double pageEnd = pageStart + pageHeight;
    final int startTick = (-topMargin / pixelsPerTick).ceil();
    final int endTick = ((pageEnd - pageStart - topMargin) / pixelsPerTick).floor();

    for (var i = startTick; i <= endTick; i++) {
      double yOffset = pageStart + topMargin + (i * pixelsPerTick);
      assert(
        yOffset >= pageStart && yOffset <= pageEnd,
        'yOffset out of bounds: $yOffset not in [$pageStart, $pageEnd]',
      );

      final bool isBelowBottomMargin = yOffset >= pageEnd - bottomMargin;
      final tickInchIndex = i % 8;
      final tickWidth = tickInchIndex == 4 ? mediumTickSize : tickSize;

      // Use darkPaint for ticks above the zero mark or below the bottom margin else use paint
      final tickPaint = i <= 0 || isBelowBottomMargin ? darkPaint : lightPaint;

      if (i == startTick) {
        yOffset += 0.5; // Adjust the first tick to align with the edge of the page
      } else if (i == endTick) {
        yOffset -= 0.5; // Adjust the last tick to align with the edge of the page
      }

      canvas.drawLine(
        Offset(size.width - tickWidth, yOffset),
        Offset(size.width, yOffset),
        tickPaint,
      );

      if (tickInchIndex == 0) {
        final int inchNum = (i / 8).round().abs();
        if (inchNum == 0) {
          continue;
        }

        textPainter.text = TextSpan(
          text: '$inchNum',
          style: const TextStyle(
            color: FloogleColors.grey,
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
  bool shouldRepaint(_VerticalRulerPainter oldDelegate) {
    return oldDelegate.pageHeight != pageHeight ||
        oldDelegate.topMargin != topMargin ||
        oldDelegate.bottomMargin != bottomMargin;
  }
}
