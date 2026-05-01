import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../model/enum.dart';

@immutable
class SegmentTextStyle {
  const SegmentTextStyle({this.textStyle, this.isSuperscript, this.isSubscript, this.textAlign});

  final TextStyle? textStyle;
  final bool? isSuperscript;
  final bool? isSubscript;
  final TextAlign? textAlign;

  SegmentTextStyle copyWith({
    TextStyle? textStyle,
    bool? isSuperscript,
    bool? isSubscript,
    double? lineSpacing,
    TextAlign? textAlign,
  }) {
    return SegmentTextStyle(
      textStyle: textStyle ?? this.textStyle,
      isSuperscript: isSuperscript ?? this.isSuperscript,
      isSubscript: isSubscript ?? this.isSubscript,
      textAlign: textAlign ?? this.textAlign,
    );
  }

  SegmentTextStyle merge(SegmentTextStyle? other) {
    if (other == null) {
      return this;
    }
    return copyWith(
      textStyle: textStyle?.merge(other.textStyle) ?? other.textStyle,
      isSuperscript: other.isSuperscript ?? isSuperscript,
      isSubscript: other.isSubscript ?? isSubscript,
      textAlign: other.textAlign ?? textAlign,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is SegmentTextStyle &&
        other.textStyle == textStyle &&
        other.isSuperscript == isSuperscript &&
        other.isSubscript == isSubscript &&
        other.textAlign == textAlign;
  }

  @override
  int get hashCode => Object.hash(textStyle, isSuperscript, isSubscript, textAlign);
}

class SegmentNode {
  SegmentNode(this.start, this.end, {required this.paragraphStyle});
  // The logical range this node currently covers
  int start;
  int end;

  // Styles that apply strictly to this node's FULL range
  SegmentTextStyle? activeStyle;

  DocumentParagraphStyle paragraphStyle;

  // The amount to shift children when visited
  int pendingShift = 0;

  SegmentNode? left;
  SegmentNode? right;

  // Does this node overlap with the query range?
  bool intersects(int qStart, int qEnd) {
    return start < qEnd && end > qStart;
  }

  // Is this node fully inside the query range?
  bool coveredBy(int qStart, int qEnd) {
    return start >= qStart && end <= qEnd;
  }
}

class StyleSegmentTree {
  final SegmentNode root = SegmentNode(0, MAX_SIZE, paragraphStyle: .normal);
  static const int MAX_SIZE = 100000000;

  void insertText(int cursorPosition, int length) {
    _shiftRecursive(root, cursorPosition, length);
  }

  void deleteText(int cursorPosition, int length) {
    _shiftRecursive(root, cursorPosition, -length);
  }

  void _shiftRecursive(SegmentNode? node, int boundary, int delta) {
    if (node == null) {
      return;
    }

    if (node.start >= boundary) {
      node.start += delta;
      node.end += delta;
      node.pendingShift += delta; // Lazy Tag
      return;
    }

    if (delta > 0 && node.end < boundary) {
      return;
    } else if (delta < 0 && node.end <= boundary) {
      return;
    }

    _pushLazy(node);

    node.end += delta;

    _shiftRecursive(node.left, boundary, delta);
    _shiftRecursive(node.right, boundary, delta);
  }

  void setTextStyle(int start, int end, SegmentTextStyle style) {
    _updateRecursive(root, start, end, style);
  }

  void _updateRecursive(SegmentNode? node, int qStart, int qEnd, SegmentTextStyle style) {
    if (node == null || !node.intersects(qStart, qEnd)) {
      return;
    }

    if (node.coveredBy(qStart, qEnd)) {
      node.activeStyle = node.activeStyle?.merge(style) ?? style;

      if (node.left != null || node.right != null) {
        _updateRecursive(node.left, qStart, qEnd, style);
        _updateRecursive(node.right, qStart, qEnd, style);
      }
      return;
    }

    _pushLazy(node);

    final int mid = (node.start + node.end) ~/ 2;
    if (node.left == null) {
      node.left = SegmentNode(node.start, mid, paragraphStyle: node.paragraphStyle)
        ..activeStyle = node.activeStyle;
      node.right = SegmentNode(mid, node.end, paragraphStyle: node.paragraphStyle)
        ..activeStyle = node.activeStyle;
    }

    _updateRecursive(node.left, qStart, qEnd, style);
    _updateRecursive(node.right, qStart, qEnd, style);

    if (node.left != null &&
        node.right != null &&
        node.left!.left == null &&
        node.left!.right == null &&
        node.right!.left == null &&
        node.right!.right == null &&
        node.left!.activeStyle == node.right!.activeStyle) {
      node.activeStyle = node.left!.activeStyle;
      node.left = null;
      node.right = null;
    }
  }

  void setParagraphStyle(int start, int end, DocumentParagraphStyle style) {
    _updateParagraphRecursive(root, start, end, style);
  }

  void _updateParagraphRecursive(
    SegmentNode? node,
    int qStart,
    int qEnd,
    DocumentParagraphStyle style,
  ) {
    if (node == null || !node.intersects(qStart, qEnd)) {
      return;
    }

    if (node.coveredBy(qStart, qEnd)) {
      node.paragraphStyle = style;
      node.activeStyle = null; // Clear text styles when paragraph style changes
      if (node.left != null || node.right != null) {
        _updateParagraphRecursive(node.left, qStart, qEnd, style);
        _updateParagraphRecursive(node.right, qStart, qEnd, style);
      }
      return;
    }

    _pushLazy(node);

    final int mid = (node.start + node.end) ~/ 2;
    if (node.left == null) {
      node.left = SegmentNode(node.start, mid, paragraphStyle: node.paragraphStyle);
      node.right = SegmentNode(mid, node.end, paragraphStyle: node.paragraphStyle);
    }

    _updateParagraphRecursive(node.left, qStart, qEnd, style);
    _updateParagraphRecursive(node.right, qStart, qEnd, style);

    if (node.left != null &&
        node.right != null &&
        node.left!.left == null &&
        node.left!.right == null &&
        node.right!.left == null &&
        node.right!.right == null &&
        node.left!.paragraphStyle == node.right!.paragraphStyle) {
      node.paragraphStyle = node.left!.paragraphStyle;
      node.activeStyle = null; // Clear text styles when paragraph style changes
      node.left = null;
      node.right = null;
    }
  }

  SegmentTextStyle queryStyles(int position) {
    return _queryRecursive(root, position, const SegmentTextStyle());
  }

  SegmentTextStyle _queryRecursive(
    SegmentNode node,
    int position,
    SegmentTextStyle accumulatedStyles,
  ) {
    if (position < node.start || position >= node.end) {
      return accumulatedStyles;
    }

    _pushLazy(node);

    var currentStyle = accumulatedStyles;
    if (node.activeStyle != null) {
      currentStyle = currentStyle.merge(node.activeStyle);
    }

    if (node.left == null && node.right == null) {
      return currentStyle;
    }

    if (node.left != null && position < node.left!.end) {
      return _queryRecursive(node.left!, position, currentStyle);
    } else if (node.right != null && position >= node.right!.start) {
      return _queryRecursive(node.right!, position, currentStyle);
    }

    return currentStyle;
  }

  DocumentParagraphStyle queryParagraphStyle(int position) {
    return _queryParagraphStyleRecursive(root, position);
  }

  int i = 0;

  DocumentParagraphStyle _queryParagraphStyleRecursive(SegmentNode node, int position) {
    if (position < node.start || position >= node.end) {
      return node.paragraphStyle;
    }

    if (node.left == null && node.right == null) {
      return node.paragraphStyle;
    }

    _pushLazy(node);

    if (node.left != null && position < node.left!.end) {
      return _queryParagraphStyleRecursive(node.left!, position);
    } else if (node.right != null && position >= node.right!.start) {
      return _queryParagraphStyleRecursive(node.right!, position);
    }

    return node.paragraphStyle;
  }

  void _pushLazy(SegmentNode node) {
    if (node.pendingShift == 0) {
      return;
    }

    if (node.left != null) {
      _applyShift(node.left!, node.pendingShift);
      _applyShift(node.right!, node.pendingShift);
    }
    node.pendingShift = 0;
  }

  void _applyShift(SegmentNode node, int amount) {
    node.start += amount;
    node.end += amount;
    node.pendingShift += amount;
  }
}
