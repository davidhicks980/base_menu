import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
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
  // Notifier to track whether the submenu or its button has focus, used to
  // apply hover background color.
  final ValueNotifier<bool> _highlightNotifier = ValueNotifier(false);
  FocusNode? _internalFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;
  bool _isAnchorHovered = false;
  bool _isPanelHovered = false;
  bool? _isParentPanelHovered = false;
  bool _isScopeFocused = false;
  Timer? _closeTimer;
  Timer? _openTimer;
  bool _enableHighlight = false;

  void _handleFocusChange() {
    if (_focusNode.hasFocus && !controller.isOpen && !_isAnchorHovered) {
      _enableHighlight = false;
    }
    _updateHighlight();
  }

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
      if (widget.focusNode == null) {
        oldWidget.focusNode?.removeListener(_handleFocusChange);
        _internalFocusNode = FocusNode();
      } else {
        _internalFocusNode!.dispose();
        _internalFocusNode = null;
      }
      _focusNode.addListener(_handleFocusChange);
    }
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
        _highlightNotifier.value = false;
        if (controller.isOpen) {
          _scheduleHoverClose();
        }
      }
    }
  }

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    _openTimer?.cancel();
    _openTimer = null;
    _closeTimer?.cancel();
    _closeTimer = null;
    _highlightNotifier.dispose();
    super.dispose();
  }

  void _scheduleHoverClose() {
    assert(!_isAnchorHovered);
    assert(!_isPanelHovered);
    _closeTimer?.cancel();
    _closeTimer = Timer(widget.hoverOpenDelay, () {
      _closeTimer = null;
      assert(!_isAnchorHovered);
      assert(!_isPanelHovered);
      assert(_openTimer?.isActive != true);
      controller.close();
      _enableHighlight = false;
    });
  }

  void _scheduleHoverOpen() {
    if (controller.isOpen) {
      return;
    }

    _openTimer?.cancel();
    _enableHighlight = true;
    _updateHighlight();
    _openTimer = Timer(widget.hoverOpenDelay, () {
      if (!controller.isOpen) {
        controller.open();
        if (kIsWeb) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted && controller.isOpen && _isAnchorHovered) {
              // Prevents root scope from receiving focus when the menu is opened
              // on web.
              _focusNode.requestFocus();
            }
          });
        }
      }
    });
  }

  void _updateHighlight() {
    _highlightNotifier.value =
        _enableHighlight &&
        (_isAnchorHovered || _isPanelHovered || _focusNode.hasFocus || _isScopeFocused);
  }

  // bool _descendantAnchorHasHighlight = false;
  // void _updateHighlight() {
  //   _highlightNotifier.value =
  //       _enableHighlight &&
  //       (_isAnchorHovered ||
  //           _isPanelHovered ||
  //           _focusNode.hasFocus ||
  //           _isScopeFocused ||
  //           _descendantAnchorHasHighlight);

  //   if (_highlightNotifier.value) {
  //     const DescendantHighlightedNotification().dispatch(context);
  //   } else {
  //     const DescendantLostHighlightNotification().dispatch(context);
  //   }
  // }

  // bool _handleDescendantPanelPointerNotification(_DescendantPanelPointerNotification notification) {
  //   switch (notification) {
  //     case DescendantHighlightedNotification():
  //       _descendantAnchorHasHighlight = true;
  //       print((widget.child, 'highlight on descendant'));
  //     case DescendantLostHighlightNotification():
  //       _descendantAnchorHasHighlight = false;
  //       print((widget.child, 'lost highlight on descendant'));
  //   }

  //   // _updateHighlight();
  //   return false;
  // }

  void _handlePointerEnterAnchor(PointerEnterEvent event) {
    _isAnchorHovered = true;
    _scheduleHoverOpen();
    _closeTimer?.cancel();
    _updateHighlight();
  }

  void _handlePointerLeaveAnchor(PointerExitEvent event) {
    _isAnchorHovered = false;
    _enableHighlight = false;
    _openTimer?.cancel();
    _updateHighlight();

    if (controller.isOpen) {
      if (_isPanelHovered || _isScopeFocused) {
        return;
      }
      _scheduleHoverClose();
    }
  }

  void _handlePointerEnterPanel(PointerEvent event) {
    _isPanelHovered = true;
    _enableHighlight = true;
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
    }

    widget.onPressed?.call();
  }

  void _handleScopeFocusChange(bool focused) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateHighlight();
      }
    });
    if (focused) {
      _enableHighlight = true;
    }
    _isScopeFocused = focused;
  }

  void _handleClose() {
    // Don't call update highlight here because it can cause the panel to
    // momentarily lose the hover color.
    _isPanelHovered = false;

    // Wait for the panel to close before updating the highlight to prevent the
    // hover color from flickering.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _enableHighlight = false;
        _updateHighlight();
      }
    });
  }

  void _handleOpen() {
    _enableHighlight = true;
    _updateHighlight();
  }

  // bool _handleDescendantPanelPointerNotification(_DescendantPanelPointerNotification notification) {
  //   if (notification.isHovered) {
  //     _closeTimer?.cancel();
  //   } else {
  //     if (!_isAnchorHovered && !_isPanelHovered && !_focusNode.hasFocus) {
  //       _scheduleHoverClose('panel leave');
  //     }
  //   }

  //   return false;
  // }

  Widget _buildHighlight(BuildContext context, Widget? child) {
    return ColoredBox(
      color: _highlightNotifier.value
          ? FloogleColors.menuItemFocusColor
          : FloogleColors.transparent,
      child: child,
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
      onOpen: _handleOpen,
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
        debugLabel: widget.debugLabel,
        child: widget.child,
      ),
    );
  }
}
