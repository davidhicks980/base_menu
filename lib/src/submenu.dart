import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../menu_utilities.dart';
import 'focusable.dart';
import 'interface.dart';
import 'menu.dart';

/// A widget that anchors a nested submenu to an item within a parent menu.
///
/// The [BaseSubmenu] widget is optimized specifically for hierarchical nested
/// submenus. It includes built-in hover delay timing ([hoverOpenDelay] and
/// [hoverCloseDelay]), synchronized pseudo-focus highlighting across submenu
/// levels, and orientation-aware keyboard navigation.
///
/// The [child] widget should only handle visual representation. Focus,
/// activation, and hover interactions should be handled through the
/// [BaseSubmenu] properties, which are then passed to the internal
/// [BaseMenuItem].
///
/// To customize the [Actions] for the submenu anchor, use the [anchorActions]
/// property. The overlay's [Actions] can be customized by wrapping the [menu]
/// in an [Actions] widget.
///
/// **See also**:
///  * [BaseMenu], which is used internally to manage the submenu's overlay.
///  * [BaseMenuItem], which is used internally to manage the submenu's anchor.
///  * [BaseMenuBar], which can used to group multiple [BaseSubmenu] widgets
///    into a menu bar.
class BaseSubmenu extends StatefulWidget implements BaseMenuInterface, BaseMenuItemInterface {
  /// Creates a [BaseSubmenu].
  ///
  /// The [child], [menu], and [controller] parameters are required.
  const BaseSubmenu({
    super.key,
    required this.child,
    required this.menu,
    required this.controller,
    this.hoverOpenDelay = Duration.zero,
    this.hoverCloseDelay = Duration.zero,
    this.onOpen,
    this.onOpenRequest = BaseMenu.defaultOnOpenRequested,
    this.onClose,
    this.onCloseRequest = BaseMenu.defaultOnCloseRequested,
    this.useRootOverlay = false,
    this.consumeOutsideTaps = false,
    this.onFocusChange,
    this.directionalFocusEdgeBehavior,
    this.semanticProperties = const SemanticsProperties(
      scopesRoute: true,
      role: SemanticsRole.menu,
    ),
    this.orientation = Axis.vertical,
    this.positionDelegate = const DefaultMenuPositioningDelegate(),
    this.overlayChildBuilder,
    this.focusNode,
    this.autofocus = false,
    this.onPressed,
    this.onActivate,
    this.onPointerEnter,
    this.onPointerHover,
    this.onPointerExit,
    this.behavior = HitTestBehavior.deferToChild,
    this.opaque = true,
    this.mouseCursor,
    this.role = SemanticsRole.menuItem,
    this.gestureSemanticsEnabled = true,
    this.gestureSemantics,
    this.shortcuts = BaseControl.activateOnEnterAndSpaceUpShortcuts,
    this.enabled = true,
    this.anchorActions,
    this.requestFocusOnHover = true,
  });

  @override
  final Widget child;

  @override
  final Widget menu;

  @override
  final MenuController controller;

  @override
  final FocusNode? focusNode;

  @override
  final bool autofocus;

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
  final ValueChanged<bool>? onFocusChange;

  @override
  final TraversalEdgeBehavior? directionalFocusEdgeBehavior;

  @override
  final SemanticsProperties semanticProperties;

  @override
  final Axis orientation;

  @override
  final MenuPositioningDelegate positionDelegate;

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
  final PointerExitEventListener? onPointerExit;

  @override
  final HitTestBehavior behavior;

  @override
  final bool opaque;

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

  /// Whether the submenu is enabled. When false, the submenu will not open and
  /// the button will be disabled.
  @override
  final bool enabled;

  /// The [Actions] to be used for the submenu anchor when the submenu is open.
  ///
  /// This can be used to customize the keyboard navigation for the submenu
  /// anchor.
  ///
  /// Defaults to null.
  final Map<Type, Action<Intent>>? anchorActions;

  @override
  final bool requestFocusOnHover;

  @override
  bool get requestCloseOnActivate => false;

  @visibleForTesting
  // ignore: public_member_api_docs
  String get debugMenuFocusNodeLabel => 'BaseSubmenu FocusNode${key != null ? ' ($key)' : ''}';

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
      _internalFocusNode = FocusNode(debugLabel: widget.debugMenuFocusNodeLabel);
    }

    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final MenuScope? scope = MenuScope.maybeOf(context);
    if (scope?.axis != _parentOrientation || scope?.isSubmenu != _parentIsSubmenu) {
      _parentOrientation = scope?.axis;
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
        _internalFocusNode = FocusNode(debugLabel: widget.debugMenuFocusNodeLabel);
      } else {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      }
      _focusNode.addListener(_handleFocusChange);
    }

    assert(() {
      _internalFocusNode?.debugLabel = widget.debugMenuFocusNodeLabel;
      return true;
    }());

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
    widget.onPointerExit?.call(event);
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
      Actions.maybeInvoke(_focusNode.context!, const EnterMenuIntent.focusFirst());
    }
  }

  Map<Type, Action<Intent>>? _buildActions({required bool inSubmenu}) =>
      switch ((widget.orientation, inSubmenu)) {
        (Axis.horizontal, true) => {
          VerticalMenuFocusPreviousIntent: CallbackAction<VerticalMenuFocusPreviousIntent>(
            onInvoke: _handleSameAxisSubmenuPrevious,
          ),
        },
        (Axis.vertical, true) => {
          HorizontalMenuFocusPreviousIntent: CallbackAction<HorizontalMenuFocusPreviousIntent>(
            onInvoke: _handleSameAxisSubmenuPrevious,
          ),
        },
        (Axis.horizontal, false) => {
          VerticalMenuFocusPreviousIntent: CallbackAction<VerticalMenuFocusPreviousIntent>(
            onInvoke: _handleCrossAxisPrevious,
          ),
          VerticalMenuFocusNextIntent: CallbackAction<VerticalMenuFocusNextIntent>(
            onInvoke: _handleCrossAxisNext,
          ),
        },
        (Axis.vertical, false) => {
          HorizontalMenuFocusPreviousIntent: CallbackAction<HorizontalMenuFocusPreviousIntent>(
            onInvoke: _handleCrossAxisPrevious,
          ),
          HorizontalMenuFocusNextIntent: CallbackAction<HorizontalMenuFocusNextIntent>(
            onInvoke: _handleCrossAxisNext,
          ),
        },
      };

  Widget _buildHighlight(BuildContext context, Widget? child) =>
      BaseFocusableStateInjector<BaseMenuItem>(
        showFocusHighlight: _highlightNotifier.value,
        child: child!,
      );

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
    if (_overlayActions == null && _parentOrientation != null) {
      _overlayActions = _buildActions(inSubmenu: _parentOrientation == widget.orientation);
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
    if (controller.isOpen && _anchorActions == null) {
      _anchorActions = _buildActions(
        inSubmenu: _parentOrientation == widget.orientation && _parentIsSubmenu,
      );
    }

    final (
      SingleActivator horizontalArrowNext,
      SingleActivator horizontalArrowPrevious,
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
        onPointerExit: _handlePointerLeaveAnchor,
        requestCloseOnActivate: widget.requestCloseOnActivate,
        requestFocusOnHover: widget.requestFocusOnHover,
        behavior: widget.behavior,
        opaque: widget.opaque,
        mouseCursor: widget.mouseCursor,
        role: widget.role,
        gestureSemanticsEnabled: widget.gestureSemanticsEnabled,
        gestureSemantics: widget.gestureSemantics,
        shortcuts: _parentOrientation == .vertical
            ? {
                horizontalArrowNext: const EnterMenuIntent.focusFirst(),
                if (widget.orientation == .horizontal)
                  horizontalArrowPrevious: const EnterMenuIntent.focusLast(),
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
