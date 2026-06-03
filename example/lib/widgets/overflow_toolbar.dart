import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

typedef OverflowCallback = void Function(int lastVisibleChildIndex);

class OverflowRow extends StatefulWidget {
  const OverflowRow({super.key, required this.onOverflow, required this.children});
  final OverflowCallback onOverflow;
  final List<Widget> children;

  @override
  State<OverflowRow> createState() => _OverflowRowState();
}

class _OverflowRowState extends State<OverflowRow> {
  late int _lastVisible = widget.children.length;

  void _handleOverflow(int lastVisibleIndex) {
    if (_lastVisible != lastVisibleIndex) {
      _lastVisible = lastVisibleIndex;
      widget.onOverflow(lastVisibleIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _OverflowRow(
      onOverflow: _handleOverflow,
      children: [
        for (int i = 0; i < widget.children.length; i++)
          IgnorePointer(
            ignoring: i >= _lastVisible,
            ignoringSemantics: i >= _lastVisible,
            child: ExcludeFocus(excluding: i >= _lastVisible, child: widget.children[i]),
          ),
      ],
    );
  }
}

class _OverflowRow extends MultiChildRenderObjectWidget {
  const _OverflowRow({required super.children, required this.onOverflow});
  final void Function(int cutoffIndex) onOverflow;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderOverflowToolbarRow(
      onOverflow: onOverflow,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderOverflowToolbarRow renderObject) {
    renderObject
      ..onOverflow = onOverflow
      ..textDirection = Directionality.of(context);
  }
}

class _OverflowParentData extends ContainerBoxParentData<RenderBox> {}

class RenderOverflowToolbarRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _OverflowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _OverflowParentData> {
  RenderOverflowToolbarRow({required this._onOverflow, required this._textDirection});

  OverflowCallback get onOverflow => _onOverflow;
  OverflowCallback _onOverflow;
  set onOverflow(OverflowCallback value) {
    if (_onOverflow != value) {
      _onOverflow = value;
      markNeedsLayout();
    }
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection != value) {
      _textDirection = value;
      markNeedsLayout();
    }
  }

  int _lastVisibleIndex = 0;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _OverflowParentData) {
      child.parentData = _OverflowParentData();
    }
  }

  @override
  void performLayout() {
    if (childCount == 0) {
      size = constraints.smallest;
      return;
    }

    final double maxHeight = constraints.maxHeight;
    final double maxAvailableWidth = constraints.maxWidth;
    RenderBox? child = firstChild;
    var hasOverflowed = false;
    var idx = 0;
    double currentX = 0;
    while (child != null) {
      final childParentData = child.parentData! as _OverflowParentData;
      child.layout(BoxConstraints(maxHeight: maxHeight), parentUsesSize: true);
      if (hasOverflowed || currentX + child.size.width > maxAvailableWidth) {
        hasOverflowed = true;
      } else {
        final double yOffset = (maxHeight - child.size.height) / 2.0;
        childParentData.offset = Offset(currentX, yOffset);
        currentX += child.size.width;
        idx += 1;
      }

      child = childAfter(child);
    }

    if (_textDirection == TextDirection.rtl) {
      child = firstChild;
      for (var i = 0; i < idx; i++) {
        final childParentData = child!.parentData! as _OverflowParentData;
        childParentData.offset = Offset(
          currentX - childParentData.offset.dx - child.size.width,
          childParentData.offset.dy,
        );
        child = childAfter(child);
      }
    }

    onOverflow(idx);
    _lastVisibleIndex = idx;
    size = constraints.constrain(Size(currentX, maxHeight));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    RenderBox? child = firstChild;
    for (var i = 0; i < _lastVisibleIndex; i++) {
      final childParentData = child!.parentData! as _OverflowParentData;
      context.paintChild(child, offset + childParentData.offset);
      child = childAfter(child);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    RenderBox? child = lastChild;
    var i = childCount - 1;
    while (child != null) {
      if (i < _lastVisibleIndex) {
        final childParentData = child.parentData! as _OverflowParentData;
        final isHit = result.addWithPaintOffset(
          offset: childParentData.offset,
          position: position,
          hitTest: (BoxHitTestResult result, Offset transformed) {
            assert(transformed == position - childParentData.offset);
            return child!.hitTest(result, position: transformed);
          },
        );
        if (isHit) {
          return true;
        }
      }

      child = childBefore(child);
      i--;
    }

    return false;
  }
}
