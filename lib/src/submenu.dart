import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../menu_utilities.dart';
import 'interface.dart';

typedef HPreviousIntent = BaseMenuHorizontalFocusPreviousIntent;
typedef HNextIntent = BaseMenuHorizontalFocusNextIntent;
typedef VPreviousIntent = BaseMenuVerticalFocusPreviousIntent;
typedef VNextIntent = BaseMenuVerticalFocusNextIntent;

class BaseSubmenu extends StatefulWidget with BaseMenuInterface implements BaseMenuItemInterface {
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
    required this.controller,
    this.consumeOutsideTaps = false,
    this.onFocusChange,
    this.directionalFocusEdgeBehavior,
    this.semanticProperties = const SemanticsProperties(
      scopesRoute: true,
      namesRoute: true,
      label: 'Submenu',
      role: SemanticsRole.menu,
    ),
    this.orientation = Axis.vertical,
    this.positionDelegate = const DefaultBaseMenuPositioningDelegate(),
    this.overlayChildBuilder,
    this.focusNode,
    this.autofocus = false,
    this.onPressed,
    this.onActivate,
    this.onPointerEnter,
    this.onPointerHover,
    this.onPointerLeave,
    this.behavior = HitTestBehavior.deferToChild,
    this.mouseCursor,
    this.role = SemanticsRole.menuItem,
    this.gestureSemanticsEnabled = true,
    this.gestureSemantics,
    this.shortcuts = BaseControl.defaultShortcuts,
    this.enabled = true,
    this.anchorActions,
    this.requestFocusOnHover = true,
  });

  @override
  final Widget child;

  @override
  final FocusNode? focusNode;

  @override
  final bool autofocus;

  @override
  final MenuController controller;

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
  final TraversalEdgeBehavior? directionalFocusEdgeBehavior;

  @override
  final SemanticsProperties semanticProperties;

  @override
  final Axis orientation;

  @override
  final BaseMenuPositioningDelegate positionDelegate;

  @override
  final BaseMenuOverlayChildBuilder? overlayChildBuilder;

  @override
  final VoidCallback? onPressed;

  /// Called when the button is activated by a keyboard shortcut or other
  /// non-pointer input.
  ///
  /// When null, the default behavior is to open the submenu and focus the first
  /// item.
  ///
  /// Defaults to null.
  @override
  final VoidCallback? onActivate;

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
  final Map<ShortcutActivator, Intent>? shortcuts;

  /// The delay after which the submenu should open after being hovered.
  final Duration hoverOpenDelay;

  /// The delay after which the submenu should close when no longer hovered.
  final Duration hoverCloseDelay;

  @override
  final bool enabled;

  final Map<Type, Action<Intent>>? anchorActions;

  @override
  final bool requestFocusOnHover;

  @override
  bool get requestCloseOnActivate => false;

  @override
  State<BaseSubmenu> createState() => _BaseSubmenuState();
}

class _BaseSubmenuState extends State<BaseSubmenu> {
  // Notifier to track whether the submenu or its button has focus.
  //
  // This is used to apply a pseudo focus highlight on ancestor submenu anchors.
  final ValueNotifier<bool?> _highlightNotifier = ValueNotifier(null);
  FocusNode? _internalFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;
  bool _isScopeFocused = false;
  Timer? _closeTimer;
  Timer? _openTimer;
  Axis? _parentOrientation;
  bool _parentIsSubmenu = false;
  Map<Type, Action<Intent>>? _overlayActions;
  Map<Type, Action<Intent>>? _anchorActions;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }

    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = MenuScope.maybeOf(context);
    if (scope?.orientation != _parentOrientation || scope?.isSubmenu != _parentIsSubmenu) {
      _parentOrientation = scope?.orientation;
      _parentIsSubmenu = scope?.isSubmenu ?? false;
      _overlayActions = null;
      _anchorActions = null;
    }
  }

  @override
  void didUpdateWidget(BaseSubmenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled && widget.controller.isOpen) {
      widget.controller.close();
    }

    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      if (widget.focusNode == null) {
        assert(_internalFocusNode == null);
        _internalFocusNode = FocusNode();
      } else {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      }
      _focusNode.addListener(_handleFocusChange);
    }

    if (oldWidget.orientation != widget.orientation) {
      _overlayActions = null;
      _anchorActions = null;
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
    if (widget.controller.isOpen) {
      _highlightNotifier.value = _focusNode.hasFocus || _isScopeFocused;
    } else {
      _highlightNotifier.value = null;
    }
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus && !_isScopeFocused && widget.controller.isOpen) {
      _scheduleHoverClose();
    } else {
      _closeTimer?.cancel();
    }

    _updateHighlight();
  }

  void _scheduleHoverClose() {
    assert(widget.controller.isOpen);
    _closeTimer?.cancel();
    _closeTimer = Timer(widget.hoverCloseDelay, () {
      _closeTimer = null;
      assert(_openTimer?.isActive != true);
      widget.controller.close();
    });
  }

  void _scheduleHoverOpen() {
    assert(!widget.controller.isOpen);
    _openTimer?.cancel();
    _openTimer = Timer(widget.hoverOpenDelay, () {
      if (!widget.controller.isOpen) {
        widget.controller.open();
      }
    });
  }

  void _handlePointerEnterAnchor(PointerEnterEvent event) {
    if (!widget.requestFocusOnHover) {
      return;
    }

    if (!widget.controller.isOpen) {
      _scheduleHoverOpen();
    }
    _closeTimer?.cancel();
    widget.onPointerEnter?.call(event);
  }

  void _handlePointerLeaveAnchor(PointerExitEvent event) {
    _openTimer?.cancel();
    if (widget.controller.isOpen && !_isScopeFocused) {
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
      if (widget.controller.isOpen && !_focusNode.hasFocus) {
        _scheduleHoverClose();
      }
    }

    _updateHighlight();
    widget.onFocusChange?.call(focused);
  }

  void _handleSameAxisSubmenuPrevious(Intent intent) {
    if (widget.controller.isOpen) {
      widget.controller.close();
    } else {
      Actions.maybeInvoke(context, intent);
    }
  }

  void _handleCrossAxisPrevious(Intent intent) {
    // Move focus to the anchor, which is within the parent menu's cross-axis
    // focus scope. Then, invoke the action to move focus to the previous item
    // in that scope. The parent's edge behavior will determine whether focus moves to
    // the next item or wraps to the first item.
    _focusNode.requestFocus();
    Actions.maybeInvoke(context, intent);
    FocusManager.instance.applyFocusChangesIfNeeded();
    if (widget.controller.isOpen && primaryFocus?.context?.mounted == true) {
      MenuController.maybeOf(primaryFocus!.context!)?.open();
    }
  }

  void _handleCrossAxisNext(Intent intent) {
    // Move focus to the anchor, which is within the parent menu's cross-axis
    // focus scope. Bubbling the intent will move focus to the next item in that
    // scope. The parent's edge behavior will determine whether focus moves to
    // the next item or wraps to the first item.
    _focusNode.requestFocus();
    Actions.maybeInvoke(context, intent);
    FocusManager.instance.applyFocusChangesIfNeeded();
    if (widget.controller.isOpen && primaryFocus?.context?.mounted == true) {
      MenuController.maybeOf(primaryFocus!.context!)?.open();
    }
  }

  void _handleClose() {
    _isScopeFocused = false;
    widget.onClose?.call();

    // Let the menu close before updating the highlight state.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateHighlight();
      }
    });
  }

  void _handleActivate() {
    if (widget.onActivate != null) {
      widget.onActivate!.call();
    } else {
      Actions.maybeInvoke(_focusNode.context!, const BaseMenuEnterIntent.focusFirst());
    }
  }

  Widget _buildHighlight(BuildContext context, Widget? child) {
    return BaseFocusableStateInjector<BaseMenuItem>(
      showFocusHighlight: _highlightNotifier.value,
      child: child!,
    );
  }

  Widget _buildOverlayChild(BuildContext context, Widget child) {
    final overlay = MouseRegion(
      hitTestBehavior: .deferToChild,
      onEnter: _handlePointerEnterPanel,
      onExit: _handlePointerExitPanel,
      child: child,
    );

    return widget.overlayChildBuilder?.call(context, overlay) ?? overlay;
  }

  @override
  Widget build(BuildContext context) {
    // When _parentOrientation == null, there is no parent menu bar or menu
    // anchor. In this case, overlay actions are not set.
    if (_parentOrientation != null) {
      final inSameAxisSubmenu = _parentOrientation == widget.orientation;
      _overlayActions ??= switch ((widget.orientation, inSameAxisSubmenu)) {
        (Axis.horizontal, true) => {
          VPreviousIntent: CallbackAction<VPreviousIntent>(
            onInvoke: _handleSameAxisSubmenuPrevious,
          ),
        },
        (Axis.vertical, true) => {
          HPreviousIntent: CallbackAction<HPreviousIntent>(
            onInvoke: _handleSameAxisSubmenuPrevious,
          ),
        },
        (Axis.vertical, false) => {
          HPreviousIntent: CallbackAction<HPreviousIntent>(onInvoke: _handleCrossAxisPrevious),
          HNextIntent: CallbackAction<HNextIntent>(onInvoke: _handleCrossAxisNext),
        },

        (Axis.horizontal, false) => {
          VPreviousIntent: CallbackAction<VPreviousIntent>(onInvoke: _handleCrossAxisPrevious),
          VNextIntent: CallbackAction<VNextIntent>(onInvoke: _handleCrossAxisNext),
        },
      };
    }

    return BaseMenu(
      onOpen: widget.onOpen,
      onOpenRequest: widget.onOpenRequest,
      onClose: _handleClose,
      onCloseRequest: widget.onCloseRequest,
      controller: widget.controller,
      consumeOutsideTaps: widget.consumeOutsideTaps,
      useRootOverlay: widget.useRootOverlay,
      menu: Actions(actions: _overlayActions ?? const {}, child: widget.menu),
      onFocusChange: _handleScopeFocusChange,
      directionalFocusEdgeBehavior: widget.directionalFocusEdgeBehavior,
      semanticProperties: widget.semanticProperties,
      orientation: widget.orientation,
      positionDelegate: widget.positionDelegate,
      overlayChildBuilder: _buildOverlayChild,
      builder: _buildChild,
    );
  }

  Widget _buildChild(BuildContext context, MenuController controller, Widget? child) {
    if (controller.isOpen) {
      final bool inSameAxisSubmenu = _parentOrientation == widget.orientation && _parentIsSubmenu;
      _anchorActions ??= switch ((widget.orientation, inSameAxisSubmenu)) {
        (Axis.horizontal, true) => {
          VPreviousIntent: CallbackAction<VPreviousIntent>(
            onInvoke: _handleSameAxisSubmenuPrevious,
          ),
        },
        (Axis.vertical, true) => {
          HPreviousIntent: CallbackAction<HPreviousIntent>(
            onInvoke: _handleSameAxisSubmenuPrevious,
          ),
        },
        (Axis.vertical, false) => {
          HPreviousIntent: CallbackAction<HPreviousIntent>(onInvoke: _handleCrossAxisPrevious),
          HNextIntent: CallbackAction<HNextIntent>(onInvoke: _handleCrossAxisNext),
        },

        (Axis.horizontal, false) => {
          VPreviousIntent: CallbackAction<VPreviousIntent>(onInvoke: _handleCrossAxisPrevious),
          VNextIntent: CallbackAction<VNextIntent>(onInvoke: _handleCrossAxisNext),
        },
      };
    }

    final (
      horizontalArrowNext,
      horizontalArrowPrevious,
    ) = switch (Directionality.maybeOf(context) ?? .ltr) {
      .ltr => (const SingleActivator(.arrowRight), const SingleActivator(.arrowLeft)),
      .rtl => (const SingleActivator(.arrowLeft), const SingleActivator(.arrowRight)),
    };

    return Actions(
      actions: controller.isOpen
          ? {...?_anchorActions, ...?widget.anchorActions}
          : widget.anchorActions ?? const {},
      child: BaseMenuItem(
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        onPressed: widget.enabled ? widget.onPressed : null,
        onActivate: widget.enabled ? _handleActivate : null,
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
        shortcuts: _parentOrientation == .vertical
            ? {
                horizontalArrowNext: const BaseMenuEnterIntent.focusFirst(),
                if (widget.orientation == .horizontal)
                  horizontalArrowPrevious: const BaseMenuEnterIntent.focusLast(),
                ...?widget.shortcuts,
              }
            : widget.shortcuts ?? {},
        child: ListenableBuilder(
          listenable: _highlightNotifier,
          builder: _buildHighlight,
          child: widget.child,
        ),
      ),
    );
  }
}
