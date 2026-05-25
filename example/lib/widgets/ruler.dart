import 'dart:math' as math;
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

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

class HorizontalDocumentRuler extends StatefulWidget {
  const HorizontalDocumentRuler({super.key, this.pageWidth = pixelsPerInch * 8.5});

  final double pageWidth;

  @override
  State<HorizontalDocumentRuler> createState() => _HorizontalDocumentRulerState();
}

class _HorizontalDocumentRulerState extends State<HorizontalDocumentRuler> {
  double totalLDelta = 0.0;
  double totalRDelta = 0.0;
  double firstLineIndentDelta = 0.0;
  double leftIndentDelta = 0.0;
  double rightIndentDelta = 0.0;
  double _initialLeftMargin = 0.0;
  double _initialRightMargin = 0.0;
  double _initialLeftIndent = 0.0;
  double _initialFirstLineIndent = 0.0;
  double _initialRightIndent = 0.0;

  double? _draggingX;

  void _setDraggingX(double? x) {
    if (_draggingX != x) {
      setState(() {
        _draggingX = x;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double totalWidth = MediaQuery.widthOf(context);
    final double pageStart =
        ui.clampDouble(totalWidth - widget.pageWidth + 16, 160.0, math.max(totalWidth, 161)) / 2;

    final double leftMargin =
        AppStateManager.documentStateOf(context)[SelectionKey.leftMargin] as double? ??
        pixelsPerInch;

    final double rightMargin =
        AppStateManager.documentStateOf(context)[SelectionKey.rightMargin] as double? ??
        pixelsPerInch;

    final double leftIndent =
        AppStateManager.documentStateOf(context)[SelectionKey.leftIndent] as double? ?? 0.0;

    final double rightIndent =
        AppStateManager.documentStateOf(context)[SelectionKey.rightIndent] as double? ?? 0.0;

    final double firstLineIndent =
        AppStateManager.documentStateOf(context)[SelectionKey.firstLineIndent] as double? ?? 0.0;

    const double minIndentGap = pixelsPerInch / 2;
    final double maxRightMargin =
        widget.pageWidth - leftMargin - leftIndent - rightIndent - minIndentGap;
    final double minimumRightMargin = math.max(0, maxRightMargin);
    final double maxLeftMargin =
        widget.pageWidth - rightMargin - leftIndent - rightIndent - minIndentGap;
    final double minimumLeftMargin = math.max(0, maxLeftMargin);

    return SizedBox(
      height: double.infinity,
      child: Stack(
        children: [
          SizedBox(
            height: 24,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RulerPainter(
                      pageWidth: widget.pageWidth,
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
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeRight,
                    child: GestureDetector(
                      behavior: .opaque,
                      dragStartBehavior: DragStartBehavior.down,
                      onHorizontalDragStart: (details) {
                        totalLDelta = 0.0;
                        _initialLeftMargin = leftMargin;
                        _setDraggingX(pageStart + math.max(leftMargin, pixelsPerTick * 2));
                      },
                      onHorizontalDragUpdate: (details) {
                        totalLDelta += details.delta.dx;
                        final quantized = _quantize(
                          totalLDelta + _initialLeftMargin,
                          to: pixelsPerTick,
                        );
                        if (quantized != leftMargin) {
                          final value = ui.clampDouble(quantized, 0.0, minimumLeftMargin);
                          Actions.maybeInvoke(context, SetDocumentLeftMarginIntent(value));
                          _setDraggingX(pageStart + value);
                        }
                      },
                      onHorizontalDragEnd: (details) {
                        _setDraggingX(null);
                      },
                      child: const ColoredBox(color: Color(0x00000000)),
                    ),
                  ),
                ),

                // Right Margin Drag Handle
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: pageStart + widget.pageWidth - math.max(rightMargin, pixelsPerTick * 2),
                  width: math.max(rightMargin, pixelsPerTick * 2),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeLeft,
                    child: GestureDetector(
                      dragStartBehavior: DragStartBehavior.down,
                      behavior: .opaque,
                      onHorizontalDragStart: (details) {
                        totalRDelta = 0.0;
                        _initialRightMargin = rightMargin;
                        _setDraggingX(
                          pageStart + widget.pageWidth - math.max(rightMargin, pixelsPerTick * 2),
                        );
                      },
                      onHorizontalDragUpdate: (DragUpdateDetails details) {
                        totalRDelta -= details.delta.dx;
                        final quantized = _quantize(
                          totalRDelta + _initialRightMargin,
                          to: pixelsPerTick,
                        );
                        if (quantized != rightMargin) {
                          final value = ui.clampDouble(quantized, 0.0, minimumRightMargin);
                          Actions.maybeInvoke(context, SetDocumentRightMarginIntent(value));
                          _setDraggingX(pageStart + widget.pageWidth - value);
                        }
                      },
                      onHorizontalDragEnd: (details) {
                        _setDraggingX(null);
                      },
                      child: const ColoredBox(color: Color(0x00000000)),
                    ),
                  ),
                ),

                // Left Indent Drag Handle (triangle)
                Positioned(
                  bottom: 0,
                  left: pageStart + leftMargin + leftIndent - 14,
                  width: 28,
                  height: 10.5,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.basic,
                    child: GestureDetector(
                      behavior: .opaque,
                      dragStartBehavior: .down,
                      onHorizontalDragStart: (DragStartDetails details) {
                        leftIndentDelta = 0.0;
                        _initialLeftIndent = leftIndent;
                        _setDraggingX(pageStart + leftMargin + leftIndent);
                      },
                      onHorizontalDragUpdate: (details) {
                        leftIndentDelta += details.delta.dx;
                        final quantized = _quantize(
                          leftIndentDelta + _initialLeftIndent,
                          to: pixelsPerTick,
                        );

                        if (quantized != leftIndent) {
                          final double maxLeftIndent =
                              widget.pageWidth -
                              leftMargin -
                              rightMargin -
                              rightIndent -
                              minIndentGap;

                          final value = ui.clampDouble(quantized, 0.0, math.max(0, maxLeftIndent));

                          Actions.maybeInvoke(context, SetParagraphLeftIndentIntent(value));
                          _setDraggingX(pageStart + leftMargin + value);
                        }
                      },
                      onHorizontalDragEnd: (details) {
                        _setDraggingX(null);
                      },

                      child: CustomPaint(painter: _ParagraphIndentHandlePainter()),
                    ),
                  ),
                ),

                // First Line Indent Handle (rectangle)
                Positioned(
                  bottom: 10.5,
                  left: pageStart + leftMargin + firstLineIndent - 14,
                  width: 28,
                  height: 16,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.basic,
                    child: GestureDetector(
                      behavior: .opaque,

                      dragStartBehavior: DragStartBehavior.down,
                      onHorizontalDragStart: (DragStartDetails details) {
                        firstLineIndentDelta = 0.0;
                        _initialFirstLineIndent = firstLineIndent;
                        _setDraggingX(pageStart + leftMargin + _initialFirstLineIndent);
                      },
                      onHorizontalDragUpdate: (details) {
                        firstLineIndentDelta += details.delta.dx;
                        final quantized = _quantize(
                          firstLineIndentDelta + _initialFirstLineIndent,
                          to: pixelsPerTick,
                        );
                        if (quantized != firstLineIndent) {
                          final double maxFirstLineIndent =
                              widget.pageWidth -
                              leftMargin -
                              rightMargin -
                              rightIndent -
                              minIndentGap;

                          final value = ui.clampDouble(
                            quantized,
                            0.0,
                            math.max(0, maxFirstLineIndent),
                          );

                          Actions.maybeInvoke(context, SetParagraphFirstLineIndentIntent(value));
                          _setDraggingX(pageStart + leftMargin + value);
                        }
                      },
                      onHorizontalDragEnd: (details) {
                        _setDraggingX(null);
                      },
                      child: const CustomPaint(painter: _FirstLineIndentHandlePainter()),
                    ),
                  ),
                ),

                // Right Indent Handle (triangle)
                Positioned(
                  bottom: 0,
                  left: pageStart + widget.pageWidth - rightMargin - rightIndent - 14,
                  width: 28,
                  height: 10.5,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.basic,
                    child: GestureDetector(
                      behavior: .opaque,

                      dragStartBehavior: DragStartBehavior.down,
                      onHorizontalDragStart: (DragStartDetails details) {
                        rightIndentDelta = 0.0;
                        _initialRightIndent = rightIndent;
                        _setDraggingX(pageStart + widget.pageWidth - rightMargin - rightIndent);
                      },
                      onHorizontalDragUpdate: (details) {
                        rightIndentDelta -= details.delta.dx;
                        final quantized = _quantize(
                          rightIndentDelta + _initialRightIndent,
                          to: pixelsPerTick,
                        );
                        if (quantized != rightIndent) {
                          final double maxRightIndent =
                              widget.pageWidth -
                              leftMargin -
                              rightMargin -
                              leftIndent -
                              minIndentGap;

                          final value = ui.clampDouble(quantized, 0.0, math.max(0, maxRightIndent));
                          Actions.maybeInvoke(context, SetParagraphRightIndentIntent(value));
                          _setDraggingX(pageStart + widget.pageWidth - rightMargin - value);
                        }
                      },
                      onHorizontalDragEnd: (details) {
                        _setDraggingX(null);
                      },
                      child: CustomPaint(painter: _ParagraphIndentHandlePainter()),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_draggingX != null)
            Positioned(
              top: 24,
              left: _draggingX! - 0.5,
              width: 1,
              height: MediaQuery.heightOf(context),
              child: const ColoredBox(color: Color(0xFF4285f4), isAntiAlias: false),
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

// Triangle handle painter for the indent
class _ParagraphIndentHandlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4285f4)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, size.height - 4)
      ..lineTo(size.width / 2 - 6, size.height - 10)
      ..lineTo(size.width / 2 + 6, size.height - 10)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ParagraphIndentHandlePainter oldDelegate) => false;
}

class _FirstLineIndentHandlePainter extends CustomPainter {
  const _FirstLineIndentHandlePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4285f4)
      ..style = PaintingStyle.fill;
    // 12 by 4 rect centered horizontally
    final rect = Rect.fromLTWH((size.width - 12) / 2, size.height - 5, 12, 4);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_FirstLineIndentHandlePainter oldDelegate) => false;
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
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeUp,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  totalBDelta -= details.delta.dy;
                  final quantized = _quantize(totalBDelta + bottomMargin, to: pixelsPerTick);
                  if (quantized != bottomMargin) {
                    final value = ui.clampDouble(quantized, 0.0, minimumBottomMargin);
                    Actions.maybeInvoke(context, SetDocumentBottomMarginIntent(value));
                  }
                },
                child: const ColoredBox(color: Color(0x00000000)),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: math.max(topMargin, pixelsPerTick * 2),
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeDown,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  totalTDelta += details.delta.dy;
                  final quantized = _quantize(totalTDelta + topMargin, to: pixelsPerTick);
                  if (quantized != topMargin) {
                    final value = ui.clampDouble(quantized, 0.0, minimumTopMargin);
                    Actions.maybeInvoke(context, SetDocumentTopMarginIntent(value));
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
