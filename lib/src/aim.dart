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

/// An inherited widget that provides a boolean flag indicating whether menu aim
/// assist is enabled.
///
/// This can be used to conditionally enable or disable menu aim assist behavior for
/// all [BaseMenu] and [BaseSubmenu] descendants in the widget tree.
class MenuAimScope extends InheritedWidget {
  /// Creates a [MenuAimScope] that wraps its child and provides the [enable] flag.
  const MenuAimScope({
    super.key,
    required this.enable,
    required super.child,
    this.sampleCount = MenuAimInterceptor.defaultSampleCount,
    this.minimumDistanceSquared = MenuAimInterceptor.defaultMinimumDistanceSquared,
    this.exitDuration = MenuAimInterceptor.defaultExitDuration,
  });

  /// A boolean flag indicating whether menu aim assist is enabled.
  ///
  /// When set to `true`, menu aim assist is enabled by default for all
  /// [BaseMenu] and [BaseSubmenu] descendants in the widget tree. When set to
  /// `false`, menu aim assist behavior is disabled.
  final bool enable;

  /// {@template MenuAimInterceptor.sampleCount}
  /// The number of pointer position samples to maintain for trajectory calculations.
  /// {@endtemplate}
  final int sampleCount;

  /// {@template MenuAimInterceptor.minimumDistanceSquared}
  /// The minimum squared distance between the first and last pointer position
  /// to consider the pointer as moving towards the target.
  /// {@endtemplate}
  final double minimumDistanceSquared;

  /// {@template MenuAimInterceptor.exitDuration}
  /// The duration for the exit timer that disables menu aim assist after the
  /// pointer leaves the anchor area.
  /// {@endtemplate}
  final Duration exitDuration;

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
        minimumDistanceSquared != oldWidget.minimumDistanceSquared ||
        exitDuration != oldWidget.exitDuration;
  }
}

/// A widget that intercepts pointer hit-tests when the pointer moves
/// diagonally from a menu item toward a submenu.
///
/// This prevents premature submenu closures when the pointer travels diagonally
/// over sibling menu items on its way to the [MenuAimGeometry.targetRect].
///
/// The algorithm performs the following:
/// 1. Maintains a queue of [Offset] samples to calculate trajectory.
/// 2. Performs a dot-product check to confirm movement is directed toward
///    the target.
/// 3. Validates that the pointer remains within an angular projection
///    extending from the origin of movement to the submenu's boundaries.
/// 4. Intercepts hit-tests to prevent sibling items from gaining focus
///    until the pointer enters the target area or exits the projection cone.
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
  ///
  ///
  /// This flag has no effect in release builds and is intended for debugging
  /// and testing purposes only. To enable this feature in production builds,
  /// set the environment variable `VISUALIZE_MENU_AIM` to `true` at compile
  /// time.
  static bool visualizeAim = false;

  /// The default duration for the exit timer that disables menu aim assist after
  /// the pointer leaves the anchor area.
  static const defaultExitDuration = Duration(milliseconds: 300);

  /// The default number of pointer position samples to maintain for trajectory calculations.
  static const int defaultSampleCount = 15;

  /// The default minimum squared distance between the first and last pointer
  /// position samples to consider the pointer as moving towards the target.
  static const double defaultMinimumDistanceSquared = 15.0;

  /// Returns the class name of the private widget used for menu aim.
  @visibleForTesting
  static Type get debugAimListenerWidgetType {
    return _kEnableMenuAimVisualizer && visualizeAim ? _MenuAimVisualizer : _MenuAimListener;
  }

  @override
  Widget build(BuildContext context) {
    final scope = MenuAimScope.maybeOf(context);
    if (scope != null && !scope.enable) {
      return const SizedBox.shrink();
    }

    if (_kEnableMenuAimVisualizer && visualizeAim) {
      return _MenuAimVisualizer(
        geometry: geometry,
        sampleCount: scope?.sampleCount ?? defaultSampleCount,
        minimumDistanceSquared: scope?.minimumDistanceSquared ?? defaultMinimumDistanceSquared,
        exitDuration: scope?.exitDuration ?? defaultExitDuration,
      );
    }

    return _MenuAimListener(
      geometry: geometry,
      sampleCount: scope?.sampleCount ?? defaultSampleCount,
      minimumDistanceSquared: scope?.minimumDistanceSquared ?? defaultMinimumDistanceSquared,
      exitDuration: scope?.exitDuration ?? defaultExitDuration,
    );
  }
}

class _MenuAimListener extends LeafRenderObjectWidget {
  const _MenuAimListener({
    required this.geometry,
    required this.sampleCount,
    required this.minimumDistanceSquared,
    required this.exitDuration,
  });
  final MenuAimGeometry geometry;
  final int sampleCount;
  final double minimumDistanceSquared;
  final Duration exitDuration;

  @override
  _RenderMenuAimListener createRenderObject(BuildContext context) {
    return _RenderMenuAimListener(
      geometry: geometry,
      sampleCount: sampleCount,
      minimumDistanceSquared: minimumDistanceSquared,
      exitDuration: exitDuration,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderMenuAimListener renderObject) {
    renderObject
      ..geometry = geometry
      ..sampleCount = sampleCount
      ..minimumDistanceSquared = minimumDistanceSquared
      ..exitDuration = exitDuration;
  }
}

class _RenderMenuAimListener extends RenderProxyBoxWithHitTestBehavior {
  _RenderMenuAimListener({
    required this.exitDuration,
    required this.minimumDistanceSquared,
    required this.geometry,
    required int sampleCount,
  }) : _sampleCount = sampleCount;

  late final ListQueue<Offset> points = ListQueue(_sampleCount);
  MenuAimGeometry geometry;
  bool enabled = true;
  Timer? exitTimer;
  Duration exitDuration;
  double minimumDistanceSquared;
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
    exitTimer?.cancel();
    exitTimer = null;
    super.detach();
  }

  // coverage:ignore-start
  @protected
  void handleConeUpdate() {
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
    double minimumDistanceSquared,
  ) {
    final Offset movement = end - start;

    if (movement.distanceSquared < minimumDistanceSquared) {
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
        handleConeUpdate();
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
        handleConeUpdate();
      }
      return false;
    }

    if (_isMovingTowardsTarget(points.first, points.last, target, minimumDistanceSquared)) {
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

  // coverage:ignore-start
  @override
  void debugPaintSize(PaintingContext context, ui.Offset offset) {
    super.debugPaintSize(context, offset);
    assert(() {
      if (enabled) {
        _paintCone(context, offset, points, geometry);
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
    required super.minimumDistanceSquared,
    required super.exitDuration,
  });

  @override
  _RenderMenuAimVisualizer createRenderObject(BuildContext context) {
    return _RenderMenuAimVisualizer(
      geometry: geometry,
      sampleCount: sampleCount,
      minimumDistanceSquared: minimumDistanceSquared,
      exitDuration: exitDuration,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderMenuAimVisualizer renderObject) {
    renderObject.geometry = geometry;
    renderObject.sampleCount = sampleCount;
    renderObject.minimumDistanceSquared = minimumDistanceSquared;
    renderObject.exitDuration = exitDuration;
  }
}

class _RenderMenuAimVisualizer extends _RenderMenuAimListener {
  _RenderMenuAimVisualizer({
    required super.exitDuration,
    required super.minimumDistanceSquared,
    required super.geometry,
    required super.sampleCount,
  });

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
      _paintCone(context, offset, points, geometry);
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
