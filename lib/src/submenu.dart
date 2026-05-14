import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../menu_utilities.dart';
import 'menu_interface.dart';

class Submenu extends StatefulWidget implements BaseMenuInterface, BaseMenuPositionInterface {
  const Submenu({
    super.key,
    this.hoverOpenDelay = Duration.zero,
    required this.child,
    this.onOpen,
    this.onOpenRequest = BaseMenuInterface.defaultOnOpenRequested,
    this.onClose,
    this.onCloseRequest = BaseMenuInterface.defaultOnCloseRequested,
    this.useRootOverlay = false,
    required this.menu,
    this.controller,
    this.consumeOutsideTaps = false,
    this.onFocusChange,
    this.semanticProperties = const SemanticsProperties(
      scopesRoute: true,
      label: 'Submenu',
      role: SemanticsRole.menu,
    ),
    this.orientation = Axis.vertical,

    // Positioning parameters
    this.builder,
    this.alignment,
    this.menuAlignment,
    this.padding = EdgeInsets.zero,
    this.overlayPadding = const EdgeInsets.all(8),
    this.alignmentOffset = Offset.zero,
    this.overlayWrapper,

    // BaseMenuItem parameters
    this.focusNode,
    this.onPressed,
    this.autofocus = false,
    this.onPointerHover,
    this.onPointerEnter,
    this.onPointerLeave,
    this.requestFocusOnHover = true,
    this.requestCloseOnActivate = true,
    this.enabled = true,
    this.behavior = HitTestBehavior.deferToChild,
    this.mouseCursor,
    this.role = SemanticsRole.menuItem,
    this.excludeGestureSemantics = false,
    this.semanticsGestureDelegate,
  });

  final Duration hoverOpenDelay;

  @override
  final VoidCallback? onPressed;

  @override
  final Widget child;

  @override
  final FocusNode? focusNode;

  @override
  final bool autofocus;

  @override
  final MenuController? controller;

  @override
  final bool consumeOutsideTaps;

  @override
  final VoidCallback? onOpen;

  @override
  final RawMenuAnchorOpenRequestedCallback onOpenRequest;

  @override
  final VoidCallback? onClose;

  @override
  final RawMenuAnchorCloseRequestedCallback onCloseRequest;

  @override
  final bool useRootOverlay;

  @override
  final Widget menu;

  @override
  final ValueChanged<bool>? onFocusChange;

  @override
  final SemanticsProperties semanticProperties;

  @override
  final Axis orientation;

  @override
  final RawMenuAnchorChildBuilder? builder;

  @override
  final AlignmentGeometry? menuAlignment;

  @override
  final AlignmentGeometry? alignment;

  @override
  final Offset alignmentOffset;

  @override
  final EdgeInsetsGeometry padding;

  @override
  final EdgeInsetsGeometry overlayPadding;

  @override
  final Widget Function(BuildContext context, Widget child)? overlayWrapper;

  @override
  final PointerEnterEventListener? onPointerEnter;

  @override
  final PointerHoverEventListener? onPointerHover;

  @override
  final PointerExitEventListener? onPointerLeave;

  @override
  final bool requestFocusOnHover;

  @override
  final bool requestCloseOnActivate;

  @override
  final bool enabled;

  @override
  final HitTestBehavior behavior;

  @override
  final WidgetStateProperty<MouseCursor>? mouseCursor;

  @override
  final SemanticsRole? role;

  @override
  final bool excludeGestureSemantics;

  @override
  final SemanticsGestureDelegate? semanticsGestureDelegate;

  @override
  State<Submenu> createState() => _SubmenuState();
}

class _SubmenuState extends State<Submenu> {
  late final _actions = {
    ActivateIntent: CallbackAction<ActivateIntent>(
      onInvoke: (intent) => Actions.maybeInvoke(context, const MenuEnterIntent.focusFirst()),
    ),
    ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
      onInvoke: (intent) => Actions.maybeInvoke(context, const MenuEnterIntent.focusFirst()),
    ),
  };

  final MenuController _menuController = MenuController();
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
    if (_menuController.isOpen) {
      _highlightNotifier.value = _focusNode.hasFocus || _isScopeFocused;
    } else {
      _highlightNotifier.value = null;
    }
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus && !_isScopeFocused && _menuController.isOpen) {
      _scheduleHoverClose();
    } else {
      _closeTimer?.cancel();
    }

    _updateHighlight();
  }

  void _scheduleHoverClose() {
    assert(_menuController.isOpen);
    _closeTimer?.cancel();
    _closeTimer = Timer(widget.hoverOpenDelay, () {
      _closeTimer = null;
      assert(_openTimer?.isActive != true);
      _menuController.close();
    });
  }

  void _scheduleHoverOpen() {
    assert(!_menuController.isOpen);
    _openTimer?.cancel();
    _openTimer = Timer(widget.hoverOpenDelay, () {
      if (!_menuController.isOpen) {
        _menuController.open();
      }
    });
  }

  void _handlePointerEnterAnchor(PointerEnterEvent event) {
    if (!_menuController.isOpen) {
      _scheduleHoverOpen();
    }
    _closeTimer?.cancel();
    widget.onPointerEnter?.call(event);
  }

  void _handlePointerLeaveAnchor(PointerExitEvent event) {
    _openTimer?.cancel();
    if (_menuController.isOpen && !_isScopeFocused) {
      _scheduleHoverClose();
    }
    _updateHighlight();
    widget.onPointerLeave?.call(event);
  }

  void _handlePointerEnterPanel(PointerEvent event) {
    _closeTimer?.cancel();
    _focusNode.requestFocus();
    _updateHighlight();
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
      if (_menuController.isOpen && !_focusNode.hasFocus) {
        _scheduleHoverClose();
      }
    }

    _updateHighlight();
    widget.onFocusChange?.call(focused);
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
      onOpen: widget.onOpen,
      onOpenRequest: widget.onOpenRequest,
      onClose: _handleClose,
      onCloseRequest: widget.onCloseRequest,
      controller: _menuController,
      consumeOutsideTaps: widget.consumeOutsideTaps,
      useRootOverlay: widget.useRootOverlay,
      menu: widget.menu,
      onFocusChange: _handleScopeFocusChange,
      semanticProperties: widget.semanticProperties,
      orientation: widget.orientation,
      builder: widget.builder,
      alignment: widget.alignment,
      menuAlignment: widget.menuAlignment,
      alignmentOffset: widget.alignmentOffset,
      padding: widget.padding,
      overlayPadding: widget.overlayPadding,
      overlayWrapper: _buildOverlayWrapper,
      child: Actions(
        actions: _actions,
        child: BaseMenuItem(
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          requestCloseOnActivate: false,
          onPointerEnter: _handlePointerEnterAnchor,
          onPointerLeave: _handlePointerLeaveAnchor,
          onPointerHover: widget.onPointerHover,
          requestFocusOnHover: widget.requestFocusOnHover,
          enabled: widget.enabled,
          behavior: widget.behavior,
          mouseCursor: widget.mouseCursor,
          role: widget.role,
          excludeGestureSemantics: widget.excludeGestureSemantics,
          semanticsGestureDelegate: widget.semanticsGestureDelegate,
          onPressed: widget.onPressed,
          child: MouseRegion(
            onEnter: _handlePointerEnterAnchor,
            onExit: _handlePointerLeaveAnchor,
            child: ListenableBuilder(
              listenable: _highlightNotifier,
              builder: _buildHighlight,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
