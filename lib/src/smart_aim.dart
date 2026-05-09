import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class AimDelegate {
  Rect? anchorRect;
  Rect? targetRect;
  VoidCallback? end;
}

bool _isMovingTowardsTarget(Offset start, Offset end, Rect target) {
  final Offset movement = end - start;

  if (movement.distanceSquared < 10.0) {
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

class _MenuAimScope extends InheritedWidget {
  const _MenuAimScope({required super.child, required this.state});
  final _MenuAimAnchorState state;

  @override
  bool updateShouldNotify(_MenuAimScope oldWidget) {
    return state != oldWidget.state;
  }
}

class MenuAimAnchor extends StatefulWidget {
  const MenuAimAnchor({super.key, required this.child});
  final Widget child;

  @override
  State<MenuAimAnchor> createState() => _MenuAimAnchorState();
}

class _MenuAimAnchorState extends State<MenuAimAnchor> {
  _MenuAimTargetRenderBox? _child;

  @override
  void dispose() {
    _overlay?.remove();
    _overlay?.dispose();
    _overlay = null;
    super.dispose();
  }

  void attachChild(_MenuAimTargetRenderBox child) {
    if (_child == child) {
      return;
    }

    assert(_child == null, 'Only one child can be attached to a SmartAimParent at a time.');

    _child = child;
    final box = context.findRenderObject()! as RenderBox;
    final anchorRect = box.localToGlobal(Offset.zero) & box.size;
    final targetRect = _child!.rect;
    delegate.anchorRect = anchorRect;
    delegate.targetRect = targetRect;
    delegate.end = () {
      _overlay?.remove();
      _overlay?.dispose();
      setState(() {
        _overlay = null;
      });
    };
  }

  void detachChild(_MenuAimTargetRenderBox child) {
    if (_child == child) {
      _child = null;
      delegate.anchorRect = null;
      delegate.targetRect = null;
      delegate.end = null;
      _overlay?.remove();
      _overlay?.dispose();
      _overlay = null;
    }
  }

  OverlayEntry? _overlay;
  AimDelegate delegate = AimDelegate();

  void _createAimAssist() {
    assert(_overlay == null);
    _overlay = OverlayEntry(
      builder: (context) {
        return MenuAimListener(delegate: delegate);
      },
    );

    Overlay.of(context).insert(_overlay!);
  }

  void _handlePointerHover(PointerHoverEvent event) {
    if (_overlay == null) {
      setState(() {
        _createAimAssist();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _MenuAimScope(
      state: this,
      child: Listener(onPointerHover: _handlePointerHover, child: widget.child),
    );
  }
}

class MenuAimTarget extends SingleChildRenderObjectWidget {
  const MenuAimTarget({super.key, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MenuAimTargetRenderBox(
      context.dependOnInheritedWidgetOfExactType<_MenuAimScope>()!.state,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _MenuAimTargetRenderBox).state = context
        .dependOnInheritedWidgetOfExactType<_MenuAimScope>()!
        .state;
  }
}

class _MenuAimTargetRenderBox extends RenderProxyBox {
  _MenuAimTargetRenderBox(this.state);
  _MenuAimAnchorState state;

  Rect get rect => localToGlobal(Offset.zero) & size;

  bool _attached = false;

  @override
  void detach() {
    _attached = false;
    state.detachChild(this);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    if (!_attached) {
      _attached = true;
      state.attachChild(this);
    }
  }
}

/// A widget that uses [RenderMenuAimListener].
class MenuAimListener extends LeafRenderObjectWidget {
  const MenuAimListener({super.key, required this.delegate});
  final AimDelegate delegate;

  @override
  RenderMenuAimListener createRenderObject(BuildContext context) {
    return RenderMenuAimListener(delegate);
  }

  @override
  void updateRenderObject(BuildContext context, RenderMenuAimListener renderObject) {
    renderObject.delegate = delegate;
  }
}

/// A render object that absorbs pointer events only if they occur within the
/// "smart aim" triangle.
class RenderMenuAimListener extends RenderProxyBox {
  RenderMenuAimListener(this.delegate);
  final ListQueue<Offset> points = ListQueue(15);
  AimDelegate delegate;
  Timer? _exitTimer;

  void _resetTimer() {
    _exitTimer?.cancel();
    _exitTimer = Timer(const Duration(milliseconds: 250), _removeAimAssist);
  }

  void _removeAimAssist() {
    _exitTimer?.cancel();
    _exitTimer = null;
    points.clear();
    delegate.end?.call();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _exitTimer = Timer(const Duration(milliseconds: 250), _removeAimAssist);
  }

  @override
  void detach() {
    _exitTimer?.cancel();
    _exitTimer = null;
    super.detach();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (delegate.targetRect == null || delegate.anchorRect == null) {
      return false;
    }

    if (points.length == 20) {
      points.removeFirst();
    }

    points.add(position);

    if (delegate.anchorRect!.contains(position)) {
      _resetTimer();
      return false;
    }

    final target = delegate.targetRect!;

    if (target.contains(position)) {
      _removeAimAssist();
      return false;
    }

    if (_isMovingTowardsTarget(points.first, points.last, target)) {
      result.add(BoxHitTestEntry(this, position));
      _resetTimer();
      assert(() {
        markNeedsPaint();
        _debugPaint = true;
        return true;
      }());
      return true;
    }

    _removeAimAssist();
    return false;
  }

  bool _debugPaint = false;
  @override
  void debugPaint(PaintingContext context, ui.Offset offset) {
    if (!_debugPaint) {
      return;
    }
    assert(() {
      print('Painting Smart Aim Overlay with ${points.length} points');
      final Canvas canvas = context.canvas;
      final Rect? target = delegate.targetRect;
      if (target != null && points.isNotEmpty) {
        final conePaint = Paint()
          ..color = const Color(0xFFFF00FF)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

        // Draw lines to corners to visualize the bounding cone
        final List<Offset> corners = [
          target.topLeft,
          target.topRight,
          target.bottomLeft,
          target.bottomRight,
        ];

        final Offset origin = points.first;
        for (final corner in corners) {
          canvas.drawLine(origin, corner, conePaint);
        }

        // Visualize Dot Product
        if (points.length >= 2) {
          final Offset p1 = points.first;
          final Offset p2 = points.last;
          final rect = delegate.targetRect!;
          final double clampedX = ui.clampDouble(p1.dx, rect.left, rect.right);
          final double clampedY = ui.clampDouble(p1.dy, rect.top, rect.bottom);
          final nearestTargetPoint = Offset(clampedX, clampedY);

          final Offset toTarget = nearestTargetPoint - p1;
          final Offset movement = p2 - p1;
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
            double projectionLength = targetDist > 0 ? dotProduct / targetDist : 0.0;
            projectionLength = math.pow(projectionLength, 2.0).toDouble();

            final double lineLength = ui.clampDouble(projectionLength.abs(), 20.0, 800.0);
            final Offset trajectory = origin + (movement / movement.distance * lineLength);

            final traitColor = dotProduct > 0 ? const Color(0xFF00FF00) : const Color(0xFFFF0000);

            canvas.drawLine(
              origin,
              trajectory,
              Paint()
                ..color = traitColor
                ..strokeWidth = 2.0,
            );
          }
        }
      }
      return true;
    }());
  }
}
