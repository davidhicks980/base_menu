import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../menu_utilities.dart';

abstract class BaseMenuInterface {
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

  /// The widget that this [BaseMenu] surrounds.
  ///
  /// Typically, this is a button used to open the menu by calling
  /// [MenuController.open] on the `controller` passed to the builder.
  ///
  /// If not supplied, then the [BaseMenu] will be the size that its parent
  /// allocates for it.
  RawMenuAnchorChildBuilder? get builder;

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

  // The menu panel that is displayed when the menu is opened.
  //
  // The panel should lay out its menu children in a vertical list.
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
  BaseMenuPositioningDelegate get positioningDelegate;

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
