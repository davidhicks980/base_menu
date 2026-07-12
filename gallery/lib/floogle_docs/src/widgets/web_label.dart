import 'package:flutter/widgets.dart';

/// Text on web is slightly wider for lowercase letters for the GoogleSans font.
///
/// This widget applies a different TextStyle to uppercase letters to compensate.
class WebLabel extends StatelessWidget {
  const WebLabel({super.key, required this.label, this.textStyle, this.uppercaseTextStyle});
  final String label;
  final TextStyle? textStyle;
  final TextStyle? uppercaseTextStyle;
  @override
  Widget build(BuildContext context) {
    final TextStyle baseTextStyle = DefaultTextStyle.of(context).style;
    final TextStyle defaultStyle = baseTextStyle.merge(textStyle);
    final TextStyle upperStyle = baseTextStyle.merge(uppercaseTextStyle);

    final it = label.codeUnits.iterator;
    final currentText = StringBuffer();
    final List<InlineSpan> spans = [];
    var isUpper = false;

    while (it.moveNext()) {
      if (it.current case <= 90 && >= 65) {
        if (!isUpper) {
          spans.add(TextSpan(text: currentText.toString(), style: defaultStyle));
          currentText.clear();
        }

        currentText.writeCharCode(it.current);
        isUpper = true;
      } else {
        if (isUpper) {
          spans.add(TextSpan(text: currentText.toString(), style: upperStyle));
          currentText.clear();
        }

        currentText.writeCharCode(it.current);
        isUpper = false;
      }
    }

    if (currentText.isNotEmpty) {
      spans.add(TextSpan(text: currentText.toString(), style: isUpper ? upperStyle : defaultStyle));
    }

    return Text.rich(TextSpan(children: spans));
  }
}
