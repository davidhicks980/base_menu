import 'package:flutter/widgets.dart';

import '../model/enum.dart';
import 'style_segment_tree.dart';

class EditorController extends TextEditingController {
  EditorController({super.text});

  final StyleSegmentTree _styleTree = StyleSegmentTree();

  Map<DocumentParagraphStyle, SegmentTextStyle> paragraphStyles = {
    DocumentParagraphStyle.normal: const SegmentTextStyle(
      textStyle: TextStyle(fontSize: 14, height: 20 / 14),
    ),
    DocumentParagraphStyle.title: const SegmentTextStyle(
      textStyle: TextStyle(fontSize: 36, height: 32 / 26, fontWeight: FontWeight.w500),
    ),
    DocumentParagraphStyle.subtitle: const SegmentTextStyle(
      textStyle: TextStyle(
        fontSize: 18,
        height: 28 / 18,
        fontStyle: FontStyle.italic,
        color: Color(0xFF888888),
      ),
    ),
    DocumentParagraphStyle.heading1: const SegmentTextStyle(
      textStyle: TextStyle(fontSize: 28, height: 28 / 22, fontWeight: FontWeight.w500),
    ),
    DocumentParagraphStyle.heading2: const SegmentTextStyle(
      textStyle: TextStyle(fontSize: 24, height: 24 / 16, fontWeight: FontWeight.w500),
    ),
    DocumentParagraphStyle.heading3: const SegmentTextStyle(
      textStyle: TextStyle(fontSize: 20, height: 20 / 14, fontWeight: FontWeight.w400),
    ),
  };

  void updateParagraphStyle(DocumentParagraphStyle paragraphStyle, SegmentTextStyle style) {
    if (paragraphStyles[paragraphStyle] != style) {
      paragraphStyles[paragraphStyle] = style;
      notifyListeners();
    }
  }

  double get indent => _indent;
  double _indent = 0.0;
  set indent(double value) {
    if (_indent != value) {
      _indent = value;
      notifyListeners();
    }
  }

  ColumnLayout get columnLayout => _columnLayout;
  ColumnLayout _columnLayout = ColumnLayout.one;
  set columnLayout(ColumnLayout layout) {
    if (_columnLayout != layout) {
      _columnLayout = layout;
      notifyListeners();
    }
  }

  /// Applies a specific style to the currently selected text range.
  void applyStyle(SegmentTextStyle style) {
    if (!selection.isValid) {
      return;
    }

    if (selection.isCollapsed) {
      // Apply style to the character immediately preceding the cursor.
      final position = selection.baseOffset > 0 ? selection.baseOffset - 1 : 0;
      _styleTree.setTextStyle(position, position + 1, style);
    } else {
      // Apply style to the highlighted region.
      _styleTree.setTextStyle(selection.start, selection.end, style);
    }

    notifyListeners();
  }

  void applyParagraphStyle(DocumentParagraphStyle style) {
    if (!selection.isValid) {
      return;
    }

    if (selection.isCollapsed) {
      final position = selection.baseOffset > 0 ? selection.baseOffset - 1 : 0;
      _styleTree.setParagraphStyle(position, position + 1, style);
    } else {
      _styleTree.setParagraphStyle(selection.start, selection.end, style);
    }

    notifyListeners();
  }

  @override
  set text(String newText) {
    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  /// Returns the currently selected text.
  String get selectedText {
    if (!selection.isValid || selection.isCollapsed) {
      return '';
    }
    return selection.textInside(text);
  }

  /// Returns the style of the currently selected text.
  /// If the selection is collapsed, returns the style of the preceding character.
  SegmentTextStyle? get selectedTextStyle {
    if (!selection.isValid) {
      return null;
    }
    if (selection.isCollapsed) {
      if (selection.baseOffset > 0) {
        return _styleTree.queryStyles(selection.baseOffset - 1);
      }
      return null;
    }
    return _styleTree.queryStyles(selection.start);
  }

  DocumentParagraphStyle get selectedParagraphStyle {
    if (!selection.isValid) {
      return .normal;
    }
    if (selection.isCollapsed) {
      if (selection.baseOffset > 0) {
        return _styleTree.queryParagraphStyle(selection.baseOffset - 1);
      }
      return .normal;
    }
    return _styleTree.queryParagraphStyle(selection.start);
  }

  bool selectionHasAttributes(bool Function(SegmentTextStyle style) predicate) {
    if (!selection.isValid || selection.isCollapsed) {
      final style = selectedTextStyle;
      return style != null && predicate(style);
    }
    // Check if the predicate holds for entire range
    for (int i = selection.start; i < selection.end; i++) {
      if (predicate(_styleTree.queryStyles(i))) {
        return true;
      }
    }
    return false;
  }

  @override
  set value(TextEditingValue newValue) {
    final String oldText = value.text;
    final String newText = newValue.text;

    if (oldText != newText) {
      var prefix = 0;
      while (prefix < oldText.length &&
          prefix < newText.length &&
          oldText.codeUnitAt(prefix) == newText.codeUnitAt(prefix)) {
        prefix++;
      }

      var suffix = 0;
      while (suffix < oldText.length - prefix &&
          suffix < newText.length - prefix &&
          oldText.codeUnitAt(oldText.length - 1 - suffix) ==
              newText.codeUnitAt(newText.length - 1 - suffix)) {
        suffix++;
      }

      final int deletedLength = oldText.length - prefix - suffix;
      final String insertedText = newText.substring(prefix, newText.length - suffix);

      if (deletedLength > 0) {
        _styleTree.deleteText(prefix, deletedLength);
      }

      if (insertedText.isNotEmpty) {
        _styleTree.insertText(prefix, insertedText.length);
      }
    }

    super.value = newValue;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (text.isEmpty) {
      return TextSpan(style: style, text: '');
    }

    final children = <InlineSpan>[];

    // Rebuild the text span by querying the style segment tree for each character.
    var i = 0;
    while (i < text.length) {
      final paragraph = _styleTree.queryParagraphStyle(i);
      final SegmentTextStyle currentStyle = _styleTree.queryStyles(i);
      final start = i;

      // Look ahead to group characters with the same style
      while (i < text.length &&
          _styleTree.queryParagraphStyle(i) == paragraph &&
          _styleTree.queryStyles(i) == currentStyle) {
        i++;
      }

      final paragraphStyle = paragraphStyles[paragraph]!;
      final mergedStyle = paragraphStyle.merge(currentStyle);
      if (currentStyle.isSuperscript == true || currentStyle.isSubscript == true) {
        final double fontSize = mergedStyle.textStyle?.fontSize ?? 14.0;
        const scaleFactor = 0.7;
        final double yOffset = currentStyle.isSuperscript == true
            ? -fontSize * 0.4
            : fontSize * 0.2;

        children.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Transform.translate(
              offset: Offset(0, yOffset),
              child: Text(
                text.substring(start, i),
                style: mergedStyle.textStyle?.copyWith(fontSize: fontSize * scaleFactor),
              ),
            ),
          ),
        );
      } else {
        children.add(TextSpan(text: text.substring(start, i), style: mergedStyle.textStyle));
      }
    }

    return TextSpan(style: style, children: children);
  }
}
