import 'dart:io';

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../menu_utilities.dart';
import 'panel.dart';

// These interfaces are used to limit duplicate documentation.

abstract mixin class BaseMenuInterface {
  /// The behavior to use when focus reaches the edge of the menu overlay while
  /// using directional focus traversal.
  ///
  /// Defaults to using [TraversalEdgeBehavior.stop] when [Platform.isMacOS] or
  /// [Platform.isIOS], and [TraversalEdgeBehavior.closedLoop] otherwise.
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

  /// Called when the menu is opened.
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
  RawMenuAnchorOpenRequestedCallback get onOpenRequest;

  /// Called when the menu overlay will close.
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
  BaseMenuOverlayChildBuilder? get overlayChildBuilder;

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
}

abstract interface class BaseControlInterface {
  /// Called when the button is tapped or otherwise activated.
  ///
  /// If this callback is null, then the button will be disabled.
  ///
  /// See also:
  ///
  ///  * [enabled], which is true if the button is enabled.
  VoidCallback? get onPressed;

  /// Called when the button is activated by a keyboard shortcut or other
  /// non-pointer input.
  ///
  /// If this callback is null, onPressed will be used instead. If both are
  /// null, the button will be disabled.
  ///
  /// Defaults to null, which means that [onPressed] will be used for activation.
  VoidCallback? get onActivate;

  /// Called when a pointer enters the menu item.
  PointerEnterEventListener? get onPointerEnter;

  /// Called when a pointer hovers over the menu item.
  PointerHoverEventListener? get onPointerHover;

  /// Called when a pointer exits the menu item.
  PointerExitEventListener? get onPointerLeave;

  /// Handler called when the [FocusNode] of this menu item gains or loses focus.
  ///
  /// Called with true if this widget's node gains focus, and false if it loses
  /// focus.
  ValueChanged<bool>? get onFocusChange;

  /// {@macro flutter.widgets.Focus.focusNode}
  FocusNode? get focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  bool get autofocus;

  /// How to behave during hit testing when deciding how the hit test propagates
  /// to children and whether to consider targets behind this one.
  ///
  /// Defaults to [HitTestBehavior.deferToChild].
  ///
  /// See [HitTestBehavior] for the allowed values and their meanings.
  HitTestBehavior get behavior;

  /// Whether this control obstructs hit testing for widgets behind it.
  bool get opaque;

  /// The mouse cursor to show when hovering over this menu item.
  WidgetStateProperty<MouseCursor>? get mouseCursor;

  /// Whether to exclude this menu item's tap gestures from the semantics tree.
  bool get gestureSemanticsEnabled;

  /// The delegate that controls how this menu item adds gestures to the
  /// semantics tree.
  SemanticsGestureDelegate? get gestureSemantics;

  /// The shortcuts that this control should respond to.
  ///
  /// This map allows overriding the default keyboard shortcuts for the control.
  ///
  /// By default, [BaseControl] handles:
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
  /// Returns true if [onPressed] is not null, and false otherwise.
  bool get enabled;

  /// The visual content of this menu item.
  ///
  /// [BaseMenuItem] doesn't specify how the menu item is visually styled, so
  /// the menu item content is fully customizable.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  Widget get child;
}

abstract interface class BaseMenuItemInterface extends BaseControlInterface {
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
