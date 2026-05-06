import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../utilities/colors.dart';
import 'dropdown_arrow.dart';
import 'menu_panel.dart';

class Select extends StatelessWidget {
  const Select({
    super.key,
    required this.child,
    required this.panel,
    this.buttonPadding = const EdgeInsets.symmetric(horizontal: 11, vertical: 2),
    this.buttonRadius = const BorderRadiusGeometry.all(Radius.circular(4)),
    this.menuController,
  });

  final Widget child;
  final Widget panel;
  final MenuController? menuController;
  final EdgeInsetsGeometry buttonPadding;
  final BorderRadiusGeometry buttonRadius;

  @override
  Widget build(BuildContext context) {
    final controller = menuController ?? MenuController();
    return BaseMenu(
      controller: controller,
      onFocusChange: (bool value) {
        if (!value) {
          controller.close();
        }
      },
      overlayPadding: const EdgeInsets.only(top: 98, bottom: 8),
      padding: MenuPanel.defaultPadding,
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
      Actions.invoke(context, const MenuEnterIntent.focusFirst());
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = Padding(
      padding: widget.padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DefaultTextStyle.merge(
            style: const TextStyle(
              fontFamily: 'GoogleSans',
              fontSize: 14,
              height: 1.2,
              letterSpacing: 0.1,
              fontWeight: FontWeight(450),
              fontVariations: [FontVariation.opticalSize(17)],
              decoration: TextDecoration.none,
            ),
            overflow: TextOverflow.ellipsis,
            child: Flexible(child: widget.child),
          ),
          const DropdownArrow(),
        ],
      ),
    );

    return Builder(
      builder: (context) {
        final isOpen = MenuController.maybeIsOpenOf(context) ?? false;
        return DefaultTextStyle(
          style: TextStyle(color: isOpen ? FloogleColors.grey : FloogleColors.selectTextColor),
          child: SizedBox(
            height: 30,
            child: BaseMenuItem(
              role: null,
              focusNode: focusNode,
              mouseCursor: WidgetStateMouseCursor.clickable,
              isExpanded: isOpen,
              requestFocusOnHover: false,
              requestCloseOnActivate: false,
              onPressed: _handlePressed,
              child: Builder(
                builder: (context) {
                  return DecoratedBox(
                    decoration: isOpen
                        ? BoxDecoration(
                            color: FloogleColors.activeColor,
                            borderRadius: widget.radius,
                          )
                        : BaseMenuItem.isFocusedOf(context) || BaseMenuItem.isHoveredOf(context)
                        ? BoxDecoration(
                            color: FloogleColors.zoomHoverColor,
                            borderRadius: widget.radius,
                          )
                        : const BoxDecoration(),
                    child: label,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
