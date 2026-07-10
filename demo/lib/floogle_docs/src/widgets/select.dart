import 'package:base_menu/base_menu.dart';
import 'package:flutter/widgets.dart';

import '../../../shared/package.dart';
import '../theme/colors.dart';
import '../utilities/exclusive_menu_manager.dart';
import 'app_state_manager.dart';
import 'dropdown_arrow.dart';
import 'tooltip.dart';

class Select extends StatefulWidget {
  const Select({
    super.key,
    required this.child,
    required this.panel,
    required this.focusNode,
    this.buttonPadding = const EdgeInsets.only(left: 11, right: 6, top: 2, bottom: 2),
    this.buttonRadius = const BorderRadius.all(Radius.circular(4)),
    required this.menuController,
  });

  final Widget child;
  final Widget panel;
  final FocusNode focusNode;
  final MenuController menuController;
  final EdgeInsetsGeometry buttonPadding;
  final BorderRadiusGeometry buttonRadius;

  @override
  State<Select> createState() => _SelectState();
}

class _SelectState extends State<Select> {
  void _handleOpen() {
    MenuTooltipScope.of(context).hideTooltip(sync: true);
    widget.focusNode.requestFocus();
    ExclusiveMenuManager.of(context).setActive(widget.menuController);
  }

  void _handleClose() {
    ExclusiveMenuManager.of(context).setInactive(widget.menuController);
  }

  void _handlePressed() {
    if (widget.menuController.isOpen) {
      widget.menuController.close();
    } else {
      widget.menuController.open();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseSubmenu(
      controller: widget.menuController,
      onOpen: _handleOpen,
      onClose: _handleClose,
      positionDelegate: AppStateManager.isHeaderShownOf(context)
          ? const DefaultMenuPositioningDelegate(
              edgeBehavior: EdgeBehavior(
                vertical: EdgeBehaviorStrategy(shift: false, flip: false, constrain: false),
                horizontal: EdgeBehaviorStrategy(shift: true, flip: true, constrain: false),
              ),
            )
          : const DefaultMenuPositioningDelegate(
              edgeBehavior: EdgeBehavior(
                vertical: EdgeBehaviorStrategy(shift: false, flip: false, constrain: false),
                horizontal: EdgeBehaviorStrategy(shift: true, flip: true, constrain: false),
              ),
            ),
      requestFocusOnHover: false,
      requestOpenOnPointerEnter: false,
      requestCloseOnPointerExit: false,
      menu: widget.panel,
      focusNode: widget.focusNode,
      mouseCursor: WidgetStateMouseCursor.clickable,
      onPressed: _handlePressed,
      child: _SelectTextButton(
        padding: widget.buttonPadding,
        radius: widget.buttonRadius,
        child: widget.child,
      ),
    );
  }
}

class _SelectTextButton extends StatelessWidget {
  const _SelectTextButton({required this.padding, required this.radius, required this.child});
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final label = Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DefaultTextStyle.merge(
            style: const TextStyle(
              fontFamily: 'GoogleSans',
              package: kPackage,
              fontSize: 14,
              height: 1.2,
              letterSpacing: 0.1,
              fontWeight: FontWeight(450),
              fontVariations: [FontVariation.opticalSize(17)],
              decoration: TextDecoration.none,
            ),
            overflow: TextOverflow.ellipsis,
            child: Flexible(child: child),
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
            child: Builder(
              builder: (context) {
                return DecoratedBox(
                  decoration: isOpen
                      ? BoxDecoration(color: FloogleColors.toolbarItemPressed, borderRadius: radius)
                      : BaseMenuItem.isFocusedOf(context) || BaseMenuItem.isHoveredOf(context)
                      ? BoxDecoration(
                          color: FloogleColors.toolbarItemHoverFocus,
                          borderRadius: radius,
                        )
                      : const BoxDecoration(),
                  child: label,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
