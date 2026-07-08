import 'package:base_menu/base_menu.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../../shared/package.dart';
import '../theme/colors.dart';
import 'app_state_manager.dart';
import 'dropdown_arrow.dart';
import 'menu_panel.dart';
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
  bool _scopeHasFocus = false;
  bool _buttonHasFocus = false;
  bool _isFrameScheduled = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleAnchorFocusChange);
  }

  @override
  void didUpdateWidget(Select oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleAnchorFocusChange);
      widget.focusNode.addListener(_handleAnchorFocusChange);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleAnchorFocusChange);
    super.dispose();
  }

  void _resolveFocus() {
    if (_isFrameScheduled) {
      return;
    }
    _isFrameScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_scopeHasFocus && !_buttonHasFocus && mounted) {
        widget.menuController.close();
      }
      _isFrameScheduled = false;
    });
  }

  void _handleAnchorFocusChange() {
    _buttonHasFocus = widget.focusNode.hasFocus;
    if (!_buttonHasFocus) {
      _resolveFocus();
    }
  }

  void _handleScopeFocusChange(bool value) {
    _scopeHasFocus = value;
    if (!value) {
      _resolveFocus();
    }
  }

  void _handleOpen() {
    MenuTooltipScope.of(context).hideTooltip(sync: true);
    widget.focusNode.requestFocus();
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
      onFocusChange: _handleScopeFocusChange,
      onOpen: _handleOpen,
      positionDelegate: AppStateManager.isHeaderShownOf(context)
          ? const DefaultMenuPositioningDelegate(
              overlayPadding: EdgeInsets.only(top: 98, bottom: 8),
              padding: MenuPanel.defaultPadding,
            )
          : const DefaultMenuPositioningDelegate(
              overlayPadding: EdgeInsets.only(top: 37, bottom: 8),
              padding: MenuPanel.defaultPadding,
            ),
      requestFocusOnHover: false,
      requestOpenOnHover: false,
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
