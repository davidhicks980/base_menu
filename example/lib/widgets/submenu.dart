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
  final ValueNotifier<Set<WidgetState>> _highlightNotifier = ValueNotifier({});
  late final FocusNode _focusNode = FocusNode();
  bool _isAnchorHovered = false;
  bool _isPanelHovered = false;
  bool? _isParentPanelHovered = false;
  bool _isScopeFocused = false;
  Timer? _closeTimer;
  Timer? _openTimer;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      _updateHighlight();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scopeHovered =
        BaseHoverable.maybeIsHoveredOf<Submenu>(context) ??
        BaseHoverable.maybeIsHoveredOf<BaseMenu>(context);

    if (_isParentPanelHovered != scopeHovered) {
      _isParentPanelHovered = scopeHovered;
      if (scopeHovered == false && !_isPanelHovered && !_isScopeFocused) {
        _highlightNotifier.value = {};
        if (controller.isOpen) {
          _scheduleHoverClose();
        }
      }
    }
  }

  @override
  void dispose() {
    _openTimer?.cancel();
    _openTimer = null;
    _closeTimer?.cancel();
    _closeTimer = null;
    _highlightNotifier.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scheduleHoverClose([String? label]) {
    assert(!_isAnchorHovered);
    assert(!_isPanelHovered);
    _closeTimer?.cancel();
    _closeTimer = Timer(widget.hoverOpenDelay, () {
      _closeTimer = null;
      assert(!_isAnchorHovered, '${widget.child}${label != null ? '($label)' : ''} hover close');
      assert(_openTimer?.isActive != true);
      assert(!_isPanelHovered, '${widget.child}${label != null ? '($label)' : ''} hover close');
      controller.close();
    });
  }

  void _scheduleHoverOpen() {
    if (controller.isOpen) {
      return;
    }

    _openTimer?.cancel();
    _openTimer = Timer(widget.hoverOpenDelay, () {
      if (!controller.isOpen) {
        controller.open();
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted && controller.isOpen && _isAnchorHovered) {
            // Prevents root scope from receiving focus when the menu is opened
            // on web.
            _focusNode.requestFocus();
          }
        });
      }
    });
  }

  void _updateHighlight() {
    if (!_enableHighlight) {
      return;
    }
    _highlightNotifier.value = _isPanelHovered || _focusNode.hasFocus || _isScopeFocused
        ? {WidgetState.focused}
        : {};
  }

  void _handlePointerEnterAnchor(PointerEnterEvent event) {
    _isAnchorHovered = true;
    _scheduleHoverOpen();
    _closeTimer?.cancel();
    _updateHighlight();
  }

  void _handlePointerLeaveAnchor(PointerExitEvent event) {
    _isAnchorHovered = false;
    _openTimer?.cancel();
    if (controller.isOpen) {
      if (_isPanelHovered || _isScopeFocused) {
        return;
      }
      _scheduleHoverClose();
    }

    _updateHighlight();
  }

  void _handlePointerEnterPanel(PointerEnterEvent event) {
    _isPanelHovered = true;
    _closeTimer?.cancel();
    _updateHighlight();
  }

  void _handlePointerLeavePanel(PointerExitEvent event) {
    _isPanelHovered = false;
    _focusNode.requestFocus();
    _updateHighlight();
  }

  void _handlePressed() {
    if (!controller.isOpen) {
      controller.open();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && controller.isOpen) {
          _focusNode.requestFocus();
          _updateHighlight();
        }
      });
    }

    widget.onPressed?.call();
  }

  void _handleScopeFocusChange(bool focused) {
    _isScopeFocused = focused;
    _updateHighlight();
  }

  bool _enableHighlight = false;
  void _handleClose() {
    // Don't call update highlight here because it can cause the panel to
    // momentarily lose the hover color.
    _isPanelHovered = false;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _enableHighlight = false;
        _highlightNotifier.value = {};
        _updateHighlight();
      }
    });
  }

  Widget _buildHighlight(BuildContext context, Widget? child) {
    return BaseMenuItemStateProvider(
      merge: true,
      states: _enableHighlight ? _highlightNotifier.value : {},
      child: child!,
    );
  }

  Widget _buildOverlayWrapper(BuildContext context, Widget child) {
    return BaseHoverable<Submenu>(
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
      onClose: _handleClose,
      onOpen: () {
        _enableHighlight = true;
        _updateHighlight();
      },
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
        debugLabel: 'SubmenuButton(${widget.child})',
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
    this.debugLabel,
  });

  final VoidCallback? onPressed;
  final Duration hoverDelay;
  final bool autofocus;
  final FocusNode focusNode;
  final Widget child;
  final PointerExitEventListener? onPointerLeave;
  final PointerEnterEventListener? onPointerEnter;
  final String? debugLabel;

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
    widget.focusNode.debugLabel = widget.debugLabel;
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
