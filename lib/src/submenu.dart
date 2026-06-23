import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../menu_utilities.dart';
import 'interface.dart';
import 'menu.dart';

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

  @override
  bool get requestFocusOnHover => true;

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

  void _handleCrossAxisPrevious(Intent intent) {
    if (_parentOrientation == widget.orientation) {
      if (widget.controller.isOpen) {
        widget.controller.close();
      } else {
        Actions.maybeInvoke(context, intent);
      }
      return;
    }

    final policy = FocusTraversalGroup.maybeOfNode(_focusNode);
    if (policy != null) {
      final parentScope = _focusNode.enclosingScope;
      final first = policy.findFirstFocus(parentScope!, ignoreCurrentFocus: true);

      if (first == _focusNode || _focusNode.traversalDescendants.contains(first)) {
        final last = policy.findLastFocus(parentScope, ignoreCurrentFocus: true);
        policy.requestFocusCallback(last, alignmentPolicy: .keepVisibleAtEnd);
        MenuController.maybeOf(last.context!)?.open();
        return;
      }
    }

    final success = _focusNode.enclosingScope?.previousFocus();
    if (success != true) {
      Actions.maybeInvoke(context, intent);
      return;
    }
    FocusManager.instance.applyFocusChangesIfNeeded();
    Actions.maybeInvoke(context, intent);
    if (primaryFocus?.context?.mounted != true) {
      return;
    }
    MenuController.maybeOf(primaryFocus!.context!)?.open();
  }

  void _handleAnchorCrossAxisPrevious(Intent intent) {
    if (_parentIsSubmenu && _parentOrientation == widget.orientation) {
      if (widget.controller.isOpen) {
        widget.controller.close();
      } else {
        Actions.maybeInvoke(context, intent);
      }
      return;
    }

    final policy = FocusTraversalGroup.maybeOfNode(_focusNode);
    if (policy != null) {
      final parentScope = _focusNode.enclosingScope;
      final first = policy.findFirstFocus(parentScope!, ignoreCurrentFocus: true);
      if (first == _focusNode || _focusNode.traversalDescendants.contains(first)) {
        final last = policy.findLastFocus(parentScope, ignoreCurrentFocus: true);
        policy.requestFocusCallback(last, alignmentPolicy: .keepVisibleAtEnd);
        if (widget.controller.isOpen) {
          MenuController.maybeOf(last.context!)?.open();
        }
        return;
      }
    }

    final success = _focusNode.enclosingScope?.previousFocus();
    if (success != true) {
      Actions.maybeInvoke(context, intent);
      return;
    }

    if (!widget.controller.isOpen) {
      return;
    }

    FocusManager.instance.applyFocusChangesIfNeeded();

    if (primaryFocus?.context?.mounted != true) {
      return;
    }

    MenuController.maybeOf(primaryFocus!.context!)?.open();
  }

  void _handleCrossAxisNext(Intent intent) {
    // In a HVV menu, pressing right on a leaf submenu item should move to the
    // next horizontal item in the parent menu.
    if (_parentOrientation == widget.orientation) {
      Actions.maybeInvoke(context, intent);
      return;
    }

    final policy = FocusTraversalGroup.maybeOfNode(_focusNode);
    if (policy != null) {
      final parentScope = _focusNode.enclosingScope;
      final last = policy.findLastFocus(parentScope!, ignoreCurrentFocus: true);
      if (last == _focusNode || _focusNode.traversalDescendants.contains(last)) {
        final first = policy.findFirstFocus(parentScope, ignoreCurrentFocus: true);
        if (first != null) {
          policy.requestFocusCallback(first, alignmentPolicy: .keepVisibleAtStart);
          if (widget.controller.isOpen) {
            MenuController.maybeOf(first.context!)?.open();
          }
          return;
        }
      }
    }

    Actions.maybeInvoke(context, intent);
    if (!widget.controller.isOpen) {
      return;
    }

    FocusManager.instance.applyFocusChangesIfNeeded();
    if (primaryFocus?.context?.mounted != true) {
      return;
    }

    MenuController.maybeOf(primaryFocus!.context!)?.open();
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

    // When _parentOrientation == null, there is no parent menu bar or menu
    // anchor. In this case, overlay actions are not set.
    if (_overlayActions == null && _parentOrientation != null) {
      final Type previousIntentType = switch (widget.orientation) {
        Axis.vertical => BaseMenuHorizontalFocusPreviousIntent,
        Axis.horizontal => BaseMenuVerticalFocusPreviousIntent,
      };

      final Type nextIntentType = switch (widget.orientation) {
        Axis.vertical => BaseMenuHorizontalFocusNextIntent,
        Axis.horizontal => BaseMenuVerticalFocusNextIntent,
      };

      _overlayActions = {
        previousIntentType: CallbackAction(onInvoke: _handleCrossAxisPrevious),
        nextIntentType: CallbackAction(onInvoke: _handleCrossAxisNext),
      };
    }

    return Actions(
      actions: _overlayActions ?? const {},
      child: widget.overlayChildBuilder?.call(context, overlay) ?? overlay,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseMenu(
      onOpen: widget.onOpen,
      onOpenRequest: widget.onOpenRequest,
      onClose: _handleClose,
      onCloseRequest: widget.onCloseRequest,
      controller: widget.controller,
      consumeOutsideTaps: widget.consumeOutsideTaps,
      useRootOverlay: widget.useRootOverlay,
      menu: widget.menu,
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
      final Type previousIntentType = switch (widget.orientation) {
        Axis.vertical => BaseMenuHorizontalFocusPreviousIntent,
        Axis.horizontal => BaseMenuVerticalFocusPreviousIntent,
      };

      final Type? nextIntentType = _parentOrientation != widget.orientation
          ? switch (widget.orientation) {
              Axis.vertical => BaseMenuHorizontalFocusNextIntent,
              Axis.horizontal => BaseMenuVerticalFocusNextIntent,
            }
          : null;

      _anchorActions = {
        previousIntentType: CallbackAction(onInvoke: _handleAnchorCrossAxisPrevious),
        ?nextIntentType: CallbackAction(onInvoke: _handleCrossAxisNext),
      };
    }

    return Actions(
      actions: _anchorActions ?? const {},
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
        shortcuts: {
          if (_parentOrientation == Axis.vertical)
            switch (Directionality.maybeOf(context) ?? TextDirection.ltr) {
              TextDirection.ltr => const SingleActivator(LogicalKeyboardKey.arrowRight),
              TextDirection.rtl => const SingleActivator(LogicalKeyboardKey.arrowLeft),
            }: const BaseMenuEnterIntent.focusFirst(),

          if (_parentOrientation == Axis.vertical && widget.orientation == Axis.horizontal)
            switch (Directionality.maybeOf(context) ?? TextDirection.ltr) {
              TextDirection.ltr => const SingleActivator(LogicalKeyboardKey.arrowLeft),
              TextDirection.rtl => const SingleActivator(LogicalKeyboardKey.arrowRight),
            }: const BaseMenuEnterIntent.focusLast(),
          ...?widget.shortcuts,
        },
        child: ListenableBuilder(
          listenable: _highlightNotifier,
          builder: _buildHighlight,
          child: widget.child,
        ),
      ),
    );
  }
}
