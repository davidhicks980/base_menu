import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart';

// Not used because the Zoomer interferes with scrolling on some devices.
class Zoomer extends StatefulWidget {
  const Zoomer({
    super.key,
    required this.child,
    required this.minScale,
    required this.maxScale,
    required this.constrained,
  });

  final Widget child;
  final double maxScale;
  final double minScale;
  final bool constrained;

  @override
  State<Zoomer> createState() => _ZoomerState();
}

class _ZoomerState extends State<Zoomer> {
  final TransformationController _transformController = TransformationController();
  final GlobalKey _viewerKey = GlobalKey();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_handleFocusChange);
  }

  @override
  void reassemble() {
    super.reassemble();
    FocusManager.instance.removeListener(_handleFocusChange);
    FocusManager.instance.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    FocusManager.instance.removeListener(_handleFocusChange);
    _transformController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (FocusManager.instance.highlightMode != FocusHighlightMode.traditional) {
      return;
    }

    if (_transformController.value.isIdentity()) {
      return;
    }

    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      return;
    }

    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext == null || !focusContext.mounted || !_focusNode.hasFocus) {
      return;
    }

    final focusedBox = focusContext.findRenderObject() as RenderBox?;
    final viewerBox = _viewerKey.currentContext?.findRenderObject() as RenderBox?;

    if (focusedBox == null || viewerBox == null) {
      return;
    }
    if (!focusedBox.hasSize || !viewerBox.hasSize) {
      return;
    }

    final Offset topLeft = focusedBox.localToGlobal(const Offset(2, 2), ancestor: viewerBox);
    final Offset bottomRight = (topLeft & focusedBox.size).bottomRight - const Offset(4, 4);
    final itemRect = Rect.fromPoints(topLeft, bottomRight);
    final Rect viewerRect = Offset.zero & viewerBox.size;

    // Only move if the item is NOT fully visible.
    if (viewerRect.contains(topLeft) || viewerRect.contains(bottomRight)) {
      return;
    }

    // Calculate the Delta required to center the item
    final Offset itemCenter = itemRect.center;
    final Offset viewerCenter = viewerRect.center;
    final Offset delta = viewerCenter - itemCenter;

    // Apply Delta to the Current Translation
    final Vector3 currentTranslationVec = _transformController.value.getTranslation();
    final double targetX = currentTranslationVec.x + delta.dx;
    final double targetY = currentTranslationVec.y + delta.dy;

    final double scale = _transformController.value.getMaxScaleOnAxis();

    // Calculate the valid range for translation (x, y)
    // These bounds ensure the viewport is always filled by the content (assuming content >= viewport)
    final double minX = viewerBox.size.width - (viewerBox.size.width * scale);
    const maxX = 0.0;
    final double minY = viewerBox.size.height - (viewerBox.size.height * scale);
    const maxY = 0.0;

    // Clamp the target translation safely handling cases where scale < 1
    final double clampedX = (minX < maxX) ? targetX.clamp(minX, maxX) : targetX.clamp(maxX, minX);

    final double clampedY = (minY < maxY) ? targetY.clamp(minY, maxY) : targetY.clamp(maxY, minY);

    _transformController.value = Matrix4.identity()
      ..translate(clampedX, clampedY)
      ..scale(scale);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      canRequestFocus: false,
      descendantsAreFocusable: true,
      descendantsAreTraversable: true,
      child: SizedBox(
        key: _viewerKey,
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: InteractiveViewer(
          clipBehavior: Clip.none,
          transformationController: _transformController,
          minScale: widget.minScale,
          maxScale: widget.maxScale,
          constrained: widget.constrained,
          child: widget.child,
        ),
      ),
    );
  }
}
