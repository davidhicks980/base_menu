import 'package:flutter/widgets.dart';

class MenuTooltip extends StatelessWidget {
  const MenuTooltip({super.key, required this.message, required this.child});

  final InlineSpan message;
  final Widget child;

  static Offset _positionDelegate(TooltipPositionContext positionContext) {
    // Center horizontally in relation to the target.
    final double dx = positionContext.target.dx - (positionContext.tooltipSize.width / 2);
    // Place below the target (target center + half height) and add the 4px margin-top.
    final double dy = positionContext.target.dy + (positionContext.targetSize.height / 2) + 4.0;
    return Offset(dx, dy);
  }

  Widget _tooltipBuilder(BuildContext context, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: Container(
        constraints: const BoxConstraints(minHeight: 16.0),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          border: Border.all(color: const Color(0x00000000)),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Text.rich(
          message,
          style: const TextStyle(
            color: Color(0xFFF2F2F2),
            fontFamily: 'RobotoFlex',
            fontSize: 12.0,
            fontVariations: [FontVariation.weight(425)],
            letterSpacing: 0.2,
            height: 16.0 / 12.0,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawTooltip(
      hoverDelay: const Duration(milliseconds: 500),
      semanticsTooltip: message.toPlainText(),
      positionDelegate: _positionDelegate,
      tooltipBuilder: _tooltipBuilder,
      // ignorePointer: true,
      child: child,
    );
  }
}
