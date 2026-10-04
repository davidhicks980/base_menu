import 'dart:math' as math;
import 'dart:ui' as ui show DisplayFeature, DisplayFeatureState, Offset, Rect, clampDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'aim.dart';
import 'interface.dart';

double _computeSquaredDistanceToRect(Offset point, Rect rect) {
  final double dx = point.dx - ui.clampDouble(point.dx, rect.left, rect.right);
  final double dy = point.dy - ui.clampDouble(point.dy, rect.top, rect.bottom);
  return dx * dx + dy * dy;
}

const Map<SingleActivator, Intent> _kMenuShortcuts = <SingleActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
  SingleActivator(LogicalKeyboardKey.arrowUp): VerticalMenuFocusPreviousIntent(),
  SingleActivator(LogicalKeyboardKey.arrowDown): VerticalMenuFocusNextIntent(),
  SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
  SingleActivator(LogicalKeyboardKey.tab, shift: true): PreviousFocusIntent(),
  SingleActivator(LogicalKeyboardKey.home): _MenuFocusFirstIntent(),
  SingleActivator(LogicalKeyboardKey.end): _MenuFocusLastIntent(),
};

const Map<SingleActivator, Intent> _kMenuLTRShortcuts = {
  ..._kMenuShortcuts,
  SingleActivator(LogicalKeyboardKey.arrowLeft): HorizontalMenuFocusPreviousIntent(),
  SingleActivator(LogicalKeyboardKey.arrowRight): HorizontalMenuFocusNextIntent(),
};

const Map<SingleActivator, Intent> _kMenuRTLShortcuts = {
  ..._kMenuShortcuts,
  SingleActivator(LogicalKeyboardKey.arrowLeft): HorizontalMenuFocusNextIntent(),
  SingleActivator(LogicalKeyboardKey.arrowRight): HorizontalMenuFocusPreviousIntent(),
};

const Map<ShortcutActivator, Intent> _kStopDirectionalPropagationShortcuts =
    <ShortcutActivator, Intent>{
      SingleActivator(LogicalKeyboardKey.arrowUp): DoNothingAndStopPropagationIntent(),
      SingleActivator(LogicalKeyboardKey.arrowDown): DoNothingAndStopPropagationIntent(),
      SingleActivator(LogicalKeyboardKey.arrowLeft): DoNothingAndStopPropagationIntent(),
      SingleActivator(LogicalKeyboardKey.arrowRight): DoNothingAndStopPropagationIntent(),
    };

/// A base class for intents that trigger directional focus traversal within a menu.
sealed class _TraversalIntent extends Intent {
  const _TraversalIntent();
}

/// An intent that moves focus to the next item within a horizontal [BaseMenu] or [BaseMenuBar].
final class HorizontalMenuFocusNextIntent extends _TraversalIntent {
  /// Creates a [HorizontalMenuFocusNextIntent].
  const HorizontalMenuFocusNextIntent();
}

/// An intent that moves focus to the previous item within a horizontal [BaseMenu] or [BaseMenuBar].
final class HorizontalMenuFocusPreviousIntent extends _TraversalIntent {
  /// Creates a [HorizontalMenuFocusPreviousIntent].
  const HorizontalMenuFocusPreviousIntent();
}

/// An intent that moves focus to the next item in a vertical [BaseMenu] or [BaseMenuBar].
final class VerticalMenuFocusNextIntent extends _TraversalIntent {
  /// Creates a [VerticalMenuFocusNextIntent].
  const VerticalMenuFocusNextIntent();
}

/// An intent that moves focus to the previous item in a vertical [BaseMenu] or [BaseMenuBar].
final class VerticalMenuFocusPreviousIntent extends _TraversalIntent {
  /// Creates a [VerticalMenuFocusPreviousIntent].
  const VerticalMenuFocusPreviousIntent();
}

class _MenuFocusFirstIntent extends Intent {
  const _MenuFocusFirstIntent();
}

class _MenuFocusLastIntent extends Intent {
  const _MenuFocusLastIntent();
}

/// An [Intent] that signals the nearest ancestor [BaseMenu] should be opened
/// and focused.
///
/// Use [EnterMenuIntent.focusFirst] to open and focus the first menu item, and
/// [EnterMenuIntent.focusLast] to open and focus the last menu item.
class EnterMenuIntent extends Intent {
  /// An intent that opens a [BaseMenu] and requests focus on the first menu item.
  const EnterMenuIntent.focusFirst() : _scopeIntent = const _MenuFocusFirstIntent();

  /// An intent that opens a [BaseMenu] and requests focus on the last menu item.
  const EnterMenuIntent.focusLast() : _scopeIntent = const _MenuFocusLastIntent();

  final Intent _scopeIntent;
}

/// An [InheritedWidget] that provides the [orientation] and [isSubmenu] status
/// of a menu to its descendants.
///
/// This is used by [BaseMenu], [BaseMenuBar], and [BaseSubmenu] to determine
/// the appropriate keyboard navigation behavior for their menu items.
@visibleForTesting
class BaseMenuScope extends InheritedWidget {
  /// Creates a [BaseMenuScope] that provides the [orientation] and [isSubmenu] status of a
  /// menu to its descendants.
  const BaseMenuScope({
    super.key,
    required super.child,
    required this.orientation,
    required this.isSubmenu,
  });

  /// The direction of keyboard navigation for the menu items in this menu.
  final Axis orientation;

  /// Whether the current menu is a submenu of another menu.
  ///
  /// Root menus (like a [BaseMenuBar] or a top-level context menu) have this set
  /// to false.
  final bool isSubmenu;

  @override
  bool updateShouldNotify(BaseMenuScope oldWidget) {
    return orientation != oldWidget.orientation || isSubmenu != oldWidget.isSubmenu;
  }
}

/// Defines the positioning behavior of a [BaseMenu] when it overflows the edge
/// of the screen.
///
/// These strategies can be combined. For example, a menu might first attempt to
/// [flip] to the other side of an anchor, and then [shift] if it still doesn't
/// fit.
///
/// If [shift] and [constrain] are false, the menu may be positioned such that
/// it is partially or fully off-screen.
@immutable
class EdgeBehaviorStrategy {
  /// Creates an [EdgeBehaviorStrategy].
  const EdgeBehaviorStrategy({this.shift = false, this.flip = false, this.constrain = false});

  /// The menu will shift to stay within the screen boundaries, potentially
  /// covering the anchor.
  final bool shift;

  /// The menu will flip across the anchor midpoint if it overflows.
  final bool flip;

  /// The menu will resize to fit within the available space between the anchor
  /// and the screen edge. This is ideal for scrollable menus.
  ///
  /// Note that if [constrain] is true while [shift] is false, a two-pass layout
  /// occurs. The first pass calculates the menu's position based on its
  /// unconstrained size; the second pass then constrains the menu to the
  /// available space without repositioning its origin. This ensures the menu
  /// remains anchored to the point determined by its preferred dimensions.
  final bool constrain;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is EdgeBehaviorStrategy &&
        other.shift == shift &&
        other.flip == flip &&
        other.constrain == constrain;
  }

  @override
  int get hashCode => shift.hashCode ^ flip.hashCode ^ constrain.hashCode;
}

/// Describes how a [BaseMenu.menu] should be positioned when it overflows the
/// edge of the screen.
///
/// Used by [DefaultMenuPositioningDelegate].
@immutable
class EdgeBehavior {
  /// Creates an [EdgeBehavior] widget.
  const EdgeBehavior({required this.horizontal, required this.vertical});

  /// The strategy to apply when the menu overflows the left or right edges of
  /// the screen.
  final EdgeBehaviorStrategy horizontal;

  /// The strategy to apply when the menu overflows the top or bottom edges of
  /// the screen.
  final EdgeBehaviorStrategy vertical;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other.runtimeType != runtimeType) {
      return false;
    }

    return other is EdgeBehavior && other.horizontal == horizontal && other.vertical == vertical;
  }

  @override
  int get hashCode {
    return horizontal.hashCode ^ vertical.hashCode;
  }
}

/// A delegate whose [build] method builds a widget that positions the menu
/// panel of a [BaseMenu].
///
/// The position is determined relative to the menu's anchor using the provided
/// [anchorAttachment], [menuAttachment], and [offset].
///
/// If [useDirectionalOffset] is true, the horizontal component of the [offset]
/// is applied in the reading direction of the ambient [Directionality].
/// Otherwise, the offset is applied as-is, regardless of the ambient
/// [Directionality].
///
/// When the menu is opened with a `position` argument, the [anchorAttachment]
/// and [offset] are ignored, and the menu is positioned at the provided
/// [RawMenuOverlayInfo.position].
///
/// If the menu panel has padding applied, the [padding] parameter can be used
/// to ensure that the menu panel is offset from the anchor by the same amount
/// of padding, which is useful for maintaining visual alignment between a
/// submenu's items and its parent anchor.
///
/// The [overlayPadding] defines a minimum distance to apply between the menu
/// overlay and the edges of the screen when the menu is open.
///
/// The [edgeBehavior] defines how the menu panel should be positioned when it
/// overflows the edge of the screen.
class DefaultMenuPositioningDelegate implements MenuPositioningDelegate {
  /// Creates a [DefaultMenuPositioningDelegate].
  const DefaultMenuPositioningDelegate({
    this.anchorAttachment,
    this.menuAttachment,
    this.offset = ui.Offset.zero,
    this.useDirectionalOffset = true,
    this.padding = EdgeInsets.zero,
    this.overlayPadding = const EdgeInsets.all(8),
    this.edgeBehavior = const EdgeBehavior(
      horizontal: EdgeBehaviorStrategy(flip: true, shift: true, constrain: true),
      vertical: EdgeBehaviorStrategy(flip: true, shift: true, constrain: true),
    ),
    this.enableAimAssist,
  });

  /// The point on the anchor surface that attaches to the menu.
  ///
  /// The [anchorAttachment] has no effect if a `position` argument is provided
  /// to [MenuController.open].
  ///
  /// Defaults to [AlignmentDirectional.topEnd] if this menu's anchor is in a
  /// vertical menu, and [AlignmentDirectional.bottomStart] otherwise.
  ///
  /// If [edgeBehavior] has [EdgeBehaviorStrategy.flip] enabled on an axis, the
  /// [anchorAttachment] will flip over the midpoint of the anchor on that axis.
  final AlignmentGeometry? anchorAttachment;

  /// The point on the menu surface that attaches to the anchor.
  ///
  /// Unlike [anchorAttachment] and [offset], the [menuAttachment] will be
  /// applied when the menu is opened with a `position` argument.
  ///
  /// Defaults to [AlignmentDirectional.topStart].
  final AlignmentGeometry? menuAttachment;

  /// The offset applied to the menu relative to the anchor attachment point.
  ///
  /// If [useDirectionalOffset] is true (the default), the horizontal component
  /// of the offset is applied in the reading direction of the ambient
  /// [Directionality]. Otherwise, the offset is applied as-is, regardless of
  /// the ambient [Directionality].
  ///
  /// The [offset] has no effect if a `position` argument is provided to
  /// [MenuController.open].
  ///
  /// Defaults to [Offset.zero].
  final Offset offset;

  /// Whether the [offset] is directional, meaning its horizontal component is
  /// applied in the reading direction of the ambient [Directionality].
  final bool useDirectionalOffset;

  /// The [EdgeInsetsGeometry] applied to the menu surface but ignored during
  /// menu positioning.
  ///
  /// Menus commonly apply padding to the top and bottom of the menu surface,
  /// which can cause a submenu's items to be vertically misaligned with their
  /// parent menu items. To ensure a submenu's items align with their parent's
  /// items, the [padding] applied to the menu surface is ignored when
  /// calculating the position of the menu.
  ///
  /// Defaults to [EdgeInsets.zero].
  final EdgeInsetsGeometry padding;

  /// A minimum distance to apply between the menu overlay and the edges of the
  /// screen when the menu is open.
  ///
  /// Defaults to 8 pixels on all sides.
  final EdgeInsetsGeometry overlayPadding;

  /// The behavior applied when the menu overflows the edge of the screen.
  final EdgeBehavior edgeBehavior;

  /// Whether to enable the aim assist feature for this menu.
  ///
  /// To enable aim assist for all menus in a subtree, place a [MenuAimScope]
  /// above the [BaseMenu] in the widget tree and set its [MenuAimScope.enable]
  /// property to true.
  ///
  /// Defaults to null, which means the menu will inherit the aim assist setting
  /// from the nearest [MenuAimScope] ancestor. If there is no [MenuAimScope]
  /// ancestor, aim assist will be disabled.
  final bool? enableAimAssist;

  @override
  Widget build(BuildContext context, RawMenuOverlayInfo position, Widget child) {
    final alignment =
        anchorAttachment ??
        switch (BaseMenu.maybeOrientationOf(context)) {
          Axis.vertical => AlignmentDirectional.topEnd,
          _ => AlignmentDirectional.bottomStart,
        };
    final resolvedOffset =
        useDirectionalOffset && Directionality.maybeOf(context) == TextDirection.rtl
        ? Offset(-offset.dx, offset.dy)
        : offset;

    final enableAim = enableAimAssist ?? MenuAimScope.maybeOf(context)?.enable ?? false;
    if (enableAim) {
      return _AimAssistBuilder(
        builder: (context, geometry) {
          geometry.anchorRect = position.anchorRect;
          return _MenuPositioner(
            overlayPadding: overlayPadding,
            menuPadding: padding,
            anchorRect: position.anchorRect,
            offset: resolvedOffset,
            menuPosition: position.position,
            menuAlignment: menuAttachment ?? AlignmentDirectional.topStart,
            alignment: alignment,
            edgeBehavior: edgeBehavior,
            onPositioned: (targetRect) {
              geometry.targetRect = targetRect;
            },
            child: child,
          );
        },
      );
    } else {
      return _MenuPositioner(
        overlayPadding: overlayPadding,
        menuPadding: padding,
        anchorRect: position.anchorRect,
        offset: resolvedOffset,
        menuPosition: position.position,
        menuAlignment: menuAttachment ?? AlignmentDirectional.topStart,
        alignment: alignment,
        edgeBehavior: edgeBehavior,
        child: child,
      );
    }
  }
}

class _AimAssistBuilder extends StatefulWidget {
  const _AimAssistBuilder({required this.builder});

  final Widget Function(BuildContext, MenuAimGeometry) builder;

  @override
  State<_AimAssistBuilder> createState() => _AimAssistBuilderState();
}

class _AimAssistBuilderState extends State<_AimAssistBuilder> {
  final geometry = MenuAimGeometry();

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: .ltr,
      children: [
        widget.builder(context, geometry),
        MenuAimInterceptor(geometry: geometry),
      ],
    );
  }
}

/// A widget that anchors a popup menu to a child widget and manages its
/// visibility.
///
/// [BaseMenu] is a foundational widget for creating context menus, dropdowns,
/// and submenus. It manages an [OverlayPortal] containing the [menu] content,
/// which is typically a [BaseMenuPanel] containing a list of menu items.
///
/// [BaseMenu] uses [RawMenuAnchor] and [MenuController] to control the
/// open/close state of the menu. As such, [BaseMenu] shares a similar API:
/// * The menu is opened by calling [MenuController.open] and closed by calling
///   [MenuController.close].
/// * The menu can be opened with a specific position by passing a `position`
///   argument to [MenuController.open].
/// * The nearest ancestor [BaseMenu] open/close state can be observed using
///   [MenuController.maybeIsOpenOf].
/// * The nearest ancestor [MenuController] can be read using
///   [MenuController.maybeOf].
/// * Tapping outside the menu or its anchor or pressing
///   [LogicalKeyboardKey.escape] will emit a [DismissIntent] that closes the
///   menu.
/// * The [consumeOutsideTaps] property can be set to true to prevent tap events
///   from propagating to underlying widgets when the menu is open.
///
/// In addition to the [RawMenuAnchor] API, the following properties can be used
/// to customize the behavior of the menu:
/// * **[orientation]**: Sets the traversal axis. Vertical menus use up/down
///   arrows; horizontal menus use left/right.
/// * **[positionDelegate]**: Controls how the menu is positioned.
/// * **[semanticProperties]**: The [SemanticsProperties] applied to the menu's
///   [Semantics] node.
/// * **[onFocusChange]**: Notifies when the menu surface gains or loses focus.
/// * **[traversalEdgeBehavior]**: Controls how focus traversal behaves
///   when focus moves beyond the first or last item in the menu. Defaults to
///   [TraversalEdgeBehavior.stop] on iOS and macOS, and
///   [TraversalEdgeBehavior.closedLoop] on other platforms (including web).
///
/// See also:
/// * [BaseSubmenu], a [BaseMenu] that adds hover and focus behavior for nested
///   submenus.
/// * [BaseMenuBar], for horizontal groupings of [BaseMenu]s.
/// * [BaseMenuPanel], a default menu panel that can be used by [BaseMenu].
/// * [DefaultMenuPositioningDelegate], for customizing how the menu is placed.
class BaseMenu extends StatefulWidget implements BaseMenuInterface {
  /// Creates a [BaseMenu].
  ///
  /// The [menu] parameter is required and must not be null.
  const BaseMenu({
    super.key,
    this.controller,
    this.consumeOutsideTaps = false,
    this.onOpen,
    this.onClose,
    this.onOpenRequest = BaseMenu.defaultOnOpenRequested,
    this.onCloseRequest = BaseMenu.defaultOnCloseRequested,
    this.onFocusChange,
    this.traversalEdgeBehavior,
    this.semanticProperties = const SemanticsProperties(
      scopesRoute: true,
      role: SemanticsRole.menu,
    ),
    this.orientation = Axis.vertical,
    this.positionDelegate = const DefaultMenuPositioningDelegate(),
    this.useRootOverlay = false,
    this.overlayChildBuilder,
    required this.menu,
    this.builder,
    this.child,
  });

  @override
  final MenuController? controller;

  @override
  final bool consumeOutsideTaps;

  @override
  final VoidCallback? onOpen;

  @override
  final VoidCallback? onClose;

  @override
  final RawMenuAnchorOpenRequestedCallback onOpenRequest;

  @override
  final RawMenuAnchorCloseRequestedCallback onCloseRequest;

  @override
  final ValueChanged<bool>? onFocusChange;

  @override
  final TraversalEdgeBehavior? traversalEdgeBehavior;

  @override
  final SemanticsProperties semanticProperties;

  @override
  final Axis orientation;

  @override
  final MenuPositioningDelegate positionDelegate;

  @override
  final bool useRootOverlay;

  @override
  final MenuOverlayChildBuilder? overlayChildBuilder;

  @override
  final Widget menu;

  /// The widget that this [BaseMenu] surrounds.
  ///
  /// Typically, this is a button used to open the menu by calling
  /// [MenuController.open] on the `controller` passed to the builder.
  ///
  /// If not supplied, then the [BaseMenu] will match the size that its parent
  /// allocates for it.
  final RawMenuAnchorChildBuilder? builder;

  @override
  final Widget? child;

  @visibleForTesting
  // ignore: public_member_api_docs
  TraversalEdgeBehavior get effectiveTraversalEdgeBehavior {
    if (traversalEdgeBehavior != null) {
      return traversalEdgeBehavior!;
    }

    if (kIsWeb) {
      return .closedLoop;
    }

    return switch (defaultTargetPlatform) {
      .android || .fuchsia || .linux || .windows => .closedLoop,
      .iOS || .macOS => .stop,
    };
  }

  // ignore: public_member_api_docs
  String get debugMenuFocusScopeLabel => 'BaseMenu FocusScopeNode${key != null ? ' ($key)' : ''}';

  /// The fallback [onOpenRequest] if one is not supplied to the menu.
  ///
  /// By default, the menu will open immediately without any delay or animation.
  static void defaultOnOpenRequested(Offset? position, VoidCallback showOverlay) {
    showOverlay();
  }

  /// The fallback `onCloseRequest` if one is not supplied to the menu.
  ///
  /// By default, the menu will close immediately without any delay or animation.
  static void defaultOnCloseRequested(VoidCallback hideOverlay) {
    hideOverlay();
  }

  /// Returns whether the nearest ancestor [BaseMenu], [BaseMenuBar], or
  /// [BaseSubmenu] is a submenu of another menu, or null if no ancestor menu is
  /// found.
  ///
  /// Calling this method establishes a dependency that will cause the provided
  /// [BuildContext] to rebuild if the ancestor menu changes from being a
  /// submenu to a root menu, or the reverse.
  static bool? maybeIsSubmenuOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BaseMenuScope>()?.isSubmenu;
  }

  /// Returns the [orientation] of the nearest ancestor [BaseMenu],
  /// [BaseMenuBar], or [BaseSubmenu], or null if no appropriate widget is
  /// found.
  ///
  /// Calling this method establishes a dependency that will cause the provided
  /// [BuildContext] to rebuild whenever the ancestor menu's [orientation]
  /// changes.
  static Axis? maybeOrientationOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BaseMenuScope>()?.orientation;
  }

  @override
  State<BaseMenu> createState() => _BaseMenuState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<MenuController>.has('controller', controller));
  }
}

class _BaseMenuState extends State<BaseMenu> {
  late final _menuScopeNode = FocusScopeNode(
    skipTraversal: true,
    traversalEdgeBehavior: widget.effectiveTraversalEdgeBehavior,
    debugLabel: widget.debugMenuFocusScopeLabel,
  );

  late final Map<Type, Action<Intent>> _anchorActions = <Type, Action<Intent>>{
    EnterMenuIntent: CallbackAction<EnterMenuIntent>(onInvoke: _handleEnterMenu),
  };

  final _overlayFocusNode = FocusNode(debugLabel: 'BaseMenu Overlay FocusNode');

  TextDirection _textDirection = TextDirection.ltr;
  bool _parentIsSubmenu = false;
  Axis? _parentOrientation;
  bool _isScopeFocused = false;
  MenuController? _internalMenuController;
  Map<Type, CallbackAction<Intent>>? _overlayActions;
  MenuController get _menuController {
    return widget.controller ?? _internalMenuController!;
  }

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalMenuController = MenuController();
    }
    _menuScopeNode.addListener(() {
      assert(mounted);
      if (_isScopeFocused != _menuScopeNode.hasFocus) {
        _isScopeFocused = _menuScopeNode.hasFocus;
        widget.onFocusChange?.call(_isScopeFocused);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
    final orientation = BaseMenu.maybeOrientationOf(context);
    final isSubmenu = BaseMenu.maybeIsSubmenuOf(context);
    if (orientation != _parentOrientation || isSubmenu != _parentIsSubmenu) {
      _parentOrientation = orientation;
      _parentIsSubmenu = isSubmenu ?? false;
    }
  }

  @override
  void didUpdateWidget(BaseMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (widget.controller == null) {
        assert(_internalMenuController == null);
        _internalMenuController = MenuController();
      } else if (oldWidget.controller == null) {
        _internalMenuController = null;
      }
    }

    if (oldWidget.traversalEdgeBehavior != widget.traversalEdgeBehavior) {
      _menuScopeNode.traversalEdgeBehavior = widget.effectiveTraversalEdgeBehavior;
    }

    assert(() {
      _menuScopeNode.debugLabel = widget.debugMenuFocusScopeLabel;
      return true;
    }());
  }

  @override
  void dispose() {
    _internalMenuController = null;
    _menuScopeNode.dispose();
    _overlayFocusNode.dispose();
    super.dispose();
  }

  void _handleEnterMenu(EnterMenuIntent intent) {
    if (_menuController.isOpen) {
      if (_menuScopeNode.context != null) {
        Actions.maybeInvoke(_menuScopeNode.context!, intent._scopeIntent);
      }
    } else {
      _menuController.open();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && _menuController.isOpen) {
          Actions.invoke(_menuScopeNode.context!, intent._scopeIntent);
        }
      });
    }
  }

  Widget _buildAnchor(BuildContext context, MenuController controller, Widget? child) {
    final directionalShortcuts = switch (_textDirection) {
      TextDirection.ltr => _kMenuLTRShortcuts,
      TextDirection.rtl => _kMenuRTLShortcuts,
    };
    return Actions(
      actions: _anchorActions,
      child: Shortcuts(
        shortcuts: switch (_parentOrientation) {
          Axis.vertical => {
            ...directionalShortcuts,
            if (controller.isOpen && widget.orientation == Axis.vertical) ...{
              const SingleActivator(LogicalKeyboardKey.arrowUp): const EnterMenuIntent.focusLast(),
              const SingleActivator(LogicalKeyboardKey.arrowDown):
                  const EnterMenuIntent.focusFirst(),
            },
          },
          Axis.horizontal || null => {
            ...directionalShortcuts,
            const SingleActivator(LogicalKeyboardKey.arrowDown): const EnterMenuIntent.focusFirst(),
            if (!_parentIsSubmenu || widget.orientation == Axis.vertical)
              const SingleActivator(LogicalKeyboardKey.arrowUp): const EnterMenuIntent.focusLast(),
          },
        },
        child: Builder(
          builder: (context) {
            return widget.builder?.call(context, controller, widget.child) ??
                widget.child ??
                const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext _, RawMenuOverlayInfo position) {
    final overlay = _MenuOverlay(
      overlayFocusNode: _overlayFocusNode,
      submenuAxis: widget.orientation,
      position: position,
      consumeOutsideTaps: widget.consumeOutsideTaps,
      semanticProperties: widget.semanticProperties,
      menuController: _menuController,
      focusScopeNode: _menuScopeNode,
      positioningDelegate: widget.positionDelegate,
      child: widget.menu,
    );

    final Widget child = widget.overlayChildBuilder != null
        ? Builder(
            builder: (context) {
              return widget.overlayChildBuilder!.call(context, overlay);
            },
          )
        : overlay;

    if (_parentOrientation != null) {
      return child;
    }

    return Actions(
      actions: _overlayActions ??= {
        NextFocusIntent: CallbackAction<NextFocusIntent>(
          onInvoke: (intent) {
            _menuController.close();
            _overlayFocusNode.descendantsAreFocusable = false;
            FocusManager.instance.applyFocusChangesIfNeeded();
            _overlayFocusNode.descendantsAreFocusable = true;
            return FocusScope.of(context, createDependency: false).nextFocus();
          },
        ),
        PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(
          onInvoke: (intent) {
            _menuController.close();
            _overlayFocusNode.descendantsAreFocusable = false;
            FocusManager.instance.applyFocusChangesIfNeeded();
            _overlayFocusNode.descendantsAreFocusable = true;
            return FocusScope.of(context, createDependency: false).previousFocus();
          },
        ),
      },
      child: child,
    );
  }

  bool _isPostFrameCallbackScheduled = false;
  void _postFrameCallback(Duration _) {
    assert(_isPostFrameCallbackScheduled);
    _isPostFrameCallbackScheduled = false;
    if (!mounted) {
      return;
    }

    final isOpen = _menuController.isOpen;
    if (!isOpen && _isScopeFocused) {
      assert(!_menuScopeNode.hasFocus);
      _isScopeFocused = _menuScopeNode.hasFocus;
      widget.onFocusChange?.call(_isScopeFocused);
    }

    if (!kIsWeb) {
      return;
    }

    // Prevents the root focus scope from taking focus on web.
    final previousPrimaryFocus = FocusManager.instance.primaryFocus;
    if (previousPrimaryFocus == null) {
      return;
    }

    if (isOpen) {
      previousPrimaryFocus.requestFocus();
      return;
    }

    FocusManager.instance.applyFocusChangesIfNeeded();
    if (FocusManager.instance.rootScope.hasPrimaryFocus) {
      previousPrimaryFocus.requestFocus();
    }
  }

  void _handleClose() {
    widget.onClose?.call();
    if (!_isPostFrameCallbackScheduled) {
      _isPostFrameCallbackScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback(_postFrameCallback);
    }
  }

  void _handleOpen() {
    widget.onOpen?.call();
    if (kIsWeb && !_isPostFrameCallbackScheduled) {
      _isPostFrameCallbackScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback(_postFrameCallback);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = Actions(
      actions: {DirectionalFocusIntent: DoNothingAction()},
      child: Shortcuts(
        includeSemantics: false,
        shortcuts: _kStopDirectionalPropagationShortcuts,
        child: RawMenuAnchor(
          useRootOverlay: widget.useRootOverlay,
          onOpen: _handleOpen,
          onClose: _handleClose,
          onOpenRequested: widget.onOpenRequest,
          onCloseRequested: widget.onCloseRequest,
          consumeOutsideTaps: widget.consumeOutsideTaps,
          controller: _menuController,
          overlayBuilder: _buildOverlay,
          builder: _buildAnchor,
        ),
      ),
    );

    return child;
  }
}

class _MenuOverlay extends StatelessWidget {
  const _MenuOverlay({
    required this.position,
    required this.menuController,
    required this.focusScopeNode,
    required this.child,
    required this.semanticProperties,
    required this.consumeOutsideTaps,
    required this.submenuAxis,
    required this.positioningDelegate,
    required this.overlayFocusNode,
  });

  final RawMenuOverlayInfo position;
  final Widget child;
  final bool consumeOutsideTaps;
  final MenuController menuController;
  final FocusScopeNode focusScopeNode;
  final Axis submenuAxis;
  final SemanticsProperties semanticProperties;
  final MenuPositioningDelegate positioningDelegate;
  final FocusNode overlayFocusNode;

  Widget _buildConditionalTraversal(BuildContext context, Widget? child) {
    return Focus(
      focusNode: overlayFocusNode,
      includeSemantics: false,
      canRequestFocus: false,
      skipTraversal: !focusScopeNode.hasFocus,
      child: child!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final MenuController menuController = MenuController.maybeOf(context)!;
    final Widget panel = ListenableBuilder(
      listenable: focusScopeNode,
      builder: _buildConditionalTraversal,
      child: TapRegion(
        groupId: position.tapRegionGroupId,
        consumeOutsideTaps: consumeOutsideTaps,
        onTapOutside: (PointerDownEvent event) {
          menuController.close();
        },
        child: _InlineMenu(
          axis: submenuAxis,
          focusScopeNode: focusScopeNode,
          semanticProperties: semanticProperties,
          child: BaseMenuScope(orientation: submenuAxis, isSubmenu: true, child: child),
        ),
      ),
    );

    return ConstrainedBox(
      constraints: BoxConstraints.loose(position.overlaySize),
      child: Builder(
        builder: (BuildContext context) {
          return positioningDelegate.build(context, position, panel);
        },
      ),
    );
  }
}

/// A widget that groups [BaseMenu]s into an accessible menu bar.
///
/// [BaseMenuBar] coordinates a series of hierarchical menus typically presented
/// as a horizontal row at the top of an application window. When one menu in
/// the bar is opened, any other open menu in that same bar is automatically
/// closed.
///
/// [BaseMenuBar] can be managed using the [MenuController] API:
/// * The nearest ancestor [BaseMenuBar] open/close state can be observed using
///   [MenuController.maybeIsOpenOf].
/// * The nearest ancestor [MenuController] can be read using
///   [MenuController.maybeOf].
/// * Tapping outside of the [BaseMenuBar] or pressing
///   [LogicalKeyboardKey.escape] will emit a [DismissIntent] that closes the
///   menu.
///
/// The [orientation] property controls the keyboard navigation layout. By
/// default, the [orientation] is [Axis.horizontal], meaning that the left and
/// right arrow keys traverse the top-level menu items. If the [orientation] is
/// set to [Axis.vertical], the up and down arrow keys traverse the top-level
/// menu items. Traversal respects the ambient [Directionality], so in a
/// right-to-left context, the left and right arrow keys are reversed.
///
/// **See also:**
/// * [BaseMenu], for creating standalone dropdown menus and context menus.
/// * [BaseSubmenu], for creating submenus within a [BaseMenuBar].
/// * [BaseMenuPanel], a companion widget for laying out menu items.
class BaseMenuBar extends StatefulWidget {
  /// Creates a [BaseMenuBar].
  ///
  /// The [child] parameter is required and must not be null.
  const BaseMenuBar({
    super.key,
    this.controller,
    this.orientation = Axis.horizontal,
    this.focusScopeNode,
    this.semanticProperties = const SemanticsProperties(
      scopesRoute: true,
      role: SemanticsRole.menuBar,
    ),
    required this.child,
  });

  /// The [MenuController] that controls the global open/close state of the
  /// [BaseMenuBar]'s submenus.
  ///
  /// If provided, this controller can be used to query whether any children are
  /// open via [MenuController.isOpen], or to close all children at once using
  /// [MenuController.close].
  final MenuController? controller;

  /// The keyboard navigation layout and axis direction for the [BaseMenuBar].
  ///
  /// Defaults to [Axis.horizontal] (meaning left and right arrow keys traverse the top-level items).
  final Axis orientation;

  /// An optional [FocusScopeNode] to manage focus events within the
  /// [BaseMenuBar].
  ///
  /// If not provided, an internal [FocusScopeNode] is instantiated and
  /// maintained automatically.
  final FocusScopeNode? focusScopeNode;

  /// The [SemanticsProperties] applied to the menu's semantic node.
  ///
  /// Defaults to describing a [SemanticsRole.menuBar] route scope.
  final SemanticsProperties semanticProperties;

  /// The content of the [BaseMenuBar].
  ///
  /// While the [BaseMenuPanel] provides a simple default layout, the [child]
  /// can be any widget.
  final Widget child;

  @override
  State<BaseMenuBar> createState() => _BaseMenuBarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<MenuController>.has('controller', controller));
    properties.add(EnumProperty<Axis>('axis', orientation));
    properties.add(ObjectFlagProperty<FocusScopeNode>.has('focusScopeNode', focusScopeNode));
  }
}

class _BaseMenuBarState extends State<BaseMenuBar> {
  late final _actions = <Type, Action<Intent>>{
    NextFocusIntent: CallbackAction<NextFocusIntent>(
      onInvoke: (intent) {
        _menuController.close();
        return _menuScopeNode.enclosingScope?.nextFocus();
      },
    ),
    PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(
      onInvoke: (intent) {
        _menuController.close();
        return _menuScopeNode.enclosingScope?.previousFocus();
      },
    ),
  };

  MenuController get _menuController => widget.controller ?? _internalMenuController!;
  MenuController? _internalMenuController;

  FocusScopeNode get _menuScopeNode => widget.focusScopeNode ?? _internalFocusScopeNode!;
  FocusScopeNode? _internalFocusScopeNode;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalMenuController = MenuController();
    }

    if (widget.focusScopeNode == null) {
      _internalFocusScopeNode = FocusScopeNode(
        debugLabel: 'BaseMenuBar.focusScopeNode ${widget.orientation}',
        directionalTraversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
      );
    }
  }

  @override
  void didUpdateWidget(BaseMenuBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (widget.controller == null) {
        _internalMenuController = MenuController();
      } else if (oldWidget.controller == null) {
        _internalMenuController = null;
      }
    }

    if (oldWidget.focusScopeNode != widget.focusScopeNode) {
      if (widget.focusScopeNode == null) {
        _internalFocusScopeNode = FocusScopeNode(
          debugLabel: 'BaseMenuBar.focusScopeNode ${widget.orientation}',
          directionalTraversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
        );
      } else {
        _internalFocusScopeNode?.dispose();
        _internalFocusScopeNode = null;
      }
    }
  }

  @override
  void dispose() {
    _internalFocusScopeNode?.dispose();
    _internalFocusScopeNode = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = _InlineMenu(
      axis: widget.orientation,
      semanticProperties: widget.semanticProperties,
      focusScopeNode: _menuScopeNode,
      child: BaseMenuScope(orientation: widget.orientation, isSubmenu: false, child: widget.child),
    );

    return RawMenuAnchorGroup(
      controller: _menuController,
      child: Builder(
        builder: (context) {
          return Actions(actions: _actions, child: child);
        },
      ),
    );
  }
}

class _InlineMenu extends StatelessWidget {
  const _InlineMenu({
    required this.child,
    required this.axis,
    required this.focusScopeNode,
    required this.semanticProperties,
  });

  final Widget child;
  final Axis axis;
  final FocusScopeNode focusScopeNode;
  final SemanticsProperties semanticProperties;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      includeSemantics: false,
      shortcuts: _kStopDirectionalPropagationShortcuts,
      child: Semantics.fromProperties(
        explicitChildNodes: true,
        properties: semanticProperties,
        child: _MenuFocusTraversal(axis: axis, focusScopeNode: focusScopeNode, child: child),
      ),
    );
  }
}

class _MenuFocusTraversal extends StatefulWidget {
  const _MenuFocusTraversal({
    required this.axis,
    required this.focusScopeNode,
    required this.child,
  });

  final Axis axis;
  final FocusScopeNode focusScopeNode;
  final Widget child;

  @override
  State<_MenuFocusTraversal> createState() => _MenuFocusTraversalState();
}

class _MenuFocusTraversalState extends State<_MenuFocusTraversal> {
  final policy = OrderedTraversalPolicy(secondary: WidgetOrderTraversalPolicy());
  Map<Type, Action<Intent>>? _actions;

  @override
  void didUpdateWidget(_MenuFocusTraversal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.axis != widget.axis || oldWidget.focusScopeNode != widget.focusScopeNode) {
      _actions = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: policy,
      child: Actions(
        actions: _actions ??= {
          _MenuFocusFirstIntent: _FocusFirstAction(widget.focusScopeNode),
          _MenuFocusLastIntent: _FocusLastAction(widget.focusScopeNode),
          ...switch (widget.axis) {
            Axis.vertical => {
              VerticalMenuFocusNextIntent: _TraverseNextAction<VerticalMenuFocusNextIntent>(
                widget.focusScopeNode,
              ),
              VerticalMenuFocusPreviousIntent:
                  _TraversePreviousAction<VerticalMenuFocusPreviousIntent>(widget.focusScopeNode),
            },
            Axis.horizontal => {
              HorizontalMenuFocusNextIntent: _TraverseNextAction<HorizontalMenuFocusNextIntent>(
                widget.focusScopeNode,
              ),
              HorizontalMenuFocusPreviousIntent:
                  _TraversePreviousAction<HorizontalMenuFocusPreviousIntent>(widget.focusScopeNode),
            },
          },
        },
        child: Shortcuts(
          shortcuts: switch (Directionality.maybeOf(context) ?? .ltr) {
            TextDirection.ltr => _kMenuLTRShortcuts,
            TextDirection.rtl => _kMenuRTLShortcuts,
          },
          child: FocusScope(
            node: widget.focusScopeNode,
            canRequestFocus: true,
            descendantsAreFocusable: true,
            descendantsAreTraversable: true,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _FocusFirstAction extends Action<_MenuFocusFirstIntent> {
  _FocusFirstAction(this.focusScopeNode);
  final FocusScopeNode focusScopeNode;

  @override
  void invoke(_MenuFocusFirstIntent intent) {
    final FocusTraversalPolicy policy = FocusTraversalGroup.maybeOfNode(focusScopeNode)!;
    final FocusNode? firstNode = policy.findFirstFocus(focusScopeNode, ignoreCurrentFocus: true);
    if (firstNode != null) {
      policy.requestFocusCallback(firstNode, alignmentPolicy: .keepVisibleAtStart);
    }
  }
}

class _FocusLastAction extends Action<_MenuFocusLastIntent> {
  _FocusLastAction(this.focusScopeNode);
  final FocusScopeNode focusScopeNode;

  @override
  void invoke(_MenuFocusLastIntent intent) {
    final FocusTraversalPolicy policy = FocusTraversalGroup.maybeOfNode(focusScopeNode)!;
    final FocusNode lastNode = policy.findLastFocus(focusScopeNode, ignoreCurrentFocus: true);
    policy.requestFocusCallback(lastNode, alignmentPolicy: .keepVisibleAtEnd);
  }
}

class _TraverseNextAction<T extends _TraversalIntent> extends Action<T> {
  _TraverseNextAction(this.focusScopeNode);
  final FocusScopeNode focusScopeNode;
  @override
  void invoke(T intent) {
    // Find the next node in the traversal order
    focusScopeNode.requestFocus();
    if (focusScopeNode.nextFocus()) {
      FocusManager.instance.applyFocusChangesIfNeeded();
      if (primaryFocus == focusScopeNode.focusedChild &&
          focusScopeNode.focusedChild!.context != null) {
        Scrollable.ensureVisible(
          focusScopeNode.focusedChild!.context!,
          alignmentPolicy: .keepVisibleAtStart,
        );
      }
    }
  }
}

class _TraversePreviousAction<T extends _TraversalIntent> extends Action<T> {
  _TraversePreviousAction(this.focusScopeNode);
  final FocusScopeNode focusScopeNode;
  @override
  void invoke(T intent) {
    focusScopeNode.requestFocus();
    if (focusScopeNode.previousFocus()) {
      FocusManager.instance.applyFocusChangesIfNeeded();
      if (primaryFocus == focusScopeNode.focusedChild &&
          focusScopeNode.focusedChild!.context != null) {
        Scrollable.ensureVisible(
          focusScopeNode.focusedChild!.context!,
          alignmentPolicy: .keepVisibleAtEnd,
        );
      }
    }
  }
}

class _MenuPositioner extends SingleChildRenderObjectWidget {
  const _MenuPositioner({
    required Widget super.child,
    required this.offset,
    required this.anchorRect,
    required this.overlayPadding,
    required this.alignment,
    required this.menuAlignment,
    required this.menuPadding,
    required this.edgeBehavior,
    this.menuPosition,
    this.onPositioned,
  });

  // Rectangle of the button anchoring the menu overlay.
  final ui.Rect anchorRect;

  /// The [Offset] applied to the menu position after aligning the menu and anchor
  /// based on [alignment] and [menuAlignment].
  final ui.Offset offset;

  /// The [Offset] of the menu relative to the top-left corner of the anchor.
  final ui.Offset? menuPosition;

  /// The padding between the menu and the edges of the overlay.
  ///
  /// Used to prevent the menu from being obstructed by system UI.
  final EdgeInsetsGeometry overlayPadding;

  /// The padding applied to the menu surface.
  final EdgeInsetsGeometry? menuPadding;

  /// The alignment of the menu attachment point relative to the anchor area.
  final AlignmentGeometry alignment;

  /// The alignment of the menu attachment point relative to the menu surface.
  final AlignmentGeometry menuAlignment;

  /// The axis or axes on which the menu should be flipped across the anchor's
  /// midpoint if it overflows the edge of the screen.
  final EdgeBehavior edgeBehavior;

  /// A callback that is invoked when the menu is positioned, providing the
  /// final [Rect] of the menu in the overlay's coordinate space.
  final ValueChanged<Rect>? onPositioned;

  static Set<ui.Rect> _avoidBounds(List<ui.DisplayFeature> displayFeatures) {
    final bounds = <ui.Rect>{};
    for (final feature in displayFeatures) {
      if (feature.bounds.shortestSide > 0 ||
          feature.state == ui.DisplayFeatureState.postureHalfOpened) {
        bounds.add(feature.bounds);
      }
    }
    return bounds;
  }

  @override
  _RenderMenuPositioner createRenderObject(BuildContext context) {
    final displayFeatures = MediaQuery.maybeDisplayFeaturesOf(context);
    final textDirection = Directionality.maybeOf(context) ?? .ltr;
    return _RenderMenuPositioner(
      anchorRect: anchorRect,
      offset: offset,
      menuPosition: menuPosition,
      overlayPadding: overlayPadding,
      avoidBounds: displayFeatures != null ? _avoidBounds(displayFeatures) : const {},
      alignment: alignment,
      menuAlignment: menuAlignment,
      textDirection: textDirection,
      menuPadding: menuPadding,
      edgeBehavior: edgeBehavior,
      onPositioned: onPositioned,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderMenuPositioner renderObject) {
    final displayFeatures = MediaQuery.maybeDisplayFeaturesOf(context);
    final textDirection = Directionality.maybeOf(context) ?? .ltr;
    renderObject
      ..anchorRect = anchorRect
      ..offset = offset
      ..menuPosition = menuPosition
      ..overlayPadding = overlayPadding
      ..avoidBounds = displayFeatures != null ? _avoidBounds(displayFeatures) : const {}
      ..alignment = alignment
      ..menuAlignment = menuAlignment
      ..textDirection = textDirection
      ..menuPadding = menuPadding
      ..edgeBehavior = edgeBehavior
      ..onPositioned = onPositioned;
  }
}

class _RenderMenuPositioner extends RenderShiftedBox {
  _RenderMenuPositioner({
    RenderBox? child,
    required ui.Rect anchorRect,
    required ui.Offset offset,
    required ui.Offset? menuPosition,
    required EdgeInsetsGeometry overlayPadding,
    required Set<ui.Rect> avoidBounds,
    required AlignmentGeometry alignment,
    required AlignmentGeometry menuAlignment,
    required TextDirection textDirection,
    required EdgeInsetsGeometry? menuPadding,
    required EdgeBehavior edgeBehavior,
    required ValueChanged<ui.Rect>? onPositioned,
  }) : _anchorRect = anchorRect,
       _offset = offset,
       _menuPosition = menuPosition,
       _overlayPadding = overlayPadding,
       _avoidBounds = avoidBounds,
       _alignment = alignment,
       _menuAlignment = menuAlignment,
       _textDirection = textDirection,
       _menuPadding = menuPadding,
       _edgeBehavior = edgeBehavior,
       _onPositioned = onPositioned,
       super(child);

  Rect get anchorRect => _anchorRect;
  Rect _anchorRect;
  set anchorRect(Rect value) {
    if (_anchorRect != value) {
      _anchorRect = value;
      markNeedsLayout();
    }
  }

  Offset get offset => _offset;
  Offset _offset;
  set offset(Offset value) {
    if (_offset != value) {
      _offset = value;
      markNeedsLayout();
    }
  }

  Offset? get menuPosition => _menuPosition;
  Offset? _menuPosition;
  set menuPosition(Offset? value) {
    if (_menuPosition != value) {
      _menuPosition = value;
      markNeedsLayout();
    }
  }

  EdgeInsetsGeometry get overlayPadding => _overlayPadding;
  EdgeInsetsGeometry _overlayPadding;
  set overlayPadding(EdgeInsetsGeometry value) {
    if (_overlayPadding != value) {
      _overlayPadding = value;
      _resolvedOverlayPadding = null;
      markNeedsLayout();
    }
  }

  Set<Rect> get avoidBounds => _avoidBounds;
  Set<Rect> _avoidBounds;
  set avoidBounds(Set<Rect> value) {
    if (_avoidBounds != value) {
      _avoidBounds = value;
      markNeedsLayout();
    }
  }

  AlignmentGeometry get alignment => _alignment;
  AlignmentGeometry _alignment;
  set alignment(AlignmentGeometry value) {
    if (_alignment != value) {
      _alignment = value;
      _resolvedAlignment = null;
      markNeedsLayout();
    }
  }

  AlignmentGeometry _menuAlignment;
  AlignmentGeometry get menuAlignment => _menuAlignment;
  set menuAlignment(AlignmentGeometry value) {
    if (_menuAlignment != value) {
      _menuAlignment = value;
      _resolvedMenuAlignment = null;
      markNeedsLayout();
    }
  }

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection != value) {
      _textDirection = value;
      _resolvedAlignment = _resolvedMenuAlignment = _resolvedMenuPadding = _resolvedOverlayPadding =
          null;
      markNeedsLayout();
    }
  }

  EdgeInsetsGeometry? _menuPadding;
  EdgeInsetsGeometry? get menuPadding => _menuPadding;
  set menuPadding(EdgeInsetsGeometry? value) {
    if (_menuPadding != value) {
      _menuPadding = value;
      _resolvedMenuPadding = null;
      markNeedsLayout();
    }
  }

  EdgeBehavior _edgeBehavior;
  EdgeBehavior get edgeBehavior => _edgeBehavior;
  set edgeBehavior(EdgeBehavior v) {
    if (_edgeBehavior != v) {
      _edgeBehavior = v;
      markNeedsLayout();
    }
  }

  ValueChanged<Rect>? get onPositioned => _onPositioned;
  ValueChanged<Rect>? _onPositioned;
  set onPositioned(ValueChanged<Rect>? value) {
    if (_onPositioned != value) {
      _onPositioned = value;
      markNeedsLayout();
    }
  }

  Alignment? _resolvedAlignment;
  Alignment get resolvedAlignment => _resolvedAlignment ??= alignment.resolve(textDirection);

  Alignment? _resolvedMenuAlignment;
  Alignment get resolvedMenuAlignment =>
      _resolvedMenuAlignment ??= menuAlignment.resolve(textDirection);

  EdgeInsets? _resolvedMenuPadding;
  EdgeInsets get resolvedMenuPadding =>
      _resolvedMenuPadding ??= menuPadding?.resolve(textDirection) ?? EdgeInsets.zero;

  EdgeInsets? _resolvedOverlayPadding;
  EdgeInsets get resolvedOverlayPadding =>
      _resolvedOverlayPadding ??= overlayPadding.resolve(textDirection);

  @override
  void performLayout() {
    assert(child != null);

    final parentSize = constraints.biggest;
    final screen = _findClosestScreen(parentSize, anchorRect.center, avoidBounds);

    var maxWidth = double.infinity;
    var maxHeight = double.infinity;
    var maybeAdjustHorizontalConstraint = false;
    var maybeAdjustVerticalConstraint = false;

    if (edgeBehavior.horizontal.constrain) {
      if (edgeBehavior.horizontal.shift) {
        maxWidth = screen.width - resolvedOverlayPadding.horizontal;
      } else {
        maybeAdjustHorizontalConstraint = true;
      }
    }

    if (edgeBehavior.vertical.constrain) {
      if (edgeBehavior.vertical.shift) {
        maxHeight = screen.height - resolvedOverlayPadding.vertical;
      } else {
        maybeAdjustVerticalConstraint = true;
      }
    }

    child!.layout(BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight), parentUsesSize: true);
    final childSize = child!.size;

    Offset anchorOffset;
    if (menuPosition == null) {
      anchorOffset = resolvedAlignment.withinRect(anchorRect);
      anchorOffset += offset;
    } else {
      anchorOffset = anchorRect.topLeft + menuPosition!;
    }

    final ui.Offset desiredPosition = anchorOffset - resolvedMenuAlignment.alongSize(childSize);
    var position = getPositionForChild(screen, childSize, desiredPosition, anchorOffset);

    if (maybeAdjustHorizontalConstraint || maybeAdjustVerticalConstraint) {
      double? boundedHeight;
      double? boundedWidth;
      final Rect(:left, :top, :right, :bottom) = resolvedOverlayPadding.deflateRect(screen);
      if (maybeAdjustVerticalConstraint) {
        final double overflowTop = math.max(top - position.dy, 0);
        final double overflowBottom = math.max(position.dy + child!.size.height - bottom, 0);
        if (overflowTop > 0 || overflowBottom > 0) {
          boundedHeight = math.max(0, child!.size.height - (overflowTop + overflowBottom));
          position += Offset(0, overflowTop);
        }
      }

      if (maybeAdjustHorizontalConstraint) {
        final double overflowLeft = math.max(left - position.dx, 0);
        final double overflowRight = math.max(position.dx + child!.size.width - right, 0);
        if (overflowLeft > 0 || overflowRight > 0) {
          boundedWidth = math.max(0, child!.size.width - (overflowLeft + overflowRight));
          position += Offset(overflowLeft, 0);
        }
      }

      if (boundedWidth != null || boundedHeight != null) {
        child!.layout(
          BoxConstraints(maxWidth: boundedWidth ?? maxWidth, maxHeight: boundedHeight ?? maxHeight),
          parentUsesSize: true,
        );
      }
    }

    final parentData = child!.parentData! as BoxParentData;
    parentData.offset = position;
    onPositioned?.call(position & child!.size);
    size = constraints.biggest;
  }

  // Finds the closest screen to the anchor position.
  //
  // The closest screen is defined as the screen whose center is closest to the
  // anchor position.
  //
  // This algorithm is different from the algorithms for PopupMenuButton and MenuAnchor,
  // since those widgets calculate the closest screen based on the center of the
  // overlay.
  Rect _findClosestScreen(Size parentSize, Offset point, Set<Rect> avoidBounds) {
    final Iterable<ui.Rect> screens = DisplayFeatureSubScreen.subScreensInBounds(
      Offset.zero & parentSize,
      avoidBounds,
    );

    Rect? closest;
    double closestSquaredDistance = 0;
    for (final screen in screens) {
      if (screen.contains(point)) {
        return screen;
      }

      if (closest == null) {
        closest = screen;
        closestSquaredDistance = _computeSquaredDistanceToRect(point, closest);
        continue;
      }

      final double squaredDistance = _computeSquaredDistanceToRect(point, screen);
      if (squaredDistance < closestSquaredDistance) {
        closest = screen;
        closestSquaredDistance = squaredDistance;
      }
    }

    return closest!;
  }

  Offset getPositionForChild(Rect screen, Size childSize, Offset position, Offset anchorPosition) {
    final EdgeInsets padding = resolvedMenuPadding;
    final EdgeInsets overlayInsets = resolvedOverlayPadding;
    final Rect anchor = menuPosition == null ? anchorRect : anchorPosition & Size.zero;

    double x = position.dx;
    double y = position.dy;

    double? shiftX;
    if (padding.horizontal > 0) {
      double ratio = (x - anchorPosition.dx) / childSize.width;
      ratio = ui.clampDouble(ratio, -1, 0);
      shiftX = padding.right * ratio + padding.left * (ratio + 1);
      x -= shiftX;
    }

    double? shiftY;
    if (padding.vertical > 0) {
      double ratio = (y - anchorPosition.dy) / childSize.height;
      ratio = ui.clampDouble(ratio, -1, 0);
      shiftY = padding.bottom * ratio + padding.top * (ratio + 1);
      y -= shiftY;
    }

    x = _resolveAxisComponent(
      component: x,
      originalPosition: position.dx,
      childSize: childSize.width,
      overlayStart: screen.left + overlayInsets.left,
      overlayEnd: screen.right - overlayInsets.right,
      anchorMidpoint: anchor.center.dx,
      anchorStart: anchor.left,
      anchorEnd: anchor.right,
      paddingShift: shiftX,
      paddingTotal: padding.horizontal,
      strategy: edgeBehavior.horizontal,
      prioritizeStartEdge: textDirection == TextDirection.ltr,
    );

    y = _resolveAxisComponent(
      component: y,
      originalPosition: position.dy,
      childSize: childSize.height,
      overlayStart: screen.top + overlayInsets.top,
      overlayEnd: screen.bottom - overlayInsets.bottom,
      anchorMidpoint: anchor.center.dy,
      anchorStart: anchor.top,
      anchorEnd: anchor.bottom,
      paddingShift: shiftY,
      paddingTotal: padding.vertical,
      strategy: edgeBehavior.vertical,
      prioritizeStartEdge: true,
    );

    return Offset(x, y);
  }

  double _resolveAxisComponent({
    required double component,
    required double originalPosition,
    required double childSize,
    required double overlayStart,
    required double overlayEnd,
    required double anchorMidpoint,
    required double anchorStart,
    required double anchorEnd,
    required double? paddingShift,
    required double paddingTotal,
    required EdgeBehaviorStrategy strategy,
    required bool prioritizeStartEdge,
  }) {
    var position = component;
    final boundaryStart = overlayStart;
    final boundaryEnd = overlayEnd - childSize;

    bool overStartEdge(double position) => position < boundaryStart;
    bool overEndEdge(double position) => position > boundaryEnd;

    final overflowStart = overStartEdge(position);
    final overflowEnd = overEndEdge(position);

    if ((overflowStart || overflowEnd) && strategy.flip) {
      double positionFlipped = anchorMidpoint * 2 - originalPosition - childSize;

      if (paddingShift != null) {
        if (overflowStart) {
          positionFlipped -= paddingTotal + paddingShift;
        } else {
          positionFlipped += paddingTotal - paddingShift;
        }
      }

      if (overStartEdge(positionFlipped) || overEndEdge(positionFlipped)) {
        if (!strategy.shift && !strategy.constrain) {
          // If neither shift nor constrain is enabled, choose the position that
          // keeps the reading/top edge visible.
          return prioritizeStartEdge
              ? math.max(position, positionFlipped)
              : math.min(position, positionFlipped);
        }

        final double availableStart = anchorStart - overlayStart;
        final double availableEnd = overlayEnd - anchorEnd;

        if (availableEnd == availableStart) {
          position = prioritizeStartEdge
              ? math.min(position, positionFlipped)
              : math.max(position, positionFlipped);
        } else {
          position = availableEnd > availableStart
              ? math.max(position, positionFlipped)
              : math.min(position, positionFlipped);
        }

        if (!strategy.shift) {
          return position;
        }

        if (boundaryEnd >= boundaryStart) {
          return ui.clampDouble(position, boundaryStart, boundaryEnd);
        }

        if (prioritizeStartEdge) {
          return boundaryStart;
        }

        return boundaryEnd;
      }

      return positionFlipped;
    }

    if (overflowStart && overflowEnd) {
      return prioritizeStartEdge ? boundaryStart : boundaryEnd;
    }

    if (strategy.shift) {
      final double availableSpace = overlayEnd - overlayStart;
      if (childSize > availableSpace) {
        return prioritizeStartEdge ? boundaryStart : boundaryEnd;
      }

      if (overflowStart) {
        return boundaryStart;
      }

      if (overflowEnd) {
        return boundaryEnd;
      }
    }

    return position;
  }
}
