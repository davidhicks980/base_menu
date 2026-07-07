import 'package:flutter/widgets.dart';

import '../checkbox_menu_item/src/checkbox_menu_item.dart';

class WebCheckbox extends StatelessWidget {
  const WebCheckbox();

  @override
  Widget build(BuildContext context) {
    final bool isChecked = WebCheckboxMenuItem.isCheckedOf(context);
    return isChecked ? const CustomPaint(painter: _WebCheckboxPainter()) : const SizedBox();
  }
}

class _WebCheckboxPainter extends CustomPainter {
  const _WebCheckboxPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.miter
      ..strokeCap = StrokeCap.square;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * (7.0 / 13.0))
      ..lineTo(size.width * 0.4, size.height * (9.5 / 13.0))
      ..lineTo(size.width * 0.8, size.height * 0.2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WebCheckboxPainter oldDelegate) => false;
}
