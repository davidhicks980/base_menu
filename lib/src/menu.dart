import 'dart:ui'
    as ui
    show Clip, DisplayFeature, DisplayFeatureState, Offset, Rect, TextDirection, clampDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../menu_utilities.dart';
import 'menu_interface.dart';

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

const Map<ShortcutActivator, Intent> _kMenuVerticalTraversalShortcuts = <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
  SingleActivator(LogicalKeyboardKey.arrowUp): VerticalMenuPreviousFocusIntent(),
  SingleActivator(LogicalKeyboardKey.arrowDown): VerticalMenuNextFocusIntent(),
  SingleActivator(LogicalKeyboardKey.arrowLeft): HorizontalMenuPreviousFocusIntent(),
  SingleActivator(LogicalKeyboardKey.arrowRight): HorizontalMenuNextFocusIntent(),
  SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
  SingleActivator(LogicalKeyboardKey.tab, shift: true): PreviousFocusIntent(),
  SingleActivator(LogicalKeyboardKey.home): MenuFocusFirstIntent(),
  SingleActivator(LogicalKeyboardKey.end): MenuFocusLastIntent(),
};

const Map<ShortcutActivator, Intent> _kMenuHorizontalTraversalShortcuts =
    <ShortcutActivator, Intent>{
      SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
      SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      SingleActivator(LogicalKeyboardKey.arrowLeft): HorizontalMenuPreviousFocusIntent(),
      SingleActivator(LogicalKeyboardKey.arrowRight): HorizontalMenuNextFocusIntent(),
      SingleActivator(LogicalKeyboardKey.arrowUp): VerticalMenuPreviousFocusIntent(),
      SingleActivator(LogicalKeyboardKey.arrowDown): VerticalMenuNextFocusIntent(),
      SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
      SingleActivator(LogicalKeyboardKey.tab, shift: true): PreviousFocusIntent(),
      SingleActivator(LogicalKeyboardKey.home): MenuFocusFirstIntent(),
      SingleActivator(LogicalKeyboardKey.end): MenuFocusLastIntent(),
    };

const Map<ShortcutActivator, Intent> _kStopDirectionalPropagationShortcuts =
    <ShortcutActivator, Intent>{
      SingleActivator(LogicalKeyboardKey.arrowUp): DoNothingAndStopPropagationIntent(),
      SingleActivator(LogicalKeyboardKey.arrowDown): DoNothingAndStopPropagationIntent(),
      SingleActivator(LogicalKeyboardKey.arrowLeft): DoNothingAndStopPropagationIntent(),
      SingleActivator(LogicalKeyboardKey.arrowRight): DoNothingAndStopPropagationIntent(),
    };

sealed class _BaseMenuFocusTraversalIntent extends Intent {
  const _BaseMenuFocusTraversalIntent();
}

final class HorizontalMenuNextFocusIntent extends _BaseMenuFocusTraversalIntent {
  const HorizontalMenuNextFocusIntent();
}

final class HorizontalMenuPreviousFocusIntent extends _BaseMenuFocusTraversalIntent {
  const HorizontalMenuPreviousFocusIntent();
}

final class VerticalMenuNextFocusIntent extends _BaseMenuFocusTraversalIntent {
  const VerticalMenuNextFocusIntent();
}

final class VerticalMenuPreviousFocusIntent extends _BaseMenuFocusTraversalIntent {
  const VerticalMenuPreviousFocusIntent();
}

class MenuFocusFirstIntent extends Intent {
  const MenuFocusFirstIntent();
}

class MenuFocusLastIntent extends Intent {
  const MenuFocusLastIntent();
}

class MenuEnterIntent extends Intent {
  const MenuEnterIntent.focusFirst() : _scopeIntent = const MenuFocusFirstIntent();
  const MenuEnterIntent.focusLast() : _scopeIntent = const MenuFocusLastIntent();

  /// An optional intent to fire on the menu's focus scope after it is opened
  /// and focused.
  ///
  /// Defaults to null, which does not fire any additional intents after opening
  /// and focusing the menu.
  final Intent? _scopeIntent;
}

// An inherited widget that provides the [RawMenuAnchor] to its descendants.
//
// Used to notify anchor descendants when the menu opens and closes, and to
// access the anchor's controller.
class _MenuScope extends InheritedWidget {
  const _MenuScope({required super.child, required this.orientation, required this.isSubmenu});

  final Axis orientation;
  final bool isSubmenu;

  static _MenuScope? _maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_MenuScope>();
  }

  @override
  bool updateShouldNotify(_MenuScope oldWidget) {
    return orientation != oldWidget.orientation || isSubmenu != oldWidget.isSubmenu;
  }
}

typedef BaseMenuPositionBuilder =
    Widget Function(BuildContext context, RawMenuOverlayInfo position, Widget child);

class MenuPanelMouseRegion extends StatelessWidget {
  const MenuPanelMouseRegion({
    super.key,
    required this.child,
    this.onSurfaceEnter,
    this.onSurfaceHover,
    this.onSurfaceLeave,
  });

  final Widget child;
  final PointerEnterEventListener? onSurfaceEnter;
  final PointerHoverEventListener? onSurfaceHover;
  final PointerExitEventListener? onSurfaceLeave;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: MouseRegion(
            hitTestBehavior: HitTestBehavior.translucent,
            onEnter: onSurfaceEnter,
            onHover: onSurfaceHover,
            onExit: onSurfaceLeave,
          ),
        ),
        child,
      ],
    );
  }
}

/// A simple menu surface that displays a vertical list of menu items.
///
/// The [BaseMenuPanel] is painted with a dark theme when
/// [MediaQuery.maybePlatformBrightnessOf] returns [Brightness.dark], and a
/// light theme when the brightness is [Brightness.light] or null. To override
/// this behavior, a [decoration] can be provided.
///
/// Any [padding] applied to the [BaseMenu] is inherited by [BaseMenuPanel].
/// This behavior can be overridden by supplying a custom [padding].
///
/// The [BaseMenuPanel] is only responsible for the size, appearance, and layout
/// of menu items. To manage the positioning, semantics, and interaction of the
/// menu overlay, the [Menu.overlayBuilder] constructor should be used.
///
/// See also:
///
///  * [BaseMenu], for a widget that creates a menu anchor that can be
///    paired with a [BaseMenuPanel].
///  * [BaseMenu.overlayBuilder], for a widget that creates a menu anchor
///    with a custom overlay.
///  * [BaseMenuBar], for a widget that creates a menu that is always
///    visible and is not displayed in an [OverlayPortal].
class BaseMenuPanel extends StatelessWidget {
  /// Creates a [BaseMenuPanel].
  ///
  /// The [menuChildren] argument is required.
  const BaseMenuPanel({
    super.key,
    this.constraints,
    this.constrainCrossAxis = false,
    this.padding = EdgeInsets.zero,
    this.spacing = 0,
    this.clipBehavior = Clip.none,
    this.onSurfaceEnter,
    required this.axis,
    required this.menuChildren,
  });

  /// The constraints to apply to the menu surface.
  ///
  /// If null, the menu will be allowed to expand to the intrinsic size of its
  /// children.
  final BoxConstraints? constraints;

  /// The menu items that should be displayed by this [BaseMenuPanel].
  final List<Widget> menuChildren;

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

  /// The [EdgeInsetsGeometry] applied to the menu surface.
  ///
  /// When a [BaseMenuPanel] is used with a [BaseMenu], [padding] applied to
  /// the menu surface can be ignored during layout by supplying an equivalent
  /// amount of [padding] to the [BaseMenu] constructor. This is useful
  /// when aligning a submenu with its anchor.
  ///
  /// Defaults to null, which applies no padding.
  final EdgeInsetsGeometry padding;

  final double spacing;
  final Axis axis;
  final ui.Clip clipBehavior;
  final PointerEnterEventListener? onSurfaceEnter;

  @override
  Widget build(BuildContext context) {
    Widget body = Flex(
      direction: axis,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: spacing,
      children: menuChildren,
    );

    if (onSurfaceEnter != null) {
      body = MenuPanelMouseRegion(onSurfaceEnter: onSurfaceEnter, child: body);
    }

    Widget child = SingleChildScrollView(
      scrollDirection: axis,
      clipBehavior: clipBehavior,
      child: body,
    );

    if (padding != EdgeInsets.zero) {
      child = Padding(padding: padding, child: child);
    }

    var applyIntrinsics = true;
    if (constraints != null) {
      child = ConstrainedBox(constraints: constraints!, child: child);
      applyIntrinsics = switch (axis) {
        Axis.vertical => !constraints!.hasTightWidth,
        Axis.horizontal => !constraints!.hasTightHeight,
      };
    }

    if (onSurfaceEnter != null) {
      child = MenuPanelMouseRegion(onSurfaceEnter: onSurfaceEnter, child: child);
    }

    if (applyIntrinsics) {
      switch (axis) {
        case Axis.vertical:
          child = IntrinsicWidth(child: child);
        case Axis.horizontal:
          child = IntrinsicHeight(child: child);
      }
    }

    if (constrainCrossAxis) {
      return child;
    }

    return UnconstrainedBox(
      clipBehavior: Clip.hardEdge,
      alignment: AlignmentDirectional.centerStart,
      constrainedAxis: axis,
      child: child,
    );
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[for (final Widget child in menuChildren) child.toDiagnosticsNode()];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('constrainCrossAxis', constrainCrossAxis));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding override', padding));
    properties.add(DoubleProperty('spacing', spacing, defaultValue: 0));
    properties.add(EnumProperty<Axis>('axis', axis));
    properties.add(EnumProperty<ui.Clip>('clipBehavior', clipBehavior, defaultValue: ui.Clip.none));
  }
}

abstract interface class BaseMenuPositionInterface {
  /// The widget that this [BaseMenu] surrounds.
  ///
  /// Typically, this is a button used to open the menu by calling
  /// [MenuController.open] on the `controller` passed to the builder.
  ///
  /// If not supplied, then the [BaseMenu] will be the size that its parent
  /// allocates for it.
  abstract final RawMenuAnchorChildBuilder? builder;

  /// The point on the menu surface that attaches to the anchor.
  ///
  /// Unlike [alignment] and [alignmentOffset], the [menuAlignment] will be
  /// applied when the menu is opened with a `position` argument.
  ///
  /// Defaults to [AlignmentDirectional.bottomStart] if this is a root menu, and
  /// [AlignmentDirectional.topEnd] if this is a submenu.
  abstract final AlignmentGeometry? menuAlignment;

  /// The point on the anchor surface that attaches to the menu.
  ///
  /// The [alignment] is ignored if a `position` argument is provided to
  /// [MenuController.open].
  ///
  /// If the menu overflows the edge of the screen, the menu will be flipped
  /// across the anchor's midpoint on the axis of overflow, effectively negating
  /// the alignment on that axis. For example, if the menu on the right side of
  /// the anchor overflows the right edge of the screen, the menu will be
  /// flipped to the left side of the anchor.
  ///
  /// Defaults to [AlignmentDirectional.bottomStart] if this is a root menu, and
  /// [AlignmentDirectional.topEnd] if this is a submenu.
  abstract final AlignmentGeometry? alignment;

  /// The offset applied to the menu relative to the anchor attachment point.
  ///
  /// By default, increasing the [Offset.dx] and [Offset.dy] value of
  /// [alignmentOffset] will shift the menu position rightward and downward,
  /// respectively.
  ///
  /// However, when the [alignment] is an [AlignmentDirectional], increasing the
  /// [Offset.dx] value of [alignmentOffset] will shift the menu in the reading
  /// direction of the ambient [Directionality] -- rightward in
  /// [TextDirection.ltr] and leftward in [TextDirection.rtl].
  ///
  /// The [alignment] and [alignmentOffset] are ignored if a `position` argument
  /// is provided to [MenuController.open].
  ///
  /// Defaults to [Offset.zero].
  abstract final Offset alignmentOffset;

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
  abstract final EdgeInsetsGeometry padding;

  /// A minimum distance to apply between the menu overlay and the edges of the
  /// screen when the menu is open.
  abstract final EdgeInsetsGeometry overlayPadding;

  abstract final Widget Function(BuildContext context, Widget child)? overlayWrapper;
}

class BaseMenu extends StatelessWidget implements BaseMenuInterface, BaseMenuPositionInterface {
  const BaseMenu({
    super.key,
    this.onOpen,
    this.onOpenRequest = BaseMenuInterface.defaultOnOpenRequested,
    this.onClose,
    this.onCloseRequest = BaseMenuInterface.defaultOnCloseRequested,
    this.useRootOverlay = false,
    this.builder,
    this.child,
    required this.menu,
    this.controller,
    this.consumeOutsideTaps = false,
    this.onFocusChange,
    this.semanticProperties = const SemanticsProperties(
      scopesRoute: true,
      label: 'Menu',
      role: SemanticsRole.menu,
    ),
    this.orientation = Axis.vertical,

    // Positioning parameters
    this.padding = EdgeInsets.zero,
    this.overlayPadding = const EdgeInsets.all(8),
    this.alignment,
    this.alignmentOffset = Offset.zero,
    this.menuAlignment,
    this.overlayWrapper,
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

  @override
  final Widget? child;

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

  Widget _buildPosition(BuildContext context, RawMenuOverlayInfo position, Widget child) {
    final displayFeatures = MediaQuery.maybeDisplayFeaturesOf(context);
    final TextDirection textDirection = Directionality.of(context);
    final scope = _MenuScope._maybeOf(context);

    // Resolve fallback alignment here so that alignmentOffset defaults to
    // being directionally-agnostic.
    final anchorAlignment =
        (alignment ??
                switch (scope?.orientation) {
                  Axis.vertical => AlignmentDirectional.topEnd,
                  _ => AlignmentDirectional.bottomStart,
                })
            .resolve(textDirection);

    final delegate = _MenuLayout(
      overlayPadding: overlayPadding.resolve(textDirection),
      padding: padding,
      avoidBounds: displayFeatures != null ? _avoidBounds(displayFeatures) : const {},
      textDirection: textDirection,
      anchorRect: position.anchorRect,
      alignmentOffset: alignmentOffset,
      menuPosition: position.position,
      menuAlignment: menuAlignment ?? AlignmentDirectional.topStart,
      alignment: anchorAlignment,
    );

    Widget overlay;

    if (scope?.isSubmenu == true &&
        context.dependOnInheritedWidgetOfExactType<MenuAimScope>()?.enable == true) {
      final geometry = MenuAimGeometry()..anchorRect = position.anchorRect;
      overlay = Stack(
        children: [
          CustomSingleChildLayout(
            delegate: _MenuAimLayoutDecorator(delegate: delegate, geometry: geometry),
            child: child,
          ),
          MenuAimListener(geometry: geometry),
        ],
      );
    } else {
      overlay = CustomSingleChildLayout(delegate: delegate, child: child);
    }

    return overlayWrapper?.call(context, overlay) ?? overlay;
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

  @override
  Widget build(BuildContext context) {
    return BasePositionedMenu(
      onOpen: onOpen,
      onClose: onClose,
      onOpenRequest: onOpenRequest,
      onCloseRequest: onCloseRequest,
      useRootOverlay: useRootOverlay,
      menu: menu,
      controller: controller,
      consumeOutsideTaps: consumeOutsideTaps,
      onFocusChange: onFocusChange,
      semanticProperties: semanticProperties,
      positionBuilder: _buildPosition,
      orientation: orientation,
      child: Builder(
        builder: (context) {
          return builder?.call(context, controller ?? MenuController.maybeOf(context)!, child) ??
              child ??
              const SizedBox();
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<MenuController>.has('controller', controller));
    properties.add(
      DiagnosticsProperty<EdgeInsetsGeometry>(
        'overlayPadding',
        overlayPadding,
        defaultValue: const EdgeInsets.all(8),
      ),
    );
    properties.add(
      DiagnosticsProperty<Offset>('alignmentOffset', alignmentOffset, defaultValue: Offset.zero),
    );
  }
}

class BasePositionedMenu extends StatefulWidget implements BaseMenuInterface {
  const BasePositionedMenu({
    super.key,
    this.onOpen,
    this.onClose,
    this.onOpenRequest = _defaultOnOpenRequested,
    this.onCloseRequest = _defaultOnCloseRequested,
    this.useRootOverlay = false,
    this.controller,
    this.consumeOutsideTaps = false,
    this.onFocusChange,
    this.semanticProperties = const SemanticsProperties(
      scopesRoute: true,
      label: 'Menu',
      role: SemanticsRole.menu,
    ),
    this.orientation = Axis.vertical,
    required this.menu,
    required this.positionBuilder,
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

  @override
  final Widget? child;

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

  final BaseMenuPositionBuilder positionBuilder;

  static void _defaultOnOpenRequested(Offset? position, VoidCallback showOverlay) {
    showOverlay();
  }

  static void _defaultOnCloseRequested(VoidCallback hideOverlay) {
    hideOverlay();
  }

  @override
  State<BasePositionedMenu> createState() => _BaseMenuState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<MenuController>.has('controller', controller));
  }
}

class _BaseMenuState extends State<BasePositionedMenu> {
  late final _menuScopeNode = FocusScopeNode(
    skipTraversal: true,
    directionalTraversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );

  late final Map<Type, Action<Intent>> _anchorActions = <Type, Action<Intent>>{
    MenuEnterIntent: CallbackAction<MenuEnterIntent>(onInvoke: _handleEnterMenu),
  };

  Map<Type, Action<Intent>>? _overlayActions;
  TextDirection _textDirection = TextDirection.ltr;
  bool _parentIsSubmenu = false;
  Axis? _parentOrientation;

  MenuController? _internalMenuController;
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
      if (widget.onFocusChange != null) {
        widget.onFocusChange!(_menuScopeNode.hasFocus);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
    final scope = _MenuScope._maybeOf(context);
    if (scope?.orientation != _parentOrientation || scope?.isSubmenu != _parentIsSubmenu) {
      _parentOrientation = scope?.orientation;
      _parentIsSubmenu = scope?.isSubmenu ?? false;
      _overlayActions = null;
    }
  }

  @override
  void didUpdateWidget(BasePositionedMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (widget.controller == null) {
        _internalMenuController = MenuController();
      } else {
        _internalMenuController = null;
      }
    }
  }

  @override
  void dispose() {
    _internalMenuController = null;
    _menuScopeNode.dispose();
    super.dispose();
  }

  void _handleEnterMenu(MenuEnterIntent intent) {
    if (_menuController.isOpen) {
      if (intent._scopeIntent != null && _menuScopeNode.context != null) {
        Actions.invoke(_menuScopeNode.context!, intent._scopeIntent);
      }
    } else {
      _menuController.open();
      if (intent._scopeIntent != null) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (_menuController.isOpen) {
            Actions.invoke(_menuScopeNode.context!, intent._scopeIntent);
          }
        });
      }
    }
  }

  void _handleMenuExit(Intent intent) {
    if (_parentIsSubmenu && _parentOrientation == widget.orientation) {
      _menuController.close();
      return;
    }

    FocusScope.of(context).previousFocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    Actions.maybeInvoke(context, intent);
  }

  Widget _buildAnchor(BuildContext context, MenuController controller, Widget? child) {
    return Actions(
      actions: _anchorActions,
      child: Shortcuts(
        shortcuts: switch (_parentOrientation) {
          Axis.vertical => {
            ..._kMenuVerticalTraversalShortcuts,
            switch (_textDirection) {
              TextDirection.ltr => const SingleActivator(LogicalKeyboardKey.arrowRight),
              TextDirection.rtl => const SingleActivator(LogicalKeyboardKey.arrowLeft),
            }: const MenuEnterIntent.focusFirst(),
            if (controller.isOpen && widget.orientation == Axis.vertical) ...{
              const SingleActivator(LogicalKeyboardKey.arrowUp): const MenuEnterIntent.focusLast(),
              const SingleActivator(LogicalKeyboardKey.arrowDown):
                  const MenuEnterIntent.focusFirst(),
            },
          },
          Axis.horizontal || null => {
            ..._kMenuHorizontalTraversalShortcuts,
            const SingleActivator(LogicalKeyboardKey.arrowDown): const MenuEnterIntent.focusFirst(),
            if (!_parentIsSubmenu || widget.orientation == Axis.vertical)
              const SingleActivator(LogicalKeyboardKey.arrowUp): const MenuEnterIntent.focusLast(),
          },
        },
        child: widget.child ?? const SizedBox(),
      ),
    );
  }

  Widget _buildOverlay(BuildContext _, RawMenuOverlayInfo position) {
    if (_overlayActions == null) {
      final Type intentType = switch (widget.orientation) {
        Axis.vertical => HorizontalMenuPreviousFocusIntent,
        Axis.horizontal => VerticalMenuPreviousFocusIntent,
      };
      _overlayActions = {intentType: CallbackAction(onInvoke: _handleMenuExit)};
    }

    return Actions(
      actions: _overlayActions!,
      child: _MenuOverlay(
        submenuAxis: widget.orientation,
        position: position,
        consumeOutsideTaps: widget.consumeOutsideTaps,
        semanticProperties: widget.semanticProperties,
        menuController: _menuController,
        focusScopeNode: _menuScopeNode,
        positionBuilder: widget.positionBuilder,
        child: widget.menu,
      ),
    );
  }

  void _handleClose() {
    widget.onClose?.call();

    if (!kIsWeb) {
      return;
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      final previousPrimaryFocus = FocusManager.instance.primaryFocus;
      if (previousPrimaryFocus == null) {
        return;
      }
      FocusManager.instance.applyFocusChangesIfNeeded();
      if (FocusManager.instance.rootScope.hasPrimaryFocus) {
        previousPrimaryFocus.requestFocus();
      }
    });
  }

  void _handleOpen() {
    widget.onClose?.call();

    if (!kIsWeb) {
      return;
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      // Prevents the root focus scope from taking focus on web.
      FocusManager.instance.primaryFocus?.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    _textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
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

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return widget.semanticProperties.label!;
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
    required this.positionBuilder,
  });

  final RawMenuOverlayInfo position;
  final Widget child;
  final bool consumeOutsideTaps;
  final MenuController menuController;
  final FocusScopeNode focusScopeNode;
  final Axis submenuAxis;
  final SemanticsProperties semanticProperties;
  final BaseMenuPositionBuilder positionBuilder;

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
          print('Tap outside menu detected at position: ${event.position}');
        },
        child: _MenuScope(
          orientation: submenuAxis,
          isSubmenu: true,
          child: _InlineMenu(
            focusScopeNode: focusScopeNode,
            semanticProperties: semanticProperties,
            child: child,
          ),
        ),
      ),
    );

    return ConstrainedBox(
      constraints: BoxConstraints.loose(position.overlaySize),
      child: Builder(
        builder: (BuildContext context) {
          return positionBuilder.call(context, position, panel);
        },
      ),
    );
  }
}

class _InlineMenu extends StatelessWidget {
  const _InlineMenu({
    required this.child,
    required this.focusScopeNode,
    required this.semanticProperties,
  });

  final Widget child;
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
        child: _MenuFocusTraversal(
          axis: _MenuScope._maybeOf(context)!.orientation,
          focusScopeNode: focusScopeNode,
          child: child,
        ),
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
      onInvoke: (intent) => _menuScopeNode.enclosingScope?.nextFocus(),
    ),
    PreviousFocusIntent: CallbackAction(
      onInvoke: (intent) => _menuScopeNode.enclosingScope?.previousFocus(),
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
        traversalEdgeBehavior: TraversalEdgeBehavior.parentScope,
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
          traversalEdgeBehavior: TraversalEdgeBehavior.parentScope,
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
    return Actions(
      actions: _actions,
      child: RawMenuAnchorGroup(
        controller: _menuController,
        child: _MenuScope(
          orientation: widget.axis,
          isSubmenu: false,
          child: _InlineMenu(
            semanticProperties: widget.semanticProperties,
            focusScopeNode: _menuScopeNode,
            child: widget.child,
          ),
        ),
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
  Map<Type, Action<Intent>>? actions;

  @override
  void didUpdateWidget(_MenuFocusTraversal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.axis != widget.axis || oldWidget.focusScopeNode != widget.focusScopeNode) {
      actions = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: policy,
      child: Shortcuts(
        debugLabel: 'Menu Focus Traversal Shortcuts ${widget.child}',
        shortcuts: widget.axis == Axis.vertical
            ? _kMenuVerticalTraversalShortcuts
            : _kMenuHorizontalTraversalShortcuts,
        child: Actions(
          actions: actions ??= {
            MenuFocusFirstIntent: _MenuFocusFirstAction(widget.focusScopeNode),
            MenuFocusLastIntent: _MenuFocusLastAction(widget.focusScopeNode),
            ...switch (widget.axis) {
              Axis.vertical => {
                VerticalMenuNextFocusIntent: _TraverseNextAction(widget.focusScopeNode),
                VerticalMenuPreviousFocusIntent: _TraversePreviousAction(widget.focusScopeNode),
              },
              Axis.horizontal => {
                HorizontalMenuNextFocusIntent: _TraverseNextAction(widget.focusScopeNode),
                HorizontalMenuPreviousFocusIntent: _TraversePreviousAction(widget.focusScopeNode),
              },
            },
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

class _MenuFocusFirstAction extends Action<MenuFocusFirstIntent> {
  _MenuFocusFirstAction(this.focusScopeNode);
  final FocusScopeNode focusScopeNode;

  @override
  void invoke(MenuFocusFirstIntent intent) {
    final FocusTraversalPolicy policy = FocusTraversalGroup.maybeOfNode(focusScopeNode)!;
    final FocusNode? firstNode = policy.findFirstFocus(focusScopeNode, ignoreCurrentFocus: true);
    if (firstNode != null) {
      policy.requestFocusCallback(firstNode);
    }
  }
}

class _MenuFocusLastAction extends Action<MenuFocusLastIntent> {
  _MenuFocusLastAction(this.focusScopeNode);
  final FocusScopeNode focusScopeNode;

  @override
  void invoke(MenuFocusLastIntent intent) {
    final FocusTraversalPolicy policy = FocusTraversalGroup.maybeOfNode(focusScopeNode)!;
    final FocusNode lastNode = policy.findLastFocus(focusScopeNode, ignoreCurrentFocus: true);
    policy.requestFocusCallback(lastNode);
  }
}

class _TraverseNextAction extends Action<_BaseMenuFocusTraversalIntent> {
  _TraverseNextAction(this.focusScopeNode);
  final FocusScopeNode focusScopeNode;
  @override
  void invoke(_BaseMenuFocusTraversalIntent intent) {
    final policy = FocusTraversalGroup.maybeOf(focusScopeNode.context!);
    if (policy == null) {
      primaryFocus?.nextFocus();
      return;
    }

    final last = policy.findLastFocus(focusScopeNode, ignoreCurrentFocus: true);
    if (!last.hasFocus) {
      focusScopeNode.nextFocus();
      return;
    }

    final first = policy.findFirstFocus(focusScopeNode, ignoreCurrentFocus: true);
    if (first == null || first == primaryFocus) {
      return;
    }

    policy.requestFocusCallback(first);
  }
}

class _TraversePreviousAction extends Action<_BaseMenuFocusTraversalIntent> {
  _TraversePreviousAction(this.focusScopeNode);
  final FocusScopeNode focusScopeNode;
  @override
  void invoke(_BaseMenuFocusTraversalIntent intent) {
    final policy = FocusTraversalGroup.maybeOf(focusScopeNode.context!);

    if (policy == null) {
      primaryFocus?.previousFocus();
      return;
    }

    final first = policy.findFirstFocus(focusScopeNode, ignoreCurrentFocus: true);
    if (first == null) {
      return;
    }

    if (!first.hasFocus) {
      focusScopeNode.previousFocus();
      return;
    }

    final last = policy.findLastFocus(focusScopeNode, ignoreCurrentFocus: true);
    if (last == primaryFocus) {
      return;
    }

    policy.requestFocusCallback(last);
  }
}

// A layout delegate that positions the menu relative to its anchor.
class _MenuLayout extends SingleChildLayoutDelegate {
  const _MenuLayout({
    required this.alignmentOffset,
    required this.anchorRect,
    required this.overlayPadding,
    required this.avoidBounds,
    required this.alignment,
    required this.menuAlignment,
    required this.textDirection,
    required EdgeInsetsGeometry? padding,
    this.menuPosition,
  }) : menuPadding = padding;

  // Rectangle of the button anchoring the menu overlay.
  final ui.Rect anchorRect;

  // The offset from the alignment position to find the ideal location for the
  // menu.
  final ui.Offset alignmentOffset;

  // The offset of the menu relative to the top-left corner of the anchor.
  final ui.Offset? menuPosition;

  // The padding obtained from calling [MediaQuery.paddingOf].
  //
  // Used to prevent the menu from being obstructed by system UI.
  final EdgeInsets overlayPadding;

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
    final Rect anchor = menuPosition == null ? anchorRect : anchorPosition & Size.zero;

    double x = position.dx;
    double y = position.dy;

    bool overLeftEdge(double x) => x < screen.left + overlayPadding.left;
    bool overRightEdge(double x) => x > screen.right - childSize.width - overlayPadding.right;
    bool overTopEdge(double y) => y < screen.top + overlayPadding.top;
    bool overBottomEdge(double y) => y > screen.bottom - childSize.height - overlayPadding.bottom;

    // Layout horizontally first to determine if the menu can be placed on
    // either side of the anchor without overlapping.
    bool hasHorizontalAnchorOverlap = childSize.width >= screen.width;
    if (hasHorizontalAnchorOverlap) {
      x = screen.left + overlayPadding.left;
    } else {
      // Shift the menu left or right to adjust for padding.
      double? shiftX;
      if (padding != null && padding.horizontal > 0) {
        double ratio = (x - anchorPosition.dx) / childSize.width;
        ratio = ui.clampDouble(ratio, -1, 0);
        shiftX = padding.right * ratio + padding.left * (ratio + 1);
        x -= shiftX;
      }

      if (overLeftEdge(x)) {
        // Flip the X position across the horizontal midpoint of the anchor so that the menu is to the right of the anchor.
        double flipX = anchor.center.dx * 2 - position.dx - childSize.width;
        if (shiftX != null) {
          flipX -= padding!.horizontal + shiftX;
        }

        hasHorizontalAnchorOverlap = overRightEdge(flipX);
        if (hasHorizontalAnchorOverlap || overLeftEdge(flipX)) {
          x = screen.left + overlayPadding.left;
        } else {
          x = flipX;
        }
      } else if (overRightEdge(x)) {
        // Flip the X position across the horizontal midpoint of the anchor so that the menu is to the left of the anchor.
        double flipX = anchor.center.dx * 2 - position.dx - childSize.width;
        if (shiftX != null) {
          flipX += padding!.horizontal - shiftX;
        }

        hasHorizontalAnchorOverlap = overLeftEdge(flipX);
        if (hasHorizontalAnchorOverlap || overRightEdge(flipX)) {
          x = screen.right - childSize.width - overlayPadding.right;
        } else {
          x = flipX;
        }
      }
    }

    if (childSize.height >= screen.height) {
      // Menu is too big to fit on screen. Fit as much as possible.
      return Offset(x, overlayPadding.top);
    }

    if (hasHorizontalAnchorOverlap && !anchor.isEmpty) {
      // If both horizontal screen edges overlap, shift the menu upwards or
      // downwards by the minimum amount needed to avoid overlapping the anchor.
      //
      // NOTE: Menus that are deliberately overlapping the anchor will stop
      // overlapping the anchor, but only when the screen is very small.
      final double below = anchor.bottom - y;
      final double above = y + childSize.height - anchor.top;
      if (below > 0 && above > 0) {
        if (below > above) {
          y = anchor.top - childSize.height;
        } else {
          y = anchor.bottom;
        }
      }
    }

    // Remove vertical padding from the y component.
    double? shiftY;
    if (padding != null && padding.vertical > 0) {
      double ratio = (y - anchorPosition.dy) / childSize.height;
      ratio = ui.clampDouble(ratio, -1, 0);
      shiftY = padding.bottom * ratio + padding.top * (ratio + 1);
      y -= shiftY;
    }

    if (overTopEdge(y)) {
      // Flip the Y position across the vertical midpoint of the anchor so that the menu is below the anchor.
      double flipY = anchor.center.dy * 2 - position.dy - childSize.height;
      if (shiftY != null) {
        flipY -= padding!.vertical + shiftY;
      }

      if (overTopEdge(flipY) || overBottomEdge(flipY)) {
        y = screen.top + overlayPadding.top;
      } else {
        y = flipY;
      }
    } else if (overBottomEdge(y)) {
      // Flip the Y position across the vertical midpoint of the anchor so that
      // the menu is above the anchor.
      double flipY = anchor.center.dy * 2 - position.dy - childSize.height;
      if (shiftY != null) {
        flipY += padding!.vertical - shiftY;
      }

      if (overTopEdge(flipY) || overBottomEdge(flipY)) {
        y = screen.bottom - childSize.height - overlayPadding.bottom;
      } else {
        y = flipY;
      }
    }

    return Offset(x, y);
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // The menu can be at most the size of the overlay minus totalPadding.
    return BoxConstraints.loose(constraints.biggest).deflate(overlayPadding);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // Point on the anchor where the menu is attached.
    Offset anchorOffset;
    if (menuPosition == null) {
      anchorOffset = alignment.resolve(textDirection).withinRect(anchorRect);
      anchorOffset += switch (textDirection) {
        ui.TextDirection.ltr => alignmentOffset,
        ui.TextDirection.rtl =>
          alignment is AlignmentDirectional
              ? Offset(-alignmentOffset.dx, alignmentOffset.dy)
              : alignmentOffset,
      };
    } else {
      anchorOffset = anchorRect.topLeft + menuPosition!;
    }

    final ui.Offset position =
        anchorOffset - menuAlignment.resolve(textDirection).alongSize(childSize);

    final Rect screen = _findClosestScreen(size, anchorRect.center, avoidBounds);

    return _fitInsideScreen(screen, childSize, position, anchorOffset);
  }

  @override
  bool shouldRelayout(_MenuLayout oldDelegate) {
    return anchorRect != oldDelegate.anchorRect ||
        alignment != oldDelegate.alignment ||
        alignmentOffset != oldDelegate.alignmentOffset ||
        menuAlignment != oldDelegate.menuAlignment ||
        menuPosition != oldDelegate.menuPosition ||
        menuPadding != oldDelegate.menuPadding ||
        overlayPadding != oldDelegate.overlayPadding ||
        textDirection != oldDelegate.textDirection ||
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
