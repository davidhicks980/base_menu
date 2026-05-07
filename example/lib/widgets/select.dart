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
    this.focusNode,
    this.onOpen,
    this.onClose,
    this.buttonPadding = const EdgeInsets.symmetric(horizontal: 11, vertical: 2),
    this.buttonRadius = const BorderRadiusGeometry.all(Radius.circular(4)),
    this.buttonDecoration,
    this.menuController,
    this.requestFocusOnHover = false,
  });

  final Widget child;
  final Widget panel;
  final MenuController? menuController;
  final EdgeInsetsGeometry buttonPadding;
  final BorderRadiusGeometry buttonRadius;
  final WidgetStateProperty<BoxDecoration>? buttonDecoration;
  final bool requestFocusOnHover;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final controller = menuController ?? MenuController();
    return BaseMenu(
      onOpen: onOpen,
      onClose: onClose,
      controller: controller,
      onFocusChange: (bool value) {
        if (!value) {
          controller.close();
        }
      },
      overlayPadding: const EdgeInsets.only(top: 98, bottom: 8),
      padding: MenuPanel.defaultPadding,
      panel: panel,
      child: _SelectTextButton(
        focusNode: focusNode,
        padding: buttonPadding,
        radius: buttonRadius,
        decoration: buttonDecoration,
        requestFocusOnHover: requestFocusOnHover,
        menuController: controller,
        child: child,
      ),
    );
  }
}

class _SelectTextButton extends StatefulWidget {
  const _SelectTextButton({
    required this.child,
    required this.padding,
    required this.menuController,
    required this.radius,
    required this.focusNode,
    required this.decoration,
    required this.requestFocusOnHover,
  });
  final EdgeInsetsGeometry padding;
  final FocusNode? focusNode;
  final WidgetStateProperty<Decoration>? decoration;
  final bool requestFocusOnHover;
  final MenuController menuController;
  final BorderRadiusGeometry radius;
  final Widget child;

  @override
  State<_SelectTextButton> createState() => _SelectTextButtonState();
}

class _SelectTextButtonState extends State<_SelectTextButton> {
  void _handlePressed() {
    if (widget.menuController.isOpen) {
      widget.menuController.close();
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
            child: MergeSemantics(
              child: Semantics(
                expanded: isOpen,
                child: BaseMenuItem(
                  role: null,
                  focusNode: widget.focusNode,
                  mouseCursor: WidgetStateMouseCursor.adaptiveClickable,
                  requestFocusOnHover: widget.requestFocusOnHover,
                  requestCloseOnActivate: false,
                  onPressed: _handlePressed,
                  child: Builder(
                    builder: (context) {
                      Decoration decoration;
                      if (widget.decoration != null) {
                        decoration = widget.decoration!.resolve(BaseMenuItem.statesOf(context));
                      } else if (isOpen) {
                        decoration = BoxDecoration(
                          color: FloogleColors.activeColor,
                          borderRadius: widget.radius,
                        );
                      } else if (BaseMenuItem.isFocusedOf(context) ||
                          BaseMenuItem.isHoveredOf(context)) {
                        decoration = BoxDecoration(
                          color: FloogleColors.zoomHoverColor,
                          borderRadius: widget.radius,
                        );
                      } else {
                        decoration = const BoxDecoration();
                      }

                      return DecoratedBox(decoration: decoration, child: label);
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
