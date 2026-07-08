import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

@internal
abstract interface class BaseHoverableInterface {
  /// Called when a pointer enters this widget.
  ///
  /// This callback is not called when [enabled] is false.
  ///
  /// See [MouseRegion.onEnter] for more details.
  PointerEnterEventListener? get onPointerEnter;

  /// Called when a pointer moves within the bounds of this widget.
  ///
  /// This callback is not called when [enabled] is false.
  ///
  /// See [MouseRegion.onHover] for more details.
  PointerHoverEventListener? get onPointerHover;

  /// Called when a pointer exits this widget.
  ///
  /// This callback is not called when [enabled] is false.
  ///
  /// See [MouseRegion.onExit] for more details.
  PointerExitEventListener? get onPointerExit;

  /// How to behave during hit testing when deciding how the hit test propagates
  /// to children and whether to consider targets behind this one.
  ///
  /// Defaults to [HitTestBehavior.deferToChild].
  ///
  /// See [HitTestBehavior] for the allowed values and their meanings.
  HitTestBehavior get behavior;

  /// Whether this widget should prevent other [MouseRegion]s visually behind it
  /// from detecting the pointer.
  ///
  /// See [MouseRegion.opaque] for more details.
  bool get opaque;
}

@internal
abstract interface class BaseFocusableInterface {
  /// An optional focus node to use as the focus node for this widget.
  ///
  /// If a focus node is provided, it is the responsibility of the parent widget
  /// to manage the lifecycle of the focus node, including disposing it when it
  /// is no longer needed.
  FocusNode? get focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  bool get autofocus;

  /// Handler called when the focus changes.
  ///
  /// Invoked with true when this widget or a descendant widget acquires focus,
  /// and false when it resigns it.
  ///
  /// See also:
  ///
  ///  * [isFocusedOf], which will rebuild the provided [BuildContext] whenever
  ///    the focus state of the nearest ancestor [BaseFocusable] changes.
  ///  * [isFocusHighlightShownOf], which will rebuild the provided
  ///    [BuildContext] whenever the focus highlight state of the nearest
  ///    ancestor [BaseFocusable] changes.
  ValueChanged<bool>? get onFocusChange;
}

@internal
abstract interface class BaseControlInterface
    implements BaseHoverableInterface, BaseFocusableInterface {
  /// Called when the button is tapped or otherwise activated.
  ///
  /// If [onPressed] and [onActivate] are null, then the button will be
  /// disabled.
  ///
  /// Defaults to null.
  ///
  /// **See also:**
  ///
  ///  * [enabled], which is false if both [onPressed] and [onActivate] are null.
  VoidCallback? get onPressed;

  /// Called when the button is activated by a keyboard shortcut or other
  /// non-pointer input.
  ///
  /// If this callback is null, [onPressed] will be used instead. If both are
  /// null, the button will be disabled.
  ///
  /// Defaults to null.
  ///
  /// **See also:**
  ///
  ///  * [enabled], which is false if both [onPressed] and [onActivate] are null.
  VoidCallback? get onActivate;

  /// The mouse cursor to show when hovering over this menu item.
  WidgetStateProperty<MouseCursor>? get mouseCursor;

  /// Whether to exclude this widget's tap gestures from the semantics tree.
  bool get gestureSemanticsEnabled;

  /// The delegate that controls how this widget adds gestures to the
  /// semantics tree.
  SemanticsGestureDelegate? get gestureSemantics;

  /// The shortcuts that this control should respond to.
  ///
  /// This map allows overriding the default keyboard shortcuts for the control.
  ///
  /// By default, this control handles:
  ///  * [LogicalKeyboardKey.space]:
  ///    * Triggers [DoNothingAndStopPropagationIntent] on **key down**.
  ///    * Triggers [ActivateIntent] on **key up**
  ///  * [LogicalKeyboardKey.enter]:
  ///    * KeyDown triggers [ButtonActivateIntent] on web.
  ///    * KeyDown triggers [ActivateIntent] on all other platforms.
  ///
  /// If [shortcuts] is supplied, it will override the default shortcuts.
  ///
  /// The [ActivateIntent] and [ButtonActivateIntent] actions are overrideable,
  /// meaning any ancestor [Actions] widget containing actions for these intents
  /// will take precedence over the default behavior of activating the control.
  Map<ShortcutActivator, Intent>? get shortcuts;

  /// Whether this control can be interacted with.
  ///
  /// Returns false if both [onPressed] and [onActivate] are null, and true otherwise.
  bool get enabled;

  /// The visual content of this control.
  ///
  /// This widget doesn't specify any visual styling or layout, so it is up to
  /// the implementer to provide a [child] that is visually appropriate for the
  /// control. This widget will match the size of the [child] and will not
  /// impose any additional constraints.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  Widget get child;
}

@internal
abstract interface class BaseMenuItemInterface implements BaseControlInterface {
  /// Whether hovering over this menu item should request focus.
  ///
  /// Defaults to true.
  bool get requestFocusOnHover;

  /// Whether activating this menu item should request to close the menu.
  ///
  /// Defaults to true.
  bool get requestCloseOnActivate;

  /// The semantic role assigned to this menu item.
  ///
  /// To disable semantics for this menu item, set [role] to null.
  ///
  /// Defaults to [SemanticsRole.menuItem].
  SemanticsRole? get role;
}

@internal
abstract interface class BaseMenuInterface {
  /// The behavior to use when focus reaches the edge of the menu overlay while
  /// using directional focus traversal.
  ///
  /// Defaults to using [TraversalEdgeBehavior.stop] when
  /// [defaultTargetPlatform] is [TargetPlatform.macOS] or
  /// [TargetPlatform.iOS], and [TraversalEdgeBehavior.closedLoop] otherwise.
  TraversalEdgeBehavior? get directionalFocusEdgeBehavior;

  /// An optional [MenuController] that allows opening and closing of the menu
  /// from other widgets.
  ///
  /// If not supplied, a new [MenuController] will be created and managed by the
  /// [BaseMenu].
  MenuController? get controller;

  /// Whether or not a tap event that closes the menu will be permitted to
  /// continue on to the gesture arena.
  ///
  /// When false, tapping outside of a menu when the menu is open will both
  /// close the menu, and allow the tap to participate in the gesture arena.
  ///
  /// When true, tapping outside of a menu will only close the menu, and the tap
  /// event will be consumed.
  ///
  /// Defaults to false.
  bool get consumeOutsideTaps;

  /// Called when the menu overlay is shown.
  ///
  /// If no close requests are made, the menu will be mounted in the next frame.
  VoidCallback? get onOpen;

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
  /// The callback's `position` argument is the `position` that
  /// [MenuController.open] was called with.
  ///
  /// A typical [onOpenRequested] consists of the following steps:
  ///
  ///  1. Optional delay.
  ///  2. Call `showOverlay` (whose call chain eventually invokes [onOpen]).
  ///  3. Optionally start the opening animation.
  ///
  /// Defaults to a callback that immediately shows the menu.
  RawMenuAnchorOpenRequestedCallback get onOpenRequest;

  /// Called when the menu overlay will be hidden.
  ///
  /// The menu will be unmounted in the next frame unless the menu is reopened.
  VoidCallback? get onClose;

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
  RawMenuAnchorCloseRequestedCallback get onCloseRequest;

  /// The optional child to be passed to the [builder].
  ///
  /// Supply this child if there is a portion of the widget tree built in
  /// [builder] that doesn't depend on the `controller` or `context` supplied to
  /// the [builder]. It will be more efficient, since Flutter doesn't then need
  /// to rebuild this child when those change.
  Widget? get child;

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
  bool get useRootOverlay;

  /// A widget containing the contents of the menu. This widget will only be
  /// displayed when the menu is open.
  ///
  /// Typically, this is a [BaseMenuPanel] that displays a list of menu items,
  /// but it can be any widget.
  Widget get menu;

  /// Called when focus enters or leaves the menu overlay and its descendants.
  ValueChanged<bool>? get onFocusChange;

  /// Properties used to annotate the menu overlay.
  SemanticsProperties get semanticProperties;

  /// The orientation in which the menu's children should be traversed.
  ///
  /// If [orientation] is [Axis.vertical], then the menu's children are
  /// traversed from top to bottom. If [orientation] is [Axis.horizontal], then
  /// the menu's children are traversed from left to right when the ambient
  /// [Directionality] is [TextDirection.ltr] and from right to left when the
  /// ambient [Directionality] is [TextDirection.rtl].
  Axis get orientation;

  /// A delegate that controls how the menu is positioned.
  MenuPositioningDelegate get positionDelegate;

  /// An optional builder that wraps the menu overlay.
  ///
  /// This builder is passed the entire menu overlay, not just the visual menu
  /// panel. As a result, it can be used to add widgets that should be outside
  /// of the menu panel, such as a barrier that dismisses the menu when tapped.
  MenuOverlayChildBuilder? get overlayChildBuilder;
}

/// Signature for a callback that builds a widget that surrounds the overlay of
/// a [BaseMenu].
typedef MenuOverlayChildBuilder = Widget Function(BuildContext context, Widget child);

/// A delegate that builds a widget that positions the menu panel of a [BaseMenu].
abstract interface class MenuPositioningDelegate {
  /// Builds a widget that positions the menu panel [child] using the provided
  /// [position] information.
  Widget build(BuildContext context, RawMenuOverlayInfo position, Widget child);
}
