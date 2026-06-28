import 'dart:math' as math;
import 'dart:ui'
    as ui
    show Clip, DisplayFeature, DisplayFeatureState, Offset, Rect, TextDirection, clampDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../menu_utilities.dart';
import 'interface.dart';

// Examples can assume:
// late BuildContext context;
// late StateSetter setState;
// late List<Widget> menuItems;
// late RawMenuAnchorOverlayPosition position;

double _computeSquaredDistanceToRect(Offset point, Rect rect) {
  final double dx = point.dx - ui.clampDouble(point.dx, rect.left, rect.right);
  final double dy = point.dy - ui.clampDouble(point.dy, rect.top, rect.bottom);
  return dx * dx + dy * dy;
}

const Map<SingleActivator, Intent> _kMenuShortcuts = <SingleActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
  SingleActivator(LogicalKeyboardKey.arrowUp): BaseMenuVerticalFocusPreviousIntent(),
  SingleActivator(LogicalKeyboardKey.arrowDown): BaseMenuVerticalFocusNextIntent(),
  SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
  SingleActivator(LogicalKeyboardKey.tab, shift: true): PreviousFocusIntent(),
  SingleActivator(LogicalKeyboardKey.home): _MenuFocusFirstIntent(),
  SingleActivator(LogicalKeyboardKey.end): _MenuFocusLastIntent(),
};

const Map<SingleActivator, Intent> _kMenuLTRShortcuts = {
  ..._kMenuShortcuts,
  SingleActivator(LogicalKeyboardKey.arrowLeft): BaseMenuHorizontalFocusPreviousIntent(),
  SingleActivator(LogicalKeyboardKey.arrowRight): BaseMenuHorizontalFocusNextIntent(),
};

const Map<SingleActivator, Intent> _kMenuRTLShortcuts = {
  ..._kMenuShortcuts,
  SingleActivator(LogicalKeyboardKey.arrowLeft): BaseMenuHorizontalFocusNextIntent(),
  SingleActivator(LogicalKeyboardKey.arrowRight): BaseMenuHorizontalFocusPreviousIntent(),
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

/// An intent that moves focus to the next item within a horizontal menu or menubar.
final class BaseMenuHorizontalFocusNextIntent extends _TraversalIntent {
  const BaseMenuHorizontalFocusNextIntent();
}

/// An intent that moves focus to the previous item within a horizontal menu or menubar.
final class BaseMenuHorizontalFocusPreviousIntent extends _TraversalIntent {
  const BaseMenuHorizontalFocusPreviousIntent();
}

/// An intent that moves focus down to the next item within a vertical menu.
final class BaseMenuVerticalFocusNextIntent extends _TraversalIntent {
  const BaseMenuVerticalFocusNextIntent();
}

/// An intent that moves focus up to the previous item within a vertical menu.
final class BaseMenuVerticalFocusPreviousIntent extends _TraversalIntent {
  const BaseMenuVerticalFocusPreviousIntent();
}

class _MenuFocusFirstIntent extends Intent {
  const _MenuFocusFirstIntent();
}

class _MenuFocusLastIntent extends Intent {
  const _MenuFocusLastIntent();
}

/// An intent that signals the menu should be opened and an item should be focused.
class BaseMenuEnterIntent extends Intent {
  const BaseMenuEnterIntent() : _scopeIntent = null;

  /// Opens the menu if it is not already open and requests focus on the first menu item.
  const BaseMenuEnterIntent.focusFirst() : _scopeIntent = const _MenuFocusFirstIntent();

  /// Opens the menu if it is not already open and requests focus on the last menu item.
  const BaseMenuEnterIntent.focusLast() : _scopeIntent = const _MenuFocusLastIntent();

  /// An intent to fire on the menu's focus scope after it is opened
  /// and focused.
  ///
  /// Defaults to null, which does not fire any additional intents after opening
  /// and focusing the menu.
  final Intent? _scopeIntent;
}

class MenuScope extends InheritedWidget {
  const MenuScope({
    super.key,
    required super.child,
    required this.orientation,
    required this.isSubmenu,
  });

  final Axis orientation;
  final bool isSubmenu;

  @internal
  static MenuScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MenuScope>();
  }

  @override
  bool updateShouldNotify(MenuScope oldWidget) {
    return orientation != oldWidget.orientation || isSubmenu != oldWidget.isSubmenu;
  }
}

/// Signature for a callback that builds a widget that surrounds the overlay of
/// a [BaseMenu].
typedef BaseMenuOverlayChildBuilder = Widget Function(BuildContext context, Widget child);

class _BaseMenuPanelMouseRegion extends StatelessWidget {
  const _BaseMenuPanelMouseRegion({
    required this.child,
    this.cursor = MouseCursor.defer,
    this.onEnter,
    this.onHover,
    this.onExit,
  });

  final Widget child;
  final MouseCursor cursor;
  final PointerEnterEventListener? onEnter;
  final PointerHoverEventListener? onHover;
  final PointerExitEventListener? onExit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: .none,
      children: [
        Positioned.fill(
          child: MouseRegion(
            cursor: cursor,
            hitTestBehavior: HitTestBehavior.translucent,
            onEnter: onEnter,
            onHover: onHover,
            onExit: onExit,
          ),
        ),
        child,
      ],
    );
  }
}

class BaseMenuPanel extends StatelessWidget {
  /// Creates a [BaseMenuPanel].
  ///
  /// The [children] argument is required.
  const BaseMenuPanel({
    super.key,
    this.constraints,
    this.constrainCrossAxis = false,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.padding = EdgeInsets.zero,
    this.scrollable = true,
    this.spacing = 0,
    this.clipBehavior = Clip.none,
    this.onEnter,
    this.onExit,
    this.onHover,
    this.cursor,
    required this.orientation,
    required this.children,
  });

  /// The constraints to apply to the menu surface.
  ///
  /// If null, the menu will be allowed to expand to the intrinsic size of its
  /// children.
  final BoxConstraints? constraints;

  /// The menu items that should be displayed by this [BaseMenuPanel].
  final List<Widget> children;

  /// Whether the menu's cross axis should be laid out with regard to the bounds
  /// of the overlay.
  ///
  /// When true, the width of the menu will be constrained by the width of the
  /// overlay. This can cause the menu contents to wrap.
  ///
  /// When false, the menu will be allowed to expand to the intrinsic size of
  /// its children, and menu items that overflow will be visually clipped.
  ///
  /// Defaults to false.
  final bool constrainCrossAxis;

  /// The alignment of the menu items along the cross axis.
  ///
  /// Defaults to [CrossAxisAlignment.stretch], which stretches the menu items
  /// to fill the cross axis.
  final CrossAxisAlignment crossAxisAlignment;

  /// The [EdgeInsetsGeometry] applied to the menu surface.
  ///
  /// When a [BaseMenuPanel] is used with a [BaseMenu], [padding] applied to
  /// the menu surface can be ignored during layout by supplying an equivalent
  /// amount of [padding] to the [BaseMenu] constructor. This is useful
  /// when aligning a submenu with its anchor.
  ///
  /// Defaults to null, which applies no padding.
  final EdgeInsetsGeometry padding;

  /// The amount of padding to apply to the menu panel's scrollable.
  // final EdgeInsetsGeometry scrollPadding;

  /// The spacing to apply between menu items.
  ///
  /// Defaults to 0, which applies no spacing.
  final double spacing;

  /// The orientation in which the menu items are displayed.
  final Axis orientation;

  /// The [ui.Clip] applied to the panel's scrollable.
  final ui.Clip clipBehavior;

  /// Called when a pointer enters the menu surface without hitting any of the
  /// menu items.
  ///
  /// This callback is intended to be used to focus the menu anchor button when
  /// the pointer enters the menu surface, which is a common behavior in desktop
  /// menus.
  final PointerEnterEventListener? onEnter;

  /// Called when a pointer leaves the menu surface after entering.
  final PointerExitEventListener? onExit;

  /// Called when a pointer moves within the menu surface after entering.
  final PointerHoverEventListener? onHover;

  /// The mouse cursor to use when a pointer is hovering over the menu surface.
  final MouseCursor? cursor;

  /// Whether the menu panel should be scrollable when its contents exceed the available space within the overlay.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    Widget child = Flex(
      direction: orientation,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      spacing: spacing,
      children: children,
    );

    final bool applyMouseRegion =
        onEnter != null || onExit != null || onHover != null || cursor != null;

    if (applyMouseRegion) {
      child = _BaseMenuPanelMouseRegion(
        onEnter: onEnter,
        onExit: onExit,
        cursor: cursor ?? MouseCursor.defer,
        onHover: onHover,
        child: child,
      );
    }

    if (scrollable) {
      child = SingleChildScrollView(
        scrollDirection: orientation,
        clipBehavior: .none,
        padding: padding,
        child: child,
      );
    } else if (padding != EdgeInsets.zero) {
      child = Padding(padding: padding, child: child);
    }

    if (clipBehavior != ui.Clip.none) {
      child = ClipRect(clipBehavior: clipBehavior, child: child);
    }

    var applyIntrinsics = true;
    if (constraints != null) {
      child = ConstrainedBox(constraints: constraints!, child: child);
      applyIntrinsics = switch (orientation) {
        Axis.vertical => !constraints!.hasTightWidth,
        Axis.horizontal => !constraints!.hasTightHeight,
      };
    }

    if (applyMouseRegion) {
      child = _BaseMenuPanelMouseRegion(
        onEnter: onEnter,
        onExit: onExit,
        cursor: cursor ?? MouseCursor.defer,
        onHover: onHover,
        child: child,
      );
    }

    if (applyIntrinsics) {
      child = switch (orientation) {
        Axis.vertical => IntrinsicWidth(child: child),
        Axis.horizontal => IntrinsicHeight(child: child),
      };
    }

    if (constrainCrossAxis) {
      return child;
    }

    return UnconstrainedBox(
      clipBehavior: Clip.hardEdge,
      alignment: AlignmentDirectional.centerStart,
      constrainedAxis: orientation,
      child: child,
    );
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[for (final Widget child in children) child.toDiagnosticsNode()];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('constrainCrossAxis', constrainCrossAxis));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding override', padding));
    properties.add(DoubleProperty('spacing', spacing, defaultValue: 0));
    properties.add(EnumProperty<Axis>('direction', orientation));
    properties.add(EnumProperty<ui.Clip>('clipBehavior', clipBehavior, defaultValue: ui.Clip.none));
  }
}

/// A delegate responsible for building a widget that positions a [BaseMenu]'s
/// menu panel.
@immutable
abstract class BaseMenuPositioningDelegate {
  /// Creates a [BaseMenuPositioningDelegate].
  const BaseMenuPositioningDelegate();

  /// Builds a widget that positions the menu panel [child] using the provided
  /// [RawMenuOverlayInfo] coordinate information.
  Widget build(BuildContext context, RawMenuOverlayInfo position, Widget child);
}

@immutable
class EdgeResolutionStrategy {
  const EdgeResolutionStrategy({this.shift = false, this.flip = false, this.constrain = false});

  /// The menu will be shifted to stay within the screen boundaries,
  /// potentially covering the anchor.
  final bool shift;

  /// The menu will be flipped across the anchor point if it overflows.
  final bool flip;

  /// The menu will be resized to fit within the available space between the
  /// anchor and the screen edge. Ideal for scrollable menus.
  ///
  /// Note that, due to Flutter performing a single-pass layout system enabling
  /// [constrain] without [shift]
  final bool constrain;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is EdgeResolutionStrategy &&
        other.shift == shift &&
        other.flip == flip &&
        other.constrain == constrain;
  }

  @override
  int get hashCode => shift.hashCode ^ flip.hashCode ^ constrain.hashCode;
}

@immutable
class EdgeBehavior {
  const EdgeBehavior({required this.horizontal, required this.vertical});

  final EdgeResolutionStrategy horizontal;
  final EdgeResolutionStrategy vertical;

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
/// [anchorAlignment], [menuAlignment], and [offset]. If the menu overflows
/// the edge of the screen, it will be flipped across the anchor's midpoint on
/// the axis of overflow if that edge is included in [flipEdges].
///
/// The [padding] is applied to the menu surface but ignored during menu
/// positioning, which is useful for ensuring a submenu's items align with their
/// parent menu's items when the submenu applies padding to its surface.
class DefaultBaseMenuPositioningDelegate extends BaseMenuPositioningDelegate {
  const DefaultBaseMenuPositioningDelegate({
    this.anchorAlignment,
    this.offset = ui.Offset.zero,
    this.useDirectionalOffset = true,
    this.menuAlignment,
    this.padding = EdgeInsets.zero,
    this.overlayPadding = const EdgeInsets.all(8),
    this.edgeBehavior = const EdgeBehavior(
      horizontal: EdgeResolutionStrategy(flip: true, shift: true, constrain: true),
      vertical: EdgeResolutionStrategy(flip: true, shift: true, constrain: true),
    ),
  });

  /// The point on the menu surface that attaches to the anchor.
  ///
  /// Unlike [anchorAlignment] and [offset], the [menuAlignment] will be
  /// applied when the menu is opened with a `position` argument.
  ///
  /// Defaults to [AlignmentDirectional.topEnd] if this menu's parent has a
  /// [Axis.vertical] orientation, and [AlignmentDirectional.bottomStart]
  /// otherwise.
  final AlignmentGeometry? menuAlignment;

  /// The point on the anchor surface that attaches to the menu.
  ///
  /// The [anchorAlignment] is ignored if a `position` argument is provided to
  /// [MenuController.open].
  ///
  /// If the menu overflows an edge of the screen included in [flipEdges], the
  /// menu will be flipped across the anchor's midpoint on the axis of overflow.
  /// For example, if the menu on the right side of the anchor overflows the
  /// right edge of the screen, the menu will be flipped to the left side of the
  /// anchor.
  ///
  /// Defaults to [AlignmentDirectional.bottomStart] if this is a root menu, and
  /// [AlignmentDirectional.topEnd] if this is a submenu.
  final AlignmentGeometry? anchorAlignment;

  /// The offset applied to the menu relative to the anchor attachment point.
  ///
  /// If [useDirectionalOffset] is true (the default), the horizontal component
  /// of the offset is applied in the reading direction of the ambient
  /// [Directionality]. Otherwise, the offset is applied as-is, regardless of
  /// the ambient [Directionality].
  ///
  /// The [anchorAlignment] and [offset] are ignored if a `position` argument is
  /// provided to [MenuController.open].
  ///
  /// Defaults to [Offset.zero].
  final Offset offset;

  /// Whether the [offset] is directional, meaning its horizontal component is
  /// applied in the reading direction of the ambient [Directionality].
  final bool useDirectionalOffset;

  /// The behavior to apply when the menu overflows the edge of the screen.
  final EdgeBehavior edgeBehavior;

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
  final EdgeInsetsGeometry overlayPadding;

  @override
  Widget build(BuildContext context, RawMenuOverlayInfo position, Widget child) {
    final displayFeatures = MediaQuery.maybeDisplayFeaturesOf(context);
    final TextDirection textDirection = Directionality.of(context);
    final resolvedAnchorAlignment =
        anchorAlignment ??
        // Only resolve the default alignment
        (switch (MenuScope.maybeOf(context)?.orientation) {
          Axis.vertical => AlignmentDirectional.topEnd,
          _ => AlignmentDirectional.bottomStart,
        }).resolve(textDirection);
    final resolvedOffset = useDirectionalOffset && textDirection == TextDirection.rtl
        ? Offset(-offset.dx, offset.dy)
        : offset;

    // final delegate = DefaultMenuLayoutDelegate(
    //   overlayPadding: overlayPadding.resolve(textDirection),
    //   padding: padding,
    //   avoidBounds: displayFeatures != null ? _avoidBounds(displayFeatures) : const {},
    //   textDirection: textDirection,
    //   anchorRect: position.anchorRect,
    //   offset: resolvedOffset,
    //   menuPosition: position.position,
    //   menuAlignment: menuAlignment ?? AlignmentDirectional.topStart,
    //   alignment: resolvedAnchorAlignment,
    //   edgeBehavior: edgeBehavior,
    // );

    if (!MenuAimScope.isEnabledOf(context) || MenuScope.maybeOf(context)?.isSubmenu != true) {
      return MenuTwoPassLayoutWidget(
        overlayPadding: overlayPadding.resolve(textDirection),
        padding: padding,
        avoidBounds: displayFeatures != null ? _avoidBounds(displayFeatures) : const {},
        textDirection: textDirection,
        anchorRect: position.anchorRect,
        offset: resolvedOffset,
        menuPosition: position.position,
        menuAlignment: menuAlignment ?? AlignmentDirectional.topStart,
        alignment: resolvedAnchorAlignment,
        edgeBehavior: edgeBehavior,
        child: child,
      );
    } else {
      final geometry = MenuAimGeometry()..anchorRect = position.anchorRect;
      return Stack(
        textDirection: .ltr,
        children: [
          // CustomSingleChildLayout(
          //   delegate: _MenuAimLayoutDecorator(delegate: delegate, geometry: geometry),
          //   child: child,
          // ),
          MenuTwoPassLayoutWidget(
            overlayPadding: overlayPadding.resolve(textDirection),
            padding: padding,
            avoidBounds: displayFeatures != null ? _avoidBounds(displayFeatures) : const {},
            textDirection: textDirection,
            anchorRect: position.anchorRect,
            offset: resolvedOffset,
            menuPosition: position.position,
            menuAlignment: menuAlignment ?? AlignmentDirectional.topStart,
            alignment: resolvedAnchorAlignment,
            edgeBehavior: edgeBehavior,
            child: child,
          ),
          MenuAimInterceptor(geometry: geometry),
        ],
      );
    }
  }

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
}

/// A widget that displays a popup menu positioned relative to its [child].
class BaseMenu extends StatefulWidget with BaseMenuInterface {
  const BaseMenu({
    super.key,
    this.onOpen,
    this.onClose,
    this.onOpenRequest = BaseMenuInterface.defaultOnOpenRequested,
    this.onCloseRequest = BaseMenuInterface.defaultOnCloseRequested,
    this.useRootOverlay = false,
    this.controller,
    this.consumeOutsideTaps = false,
    this.onFocusChange,
    this.directionalFocusEdgeBehavior,
    this.semanticProperties = const SemanticsProperties(
      scopesRoute: true,
      role: SemanticsRole.menu,
    ),
    this.orientation = Axis.vertical,
    required this.menu,
    this.positionDelegate = const DefaultBaseMenuPositioningDelegate(),
    this.builder,
    this.overlayChildBuilder,
    this.child,
  });

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

  /// The widget that this [BaseMenu] surrounds.
  ///
  /// Typically, this is a button used to open the menu by calling
  /// [MenuController.open] on the `controller` passed to the builder.
  ///
  /// If not supplied, then the [BaseMenu] will be the size that its parent
  /// allocates for it.
  final RawMenuAnchorChildBuilder? builder;

  @override
  final Widget? child;

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

  static const debugMenuFocusScopeLabel = 'BaseMenu FocusScope';

  TraversalEdgeBehavior get effectiveTraversalEdgeBehavior {
    if (directionalFocusEdgeBehavior != null) {
      return directionalFocusEdgeBehavior!;
    }

    if (kIsWeb) {
      return .closedLoop;
    }

    return switch (defaultTargetPlatform) {
      .android || .fuchsia || .linux || .windows => .closedLoop,
      .iOS || .macOS => .stop,
    };
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
    directionalTraversalEdgeBehavior: widget.effectiveTraversalEdgeBehavior,
    debugLabel: BaseMenu.debugMenuFocusScopeLabel + (widget.key != null ? ' (${widget.key})' : ''),
  );

  late final Map<Type, Action<Intent>> _anchorActions = <Type, Action<Intent>>{
    BaseMenuEnterIntent: CallbackAction<BaseMenuEnterIntent>(onInvoke: _handleEnterMenu),
  };

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
    final scope = MenuScope.maybeOf(context);
    if (scope?.orientation != _parentOrientation || scope?.isSubmenu != _parentIsSubmenu) {
      _parentOrientation = scope?.orientation;
      _parentIsSubmenu = scope?.isSubmenu ?? false;
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
    if (oldWidget.directionalFocusEdgeBehavior != widget.directionalFocusEdgeBehavior) {
      _menuScopeNode.traversalEdgeBehavior = widget.effectiveTraversalEdgeBehavior;
      _menuScopeNode.directionalTraversalEdgeBehavior = widget.effectiveTraversalEdgeBehavior;
    }

    if (oldWidget.key != widget.key) {
      _menuScopeNode.debugLabel =
          BaseMenu.debugMenuFocusScopeLabel + (widget.key != null ? ' (${widget.key})' : '');
    }
  }

  @override
  void dispose() {
    _internalMenuController = null;
    _menuScopeNode.dispose();
    super.dispose();
  }

  void _handleEnterMenu(BaseMenuEnterIntent intent) {
    if (_menuController.isOpen) {
      if (_menuScopeNode.context != null && intent._scopeIntent != null) {
        Actions.maybeInvoke(_menuScopeNode.context!, intent._scopeIntent);
      }
    } else {
      _menuController.open();
      if (intent._scopeIntent != null) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted && _menuController.isOpen) {
            Actions.invoke(_menuScopeNode.context!, intent._scopeIntent);
          }
        });
      }
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
              const SingleActivator(LogicalKeyboardKey.arrowUp):
                  const BaseMenuEnterIntent.focusLast(),
              const SingleActivator(LogicalKeyboardKey.arrowDown):
                  const BaseMenuEnterIntent.focusFirst(),
            },
          },
          Axis.horizontal || null => {
            ...directionalShortcuts,
            const SingleActivator(LogicalKeyboardKey.arrowDown):
                const BaseMenuEnterIntent.focusFirst(),
            if (!_parentIsSubmenu || widget.orientation == Axis.vertical)
              const SingleActivator(LogicalKeyboardKey.arrowUp):
                  const BaseMenuEnterIntent.focusLast(),
          },
        },
        child:
            widget.builder?.call(context, controller, widget.child) ??
            widget.child ??
            const SizedBox(),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context, RawMenuOverlayInfo position) {
    final overlay = _MenuOverlay(
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
        NextFocusIntent: CallbackAction(
          onInvoke: (intent) {
            _menuController.close();
            return _menuScopeNode.enclosingScope?.nextFocus();
          },
        ),
        PreviousFocusIntent: CallbackAction(
          onInvoke: (intent) {
            _menuController.close();
            return _menuScopeNode.enclosingScope?.previousFocus();
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
  });

  final RawMenuOverlayInfo position;
  final Widget child;
  final bool consumeOutsideTaps;
  final MenuController menuController;
  final FocusScopeNode focusScopeNode;
  final Axis submenuAxis;
  final SemanticsProperties semanticProperties;
  final BaseMenuPositioningDelegate positioningDelegate;

  Widget _buildConditionalTraversal(BuildContext context, Widget? child) {
    return Focus(
      includeSemantics: false,
      canRequestFocus: false,
      skipTraversal: !focusScopeNode.hasFocus,
      descendantsAreTraversable: true,
      descendantsAreFocusable: true,
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
          child: MenuScope(orientation: submenuAxis, isSubmenu: true, child: child),
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

class BaseMenuBar extends StatefulWidget {
  const BaseMenuBar({
    super.key,
    this.controller,
    required this.child,
    this.axis = Axis.horizontal,
    this.focusScopeNode,
    this.semanticProperties = const SemanticsProperties(
      scopesRoute: true,
      role: SemanticsRole.menuBar,
    ),
  });
  final MenuController? controller;
  final Widget child;
  final Axis axis;
  final FocusScopeNode? focusScopeNode;
  final SemanticsProperties semanticProperties;

  @override
  State<BaseMenuBar> createState() => _BaseMenuBarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<MenuController>.has('controller', controller));
    properties.add(EnumProperty<Axis>('axis', axis));
    properties.add(ObjectFlagProperty<FocusScopeNode>.has('focusScopeNode', focusScopeNode));
  }
}

class _BaseMenuBarState extends State<BaseMenuBar> {
  late final _actions = {
    NextFocusIntent: CallbackAction(
      onInvoke: (intent) {
        return _menuScopeNode.enclosingScope?.nextFocus();
      },
    ),
    PreviousFocusIntent: CallbackAction(
      onInvoke: (intent) {
        return _menuScopeNode.enclosingScope?.previousFocus();
      },
    ),
  };

  MenuController? _internalMenuController;
  MenuController get _menuController => widget.controller ?? _internalMenuController!;

  FocusScopeNode? _internalFocusScopeNode;
  FocusScopeNode get _menuScopeNode => widget.focusScopeNode ?? _internalFocusScopeNode!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalMenuController = MenuController();
    }

    if (widget.focusScopeNode == null) {
      _internalFocusScopeNode = FocusScopeNode(
        debugLabel: 'BaseMenuBar.focusScopeNode ${widget.axis}',
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
      } else {
        _internalMenuController = null;
      }
    }

    if (oldWidget.focusScopeNode != widget.focusScopeNode) {
      if (widget.focusScopeNode == null) {
        _internalFocusScopeNode = FocusScopeNode(
          debugLabel: 'BaseMenuBar.focusScopeNode ${widget.axis}',
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
      axis: widget.axis,
      semanticProperties: widget.semanticProperties,
      focusScopeNode: _menuScopeNode,
      child: MenuScope(orientation: widget.axis, isSubmenu: false, child: widget.child),
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
              BaseMenuVerticalFocusNextIntent: _TraverseNextAction<BaseMenuVerticalFocusNextIntent>(
                widget.focusScopeNode,
              ),
              BaseMenuVerticalFocusPreviousIntent:
                  _TraversePreviousAction<BaseMenuVerticalFocusPreviousIntent>(
                    widget.focusScopeNode,
                  ),
            },
            Axis.horizontal => {
              BaseMenuHorizontalFocusNextIntent:
                  _TraverseNextAction<BaseMenuHorizontalFocusNextIntent>(widget.focusScopeNode),
              BaseMenuHorizontalFocusPreviousIntent:
                  _TraversePreviousAction<BaseMenuHorizontalFocusPreviousIntent>(
                    widget.focusScopeNode,
                  ),
            },
          },
        },
        child: Shortcuts(
          debugLabel: 'Menu Focus Traversal Shortcuts ${widget.child}',
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
    final isFocusRequested = focusScopeNode.previousFocus();
    if (isFocusRequested) {
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

// A layout delegate that positions the menu relative to its anchor.
class DefaultMenuLayoutDelegate extends SingleChildLayoutDelegate {
  const DefaultMenuLayoutDelegate({
    required this.offset,
    required this.anchorRect,
    required this.overlayPadding,
    required this.avoidBounds,
    required this.alignment,
    required this.menuAlignment,
    required this.textDirection,
    required EdgeInsetsGeometry? padding,
    required this.edgeBehavior,
    this.menuPosition,
  }) : menuPadding = padding;

  // Rectangle of the button anchoring the menu overlay.
  final ui.Rect anchorRect;

  // The offset applied to the menu position after aligning the menu and anchor
  // based on [alignment] and [menuAlignment].
  final ui.Offset offset;

  // The offset of the menu relative to the top-left corner of the anchor.
  final ui.Offset? menuPosition;

  // The padding obtained from calling [MediaQuery.paddingOf].
  //
  // Used to prevent the menu from being obstructed by system UI.
  final EdgeInsetsGeometry overlayPadding;

  // Padding applied to the menu surface.
  final EdgeInsetsGeometry? menuPadding;

  // List of rectangles that the menu should not overlap. Unusable screen area.
  final Set<Rect> avoidBounds;

  // The alignment of the menu attachment point relative to the anchor button.
  final AlignmentGeometry alignment;

  // The alignment of the menu attachment point relative to the menu surface.
  final AlignmentGeometry menuAlignment;

  // The direction in which the text flows within the menu.
  final ui.TextDirection textDirection;

  // The axis or axes on which the menu should be flipped across the anchor's
  // midpoint if it overflows the edge of the screen.
  final EdgeBehavior edgeBehavior;

  // Finds the closest screen to the anchor position.
  //
  // The closest screen is defined as the screen whose center is closest to the
  // anchor position.
  // Finds the closest screen to the anchor point.
  //
  // This algorithm is different than the algorithms for PopupMenuButton and MenuAnchor,
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

  Offset _fitInsideScreen(Rect screen, Size childSize, Offset position, Offset anchorPosition) {
    final EdgeInsets? padding = menuPadding?.resolve(textDirection);
    final EdgeInsets overlayInsets = overlayPadding.resolve(textDirection);
    final Rect anchor = menuPosition == null ? anchorRect : anchorPosition & Size.zero;

    double x = position.dx;
    double y = position.dy;

    bool overLeftEdge(double x) => x < screen.left + overlayInsets.left;
    bool overRightEdge(double x) => x > screen.right - childSize.width - overlayInsets.right;
    bool overTopEdge(double y) => y < screen.top + overlayInsets.top;
    bool overBottomEdge(double y) => y > screen.bottom - childSize.height - overlayInsets.bottom;
    // If the menu is wider than the screen, shift if allowed.
    if ((edgeBehavior.horizontal.shift || edgeBehavior.horizontal.constrain) &&
        childSize.width >= screen.width - overlayInsets.horizontal) {
      x = switch (textDirection) {
        .ltr => screen.left + overlayInsets.left,
        .rtl => screen.right - childSize.width - overlayInsets.right,
      };
    } else {
      // Adjust for padding applied to the menu panel
      double? shiftX;
      if (padding != null && padding.horizontal > 0) {
        double ratio = (x - anchorPosition.dx) / childSize.width;
        ratio = ui.clampDouble(ratio, -1, 0);
        shiftX = padding.right * ratio + padding.left * (ratio + 1);
        x -= shiftX;
      }

      if (overLeftEdge(x)) {
        if (edgeBehavior.horizontal.flip) {
          double flipX = anchor.center.dx * 2 - position.dx - childSize.width;
          if (shiftX != null) {
            flipX -= padding!.horizontal + shiftX;
          }

          if (overRightEdge(flipX) || overLeftEdge(flipX)) {
            final double availableLeft = anchor.left - screen.left - overlayInsets.left;
            final double availableRight = screen.right - anchor.right - overlayInsets.right;
            x = availableLeft > availableRight ? x : flipX;
            if (edgeBehavior.horizontal.shift) {
              x = ui.clampDouble(
                x,
                screen.left + overlayInsets.left,
                screen.right - childSize.width - overlayInsets.right,
              );
            }
          } else {
            x = flipX;
          }
        } else if (edgeBehavior.horizontal.shift || edgeBehavior.horizontal.constrain) {
          x = screen.left + overlayInsets.left;
        }
      } else if (overRightEdge(x)) {
        if (edgeBehavior.horizontal.flip) {
          double flipX = anchor.center.dx * 2 - position.dx - childSize.width;
          if (shiftX != null) {
            flipX += padding!.horizontal - shiftX;
          }

          if (overLeftEdge(flipX) || overRightEdge(flipX)) {
            final double availableLeft = anchor.left - screen.left - overlayInsets.left;
            final double availableRight = screen.right - anchor.right - overlayInsets.right;
            x = availableLeft < availableRight ? x : flipX;
            if (edgeBehavior.horizontal.shift) {
              x = ui.clampDouble(
                x,
                screen.left + overlayInsets.left,
                screen.right - childSize.width - overlayInsets.right,
              );
            }
          } else {
            x = flipX;
          }
        } else if (edgeBehavior.horizontal.shift || edgeBehavior.horizontal.constrain) {
          x = screen.right - childSize.width - overlayInsets.right;
        }
      }
    }

    if (edgeBehavior.vertical.shift || edgeBehavior.vertical.constrain) {
      if (childSize.height >= screen.height - overlayInsets.vertical) {
        return Offset(x, screen.top + overlayInsets.top);
      }
    }

    double? shiftY;
    if (padding != null && padding.vertical > 0) {
      double ratio = (y - anchorPosition.dy) / childSize.height;
      ratio = ui.clampDouble(ratio, -1, 0);
      shiftY = padding.bottom * ratio + padding.top * (ratio + 1);
      y -= shiftY;
    }

    if (overTopEdge(y)) {
      if (edgeBehavior.vertical.flip) {
        double flipY = anchor.center.dy * 2 - position.dy - childSize.height;
        if (shiftY != null) {
          flipY -= padding!.vertical + shiftY;
        }
        if (overTopEdge(flipY) || overBottomEdge(flipY)) {
          final double availableTop = anchor.top - screen.top - overlayInsets.top;
          final double availableBottom = screen.bottom - anchor.bottom - overlayInsets.bottom;
          // If the flipped position also overflows, choose the side with the
          // most space available and shift if allowed.
          y = availableBottom > availableTop ? flipY : y;
          if (edgeBehavior.vertical.shift) {
            y = ui.clampDouble(
              y,
              screen.top + overlayInsets.top,
              screen.bottom - childSize.height - overlayInsets.bottom,
            );
          }
        } else {
          y = flipY;
        }
      } else if (edgeBehavior.vertical.shift || edgeBehavior.vertical.constrain) {
        y = screen.top + overlayInsets.top;
      }
    } else if (overBottomEdge(y)) {
      if (edgeBehavior.vertical.flip) {
        double flipY = anchor.center.dy * 2 - position.dy - childSize.height;
        if (shiftY != null) {
          flipY += padding!.vertical - shiftY;
        }

        if (overTopEdge(flipY) || overBottomEdge(flipY)) {
          final double availableTop = anchor.top - screen.top - overlayInsets.top;
          final double availableBottom = screen.bottom - anchor.bottom - overlayInsets.bottom;
          // If the flipped position also overflows, choose the side with the
          // most space available and shift if allowed.
          y = availableBottom < availableTop ? flipY : y;
          if (edgeBehavior.vertical.shift) {
            y = ui.clampDouble(
              y,
              screen.top + overlayInsets.top,
              screen.bottom - childSize.height - overlayInsets.bottom,
            );
          }
        } else {
          y = flipY;
        }
      } else if (edgeBehavior.vertical.shift || edgeBehavior.vertical.constrain) {
        y = screen.bottom - childSize.height - overlayInsets.bottom;
      }
    }

    return Offset(x, y);
  }

  static double computeMaxDimension(
    double leading,
    double trailing,
    double leadingRatio,
    double trailingRatio,
    double axisSize,
  ) {
    final double limitBefore = leadingRatio > 0 ? leading / leadingRatio : double.infinity;
    final double limitAfter = trailingRatio > 0 ? trailing / trailingRatio : double.infinity;

    if ((limitBefore + limitAfter) * 0.5 <= axisSize) {
      return axisSize;
    }

    return math.min(limitBefore, limitAfter);
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final Size parentSize = constraints.biggest;
    Offset anchorOffset;
    if (menuPosition == null) {
      anchorOffset = alignment.resolve(textDirection).withinRect(anchorRect);
      anchorOffset += offset;
    } else {
      anchorOffset = anchorRect.topLeft + menuPosition!;
    }

    final Rect screen = _findClosestScreen(parentSize, anchorRect.center, avoidBounds);
    final EdgeInsets overlayInsets = overlayPadding.resolve(textDirection);
    const childConstraints = BoxConstraints();

    double maxWidth = childConstraints.maxWidth;
    if (edgeBehavior.horizontal.constrain) {
      if (edgeBehavior.horizontal.shift) {
        maxWidth = screen.width - overlayInsets.horizontal;
      } else {
        // This block handles the case where the menu is constrained to the
        // space between the anchor and the screen edge, but is not allowed to
        // shift. The menu must be constrained relative to the point on the
        // anchor where it is attached, which is determined by the
        // menuAlignment.
        //
        // If the menu is flippable, the flipped position must also be
        // considered. The maximum width is the largest width that can be used
        // without overflowing the screen in either position.
        //
        // The menu will shift if the average of the left and right fractions of
        // the anchor, when pinned, exceeds the available axis space. This
        // prevents the menu width from dramatically shrinking when the anchor
        // is near the edge of the screen.
        final resolvedMenuAlignment = menuAlignment.resolve(textDirection);
        final xRatioLeading = resolvedMenuAlignment.x * 0.5 + 0.5;
        final xRatioTrailing = 1 - xRatioLeading;
        final double left = anchorOffset.dx - screen.left - overlayInsets.left;
        final double right = screen.right - anchorOffset.dx - overlayInsets.right;
        maxWidth = computeMaxDimension(
          left,
          right,
          xRatioLeading,
          xRatioTrailing,
          screen.width - overlayInsets.horizontal,
        );

        if (edgeBehavior.horizontal.flip) {
          final Offset anchorMidpoint = menuPosition == null ? anchorRect.center : anchorOffset;
          final double flippedAnchorX = anchorMidpoint.dx * 2 - anchorOffset.dx;
          final double flippedLeft = flippedAnchorX - screen.left - overlayInsets.left;
          final double flippedRight = screen.right - flippedAnchorX - overlayInsets.right;
          final double flippedWidth = computeMaxDimension(
            flippedRight,
            flippedLeft,
            xRatioLeading,
            xRatioTrailing,
            screen.width - overlayInsets.horizontal,
          );

          maxWidth = math.max(maxWidth, flippedWidth);
        }
      }
    }

    double maxHeight = childConstraints.maxHeight;
    if (edgeBehavior.vertical.constrain) {
      if (edgeBehavior.vertical.shift) {
        maxHeight = screen.height - overlayInsets.vertical;
      } else {
        final resolvedMenuAlignment = menuAlignment.resolve(textDirection);
        final yRatioLeading = resolvedMenuAlignment.y * 0.5 + 0.5;
        final yRatioTrailing = 1 - yRatioLeading;
        final double top = anchorOffset.dy - screen.top - overlayInsets.top;
        final double bottom = screen.bottom - anchorOffset.dy - overlayInsets.bottom;
        maxHeight = computeMaxDimension(
          top,
          bottom,
          yRatioLeading,
          yRatioTrailing,
          screen.height - overlayInsets.vertical,
        );
        if (edgeBehavior.vertical.flip) {
          final Offset anchorMidpoint = menuPosition == null ? anchorRect.center : anchorOffset;
          final double flippedAnchorY = anchorMidpoint.dy * 2 - anchorOffset.dy;
          final double flippedTop = flippedAnchorY - screen.top - overlayInsets.top;
          final double flippedBottom = screen.bottom - flippedAnchorY - overlayInsets.bottom;
          final double flippedHeight = computeMaxDimension(
            flippedBottom,
            flippedTop,
            yRatioLeading,
            yRatioTrailing,
            screen.height - overlayInsets.vertical,
          );
          maxHeight = math.max(maxHeight, flippedHeight);
        }
      }
    }

    return childConstraints.copyWith(
      maxWidth: ui.clampDouble(maxWidth, 0, childConstraints.maxWidth),
      maxHeight: ui.clampDouble(maxHeight, 0, childConstraints.maxHeight),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // Point on the anchor where the menu is attached.
    Offset anchorOffset;
    if (menuPosition == null) {
      anchorOffset = alignment.resolve(textDirection).withinRect(anchorRect);
      anchorOffset += offset;
    } else {
      anchorOffset = anchorRect.topLeft + menuPosition!;
    }

    final ui.Offset position =
        anchorOffset - menuAlignment.resolve(textDirection).alongSize(childSize);

    final Rect screen = _findClosestScreen(size, anchorRect.center, avoidBounds);
    return _fitInsideScreen(screen, childSize, position, anchorOffset);
  }

  @override
  bool shouldRelayout(DefaultMenuLayoutDelegate oldDelegate) {
    return anchorRect != oldDelegate.anchorRect ||
        alignment != oldDelegate.alignment ||
        offset != oldDelegate.offset ||
        menuAlignment != oldDelegate.menuAlignment ||
        menuPosition != oldDelegate.menuPosition ||
        menuPadding != oldDelegate.menuPadding ||
        overlayPadding != oldDelegate.overlayPadding ||
        textDirection != oldDelegate.textDirection ||
        edgeBehavior != oldDelegate.edgeBehavior ||
        !setEquals(avoidBounds, oldDelegate.avoidBounds);
  }
}

class _MenuAimLayoutDecorator<T extends SingleChildLayoutDelegate>
    extends SingleChildLayoutDelegate {
  const _MenuAimLayoutDecorator({required this.delegate, required this.geometry});

  final T delegate;
  final MenuAimGeometry geometry;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return delegate.getConstraintsForChild(constraints);
  }

  @override
  ui.Offset getPositionForChild(Size size, Size childSize) {
    final position = delegate.getPositionForChild(size, childSize);
    geometry.targetRect = position & childSize;
    return position;
  }

  @override
  Size getSize(BoxConstraints constraints) {
    return delegate.getSize(constraints);
  }

  @override
  bool shouldRelayout(covariant _MenuAimLayoutDecorator<T> oldDelegate) {
    return geometry != oldDelegate.geometry || delegate.shouldRelayout(oldDelegate.delegate);
  }
}

class MenuTwoPassLayoutWidget extends SingleChildRenderObjectWidget {
  const MenuTwoPassLayoutWidget({
    super.key,
    required super.child,
    required this.offset,
    required this.anchorRect,
    required this.overlayPadding,
    required this.avoidBounds,
    required this.alignment,
    required this.menuAlignment,
    required this.textDirection,
    required EdgeInsetsGeometry? padding,
    required this.edgeBehavior,
    this.menuPosition,
  }) : menuPadding = padding;

  // Rectangle of the button anchoring the menu overlay.
  final ui.Rect anchorRect;

  // The offset applied to the menu position after aligning the menu and anchor
  // based on [alignment] and [menuAlignment].
  final ui.Offset offset;

  // The offset of the menu relative to the top-left corner of the anchor.
  final ui.Offset? menuPosition;

  // The padding obtained from calling [MediaQuery.paddingOf].
  //
  // Used to prevent the menu from being obstructed by system UI.
  final EdgeInsetsGeometry overlayPadding;

  // Padding applied to the menu surface.
  final EdgeInsetsGeometry? menuPadding;

  // List of rectangles that the menu should not overlap. Unusable screen area.
  final Set<Rect> avoidBounds;

  // The alignment of the menu attachment point relative to the anchor button.
  final AlignmentGeometry alignment;

  // The alignment of the menu attachment point relative to the menu surface.
  final AlignmentGeometry menuAlignment;

  // The direction in which the text flows within the menu.
  final ui.TextDirection textDirection;

  // The axis or axes on which the menu should be flipped across the anchor's
  // midpoint if it overflows the edge of the screen.
  final EdgeBehavior edgeBehavior;

  @override
  RenderMenuTwoPassLayout createRenderObject(BuildContext context) {
    return RenderMenuTwoPassLayout(
      anchorRect: anchorRect,
      offset: offset,
      menuPosition: menuPosition,
      overlayPadding: overlayPadding,
      avoidBounds: avoidBounds,
      alignment: alignment,
      menuAlignment: menuAlignment,
      textDirection: textDirection,
      menuPadding: menuPadding,
      edgeBehavior: edgeBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderMenuTwoPassLayout renderObject) {
    renderObject
      ..anchorRect = anchorRect
      ..offset = offset
      ..menuPosition = menuPosition
      ..overlayPadding = overlayPadding
      ..avoidBounds = avoidBounds
      ..alignment = alignment
      ..menuAlignment = menuAlignment
      ..textDirection = textDirection
      ..menuPadding = menuPadding
      ..edgeBehavior = edgeBehavior;
  }
}

class RenderMenuTwoPassLayout extends RenderShiftedBox {
  RenderMenuTwoPassLayout({
    RenderBox? child,
    required this._anchorRect,
    required this._offset,
    required this._menuPosition,
    required this._overlayPadding,
    required this._avoidBounds,
    required this._alignment,
    required this._menuAlignment,
    required this._textDirection,
    required this._menuPadding,
    required this._edgeBehavior,
  }) : super(child);

  // Property Boilerplate
  Rect _anchorRect;
  Rect get anchorRect => _anchorRect;
  set anchorRect(Rect value) {
    if (_anchorRect == value) {
      return;
    }
    _anchorRect = value;
    markNeedsLayout();
  }

  Offset _offset;
  Offset get offset => _offset;
  set offset(Offset value) {
    if (_offset == value) {
      return;
    }
    _offset = value;
    markNeedsLayout();
  }

  Offset? _menuPosition;
  Offset? get menuPosition => _menuPosition;
  set menuPosition(Offset? value) {
    if (_menuPosition == value) {
      return;
    }
    _menuPosition = value;
    markNeedsLayout();
  }

  EdgeInsetsGeometry _overlayPadding;
  EdgeInsetsGeometry get overlayPadding => _overlayPadding;
  set overlayPadding(EdgeInsetsGeometry value) {
    if (_overlayPadding == value) {
      return;
    }
    _overlayPadding = value;
    _resolvedOverlayPadding = null;
    markNeedsLayout();
  }

  Set<Rect> _avoidBounds;
  Set<Rect> get avoidBounds => _avoidBounds;
  set avoidBounds(Set<Rect> value) {
    if (_avoidBounds == value) {
      return;
    }
    _avoidBounds = value;
    markNeedsLayout();
  }

  AlignmentGeometry _alignment;
  AlignmentGeometry get alignment => _alignment;
  set alignment(AlignmentGeometry value) {
    if (_alignment == value) {
      return;
    }
    _alignment = value;
    _resolvedAlignment = null;
    markNeedsLayout();
  }

  AlignmentGeometry _menuAlignment;
  AlignmentGeometry get menuAlignment => _menuAlignment;
  set menuAlignment(AlignmentGeometry value) {
    if (_menuAlignment == value) {
      return;
    }
    _menuAlignment = value;
    _resolvedMenuAlignment = null;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    _resolvedAlignment = _resolvedMenuAlignment = _resolvedMenuPadding = _resolvedOverlayPadding =
        null;
    markNeedsLayout();
  }

  EdgeInsetsGeometry? _menuPadding;
  EdgeInsetsGeometry? get menuPadding => _menuPadding;
  set menuPadding(EdgeInsetsGeometry? value) {
    if (_menuPadding == value) {
      return;
    }
    _menuPadding = value;
    _resolvedMenuPadding = null;
    markNeedsLayout();
  }

  EdgeBehavior _edgeBehavior;
  EdgeBehavior get edgeBehavior => _edgeBehavior;
  set edgeBehavior(EdgeBehavior v) {
    if (_edgeBehavior == v) {
      return;
    }
    _edgeBehavior = v;
    markNeedsLayout();
  }

  Alignment? _resolvedAlignment;
  Alignment? _resolvedMenuAlignment;
  EdgeInsets? _resolvedMenuPadding;
  EdgeInsets? _resolvedOverlayPadding;

  @override
  void performLayout() {
    if (child == null) {
      size = constraints.smallest;
      return;
    }

    _resolvedAlignment ??= alignment.resolve(textDirection);
    _resolvedMenuAlignment ??= menuAlignment.resolve(textDirection);
    _resolvedMenuPadding ??= menuPadding?.resolve(textDirection);
    _resolvedOverlayPadding ??= overlayPadding.resolve(textDirection);
    final parentSize = constraints.biggest;
    final screen = _findClosestScreen(parentSize, anchorRect.center, avoidBounds);
    final screenBounds = Offset.zero & constraints.biggest;
    var maxWidth = double.infinity;
    var maxHeight = double.infinity;
    var mayNeedHorizontalConstraintAdjustment = false;
    var mayNeedVerticalConstraintAdjustment = false;

    if (edgeBehavior.horizontal.constrain) {
      if (edgeBehavior.horizontal.shift) {
        maxWidth = screen.width - _resolvedOverlayPadding!.horizontal;
      } else {
        mayNeedHorizontalConstraintAdjustment = true;
      }
    }

    if (edgeBehavior.vertical.constrain) {
      if (edgeBehavior.vertical.shift) {
        maxHeight = screen.height - _resolvedOverlayPadding!.vertical;
      } else {
        mayNeedVerticalConstraintAdjustment = true;
      }
    }

    child!.layout(BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight), parentUsesSize: true);
    final childSize = child!.size;

    Offset anchorOffset;
    if (menuPosition == null) {
      anchorOffset = alignment.resolve(textDirection).withinRect(anchorRect);
      anchorOffset += offset;
    } else {
      anchorOffset = anchorRect.topLeft + menuPosition!;
    }

    final ui.Offset position =
        anchorOffset - menuAlignment.resolve(textDirection).alongSize(childSize);
    var desiredPosition = getPositionForChild(screen, childSize, position, anchorOffset);

    if (mayNeedHorizontalConstraintAdjustment || mayNeedVerticalConstraintAdjustment) {
      double? newMaxHeight;
      double? newMaxWidth;
      if (mayNeedVerticalConstraintAdjustment) {
        // Get the amount of overflow on the vertical axis.
        double overflowTop = screenBounds.top - desiredPosition.dy + _resolvedOverlayPadding!.top;
        double overflowBottom =
            desiredPosition.dy +
            child!.size.height -
            screenBounds.bottom +
            _resolvedOverlayPadding!.bottom;
        if (overflowTop > 0 || overflowBottom > 0) {
          if (overflowTop < 0) {
            overflowTop = 0;
          } else if (overflowBottom < 0) {
            overflowBottom = 0;
          }
          newMaxHeight = math.max(0, child!.size.height - (overflowTop + overflowBottom));
          desiredPosition += Offset(0, overflowTop);
        }
      }

      if (mayNeedHorizontalConstraintAdjustment) {
        // Get the amount of overflow on the horizontal axis.
        double overflowLeft =
            screenBounds.left - desiredPosition.dx + _resolvedOverlayPadding!.left;
        double overflowRight =
            desiredPosition.dx +
            child!.size.width -
            screenBounds.right +
            _resolvedOverlayPadding!.right;
        if (overflowLeft > 0 || overflowRight > 0) {
          if (overflowLeft < 0) {
            overflowLeft = 0;
          } else if (overflowRight < 0) {
            overflowRight = 0;
          }

          newMaxWidth = math.max(0, child!.size.width - (overflowLeft + overflowRight));
          desiredPosition += Offset(overflowLeft, 0);
        }
      }

      if (newMaxWidth != null || newMaxHeight != null) {
        child!.layout(
          BoxConstraints(maxWidth: newMaxWidth ?? maxWidth, maxHeight: newMaxHeight ?? maxHeight),
          parentUsesSize: true,
        );
      }
    }

    (child!.parentData! as BoxParentData).offset = desiredPosition;
    size = constraints.biggest;
  }

  // Finds the closest screen to the anchor position.
  //
  // The closest screen is defined as the screen whose center is closest to the
  // anchor position.
  // Finds the closest screen to the anchor point.
  //
  // This algorithm is different than the algorithms for PopupMenuButton and MenuAnchor,
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
    final EdgeInsets? padding = menuPadding?.resolve(textDirection);
    final EdgeInsets overlayInsets = overlayPadding.resolve(textDirection);
    final Rect anchor = menuPosition == null ? anchorRect : anchorPosition & Size.zero;

    double x = position.dx;
    double y = position.dy;

    bool overLeftEdge(double x) => x < screen.left + overlayInsets.left;
    bool overRightEdge(double x) => x > screen.right - childSize.width - overlayInsets.right;
    bool overTopEdge(double y) => y < screen.top + overlayInsets.top;
    bool overBottomEdge(double y) => y > screen.bottom - childSize.height - overlayInsets.bottom;

    double? shiftX;
    if (padding != null && padding.horizontal > 0) {
      double ratio = (x - anchorPosition.dx) / childSize.width;
      ratio = ui.clampDouble(ratio, -1, 0);
      shiftX = padding.right * ratio + padding.left * (ratio + 1);
      x -= shiftX;
    }

    double? shiftY;
    if (padding != null && padding.vertical > 0) {
      double ratio = (y - anchorPosition.dy) / childSize.height;
      ratio = ui.clampDouble(ratio, -1, 0);
      shiftY = padding.bottom * ratio + padding.top * (ratio + 1);
      y -= shiftY;
    }

    final bool leftOverflow = overLeftEdge(x);
    final bool rightOverflow = overRightEdge(x);
    final bool topOverflow = overTopEdge(y);
    final bool bottomOverflow = overBottomEdge(y);

    if (leftOverflow && edgeBehavior.horizontal.flip) {
      // Flip the X position across the horizontal midpoint of the anchor so that the menu is to the right of the anchor.
      double flipX = anchor.center.dx * 2 - position.dx - childSize.width;
      if (shiftX != null) {
        flipX -= padding!.horizontal + shiftX;
      }

      if (overRightEdge(flipX) || overLeftEdge(flipX)) {
        if (edgeBehavior.horizontal.shift || edgeBehavior.horizontal.constrain) {
          final double availableLeft = anchor.left - screen.left - overlayInsets.left;
          final double availableRight = screen.right - anchor.right - overlayInsets.right;
          if (availableLeft >= availableRight) {
            x = math.min(x, flipX);
          } else {
            x = math.max(x, flipX);
          }

          if (edgeBehavior.horizontal.shift) {
            // Make sure the reading edge of the menu is visible.
            final leftBoundary = screen.left + overlayInsets.left;
            final rightBoundary = screen.right - childSize.width - overlayInsets.right;
            if (rightBoundary < leftBoundary) {
              x = switch (textDirection) {
                TextDirection.ltr => leftBoundary,
                TextDirection.rtl => rightBoundary,
              };
            } else {
              x = ui.clampDouble(x, leftBoundary, rightBoundary);
            }
          }
        } else {
          // If neither shift nor constrain is enabled, choose the position that
          // keeps the leading edge (reading edge) visible.
          x = switch (textDirection) {
            TextDirection.ltr => math.max(x, flipX),
            TextDirection.rtl => math.min(x, flipX),
          };
        }
      } else {
        x = flipX;
      }
    } else if (rightOverflow && edgeBehavior.horizontal.flip) {
      // Flip the X position across the horizontal midpoint of the anchor so that the menu is to the left of the anchor.
      double flipX = anchor.center.dx * 2 - position.dx - childSize.width;
      if (shiftX != null) {
        flipX += padding!.horizontal - shiftX;
      }

      if (overLeftEdge(flipX) || overRightEdge(flipX)) {
        if (edgeBehavior.horizontal.shift || edgeBehavior.horizontal.constrain) {
          final double availableLeft = anchor.left - screen.left - overlayInsets.left;
          final double availableRight = screen.right - anchor.right - overlayInsets.right;
          if (availableLeft >= availableRight) {
            x = math.min(x, flipX);
          } else {
            x = math.max(x, flipX);
          }

          if (edgeBehavior.horizontal.shift) {
            // Make sure the reading edge of the menu is visible.
            final leftBoundary = screen.left + overlayInsets.left;
            final rightBoundary = screen.right - childSize.width - overlayInsets.right;
            if (rightBoundary < leftBoundary) {
              x = switch (textDirection) {
                TextDirection.ltr => leftBoundary,
                TextDirection.rtl => rightBoundary,
              };
            } else {
              x = ui.clampDouble(x, leftBoundary, rightBoundary);
            }
          }
        } else {
          // If neither shift nor constrain is enabled, choose the position that
          // keeps the leading edge (reading edge) visible.
          x = switch (textDirection) {
            TextDirection.ltr => math.max(x, flipX),
            TextDirection.rtl => math.min(x, flipX),
          };
        }
      } else {
        x = flipX;
      }
    } else if (leftOverflow && rightOverflow) {
      x = switch (textDirection) {
        .ltr => screen.left + overlayInsets.left,
        .rtl => screen.right - childSize.width - overlayInsets.right,
      };
    } else if (edgeBehavior.horizontal.shift) {
      final bool oversizedWidth = childSize.width > screen.width - overlayInsets.horizontal;
      if (oversizedWidth) {
        x = switch (textDirection) {
          .ltr => screen.left + overlayInsets.left,
          .rtl => screen.right - childSize.width - overlayInsets.right,
        };
      } else if (leftOverflow) {
        x = screen.left + overlayInsets.left;
      } else if (rightOverflow) {
        x = screen.right - childSize.width - overlayInsets.right;
      }
    }

    if (topOverflow && edgeBehavior.vertical.flip) {
      // Flip the Y position across the vertical midpoint of the anchor so that the menu is below the anchor.
      double flipY = anchor.center.dy * 2 - position.dy - childSize.height;
      if (shiftY != null) {
        flipY -= padding!.vertical + shiftY;
      }

      if (overTopEdge(flipY) || overBottomEdge(flipY)) {
        if (edgeBehavior.vertical.shift || edgeBehavior.vertical.constrain) {
          final double availableTop = anchor.top - screen.top - overlayInsets.top;
          final double availableBottom = screen.bottom - anchor.bottom - overlayInsets.bottom;
          if (availableTop >= availableBottom) {
            y = math.min(y, flipY);
          } else {
            y = math.max(y, flipY);
          }

          if (edgeBehavior.vertical.shift) {
            final topBoundary = screen.top + overlayInsets.top;
            final bottomBoundary = screen.bottom - childSize.height - overlayInsets.bottom;
            if (bottomBoundary < topBoundary) {
              y = topBoundary;
            } else {
              y = ui.clampDouble(y, topBoundary, bottomBoundary);
            }
          }
        } else {
          // If neither shift nor constrain is enabled, choose the position that
          // keeps the top edge visible.
          y = math.max(y, flipY);
        }
      } else {
        y = flipY;
      }
    } else if (bottomOverflow && edgeBehavior.vertical.flip) {
      // Flip the Y position across the vertical midpoint of the anchor so that the menu is above the anchor.
      double flipY = anchor.center.dy * 2 - position.dy - childSize.height;
      if (shiftY != null) {
        flipY += padding!.vertical - shiftY;
      }

      if (overTopEdge(flipY) || overBottomEdge(flipY)) {
        if (edgeBehavior.vertical.shift || edgeBehavior.vertical.constrain) {
          final double availableTop = anchor.top - screen.top - overlayInsets.top;
          final double availableBottom = screen.bottom - anchor.bottom - overlayInsets.bottom;
          if (availableTop >= availableBottom) {
            y = math.min(y, flipY);
          } else {
            y = math.max(y, flipY);
          }

          if (edgeBehavior.vertical.shift) {
            final topBoundary = screen.top + overlayInsets.top;
            final bottomBoundary = screen.bottom - childSize.height - overlayInsets.bottom;
            if (bottomBoundary < topBoundary) {
              y = topBoundary;
            } else {
              y = ui.clampDouble(y, topBoundary, bottomBoundary);
            }
          }
        } else {
          // If neither shift nor constrain is enabled, choose the position that
          // keeps the top edge visible.
          y = math.max(y, flipY);
        }
      } else {
        y = flipY;
      }
    } else if (topOverflow && bottomOverflow) {
      y = screen.top + overlayInsets.top;
    } else if (edgeBehavior.vertical.shift) {
      final bool oversizedHeight = childSize.height > screen.height - overlayInsets.vertical;
      if (oversizedHeight) {
        y = screen.top + overlayInsets.top;
      } else if (topOverflow) {
        y = screen.top + overlayInsets.top;
      } else if (bottomOverflow) {
        y = screen.bottom - childSize.height - overlayInsets.bottom;
      }
    }

    return Offset(x, y);
  }
}
