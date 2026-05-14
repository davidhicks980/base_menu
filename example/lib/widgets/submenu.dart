import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

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
    this.focusNode,
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
  final FocusNode? focusNode;
  final Duration hoverOpenDelay;
  final bool autofocus;

  @override
  State<Submenu> createState() => _SubmenuState();
}

class _SubmenuState extends State<Submenu> {
  final MenuController controller = MenuController();
  // Notifier to track whether the submenu or its button has focus.
  //
  // This is used to apply a pseudo focus highlight on ancestor submenu anchors.
  final ValueNotifier<bool?> _highlightNotifier = ValueNotifier(null);
  FocusNode? _internalFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;
  bool _isScopeFocused = false;
  Timer? _closeTimer;
  Timer? _openTimer;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }

    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(Submenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      if (widget.focusNode == null) {
        _internalFocusNode = FocusNode();
      } else {
        _internalFocusNode!.dispose();
        _internalFocusNode = null;
      }
      _focusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    _openTimer?.cancel();
    _openTimer = null;
    _closeTimer?.cancel();
    _closeTimer = null;
    _focusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    _internalFocusNode = null;
    _highlightNotifier.dispose();
    super.dispose();
  }

  void _updateHighlight() {
    if (controller.isOpen) {
      _highlightNotifier.value = _focusNode.hasFocus || _isScopeFocused;
    } else {
      _highlightNotifier.value = null;
    }
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus && !_isScopeFocused && controller.isOpen) {
      _scheduleHoverClose();
    } else {
      _closeTimer?.cancel();
    }

    _updateHighlight();
  }

  void _scheduleHoverClose() {
    assert(controller.isOpen);
    _closeTimer?.cancel();
    _closeTimer = Timer(widget.hoverOpenDelay, () {
      _closeTimer = null;
      assert(_openTimer?.isActive != true);
      controller.close();
    });
  }

  void _scheduleHoverOpen() {
    assert(!controller.isOpen);
    _openTimer?.cancel();
    _openTimer = Timer(widget.hoverOpenDelay, () {
      if (!controller.isOpen) {
        controller.open();
      }
    });
  }

  void _handlePointerEnterAnchor(PointerEnterEvent event) {
    if (!controller.isOpen) {
      _scheduleHoverOpen();
    }
    _closeTimer?.cancel();
  }

  void _handlePointerLeaveAnchor(PointerExitEvent event) {
    _openTimer?.cancel();
    if (controller.isOpen && !_isScopeFocused) {
      _scheduleHoverClose();
    }
    _updateHighlight();
  }

  void _handlePointerEnterPanel(PointerEvent event) {
    _closeTimer?.cancel();
  }

  void _handlePressed() {
    if (!controller.isOpen) {
      controller.open();
    }

    widget.onPressed?.call();
  }

  void _handlePointerExitPanel(PointerExitEvent event) {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  void _handleScopeFocusChange(bool focused) {
    _isScopeFocused = focused;
    if (_isScopeFocused) {
      _closeTimer?.cancel();
    } else {
      if (controller.isOpen && !_focusNode.hasFocus) {
        _scheduleHoverClose();
      }
    }

    _updateHighlight();
  }

  void _handleClose() {
    _isScopeFocused = false;

    // Let the menu close before updating the highlight state.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateHighlight();
      }
    });
  }

  Widget _buildHighlight(BuildContext context, Widget? child) {
    return BaseFocusableStateInjector<BaseMenuItem>(
      showFocusHighlight: _highlightNotifier.value,
      child: child!,
    );
  }

  Widget _buildOverlayWrapper(BuildContext context, Widget child) {
    return BaseHoverable<Submenu>(
      onEnter: _handlePointerEnterPanel,
      onExit: _handlePointerExitPanel,
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
      onClose: _handleClose,
      menuAlignment: widget.menuAlignment,
      onFocusChange: _handleScopeFocusChange,
      semanticProperties: SemanticsProperties(label: '${widget.child}', role: SemanticsRole.menu),
      menu: widget.panel,
      child: _SubmenuButton(
        focusNode: _focusNode,
        hoverDelay: widget.hoverOpenDelay,
        autofocus: widget.autofocus,
        onPressed: _handlePressed,
        onPointerLeave: _handlePointerLeaveAnchor,
        onPointerEnter: _handlePointerEnterAnchor,
        child: ListenableBuilder(
          listenable: _highlightNotifier,
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
  final PointerExitEventListener? onPointerLeave;
  final PointerEnterEventListener? onPointerEnter;

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
  MenuController? _controller;
  MenuController get controller => _controller ??= MenuController.maybeOf(context)!;

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: _actions,
      child: BaseMenuItem(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        requestCloseOnActivate: false,
        onPointerEnter: widget.onPointerEnter,
        onPointerLeave: widget.onPointerLeave,
        onTap: widget.onPressed,
        child: widget.child,
      ),
    );
  }
}
