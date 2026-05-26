import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../menu_utilities.dart';
import 'interface.dart';

class BaseSubmenu extends StatefulWidget implements BaseMenuInterface, BaseMenuItemInterface {
  const BaseSubmenu({
    super.key,
    this.hoverOpenDelay = Duration.zero,
    this.hoverCloseDelay = Duration.zero,
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
    this.builder,
    this.positionDelegate = const DefaultBaseMenuPositioningDelegate(),
    this.overlayChildBuilder,
    this.focusNode,
    this.autofocus = false,
    this.onPressed,
    this.onPointerEnter,
    this.onPointerHover,
    this.onPointerLeave,
    this.behavior = HitTestBehavior.deferToChild,
    this.mouseCursor,
    this.role = SemanticsRole.menuItem,
    this.gestureSemanticsEnabled = true,
    this.gestureSemantics,
  });

  /// The delay after which the submenu should open after being hovered.
  final Duration hoverOpenDelay;

  /// The delay after which the submenu should close when no longer hovered.
  final Duration hoverCloseDelay;

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
  final BaseMenuPositioningDelegate positionDelegate;

  @override
  final PointerEnterEventListener? onPointerEnter;

  @override
  final PointerHoverEventListener? onPointerHover;

  @override
  final PointerExitEventListener? onPointerLeave;

  @override
  final HitTestBehavior behavior;

  @override
  final WidgetStateProperty<MouseCursor>? mouseCursor;

  @override
  final SemanticsRole? role;

  @override
  final bool gestureSemanticsEnabled;

  @override
  final SemanticsGestureDelegate? gestureSemantics;

  @override
  final BaseMenuOverlayChildBuilder? overlayChildBuilder;

  @override
  bool get enabled => onPressed != null;

  @override
  bool get requestFocusOnHover => true;

  @override
  bool get requestCloseOnActivate => false;

  @override
  State<BaseSubmenu> createState() => _BaseSubmenuState();
}

class _BaseSubmenuState extends State<BaseSubmenu> {
  late final _actions = {
    ActivateIntent: CallbackAction<ActivateIntent>(
      onInvoke: (intent) {
        return Actions.maybeInvoke(_focusNode.context!, const BaseMenuEnterIntent.focusFirst());
      },
    ),
    ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
      onInvoke: (intent) {
        return Actions.maybeInvoke(_focusNode.context!, const BaseMenuEnterIntent.focusFirst());
      },
    ),
  };

  MenuController? _internalMenuController;
  MenuController get _menuController => widget.controller ?? _internalMenuController!;

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

    if (widget.controller == null) {
      _internalMenuController = MenuController();
    }

    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(BaseSubmenu oldWidget) {
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

    if (oldWidget.controller != widget.controller) {
      if (widget.controller == null) {
        assert(_internalMenuController == null);
        _internalMenuController = MenuController();
      } else if (oldWidget.controller == null) {
        _internalMenuController = null;
      }
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
    _internalMenuController = null;
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
    _closeTimer = Timer(widget.hoverCloseDelay, () {
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

  Widget _buildOverlayChild(BuildContext context, Widget child) {
    final overlay = BaseHoverable<BaseSubmenu>(
      onEnter: _handlePointerEnterPanel,
      onExit: _handlePointerExitPanel,
      child: child,
    );

    return widget.overlayChildBuilder?.call(context, overlay) ?? overlay;
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
      positionDelegate: widget.positionDelegate,
      overlayChildBuilder: _buildOverlayChild,
      child: Actions(
        actions: _actions,
        child: BaseMenuItem(
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          onPressed: widget.onPressed,
          onPointerEnter: _handlePointerEnterAnchor,
          onPointerHover: widget.onPointerHover,
          onPointerLeave: _handlePointerLeaveAnchor,
          requestCloseOnActivate: widget.requestCloseOnActivate,
          requestFocusOnHover: widget.requestFocusOnHover,
          behavior: widget.behavior,
          mouseCursor: widget.mouseCursor,
          role: widget.role,
          gestureSemanticsEnabled: widget.gestureSemanticsEnabled,
          gestureSemantics: widget.gestureSemantics,
          child: ListenableBuilder(
            listenable: _highlightNotifier,
            builder: _buildHighlight,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
