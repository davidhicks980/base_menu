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
    this.directionalFocusEdgeBehavior,
    this.semanticProperties = const SemanticsProperties(
      scopesRoute: true,
      label: 'Submenu',
      role: SemanticsRole.menu,
    ),
    this.orientation = Axis.vertical,
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
  final TraversalEdgeBehavior? directionalFocusEdgeBehavior;

  @override
  final SemanticsProperties semanticProperties;

  @override
  final Axis orientation;

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

    if (widget.controller == null) {
      _internalMenuController = MenuController();
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

  void _handleCrossAxisPrevious(Intent intent) {
    if (_parentIsSubmenu && _parentOrientation == widget.orientation) {
      _menuController.close();
      return;
    }

    final policy = FocusTraversalGroup.maybeOfNode(_focusNode);
    if (policy != null) {
      final parentScope = _focusNode.enclosingScope;
      final first = policy.findFirstFocus(parentScope!, ignoreCurrentFocus: true);
      if (_focusNode.traversalDescendants.contains(first)) {
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
    MenuController.maybeOf(primaryFocus!.context!)?.open();
  }

  void _handleCrossAxisNext(Intent intent) {
    final policy = FocusTraversalGroup.maybeOfNode(_focusNode);
    if (policy != null) {
      final parentScope = _focusNode.enclosingScope;
      final last = policy.findLastFocus(parentScope!, ignoreCurrentFocus: true);
      if (_focusNode.traversalDescendants.contains(last)) {
        final first = policy.findFirstFocus(parentScope, ignoreCurrentFocus: true);
        if (first != null) {
          policy.requestFocusCallback(first, alignmentPolicy: .keepVisibleAtStart);
          MenuController.maybeOf(first.context!)?.open();
          return;
        }
      }
    }

    Actions.maybeInvoke(context, intent);
    FocusManager.instance.applyFocusChangesIfNeeded();
    if (primaryFocus?.context?.mounted != true) {
      return;
    }

    MenuController.maybeOf(primaryFocus!.context!)?.open();
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

    // When _parentOrientation == null, there is no parent menu bar or menu
    // anchor. In this case, overlay actions are not set.
    if (_overlayActions == null && _parentOrientation != null) {
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

      _overlayActions = {
        previousIntentType: CallbackAction(onInvoke: _handleCrossAxisPrevious),
        ?nextIntentType: CallbackAction(onInvoke: _handleCrossAxisNext),
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
      controller: _menuController,
      consumeOutsideTaps: widget.consumeOutsideTaps,
      useRootOverlay: widget.useRootOverlay,
      menu: widget.menu,
      onFocusChange: _handleScopeFocusChange,
      directionalFocusEdgeBehavior: widget.directionalFocusEdgeBehavior,
      semanticProperties: widget.semanticProperties,
      orientation: widget.orientation,
      positionDelegate: widget.positionDelegate,
      overlayChildBuilder: _buildOverlayChild,
      child: Actions(
        actions: _actions,
        child: Builder(
          builder: (context) {
            final isOpen = MenuController.maybeIsOpenOf(context) ?? false;
            final shortcuts = <SingleActivator, Intent>{};
            if (_parentOrientation == Axis.vertical) {
              shortcuts.addAll({
                switch (Directionality.maybeOf(context) ?? TextDirection.ltr) {
                  TextDirection.ltr => const SingleActivator(LogicalKeyboardKey.arrowRight),
                  TextDirection.rtl => const SingleActivator(LogicalKeyboardKey.arrowLeft),
                }: const BaseMenuEnterIntent.focusFirst(),
              });
            }

            if (isOpen && _parentOrientation != widget.orientation) {
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
                ..._actions,
                previousIntentType: CallbackAction(onInvoke: _handleCrossAxisPrevious),
                ?nextIntentType: CallbackAction(onInvoke: _handleCrossAxisNext),
              };
            }

            return Actions(
              actions: _anchorActions ?? _actions,
              child: Shortcuts(
                shortcuts: shortcuts,
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
          },
        ),
      ),
    );
  }
}
