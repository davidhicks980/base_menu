import 'dart:async';
import 'dart:ui' as ui
    show DisplayFeature, DisplayFeatureState, Offset, Rect, TextDirection, clampDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

export 'menu_item.dart';
export 'tappable.dart';

// Examples can assume:
// late BuildContext context;
// late StateSetter setState;
// late List<Widget> menuItems;
// late RawMenuAnchorOverlayPosition position;

class _MenuStateChangeNotification extends Notification {
  const _MenuStateChangeNotification();
}

double _computeSquaredDistanceToRect(Offset point, Rect rect) {
  final double dx = point.dx - ui.clampDouble(point.dx, rect.left, rect.right);
  final double dy = point.dy - ui.clampDouble(point.dy, rect.top, rect.bottom);
  return dx * dx + dy * dy;
}

const Map<ShortcutActivator, Intent> _kMenuVerticalTraversalShortcuts = <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
  SingleActivator(LogicalKeyboardKey.arrowUp): _VerticalFocusPreviousIntent(),
  SingleActivator(LogicalKeyboardKey.arrowDown): _VerticalFocusNextIntent(),
  SingleActivator(LogicalKeyboardKey.arrowLeft): _HorizontalFocusPreviousIntent(),
  SingleActivator(LogicalKeyboardKey.arrowRight): _HorizontalFocusNextIntent(),
  SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
  SingleActivator(LogicalKeyboardKey.tab, shift: true): PreviousFocusIntent(),
  SingleActivator(LogicalKeyboardKey.home): _MenuFocusFirstIntent(),
  SingleActivator(LogicalKeyboardKey.end): _MenuFocusLastIntent(),
};

const Map<ShortcutActivator, Intent> _kMenuHorizontalTraversalShortcuts =
    <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
  SingleActivator(LogicalKeyboardKey.arrowLeft): _HorizontalFocusPreviousIntent(),
  SingleActivator(LogicalKeyboardKey.arrowRight): _HorizontalFocusNextIntent(),
  SingleActivator(LogicalKeyboardKey.arrowUp): _VerticalFocusPreviousIntent(),
  SingleActivator(LogicalKeyboardKey.arrowDown): _VerticalFocusNextIntent(),
  SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
  SingleActivator(LogicalKeyboardKey.tab, shift: true): PreviousFocusIntent(),
  SingleActivator(LogicalKeyboardKey.home): _MenuFocusFirstIntent(),
  SingleActivator(LogicalKeyboardKey.end): _MenuFocusLastIntent(),
};

const Map<ShortcutActivator, Intent> _kStopDirectionalPropagationShortcuts =
    <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.arrowUp): DoNothingAndStopPropagationIntent(),
  SingleActivator(LogicalKeyboardKey.arrowDown): DoNothingAndStopPropagationIntent(),
  SingleActivator(LogicalKeyboardKey.arrowLeft): DoNothingAndStopPropagationIntent(),
  SingleActivator(LogicalKeyboardKey.arrowRight): DoNothingAndStopPropagationIntent(),
};

sealed class _CoreMenuFocusTraversalIntent extends Intent {
  const _CoreMenuFocusTraversalIntent();
}

final class _HorizontalFocusNextIntent extends _CoreMenuFocusTraversalIntent {
  const _HorizontalFocusNextIntent();
}

final class _HorizontalFocusPreviousIntent extends _CoreMenuFocusTraversalIntent {
  const _HorizontalFocusPreviousIntent();
}

final class _VerticalFocusNextIntent extends _CoreMenuFocusTraversalIntent {
  const _VerticalFocusNextIntent();
}

final class _VerticalFocusPreviousIntent extends _CoreMenuFocusTraversalIntent {
  const _VerticalFocusPreviousIntent();
}

class _MenuFocusFirstIntent extends Intent {
  const _MenuFocusFirstIntent();
}

class _MenuFocusLastIntent extends Intent {
  const _MenuFocusLastIntent();
}

class _MenuSetFirstFocusIntent extends Intent {
  const _MenuSetFirstFocusIntent();
}

class CoreMenuEnterIntent extends Intent {
  const CoreMenuEnterIntent() : _scopeIntent = null;
  const CoreMenuEnterIntent.focusFirst() : _scopeIntent = const _MenuFocusFirstIntent();
  const CoreMenuEnterIntent.focusLast() : _scopeIntent = const _MenuFocusLastIntent();
  const CoreMenuEnterIntent.setFirstFocus() : _scopeIntent = const _MenuSetFirstFocusIntent();

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
class _CoreMenuScope extends InheritedWidget {
  const _CoreMenuScope({
    required super.child,
    required this.axis,
    required this.isSubmenu,
  });

  final Axis axis;
  final bool isSubmenu;

  static _CoreMenuScope? _maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_CoreMenuScope>();
  }

  @override
  bool updateShouldNotify(_CoreMenuScope oldWidget) {
    return axis != oldWidget.axis || isSubmenu != oldWidget.isSubmenu;
  }
}

/// A simple menu surface that displays a vertical list of menu items.
///
/// The [CoreMenuPanel] is painted with a dark theme when
/// [MediaQuery.maybePlatformBrightnessOf] returns [Brightness.dark], and a
/// light theme when the brightness is [Brightness.light] or null. To override
/// this behavior, a [decoration] can be provided.
///
/// Any [padding] applied to the [CoreMenu] is inherited by [CoreMenuPanel].
/// This behavior can be overridden by supplying a custom [padding].
///
/// The [CoreMenuPanel] is only responsible for the size, appearance, and layout
/// of menu items. To manage the positioning, semantics, and interaction of the
/// menu overlay, the [Menu.overlayBuilder] constructor should be used.
///
/// See also:
///
///  * [CoreMenu], for a widget that creates a menu anchor that can be
///    paired with a [CoreMenuPanel].
///  * [CoreMenu.overlayBuilder], for a widget that creates a menu anchor
///    with a custom overlay.
///  * [CoreMenuBar], for a widget that creates a menu that is always
///    visible and is not displayed in an [OverlayPortal].
class CoreMenuPanel extends StatelessWidget {
  /// Creates a [CoreMenuPanel].
  ///
  /// The [menuChildren] argument is required.
  const CoreMenuPanel({
    super.key,
    this.constraints,
    this.constrainCrossAxis = false,
    this.padding = EdgeInsets.zero,
    this.spacing = 0,
    required this.axis,
    required this.menuChildren,
  });

  /// The constraints to apply to the menu surface.
  ///
  /// If null, the menu will be allowed to expand to the intrinsic size of its
  /// children.
  final BoxConstraints? constraints;

  /// The menu items that should be displayed by this [CoreMenuPanel].
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
  /// When a [CoreMenuPanel] is used with a [CoreMenu], [padding] applied to
  /// the menu surface can be ignored during layout by supplying an equivalent
  /// amount of [padding] to the [CoreMenu] constructor. This is useful
  /// when aligning a submenu with its anchor.
  ///
  /// Defaults to null, which applies no padding.
  final EdgeInsetsGeometry padding;

  final double spacing;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    Widget child = SingleChildScrollView(
      scrollDirection: axis,
      child: Flex(
        direction: axis,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: spacing,
        children: menuChildren,
      ),
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
  }
}

class CoreMenu extends StatefulWidget {
  const CoreMenu({
    super.key,
    this.onOpen,
    this.onClose,
    this.onOpenRequest = _defaultOnOpenRequested,
    this.onCloseRequest = _defaultOnCloseRequested,
    this.useRootOverlay = false,
    this.builder,
    this.child,
    this.padding = EdgeInsets.zero,
    this.overlayPadding = const EdgeInsets.all(8),
    required this.panel,
    this.controller,
    this.consumeOutsideTaps = false,
    this.alignment,
    this.alignmentOffset = Offset.zero,
    this.menuAlignment,
    this.onFocusChange,
    this.semanticProperties = const SemanticsProperties(
      scopesRoute: true,
      role: SemanticsRole.menu,
    ),
    this.axis = Axis.vertical,
  });

  /// An optional [MenuController] that allows opening and closing of the menu
  /// from other widgets.
  ///
  /// If not supplied, a new [MenuController] will be created and managed by the
  /// [CoreMenu].
  final MenuController? controller;

  /// Whether or not a tap event that closes the menu will be permitted to
  /// continue on to the gesture arena.
  ///
  /// If false, then tapping outside of a menu when the menu is open will both
  /// close the menu, and allow the tap to participate in the gesture arena.
  ///
  /// If true, then it will only close the menu, and the tap event will be
  /// consumed.
  ///
  /// Defaults to false.
  final bool consumeOutsideTaps;

  /// A callback that is invoked when the menu is opened.
  final VoidCallback? onOpen;

  /// Called when a request is made to open the menu.
  ///
  /// This callback is triggered every time [MenuController.open] is called,
  /// even when the menu overlay is already showing. As a result, this callback
  /// is a good place to begin menu opening animations, or observe when a menu
  /// is repositioned.
  ///
  /// After an open request is intercepted, the `showOverlay` callback should be
  /// called when the menu overlay is ready to be shown. This can occur
  /// immediately (the default behavior), or after a delay. Calling
  /// `showOverlay` sets [MenuController.isOpen] to true, builds (or rebuilds)
  /// the overlay widget, and shows the menu overlay at the front of the overlay
  /// stack.
  ///
  /// If `showOverlay` is not called, the menu will stay hidden. Calling
  /// `showOverlay` after disposal is a no-op, meaning it will not trigger
  /// [onOpen] or show the menu overlay.
  ///
  /// If a [RawMenuAnchor] is used in a themed menu that plays an opening
  /// animation, the themed menu should show the overlay before starting the
  /// opening animation, since the animation plays on the overlay itself.
  ///
  /// The `position` argument is the `position` that [MenuController.open] was
  /// called with.
  ///
  /// A typical [onOpenRequested] consists of the following steps:
  ///
  ///  1. Optional delay.
  ///  2. Call `showOverlay` (whose call chain eventually invokes [onOpen]).
  ///  3. Optionally start the opening animation.
  ///
  /// Defaults to a callback that immediately shows the menu.
  final RawMenuAnchorOpenRequestedCallback onOpenRequest;

  /// A callback that is invoked when the menu is closed.
  final VoidCallback? onClose;

  /// Called when a request is made to close the menu.
  ///
  /// This callback is triggered every time [MenuController.close] is called,
  /// regardless of whether the overlay is already hidden. As a result, this
  /// callback can be used to add a delay or a closing animation before the menu
  /// is hidden.
  ///
  /// If the menu is not closed, this callback will also be called when the root
  /// menu anchor is scrolled and when the screen is resized.
  ///
  /// After a close request is intercepted and closing behaviors have completed,
  /// the `hideOverlay` callback should be called. This callback sets
  /// [MenuController.isOpen] to false and hides the menu overlay widget. If the
  /// [RawMenuAnchor] is used in a themed menu that plays a closing animation,
  /// `hideOverlay` should be called after the closing animation has ended,
  /// since the animation plays on the overlay itself. This means that
  /// [MenuController.isOpen] will stay true while closing animations are
  /// running.
  ///
  /// Calling `hideOverlay` after disposal is a no-op, meaning it will not
  /// trigger [onClose] or hide the menu overlay.
  ///
  /// Typically, [onCloseRequested] consists of the following steps:
  ///
  ///  1. Optionally start the closing animation and wait for it to complete.
  ///  2. Call `hideOverlay` (whose call chain eventually invokes [onClose]).
  ///
  /// Throughout the closing sequence, menus should typically not be focusable
  /// or interactive.
  ///
  /// Defaults to a callback that immediately hides the menu.
  final RawMenuAnchorCloseRequestedCallback onCloseRequest;

  /// The widget that this [CoreMenu] surrounds.
  ///
  /// Typically, this is a button used to open the menu by calling
  /// [MenuController.open] on the `controller` passed to the builder.
  ///
  /// If not supplied, then the [CoreMenu] will be the size that its parent
  /// allocates for it.
  final RawMenuAnchorChildBuilder? builder;

  /// The optional child to be passed to the [builder].
  ///
  /// Supply this child if there is a portion of the widget tree built in
  /// [builder] that doesn't depend on the `controller` or `context` supplied to
  /// the [builder]. It will be more efficient, since Flutter doesn't then need
  /// to rebuild this child when those change.
  final Widget? child;

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
  final AlignmentGeometry? alignment;

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
  final Offset alignmentOffset;

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

  /// The point on the menu surface that attaches to the anchor.
  ///
  /// Unlike [alignment] and [alignmentOffset], the [menuAlignment] will be
  /// applied when the menu is opened with a `position` argument.
  ///
  /// Defaults to [AlignmentDirectional.bottomStart] if this is a root menu, and
  /// [AlignmentDirectional.topEnd] if this is a submenu.
  final AlignmentGeometry? menuAlignment;

  /// {@template flutter.widgets.RawMenuAnchor.useRootOverlay}
  /// Whether the menu panel should be rendered in the root [Overlay].
  ///
  /// When true, the menu is mounted in the root overlay. Rendering the menu in
  /// the root overlay prevents the menu from being obscured by other widgets.
  ///
  /// When false, the menu is rendered in the nearest ancestor [Overlay].
  ///
  /// Submenus will always use the same overlay as their top-level ancestor, so
  /// setting a [useRootOverlay] value on a submenu will have no effect.
  /// {@endtemplate}
  ///
  /// Defaults to false.
  final bool useRootOverlay;

  // The menu panel that is displayed when the menu is opened.
  //
  // The panel should lay out its menu children in a vertical list.
  final Widget panel;

  /// A minimum distance to apply between the menu overlay and the edges of the
  /// screen when the menu is open.
  final EdgeInsetsGeometry overlayPadding;

  /// Called when focus leaves the menu anchor and overlay.
  final ValueChanged<bool>? onFocusChange;

  /// Properties used to annotate the menu overlay.
  final SemanticsProperties semanticProperties;

  final Axis axis;

  static void _defaultOnOpenRequested(Offset? position, VoidCallback showOverlay) {
    showOverlay();
  }

  static void _defaultOnCloseRequested(VoidCallback hideOverlay) {
    hideOverlay();
  }

  @override
  State<CoreMenu> createState() => _CoreMenuState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<MenuController>.has('controller', controller));
    properties.add(
      DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding, defaultValue: null),
    );
    properties.add(
      DiagnosticsProperty<EdgeInsetsGeometry>('overlayPadding', overlayPadding,
          defaultValue: const EdgeInsets.all(8)),
    );
    properties.add(
      DiagnosticsProperty<Offset>(
        'alignmentOffset',
        alignmentOffset,
        defaultValue: Offset.zero,
      ),
    );
  }
}

class _CoreMenuState extends State<CoreMenu> {
  MenuController get _menuController {
    return widget.controller ?? _internalMenuController!;
  }

  MenuController? _internalMenuController;
  late final FocusScopeNode _menuScopeNode = FocusScopeNode(
    debugLabel: 'FocusScopeNode.${widget.axis}.$this',
    skipTraversal: true,
    directionalTraversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );
  TextDirection _textDirection = TextDirection.ltr;
  _CoreMenuScope? get _parentMenuScope => _CoreMenuScope._maybeOf(context);

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalMenuController = MenuController();
    }
  }

  @override
  void didUpdateWidget(CoreMenu oldWidget) {
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
  }

  @override
  void dispose() {
    _internalMenuController = null;
    _anchorScope.dispose();
    _trackingFocusNode.dispose();
    _menuScopeNode.dispose();
    super.dispose();
  }

  final FocusNode _trackingFocusNode =
      FocusNode(debugLabel: 'Menu Anchor Tracking Focus Node', canRequestFocus: false);
  bool _hasFocus = false;

  void _handleFocusChange(bool focused) {
    if (_trackingFocusNode.hasFocus != _hasFocus) {
      _hasFocus = _trackingFocusNode.hasFocus;
      widget.onFocusChange?.call(_hasFocus);
      if (!_hasFocus) {
        _menuController.close();
      }
    }
  }

  void _handleClose() {
    widget.onClose?.call();
    const _MenuStateChangeNotification().dispatch(context);
  }

  void _handleOpen() {
    widget.onOpen?.call();
    const _MenuStateChangeNotification().dispatch(context);
  }

  final _anchorScope = FocusScopeNode(debugLabel: 'Menu Anchor Focus Scope');

  Widget _anchorBuilder(BuildContext context, MenuController controller, Widget? child) {
    final axis = _parentMenuScope?.axis;
    final isSubmenu = _parentMenuScope?.isSubmenu ?? false;
    final shortcuts = switch (axis) {
      Axis.vertical => {
          ..._kMenuVerticalTraversalShortcuts,
          switch (_textDirection) {
            TextDirection.ltr => const SingleActivator(LogicalKeyboardKey.arrowRight),
            TextDirection.rtl => const SingleActivator(LogicalKeyboardKey.arrowLeft),
          }: const CoreMenuEnterIntent.focusFirst(),
        },
      Axis.horizontal || null => {
          ..._kMenuHorizontalTraversalShortcuts,
          const SingleActivator(LogicalKeyboardKey.arrowDown):
              const CoreMenuEnterIntent.focusFirst(),
          if (!isSubmenu)
            const SingleActivator(LogicalKeyboardKey.arrowUp):
                const CoreMenuEnterIntent.focusLast(),
        }
    };
    return Actions(
      actions: <Type, Action<Intent>>{
        CoreMenuEnterIntent: CallbackAction<CoreMenuEnterIntent>(
          onInvoke: (CoreMenuEnterIntent intent) {
            if (_menuController.isOpen) {
              if (intent._scopeIntent != null) {
                _menuScopeNode.requestFocus();
                Actions.invoke(_menuScopeNode.context!, intent._scopeIntent);
              }
            } else {
              _menuController.open();
              _menuScopeNode.requestFocus();
              FocusManager.instance.applyFocusChangesIfNeeded();
              if (intent._scopeIntent != null) {
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  if (_menuController.isOpen) {
                    Actions.invoke(_menuScopeNode.context!, intent._scopeIntent);
                  }
                });
              }
            }
            return null;
          },
        ),
      },
      child: Shortcuts(
        includeSemantics: false,
        shortcuts: shortcuts,
        child: Builder(builder: (context) {
          return widget.builder?.call(context, controller, widget.child) ??
              widget.child ??
              const SizedBox();
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = Actions(
      actions: {
        DirectionalFocusIntent: DoNothingAction(),
      },
      child: Shortcuts(
        includeSemantics: false,
        shortcuts: _kStopDirectionalPropagationShortcuts,
        child: Focus(
          includeSemantics: false,
          focusNode: _trackingFocusNode,
          canRequestFocus: false,
          skipTraversal: true,
          descendantsAreTraversable: true,
          descendantsAreFocusable: true,
          onFocusChange: _handleFocusChange,
          child: RawMenuAnchor(
            useRootOverlay: widget.useRootOverlay,
            onOpen: _handleOpen,
            onClose: _handleClose,
            onOpenRequested: widget.onOpenRequest,
            onCloseRequested: widget.onCloseRequest,
            consumeOutsideTaps: widget.consumeOutsideTaps,
            controller: _menuController,
            overlayBuilder: _buildOverlay,
            builder: _anchorBuilder,
          ),
        ),
      ),
    );

    return child;
  }

  void _exitMenuActionCallback(Intent intent) {
    final parent = _parentMenuScope;
    if (parent != null && parent.isSubmenu && parent.axis == widget.axis) {
      _menuController.close();
      return;
    }

    FocusScope.of(context).previousFocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    Actions.maybeInvoke(context, intent);
  }

  Widget _buildOverlay(BuildContext context, RawMenuOverlayInfo position) {
    final Type intentType = switch (widget.axis) {
      Axis.vertical => _HorizontalFocusPreviousIntent,
      Axis.horizontal => _VerticalFocusPreviousIntent,
    };

    return Actions(
      actions: {
        intentType: CallbackAction(onInvoke: _exitMenuActionCallback),
      },
      child: _MenuOverlay(
        submenuAxis: widget.axis,
        position: position,
        alignmentOffset: widget.alignmentOffset,
        alignment: widget.alignment,
        menuAlignment: widget.menuAlignment,
        consumeOutsideTaps: widget.consumeOutsideTaps,
        padding: widget.padding,
        semanticProperties: widget.semanticProperties,
        overlayPadding: widget.overlayPadding,
        menuController: _menuController,
        focusScopeNode: _menuScopeNode,
        child: widget.panel,
      ),
    );
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.debug}) {
    return describeIdentity(this);
  }
}

class _CoreInlineMenu extends StatelessWidget {
  const _CoreInlineMenu({
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
          axis: _CoreMenuScope._maybeOf(context)!.axis,
          focusScopeNode: focusScopeNode,
          child: child,
        ),
      ),
    );
  }
}

class CoreMenuBar extends StatefulWidget {
  const CoreMenuBar({
    super.key,
    this.controller,
    required this.child,
    this.axis = Axis.horizontal,
    this.focusScopeNode,
    this.semanticProperties = const SemanticsProperties(
      scopesRoute: true,
      role: SemanticsRole.menuBar,
    ),
    this.onOpen,
    this.onClose,
  });
  final MenuController? controller;
  final Widget child;
  final Axis axis;
  final FocusScopeNode? focusScopeNode;
  final SemanticsProperties semanticProperties;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  @override
  State<CoreMenuBar> createState() => _CoreMenuBarState();
}

class _CoreMenuBarState extends State<CoreMenuBar> {
  MenuController? _internalMenuController;
  MenuController get _menuController => widget.controller ?? _internalMenuController!;

  FocusScopeNode? _internalFocusScopeNode;
  FocusScopeNode get _menuScopeNode => widget.focusScopeNode ?? _internalFocusScopeNode!;

  bool isMicrotaskScheduled = false;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalMenuController = MenuController();
    }

    if (widget.focusScopeNode == null) {
      _internalFocusScopeNode = FocusScopeNode(
        debugLabel: 'CoreMenuBar.focusScopeNode ${widget.axis}',
        traversalEdgeBehavior: TraversalEdgeBehavior.parentScope,
        directionalTraversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
      );
    }
  }

  @override
  void didUpdateWidget(CoreMenuBar oldWidget) {
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
          debugLabel: 'CoreMenuBar.focusScopeNode ${widget.axis}',
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

  bool _handleNotification(_MenuStateChangeNotification notification) {
    if (isMicrotaskScheduled) {
      return true;
    }

    isMicrotaskScheduled = true;
    scheduleMicrotask(() {
      isMicrotaskScheduled = false;
      if (_isOpen == _menuController.isOpen) {
        return;
      }

      _isOpen = _menuController.isOpen;
      if (_isOpen) {
        widget.onOpen?.call();
      } else {
        widget.onClose?.call();
      }
    });

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final group = Actions(
      actions: {
        NextFocusIntent: CallbackAction(
          onInvoke: (intent) {
            _menuScopeNode.enclosingScope?.nextFocus();
            return null;
          },
        ),
        PreviousFocusIntent: CallbackAction(
          onInvoke: (intent) {
            _menuScopeNode.enclosingScope?.previousFocus();
            return null;
          },
        )
      },
      child: RawMenuAnchorGroup(
        controller: _menuController,
        child: _CoreMenuScope(
          axis: widget.axis,
          isSubmenu: false,
          child: _CoreInlineMenu(
            semanticProperties: widget.semanticProperties,
            focusScopeNode: _menuScopeNode,
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.onOpen == null && widget.onClose == null) {
      return group;
    }
    return NotificationListener<_MenuStateChangeNotification>(
      onNotification: _handleNotification,
      child: group,
    );
  }
}

class _MenuFocusTraversal extends StatelessWidget {
  const _MenuFocusTraversal({
    required this.child,
    required this.focusScopeNode,
    required this.axis,
  });
  final Widget child;
  final FocusScopeNode focusScopeNode;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: WidgetOrderTraversalPolicy(),
      child: Shortcuts(
        shortcuts: axis == Axis.vertical
            ? _kMenuVerticalTraversalShortcuts
            : _kMenuHorizontalTraversalShortcuts,
        child: Actions(
          actions: {
            _MenuFocusFirstIntent: _MenuFocusFirstAction(focusScopeNode),
            _MenuFocusLastIntent: _MenuFocusLastAction(focusScopeNode),
            _MenuSetFirstFocusIntent: _MenuSetFirstFocusAction(focusScopeNode),
            ...switch (axis) {
              Axis.vertical => {
                  _VerticalFocusNextIntent: _TraverseNextAction(focusScopeNode),
                  _VerticalFocusPreviousIntent: _TraversePreviousAction(focusScopeNode)
                },
              Axis.horizontal => {
                  _HorizontalFocusNextIntent: _TraverseNextAction(focusScopeNode),
                  _HorizontalFocusPreviousIntent: _TraversePreviousAction(focusScopeNode)
                },
            },
          },
          child: FocusScope(
            node: focusScopeNode,
            canRequestFocus: true,
            descendantsAreFocusable: true,
            descendantsAreTraversable: true,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _MenuSetFirstFocusAction extends Action<_MenuSetFirstFocusIntent> {
  _MenuSetFirstFocusAction(this.focusScopeNode);
  final FocusScopeNode focusScopeNode;

  @override
  void invoke(_MenuSetFirstFocusIntent intent) {
    FocusScope.of(focusScopeNode.context!).setFirstFocus(focusScopeNode);
  }
}

class _TraverseNextAction extends Action<Intent> {
  _TraverseNextAction(this.focusScopeNode);
  final FocusScopeNode focusScopeNode;
  @override
  void invoke(Intent intent) {
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

class _TraversePreviousAction extends Action<Intent> {
  _TraversePreviousAction(this.focusScopeNode);
  final FocusScopeNode focusScopeNode;
  @override
  void invoke(Intent intent) {
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

class _MenuOverlay extends StatelessWidget {
  const _MenuOverlay({
    required this.alignmentOffset,
    required this.alignment,
    required this.menuAlignment,
    required this.position,
    required this.padding,
    required this.overlayPadding,
    required this.menuController,
    required this.focusScopeNode,
    required this.child,
    required this.semanticProperties,
    required this.consumeOutsideTaps,
    required this.submenuAxis,
  });

  final Offset alignmentOffset;
  final AlignmentGeometry? alignment;
  final AlignmentGeometry? menuAlignment;
  final RawMenuOverlayInfo position;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry overlayPadding;
  final bool consumeOutsideTaps;
  final MenuController menuController;
  final FocusScopeNode focusScopeNode;
  final Axis submenuAxis;
  final SemanticsProperties semanticProperties;

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
    final Widget panel = TapRegion(
      groupId: position.tapRegionGroupId,
      consumeOutsideTaps: consumeOutsideTaps,
      onTapOutside: (PointerDownEvent event) {
        menuController.close();
      },
      child: ListenableBuilder(
        listenable: focusScopeNode,
        builder: _buildConditionalTraversal,
        child: _CoreMenuScope(
          axis: submenuAxis,
          isSubmenu: true,
          child: _CoreInlineMenu(
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
          final displayFeatures = MediaQuery.maybeDisplayFeaturesOf(context);
          final TextDirection textDirection = Directionality.of(context);
          // Resolve fallback alignment here so that alignmentOffset defaults to
          // being directionally-agnostic.
          final anchorAlignment = (alignment ??
                  switch (_CoreMenuScope._maybeOf(context)?.axis) {
                    Axis.vertical => AlignmentDirectional.topEnd,
                    _ => AlignmentDirectional.bottomStart,
                  })
              .resolve(textDirection);

          return CustomSingleChildLayout(
            delegate: _MenuLayout(
              overlayPadding: overlayPadding.resolve(textDirection),
              padding: padding,
              avoidBounds: displayFeatures != null ? avoidBounds(displayFeatures) : const {},
              textDirection: textDirection,
              anchorRect: position.anchorRect,
              alignmentOffset: alignmentOffset,
              menuPosition: position.position,
              menuAlignment: menuAlignment ?? AlignmentDirectional.topStart,
              alignment: anchorAlignment,
            ),
            child: panel,
          );
        },
      ),
    );
  }

  static Set<ui.Rect> avoidBounds(List<ui.DisplayFeature> displayFeatures) {
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

class _MenuFocusFirstAction extends Action<_MenuFocusFirstIntent> {
  _MenuFocusFirstAction(this.focusScopeNode);
  final FocusScopeNode focusScopeNode;

  @override
  void invoke(_MenuFocusFirstIntent intent) {
    final FocusTraversalPolicy policy = FocusTraversalGroup.maybeOfNode(focusScopeNode)!;
    final FocusNode? firstNode = policy.findFirstFocus(focusScopeNode, ignoreCurrentFocus: true);
    if (firstNode != null) {
      policy.requestFocusCallback(firstNode);
    }
  }
}

class _MenuFocusLastAction extends Action<_MenuFocusLastIntent> {
  _MenuFocusLastAction(this.focusScopeNode);
  final FocusScopeNode focusScopeNode;

  @override
  void invoke(_MenuFocusLastIntent intent) {
    final FocusTraversalPolicy policy = FocusTraversalGroup.maybeOfNode(focusScopeNode)!;
    final FocusNode lastNode = policy.findLastFocus(focusScopeNode, ignoreCurrentFocus: true);
    policy.requestFocusCallback(lastNode);
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

  Offset _fitInsideScreen(
    Rect screen,
    Size childSize,
    Offset position,
    Offset anchorPosition,
  ) {
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
        ui.TextDirection.rtl => alignment is AlignmentDirectional
            ? Offset(-alignmentOffset.dx, alignmentOffset.dy)
            : alignmentOffset,
      };
    } else {
      anchorOffset = anchorRect.topLeft + menuPosition!;
    }

    final ui.Offset position =
        anchorOffset - menuAlignment.resolve(textDirection).alongSize(childSize);

    final Rect screen = _findClosestScreen(
      size,
      anchorRect.center,
      avoidBounds,
    );

    return _fitInsideScreen(
      screen,
      childSize,
      position,
      anchorOffset,
    );
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
