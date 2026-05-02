import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../utilities/colors.dart';

class FloogleDocsLogoButton extends StatelessWidget {
  const FloogleDocsLogoButton({super.key});

  static const WidgetStateColor color = WidgetStateColor.fromMap({
    WidgetState.pressed: FloogleColors.logoPressedColor,
    WidgetState.focused: FloogleColors.logoFocusHoverColor,
    WidgetState.hovered: FloogleColors.logoFocusHoverColor,
    WidgetState.any: FloogleColors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    return CoreTappable(
      mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
      onPressed: () {},
      child: Builder(
        builder: (context) {
          return CustomPaint(
            painter: _CircleBackgroundPainter(color: color.resolve(CoreTappable.statesOf(context))),
            child: const _FloogleDocsLogo(),
          );
        },
      ),
    );
  }
}

class _FloogleDocsLogo extends StatelessWidget {
  const _FloogleDocsLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 34.0,
      child: Center(
        child: CustomPaint(size: const Size(34.0 * 0.75, 34.0), painter: _FloogleDocsPainter()),
      ),
    );
  }
}

class _FloogleDocsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final double w = size.width;
    final double h = size.height;
    final double foldSize = w * 0.3;
    final double radius = w * 0.1;

    final bodyPath = Path()
      ..moveTo(radius, 0)
      ..lineTo(w - foldSize, 0)
      ..lineTo(w - foldSize, foldSize)
      ..lineTo(w, foldSize)
      ..lineTo(w, h - radius)
      ..arcToPoint(Offset(w - radius, h), radius: Radius.circular(radius))
      ..lineTo(radius, h)
      ..arcToPoint(Offset(0, h - radius), radius: Radius.circular(radius))
      ..lineTo(0, radius)
      ..arcToPoint(Offset(radius, 0), radius: Radius.circular(radius))
      ..close();

    paint.color = const Color(0xFF4285F4);
    canvas.drawPath(bodyPath, paint);

    final foldPath = Path()
      ..moveTo(w - foldSize, 0)
      ..lineTo(w - foldSize, foldSize)
      ..lineTo(w, foldSize)
      ..close();

    paint.color = const Color(0xFF2B66C5);
    canvas.drawPath(foldPath, paint);

    canvas.save();

    final double availableH = h - foldSize;
    final double logoScale = (availableH * 0.7) / 202.0;

    final double logoW = (156.2 - 9.8) * logoScale;
    final double logoH = (191.6 - 10.4) * logoScale;

    final double startX = (w - logoW) / 2 - (18 * logoScale);
    final double startY = foldSize + (availableH - logoH) * 0.3 - (18 * logoScale);

    canvas.translate(startX, startY);
    canvas.scale(logoScale, logoScale);

    // Top Beam
    paint.color = FloogleColors.white;
    final topBeam = Path()
      ..moveTo(156.2, 10.4)
      ..lineTo(100.4, 10.4)
      ..lineTo(9.8, 101.0)
      ..lineTo(37.7, 128.9)
      ..close();
    canvas.drawPath(topBeam, paint);

    paint.color = FloogleColors.white;
    final bottomChevron = Path()
      ..moveTo(156.2, 94.0)
      ..lineTo(100.4, 94.0)
      ..lineTo(51.6, 142.8)
      ..lineTo(100.4, 191.6)
      ..lineTo(156.2, 191.6)
      ..lineTo(107.4, 142.8)
      ..close();
    canvas.drawPath(bottomChevron, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CircleBackgroundPainter extends CustomPainter {
  _CircleBackgroundPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const double diameter = 54;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), diameter / 2, paint);
  }

  @override
  bool shouldRepaint(covariant _CircleBackgroundPainter oldDelegate) => oldDelegate.color != color;
}
