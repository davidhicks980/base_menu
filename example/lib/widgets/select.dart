import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../utilities/colors.dart';
import 'dropdown_arrow.dart';

class Select extends StatelessWidget {
  const Select({
    super.key,
    required this.child,
    required this.panel,
    this.padding = const EdgeInsets.symmetric(vertical: 6),
    this.buttonPadding = const EdgeInsets.symmetric(horizontal: 11, vertical: 2),
    this.buttonRadius = const BorderRadiusGeometry.all(Radius.circular(4)),
  });

  final Widget child;
  final Widget panel;
  final EdgeInsetsGeometry buttonPadding;
  final BorderRadiusGeometry buttonRadius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final controller = MenuController();
    return CoreMenu(
      controller: controller,
      onFocusChange: (value) {
        if (!value) {
          controller.close();
        }
      },
      overlayPadding: const EdgeInsets.only(top: 98, bottom: 8),
      padding: padding,
      panel: panel,
      child: _SelectTextButton(padding: buttonPadding, radius: buttonRadius, child: child),
    );
  }
}

class _SelectTextButton extends StatefulWidget {
  const _SelectTextButton({required this.child, required this.padding, required this.radius});
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry radius;
  final Widget child;

  @override
  State<_SelectTextButton> createState() => _SelectTextButtonState();
}

class _SelectTextButtonState extends State<_SelectTextButton> {
  final focusNode = FocusNode(debugLabel: 'SelectTextButton');

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  void _handlePressed() {
    final controller = MenuController.maybeOf(context);
    if (controller == null) {
      return;
    }
    if (controller.isOpen) {
      controller.close();
    } else {
      Actions.invoke(context, const CoreMenuEnterIntent.focusFirst());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = MenuController.maybeIsOpenOf(context) ?? false;
    final label = Padding(
      padding: widget.padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DefaultTextStyle(
            style: TextStyle(
              fontFamily: 'GoogleSans',
              fontSize: 14,
              color: isOpen ? FloogleColors.midGrayText : FloogleColors.selectTextColor,
              height: 1.0,
              letterSpacing: 0.1,
              fontWeight: kIsWeb ? FontWeight.w500 : const FontWeight(450),
              fontVariations: const [FontVariation.opticalSize(17)],
              decoration: TextDecoration.none,
            ),
            overflow: TextOverflow.ellipsis,
            child: Flexible(child: widget.child),
          ),
          const DropdownArrow(),
        ],
      ),
    );

    return CoreMenuItem(
      role: null,
      focusNode: focusNode,
      mouseCursor: WidgetStateMouseCursor.clickable,
      isExpanded: isOpen,
      requestFocusOnHover: false,
      requestCloseOnActivate: false,
      onPressed: _handlePressed,
      child: SizedBox(
        height: 30,
        child: Builder(
          builder: (context) {
            return DecoratedBox(
              decoration: isOpen
                  ? BoxDecoration(color: FloogleColors.activeColor, borderRadius: widget.radius)
                  : CoreTappable.isFocusedOf(context) || CoreTappable.isHoveredOf(context)
                  ? BoxDecoration(
                      color: const Color.fromRGBO(68, 71, 70, 0.08),
                      borderRadius: widget.radius,
                    )
                  : const BoxDecoration(),
              child: label,
            );
          },
        ),
      ),
    );
  }
}
