/// @docImport 'interface.dart';
/// @docImport 'menu.dart';
library;

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

const bool _kEnableMenuAimVisualizer = bool.hasEnvironment('VISUALIZE_MENU_AIM')
    ? bool.fromEnvironment('VISUALIZE_MENU_AIM', defaultValue: true)
    : kDebugMode;

/// A geometry object that holds the anchor and target rectangles for menu
/// aim assist.
class MenuAimGeometry {
  /// The rectangle of the anchor that the pointer is moving away from.
  Rect? anchorRect;

  /// The rectangle of the target that the pointer is moving towards.
  Rect? targetRect;
}

/// An inherited widget used to configure menu aim assist behavior for all
/// [BaseMenu] and [BaseSubmenu] descendants in the widget tree.
class MenuAimScope extends InheritedWidget {
  /// Creates a [MenuAimScope] that wraps its child and provides the [enable] flag.
  const MenuAimScope({
    super.key,
    required this.enable,
    required super.child,
    this.sampleCount = MenuAimInterceptor.defaultSampleCount,
    this.movementThreshold = MenuAimInterceptor.defaultMovementThreshold,
    this.aimTimeout = MenuAimInterceptor.defaultAimTimeout,
  });

  /// A boolean flag indicating whether menu aim assist is enabled.
  ///
  /// When set to `true`, menu aim assist is enabled by default for all
  /// [BaseMenu] and [BaseSubmenu] descendants in the widget tree. When set to
  /// `false`, menu aim assist behavior is disabled.
  ///
  /// If a custom [MenuPositioningDelegate] is used to position a menu, the
  /// delegate must implement menu aim assist behavior for this flag to have an
  /// effect. See [DefaultMenuPositioningDelegate] for an example of how to
  /// implement menu aim assist in a custom delegate.
  final bool enable;

  /// The number of pointer events in the sliding window used to determine the
  /// pointer trajectory and velocity.
  ///
  /// A larger sample count increases trajectory stability by averaging movement
  /// over a longer period, but can cause the aim-assist projection to lag
  /// behind the pointer after a sharp directional change. A smaller count is
  /// more responsive to sudden turns but more susceptible to input noise
  /// (jitter).
  final int sampleCount;

  /// The minimum pointer velocity required to trigger and maintain aim-assist
  /// protection.
  ///
  /// This is the minimum distance the pointer must travel within the current
  /// [sampleCount] window. Increasing it requires the user to move more quickly
  /// and deliberately to maintain aim-assist.
  final double movementThreshold;

  /// The duration that aim-assist protection remains active after a valid
  /// trajectory was last detected.
  ///
  /// This ensures the projected triangle doesn't flicker off if the user pauses
  /// briefly while navigating toward the submenu.
  final Duration aimTimeout;

  /// Returns `true` if menu aim assist is enabled in the current context.
  ///
  /// Calling this method establishes a dependency that rebuilds the provided
  /// [BuildContext] whenever [MenuAimScope.enable] changes.
  static MenuAimScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MenuAimScope>();
  }

  @override
  bool updateShouldNotify(MenuAimScope oldWidget) {
    return enable != oldWidget.enable ||
        sampleCount != oldWidget.sampleCount ||
        movementThreshold != oldWidget.movementThreshold ||
        aimTimeout != oldWidget.aimTimeout;
  }
}

/// A widget that intercepts pointer hit-tests when the pointer moves diagonally
/// from a menu item toward a submenu.
///
/// This prevents premature submenu closures when the pointer travels diagonally
/// over sibling menu items on its way to the [MenuAimGeometry.targetRect].
///
/// The algorithm:
/// 1. Maintains a queue of [Offset] samples to calculate trajectory.
/// 2. Performs a dot-product check to confirm movement is directed toward the
///    target.
/// 3. Validates that the pointer remains within an angular projection extending
///    from the origin of movement to the submenu's boundaries.
/// 4. Intercepts hit-tests to prevent sibling items from gaining focus until
///    the pointer enters the target area or exits the projected triangle.
///
/// Setting [MenuAimInterceptor.visualizeAim] to true draws the trajectory in
/// debug builds. To enable visualization in production builds, set the
/// environment variable `VISUALIZE_MENU_AIM` to true.
///
/// To implement menu aim assist in a custom [MenuPositioningDelegate], place
/// the [MenuAimInterceptor] widget in front of the menu overlay in a [Stack],
/// and provide a [MenuAimGeometry] object that defines the anchor and target
/// rectangles. See [DefaultMenuPositioningDelegate] for an example.
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
  /// behavior. When set to `true`, the widget will draw lines and triangles on
  /// the canvas to illustrate the current pointer trajectory and the target
  /// area.
  ///
  /// Aim visualization is intended for debugging and is ignored in release
  /// builds by default. To enable this feature in production builds, set the
  /// environment variable `VISUALIZE_MENU_AIM` to `true` at compile time.
  static bool visualizeAim = false;

  /// The default duration for the aim timeout that disables menu aim assist after
  /// the pointer leaves the anchor area.
  static const defaultAimTimeout = Duration(milliseconds: 300);

  /// The default number of pointer position samples to maintain for trajectory
  /// calculations.
  static const int defaultSampleCount = 15;

  /// The default distance the pointer must travel within the [sampleCount]
  /// window to trigger aim-assist protection.
  static const double defaultMovementThreshold = 3.8;

  /// Returns the class name of the private widget used for menu aim.
  @visibleForTesting
  static Type get debugAimListenerWidgetType {
    return _kEnableMenuAimVisualizer && visualizeAim ? _MenuAimVisualizer : _MenuAimListener;
  }

  @override
  Widget build(BuildContext context) {
    final scope = MenuAimScope.maybeOf(context);
    final sampleCount = scope?.sampleCount ?? defaultSampleCount;
    final movementThreshold = scope?.movementThreshold ?? defaultMovementThreshold;
    final aimTimeout = scope?.aimTimeout ?? defaultAimTimeout;

    if (_kEnableMenuAimVisualizer && visualizeAim) {
      return _MenuAimVisualizer(
        geometry: geometry,
        sampleCount: sampleCount,
        movementThreshold: movementThreshold,
        aimTimeout: aimTimeout,
      );
    }

    return _MenuAimListener(
      geometry: geometry,
      sampleCount: sampleCount,
      movementThreshold: movementThreshold,
      aimTimeout: aimTimeout,
    );
  }
}

class _MenuAimListener extends LeafRenderObjectWidget {
  const _MenuAimListener({
    required this.geometry,
    required this.sampleCount,
    required this.movementThreshold,
    required this.aimTimeout,
  });
  final MenuAimGeometry geometry;
  final int sampleCount;
  final double movementThreshold;
  final Duration aimTimeout;

  @override
  _RenderMenuAimListener createRenderObject(BuildContext context) {
    return _RenderMenuAimListener(
      geometry: geometry,
      sampleCount: sampleCount,
      movementThreshold: movementThreshold,
      aimTimeout: aimTimeout,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderMenuAimListener renderObject) {
    renderObject
      ..geometry = geometry
      ..sampleCount = sampleCount
      ..movementThreshold = movementThreshold
      ..aimTimeout = aimTimeout;
  }
}

class _RenderMenuAimListener extends RenderProxyBoxWithHitTestBehavior {
  _RenderMenuAimListener({
    required this.aimTimeout,
    required this.movementThreshold,
    required this.geometry,
    required int sampleCount,
  }) : _sampleCount = sampleCount;

  late final ListQueue<Offset> points = ListQueue(_sampleCount);
  MenuAimGeometry geometry;
  bool enabled = true;
  Timer? aimTimeoutTimer;
  Duration aimTimeout;
  double movementThreshold;
  int get sampleCount => _sampleCount;
  int _sampleCount;
  set sampleCount(int value) {
    if (_sampleCount == value) {
      return;
    }
    _sampleCount = value;
    // Evict any excess old samples if queue threshold gets reduced
    while (points.length > _sampleCount && points.isNotEmpty) {
      points.removeFirst();
    }
  }

  @override
  void detach() {
    aimTimeoutTimer?.cancel();
    aimTimeoutTimer = null;
    super.detach();
  }

  // coverage:ignore-start
  @protected
  void handleTriangleUpdate() {
    assert(() {
      if (attached && debugPaintSizeEnabled) {
        markNeedsPaint();
      }
      return true;
    }());
  }
  // coverage:ignore-end

  static bool _isMovingTowardsTarget(
    Offset start,
    Offset end,
    Rect target,
    double movementThreshold,
  ) {
    final Offset movement = end - start;

    if (movement.distanceSquared < movementThreshold * movementThreshold) {
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

    // Verify movement vector falls within the triangle formed by the target's corners
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

    // If the movement direction is bounded by the outermost angle differences,
    // it is inside the triangle
    return minAngleDiff <= 0 && maxAngleDiff >= 0;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (aimTimeoutTimer != null) {
      aimTimeoutTimer!.cancel();
      aimTimeoutTimer = null;
    }

    if (geometry.targetRect == null || geometry.anchorRect == null) {
      return false;
    }

    if (points.length >= sampleCount && points.isNotEmpty) {
      points.removeFirst();
    }
    points.add(position);

    if (geometry.anchorRect!.contains(position) || points.length < 2) {
      enabled = true;
      if (_kEnableMenuAimVisualizer) {
        handleTriangleUpdate();
      }
      return false;
    }

    if (!enabled) {
      return false;
    }

    final target = geometry.targetRect!;
    if (target.contains(position)) {
      enabled = false;
      if (_kEnableMenuAimVisualizer) {
        handleTriangleUpdate();
      }
      return false;
    }

    if (_isMovingTowardsTarget(points.first, points.last, target, movementThreshold)) {
      result.add(BoxHitTestEntry(this, position));
      aimTimeoutTimer = Timer(aimTimeout, () {
        enabled = false;
        if (attached) {
          markNeedsPaint();
        }
        if (_kEnableMenuAimVisualizer) {
          handleTriangleUpdate();
        }
      });
      if (_kEnableMenuAimVisualizer) {
        handleTriangleUpdate();
      }
      return true;
    }

    enabled = false;
    return false;
  }

  // coverage:ignore-start
  @override
  void debugPaintSize(PaintingContext context, ui.Offset offset) {
    super.debugPaintSize(context, offset);
    assert(() {
      if (enabled) {
        _paintTriangle(context, offset, points, geometry);
      }
      return true;
    }());
  }

  // coverage:ignore-end
}

class _MenuAimVisualizer extends _MenuAimListener {
  const _MenuAimVisualizer({
    required super.geometry,
    required super.sampleCount,
    required super.movementThreshold,
    required super.aimTimeout,
  });

  @override
  _RenderMenuAimVisualizer createRenderObject(BuildContext context) {
    return _RenderMenuAimVisualizer(
      geometry: geometry,
      sampleCount: sampleCount,
      movementThreshold: movementThreshold,
      aimTimeout: aimTimeout,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderMenuAimVisualizer renderObject) {
    renderObject.geometry = geometry;
    renderObject.sampleCount = sampleCount;
    renderObject.movementThreshold = movementThreshold;
    renderObject.aimTimeout = aimTimeout;
  }
}

class _RenderMenuAimVisualizer extends _RenderMenuAimListener {
  _RenderMenuAimVisualizer({
    required super.aimTimeout,
    required super.movementThreshold,
    required super.geometry,
    required super.sampleCount,
  });

  @override
  void handleTriangleUpdate() {
    if (attached) {
      markNeedsPaint();
    }
  }

  @override
  void paint(PaintingContext context, ui.Offset offset) {
    super.paint(context, offset);
    if (enabled) {
      _paintTriangle(context, offset, points, geometry);
    }
  }
}

void _paintTriangle(
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

      final trianglePaint = Paint()
        ..color = const Color(0xFFFF00FF)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      if (minCorner != null) {
        canvas.drawLine(origin, minCorner, trianglePaint);
      }
      if (maxCorner != null && maxCorner != minCorner) {
        canvas.drawLine(origin, maxCorner, trianglePaint);
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
