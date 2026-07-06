import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

const bool _kEnableMenuAimVisualizer = bool.hasEnvironment('VISUALIZE_MENU_AIM') || kDebugMode;

/// A geometry object that holds the anchor and target rectangles for menu
/// aim assist.
class MenuAimGeometry {
  /// The rectangle of the anchor that the pointer is moving away from.
  Rect? anchorRect;

  /// The rectangle of the target that the pointer is moving towards.
  Rect? targetRect;
}

/// An inherited widget that provides a boolean flag indicating whether menu aim
/// assist is enabled.
///
/// This can be used to conditionally enable or disable menu aim assist behavior for
/// all [BaseMenu] and [BaseSubmenu] descendants in the widget tree.
class MenuAimScope extends InheritedWidget {
  /// Creates a [MenuAimScope] that wraps its child and provides the [enable] flag.
  const MenuAimScope({super.key, required this.enable, required super.child});

  /// A boolean flag indicating whether menu aim assist is enabled.
  ///
  /// When set to `true`, menu aim assist be enabled by default for all
  /// [BaseMenu] and [BaseSubmenu] descendants in the widget tree. When set to
  /// `false`, menu aim assist behavior is disabled.
  final bool enable;

  /// Returns `true` if menu aim assist is enabled in the current context.
  ///
  /// Calling this method establishes a dependency that rebuilds the provided
  /// [BuildContext] whenever [MenuAimScope.enable] changes.
  static bool isEnabledOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MenuAimScope>();
    return scope?.enable ?? false;
  }

  @override
  bool updateShouldNotify(MenuAimScope oldWidget) => enable != oldWidget.enable;
}

/// A widget that intercepts pointer hit-tests when the cursor is moving
/// diagonally from an active menu item towards a submenu.
///
/// It prevents premature submenu closures when the mouse travels diagonally
/// over other sibling menu items on its way to the submenu
/// [MenuAimGeometry.targetRect].
///
/// Under the hood, this widget:
/// 1. Maintains a queue of pointer [Offset]s to calculate path trajectories.
/// 2. Performs a dot-product check to confirm movement is towards the target
///    area.
/// 3. Validates that the cursor falls within an angular cone projected from the
///    movement point to the boundaries of the sub-menu.
/// 4. Intercepts hit-tests to prevent sibling menu items from receiving pointer
///    events until the cursor either enters the target area or exits the cone
///    of movement.
///
/// Set [MenuAimInterceptor.visualizeAim] to `true` to draw the active tracking
/// lines and cone overlays directly on the canvas for visual testing in debug
/// builds.
class MenuAimInterceptor extends StatelessWidget {
  /// Creates a [MenuAimInterceptor] that wraps its child.
  ///
  /// A [MenuAimGeometry] object must be provided to define the anchor and
  /// target rectangles for menu aim assist.
  const MenuAimInterceptor({super.key, required this.geometry});

  /// The geometry object that holds the anchor and target rectangles for menu
  /// aim assist.
  final MenuAimGeometry geometry;

  /// A static flag to enable or disable visualization of the aim assist
  /// behavior. When set to `true`, the widget will draw lines and cones on the
  /// canvas to illustrate the current pointer trajectory and the target area.
  static bool visualizeAim = false;

  @override
  Widget build(BuildContext context) {
    if (_kEnableMenuAimVisualizer && visualizeAim) {
      return _MenuAimVisualizer(geometry: geometry);
    }

    return _MenuAimListener(geometry: geometry);
  }
}

class _MenuAimListener extends LeafRenderObjectWidget {
  const _MenuAimListener({required this.geometry});
  final MenuAimGeometry geometry;

  @override
  _RenderMenuAimListener createRenderObject(BuildContext context) {
    return _RenderMenuAimListener(geometry);
  }

  @override
  void updateRenderObject(BuildContext context, _RenderMenuAimListener renderObject) {
    renderObject.delegate = geometry;
  }
}

class _RenderMenuAimListener extends RenderProxyBoxWithHitTestBehavior {
  _RenderMenuAimListener(this.delegate);
  static const exitDuration = Duration(milliseconds: 300);
  static const int sampleCount = 15;
  final ListQueue<Offset> points = ListQueue(sampleCount);

  MenuAimGeometry delegate;
  bool enabled = true;
  Timer? exitTimer;

  @override
  void detach() {
    exitTimer?.cancel();
    exitTimer = null;
    super.detach();
  }

  @protected
  void handleConeUpdate() {
    assert(() {
      if (attached && debugPaintSizeEnabled) {
        markNeedsPaint();
      }
      return true;
    }());
  }

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
    if (exitTimer != null) {
      exitTimer!.cancel();
      exitTimer = null;
    }

    if (delegate.targetRect == null || delegate.anchorRect == null) {
      return false;
    }

    if (points.length == 15) {
      points.removeFirst();
    }
    points.add(position);

    if (delegate.anchorRect!.contains(position) || points.length < 2) {
      enabled = true;
      if (_kEnableMenuAimVisualizer) {
        handleConeUpdate();
      }
      return false;
    }

    if (!enabled) {
      return false;
    }

    final target = delegate.targetRect!;
    if (target.contains(position)) {
      enabled = false;
      if (_kEnableMenuAimVisualizer) {
        handleConeUpdate();
      }
      return false;
    }

    if (_isMovingTowardsTarget(points.first, points.last, target)) {
      result.add(BoxHitTestEntry(this, position));
      exitTimer = Timer(exitDuration, () {
        enabled = false;
        if (attached) {
          markNeedsPaint();
        }
        if (_kEnableMenuAimVisualizer) {
          handleConeUpdate();
        }
      });
      if (_kEnableMenuAimVisualizer) {
        handleConeUpdate();
      }
      return true;
    }

    enabled = false;
    return false;
  }

  @override
  void debugPaintSize(PaintingContext context, ui.Offset offset) {
    super.debugPaintSize(context, offset);
    assert(() {
      if (enabled) {
        _paintCone(context, offset, points, delegate);
      }
      return true;
    }());
  }
}

class _MenuAimVisualizer extends _MenuAimListener {
  const _MenuAimVisualizer({required super.geometry});

  @override
  _RenderMenuAimVisualizer createRenderObject(BuildContext context) {
    return _RenderMenuAimVisualizer(geometry);
  }

  @override
  void updateRenderObject(BuildContext context, _RenderMenuAimVisualizer renderObject) {
    renderObject.delegate = geometry;
  }
}

class _RenderMenuAimVisualizer extends _RenderMenuAimListener {
  _RenderMenuAimVisualizer(super.delegate);

  @override
  void handleConeUpdate() {
    if (attached) {
      markNeedsPaint();
    }
  }

  @override
  void paint(PaintingContext context, ui.Offset offset) {
    super.paint(context, offset);
    if (enabled) {
      _paintCone(context, offset, points, delegate);
    }
  }
}

void _paintCone(
  PaintingContext context,
  ui.Offset offset,
  ListQueue<Offset> points,
  MenuAimGeometry delegate,
) {
  final Canvas canvas = context.canvas;
  final Rect? target = delegate.targetRect;
  if (target != null && points.isNotEmpty) {
    if (target.contains(points.last)) {
      return;
    }
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
}
