import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../../shared/package.dart';
import '../theme/colors.dart';

const webStyle = TextStyle(
  color: FloogleColors.onDarkGray,
  fontFamily: 'GoogleSans',
  package: kPackage,
  fontSize: 12.0,
  fontVariations: [FontVariation.weight(500)],
  letterSpacing: 0.1,
  height: 1,
  decoration: TextDecoration.none,
);

const defaultStyle = TextStyle(
  color: FloogleColors.onDarkGray,
  fontFamily: 'GoogleSans',
  package: kPackage,
  fontSize: 12.0,
  fontVariations: [FontVariation.weight(425)],
  letterSpacing: 0.1,
  height: 1,
  decoration: TextDecoration.none,
);

class MenuTooltip extends StatefulWidget {
  const MenuTooltip({
    super.key,
    required this.message,
    required this.child,
    this.enableSemantics = true,
  });

  final bool enableSemantics;
  final InlineSpan message;
  final Widget child;

  @override
  State<MenuTooltip> createState() => _MenuTooltipState();
}

class _MenuTooltipState extends State<MenuTooltip> {
  bool isForwardOrComplete = false;

  static Offset _positionDelegate(TooltipPositionContext positionContext) {
    final anchorRect =
        (positionContext.target - positionContext.targetSize.center(Offset.zero)) &
        positionContext.targetSize;
    // Center the tooltip below the anchor rect, with a small offset.
    final tooltipOffset = Offset(
      anchorRect.center.dx - positionContext.tooltipSize.width / 2,
      anchorRect.bottom + 4.0,
    );
    return tooltipOffset;
  }

  Widget _tooltipBuilder(BuildContext context, Animation<double> animation) {
    final child = Container(
      padding: const EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 8.0, 2.0),
      constraints: const BoxConstraints(minHeight: 24),
      decoration: BoxDecoration(
        color: FloogleColors.darkGray,
        border: const .fromBorderSide(BorderSide(color: FloogleColors.transparent)),
        borderRadius: .circular(4.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text.rich(
            widget.message,
            style: kIsWeb ? webStyle : defaultStyle,
            textAlign: TextAlign.center,
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              leadingDistribution: .even,
            ),
          ),
        ],
      ),
    );

    // On web, additional overlays can cause focus to drift to the root scope.
    // This logic ensures that focus returns to the previously focused element
    // when the tooltip appears.
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        if (kIsWeb && isForwardOrComplete != animation.isForwardOrCompleted) {
          isForwardOrComplete = animation.isForwardOrCompleted;
          final tooltip = isForwardOrComplete ? child! : const SizedBox();
          // Prevents the root focus scope from taking focus on web.
          final previousPrimaryFocus = FocusManager.instance.primaryFocus;
          if (previousPrimaryFocus == null) {
            return tooltip;
          }

          SchedulerBinding.instance.addPostFrameCallback((_) {
            FocusManager.instance.applyFocusChangesIfNeeded();
            if (FocusManager.instance.rootScope.hasPrimaryFocus) {
              previousPrimaryFocus.requestFocus();
            }
          });
        }
        return isForwardOrComplete ? child! : const SizedBox();
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawTooltip(
      hoverDelay: const Duration(milliseconds: 500),
      semanticsTooltip: widget.enableSemantics
          ? widget.message.toPlainText(includePlaceholders: false)
          : null,
      positionDelegate: _positionDelegate,
      tooltipBuilder: _tooltipBuilder,
      child: widget.child,
    );
  }
}
