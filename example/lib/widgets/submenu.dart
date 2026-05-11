import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../utilities/colors.dart';
import 'menu_action_label.dart';
import 'menu_panel.dart';

class Submenu extends StatefulWidget {
  const Submenu({
    super.key,
    this.onPressed,
    this.alignment,
    this.menuAlignment,
    this.hoverOpenDelay = Duration.zero,
    this.leading,
    required this.child,
    required this.panel,
    this.autofocus = false,
  });

  final VoidCallback? onPressed;
  final AlignmentGeometry? alignment;
  final AlignmentGeometry? menuAlignment;
  final Widget? leading;
  final Widget child;
  final Widget panel;
  final Duration hoverOpenDelay;
  final bool autofocus;

  @override
  State<Submenu> createState() => _SubmenuState();
}

class _SubmenuState extends State<Submenu> {
  final MenuController controller = MenuController();
  // Notifier to track whether the submenu or its button has focus, used to
  // apply hover background color.
  final ValueNotifier<bool> _highlightNotifier = ValueNotifier(false);
  late final FocusNode _focusNode = FocusNode(debugLabel: '${widget.child}');
  FocusScopeNode? _overlayScope;
  bool _isAnchorHovered = false;
  bool _isPanelHovered = false;
  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_handleSiblingFocusChange);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_handleSiblingFocusChange);
    _closeTimer?.cancel();
    _closeTimer = null;
    _highlightNotifier.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSiblingFocusChange() {
    if (!_focusNode.hasFocus) {
      final hasOverlayFocus = _overlayScope?.hasFocus == true;
      if (!hasOverlayFocus) {
        _scheduleClose();
        _highlightNotifier.value = false;
      } else {
        _cancelCloseTimer();
      }
    }
  }

  void _scheduleClose({bool closeSelf = true}) {
    _closeTimer?.cancel();
    _closeTimer = Timer(widget.hoverOpenDelay, () {
      if (mounted && !_isAnchorHovered && !_isPanelHovered) {
        if (closeSelf) {
          controller.close();
          _highlightNotifier.value = false;
          if (_overlayScope?.hasFocus == true) {
            _overlayScope?.unfocus();
            final parentScope = FocusScope.of(context, createDependency: false);
            FocusManager.instance.rootScope.setFirstFocus(parentScope);
          }
        } else {
          _focusNode.requestFocus();
          if (_overlayScope != null) {
            FocusManager.instance.rootScope.setFirstFocus(_overlayScope!);
          }
        }
      }
    });
  }

  void _cancelCloseTimer() {
    _closeTimer?.cancel();
    _highlightNotifier.value = true; // Ensures the button stays highlighted
  }

  void _handlePointerEnterAnchor(PointerHoverEvent event) {
    _isAnchorHovered = true;
    _cancelCloseTimer();
  }

  void _handlePointerLeaveAnchor(PointerExitEvent event) {
    _isAnchorHovered = false;
    _highlightNotifier.value = false;
    _scheduleClose();
  }

  void _handlePointerLeavePanel(PointerExitEvent event) {
    _isPanelHovered = false;
    _scheduleClose(closeSelf: false);
  }

  void _handlePointerEnterPanel(PointerEnterEvent event) {
    _isPanelHovered = true;
    _cancelCloseTimer();
  }

  Widget _buildHighlight(BuildContext context, bool isHighlighted, Widget? child) {
    return ColoredBox(
      color: isHighlighted ? FloogleColors.menuItemFocusColor : FloogleColors.transparent,
      child: child,
    );
  }

  Widget _buildOverlayWrapper(BuildContext context, Widget child) {
    return MouseRegion(
      hitTestBehavior: HitTestBehavior.deferToChild,
      onEnter: _handlePointerEnterPanel,
      onExit: _handlePointerLeavePanel,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseMenu(
      overlayWrapper: _buildOverlayWrapper,
      padding: MenuPanel.defaultPadding,
      controller: controller,
      alignment: widget.alignment,
      menuAlignment: widget.menuAlignment,
      menu: Builder(
        builder: (context) {
          _overlayScope = FocusScope.of(context);
          return widget.panel;
        },
      ),
      child: _SubmenuButton(
        focusNode: _focusNode,
        hoverDelay: widget.hoverOpenDelay,
        autofocus: widget.autofocus,
        onPressed: widget.onPressed,
        onPointerLeave: _handlePointerLeaveAnchor,
        onPointerEnter: _handlePointerEnterAnchor,
        child: ValueListenableBuilder<bool>(
          valueListenable: _highlightNotifier,
          builder: _buildHighlight,
          child: SubmenuActionLabel(
            leading: widget.leading,
            axis: Axis.vertical,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _SubmenuButton extends StatefulWidget {
  const _SubmenuButton({
    this.onPressed,
    required this.child,
    required this.hoverDelay,
    required this.autofocus,
    required this.focusNode,
    required this.onPointerLeave,
    required this.onPointerEnter,
  });

  final VoidCallback? onPressed;
  final Duration hoverDelay;
  final bool autofocus;
  final FocusNode focusNode;
  final Widget child;
  final void Function(PointerExitEvent)? onPointerLeave;
  final void Function(PointerHoverEvent)? onPointerEnter;

  @override
  State<_SubmenuButton> createState() => __SubmenuButtonState();
}

class __SubmenuButtonState extends State<_SubmenuButton> {
  late final Map<Type, Action<Intent>> _actions = {
    ActivateIntent: CallbackAction<ActivateIntent>(
      onInvoke: (intent) => Actions.maybeInvoke(context, const MenuEnterIntent.focusFirst()),
    ),
    ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
      onInvoke: (intent) => Actions.maybeInvoke(context, const MenuEnterIntent.focusFirst()),
    ),
  };
  Timer? _openTimer;
  MenuController? _controller;
  MenuController get controller => _controller ??= MenuController.maybeOf(context)!;

  @override
  void dispose() {
    _openTimer?.cancel();
    _openTimer = null;
    super.dispose();
  }

  void _cancelTimer() {
    _openTimer?.cancel();
    _openTimer = null;
  }

  void _handleDelayedOpen() {
    _cancelTimer();
    if (!mounted || controller.isOpen) {
      return;
    }

    Actions.maybeInvoke(context, const MenuEnterIntent.setFirstFocus());
  }

  void _handlePointerEnter(PointerHoverEvent event) {
    _openTimer ??= Timer(widget.hoverDelay, _handleDelayedOpen);
    widget.onPointerEnter?.call(event);
  }

  void _handlePointerLeave(PointerExitEvent event) {
    _cancelTimer();
    widget.onPointerLeave?.call(event);
  }

  void _handlePressed() {
    _cancelTimer();
    if (!controller.isOpen) {
      controller.open();
    }

    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: _actions,
      child: BaseMenuItem(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        requestCloseOnActivate: false,
        onPointerEnter: _handlePointerEnter,
        onPointerLeave: _handlePointerLeave,
        onTap: _handlePressed,
        child: widget.child,
      ),
    );
  }
}
