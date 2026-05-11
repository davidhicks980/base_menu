import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class MenuAimGeometry {
  Rect? anchorRect;
  Rect? targetRect;
}

class MenuAimScope extends InheritedWidget {
  const MenuAimScope({super.key, required this.enable, required super.child});

  final bool enable;

  @override
  bool updateShouldNotify(MenuAimScope oldWidget) => enable != oldWidget.enable;
}

class MenuAimListener extends StatelessWidget {
  const MenuAimListener({super.key, required this.geometry});
  final MenuAimGeometry geometry;
  static bool visualizeAim = false;

  @override
  Widget build(BuildContext context) {
    return _MenuAimListener(delegate: geometry);
  }
}

/// A widget that uses [_RenderMenuAimListener].
class _MenuAimListener extends LeafRenderObjectWidget {
  const _MenuAimListener({required this.delegate});
  final MenuAimGeometry delegate;

  @override
  _RenderMenuAimListener createRenderObject(BuildContext context) {
    return _RenderMenuAimListener(delegate);
  }

  @override
  void updateRenderObject(BuildContext context, _RenderMenuAimListener renderObject) {
    renderObject.delegate = delegate;
  }
}

class _RenderMenuAimListener extends RenderProxyBoxWithHitTestBehavior {
  _RenderMenuAimListener(this.delegate);
  static const exitDuration = Duration(milliseconds: 300);
  static const int sampleCount = 15;
  final ListQueue<Offset> points = ListQueue(sampleCount);
  MenuAimGeometry delegate;
  bool enabled = true;
  Timer? _exitTimer;

  static bool _isMovingTowardsTarget(Offset start, Offset end, Rect target) {
    final Offset movement = end - start;

    if (movement.distanceSquared < 15.0) {
      return false;
    }

    // Find the nearest point on the target rect to the starting point for better edge tolerance
    final double clampedX = ui.clampDouble(start.dx, target.left, target.right);
    final double clampedY = ui.clampDouble(start.dy, target.top, target.bottom);
    final nearestTargetPoint = Offset(clampedX, clampedY);
    final Offset toTarget = nearestTargetPoint - start;

    // Dot product to check that the pointer is moving towards the target
    final double dotProduct = movement.dx * toTarget.dx + movement.dy * toTarget.dy;
    if (dotProduct <= 0) {
      return false;
    }

    // Verify movement vector falls within the cone formed by the target's corners
    final List<Offset> corners = [
      target.topLeft,
      target.topRight,
      target.bottomLeft,
      target.bottomRight,
    ];

    double minAngleDiff = double.infinity;
    double maxAngleDiff = double.negativeInfinity;
    final double moveDirection = movement.direction;

    for (final corner in corners) {
      final Offset toCorner = corner - start;

      // Normalize angle difference to [-pi, pi]
      double angleDiff = toCorner.direction - moveDirection;
      angleDiff = (angleDiff + math.pi) % (2 * math.pi) - math.pi;

      if (angleDiff < minAngleDiff) {
        minAngleDiff = angleDiff;
      }
      if (angleDiff > maxAngleDiff) {
        maxAngleDiff = angleDiff;
      }
    }

    // If the movement direction is bounded by the outermost angle differences, it is inside the cone
    return minAngleDiff <= 0 && maxAngleDiff >= 0;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (_exitTimer != null) {
      _exitTimer!.cancel();
      _exitTimer = null;
    }

    if (delegate.targetRect == null || delegate.anchorRect == null) {
      return false;
    }

    if (points.length == 15) {
      points.removeFirst();
    }
    points.add(position);

    if (MenuAimListener.visualizeAim) {
      markNeedsPaint();
    }

    if (delegate.anchorRect!.contains(position) || points.length < 2) {
      enabled = true;
      return false;
    }

    if (!enabled) {
      return false;
    }

    final target = delegate.targetRect!;
    if (target.contains(position)) {
      enabled = false;
      return false;
    }

    if (_isMovingTowardsTarget(points.first, points.last, target)) {
      result.add(BoxHitTestEntry(this, position));
      _exitTimer = Timer(exitDuration, () {
        enabled = false;

        // If a pointer is quickly stopped while moving towards the target,
        // hover hit testing may not trigger again after aim is disabled. To
        // mitigate, a synthetic hover event is dispatched after a short delay
        // to ensure the correct menu item is highlighted.
        if (attached) {
          GestureBinding.instance.handlePointerEvent(
            PointerHoverEvent(position: localToGlobal(position), kind: PointerDeviceKind.mouse),
          );
        }
      });
      return true;
    }

    enabled = false;
    return false;
  }

  @override
  void paint(PaintingContext context, ui.Offset offset) {
    super.paint(context, offset);
    if (!enabled || !MenuAimListener.visualizeAim) {
      return;
    }

    final Canvas canvas = context.canvas;
    final Rect? target = delegate.targetRect;
    if (target != null && points.isNotEmpty) {
      // Visualize Dot Product
      if (points.length >= 2) {
        final Offset origin = points.first;
        final Offset p1 = points.last;
        final Offset movement = points.last - points.first;
        final double moveDirection = movement.direction;

        final List<Offset> corners = [
          target.topLeft,
          target.topRight,
          target.bottomLeft,
          target.bottomRight,
        ];

        Offset? minCorner;
        Offset? maxCorner;
        double minAngleDiff = double.infinity;
        double maxAngleDiff = double.negativeInfinity;

        for (final corner in corners) {
          final Offset toCorner = corner - origin;
          double angleDiff = toCorner.direction - moveDirection;
          angleDiff = (angleDiff + math.pi) % (2 * math.pi) - math.pi;

          if (angleDiff < minAngleDiff) {
            minAngleDiff = angleDiff;
            minCorner = corner;
          }
          if (angleDiff > maxAngleDiff) {
            maxAngleDiff = angleDiff;
            maxCorner = corner;
          }
        }

        final conePaint = Paint()
          ..color = const Color(0xFFFF00FF)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

        if (minCorner != null) {
          canvas.drawLine(origin, minCorner, conePaint);
        }
        if (maxCorner != null && maxCorner != minCorner) {
          canvas.drawLine(origin, maxCorner, conePaint);
        }
        final rect = delegate.targetRect!;
        final double clampedX = ui.clampDouble(p1.dx, rect.left, rect.right);
        final double clampedY = ui.clampDouble(p1.dy, rect.top, rect.bottom);
        final nearestTargetPoint = Offset(clampedX, clampedY);

        final Offset toTarget = nearestTargetPoint - p1;
        final double dotProduct = movement.dx * toTarget.dx + movement.dy * toTarget.dy;

        canvas.drawLine(
          p1,
          nearestTargetPoint,
          Paint()
            ..color = const Color(0x880000FF)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke,
        );

        if (movement.distance > 0) {
          final double targetDist = toTarget.distance;
          final double projectionLength = targetDist > 0 ? dotProduct / targetDist : 0.0;

          double lineLength = ui.clampDouble(projectionLength.abs(), 2.0, 300.0);
          Color traitColor;
          if (dotProduct > 0) {
            traitColor = const Color(0xFF00FF00);
            lineLength *= 3;
          } else {
            traitColor = const Color(0xFFFF0000);
          }

          final Offset trajectory = origin + (movement / movement.distance * lineLength);

          // Draw the main trajectory line
          canvas.drawLine(
            origin,
            trajectory,
            Paint()
              ..color = traitColor
              ..strokeWidth = 2.0,
          );

          // Draw an arrowhead at the end of the trajectory
          const arrowSize = 10.0;
          const double arrowAngle = math.pi / 7;

          final double angle = (trajectory - origin).direction;
          final Offset arrowP1 = trajectory - Offset.fromDirection(angle - arrowAngle, arrowSize);
          final Offset arrowP2 = trajectory - Offset.fromDirection(angle + arrowAngle, arrowSize);

          final arrowPaint = Paint()
            ..color = traitColor
            ..strokeWidth = 2.0;

          canvas.drawLine(trajectory, arrowP1, arrowPaint);
          canvas.drawLine(trajectory, arrowP2, arrowPaint);
        }
      }
    }
    return;
  }
}
