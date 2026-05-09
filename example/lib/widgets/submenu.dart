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
    this.hoverDelay = Duration.zero,
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
  final Duration hoverDelay;
  final bool autofocus;

  @override
  State<Submenu> createState() => _SubmenuState();
}

class _SubmenuState extends State<Submenu> {
  final MenuController controller = MenuController();
  // Notifier to track whether the submenu or its button has focus, used to
  // apply hover background color.
  final ValueNotifier<bool> focusNotifier = ValueNotifier(false);
  Timer? _openTimer;
  Timer? _closeTimer;

  @override
  void dispose() {
    _openTimer?.cancel();
    _closeTimer?.cancel();
    focusNotifier.dispose();
    super.dispose();
  }

  void _handleFocusChange(bool value) {
    focusNotifier.value = value;
    if (!value) {
      _closeTimer ??= Timer(widget.hoverDelay, () {
        if (mounted && controller.isOpen) {
          controller.close();
        }
      });
    } else {
      _closeTimer?.cancel();
      _closeTimer = null;
    }
  }

  Widget _buildHoverBackground(BuildContext context, bool hasFocus, Widget? child) {
    return ColoredBox(
      color: hasFocus ? FloogleColors.menuItemFocusColor : FloogleColors.transparent,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseMenu(
      padding: MenuPanel.defaultPadding,
      controller: controller,
      alignment: widget.alignment,
      menuAlignment: widget.menuAlignment,
      onFocusChange: _handleFocusChange,
      menu: widget.panel,
      child: _SubmenuButton(
        hoverDelay: widget.hoverDelay,
        autofocus: widget.autofocus,
        onPressed: widget.onPressed,
        child: ValueListenableBuilder<bool>(
          valueListenable: focusNotifier,
          builder: _buildHoverBackground,
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
  });

  final VoidCallback? onPressed;
  final Duration hoverDelay;
  final bool autofocus;
  final Widget child;

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
    super.dispose();
  }

  void _handleDelayedOpen() {
    if (!context.mounted || controller.isOpen) {
      return;
    }

    Actions.maybeInvoke(context, const MenuEnterIntent.setFirstFocus());
    _openTimer = null;
  }

  void _handlePointerEnter(PointerHoverEvent event) {
    _openTimer ??= Timer(widget.hoverDelay, _handleDelayedOpen);
  }

  void _handlePointerLeave(PointerExitEvent event) {
    _openTimer?.cancel();
    _openTimer = null;
  }

  void _handlePressed() {
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
