import 'dart:ui' as ui show Clip;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'menu.dart';

/// A widget that displays menu items in a linear layout along a given
/// [orientation].
///
/// [BaseMenuPanel] does not provide any visual styling. To style the menu
/// surface, wrap [BaseMenuPanel] in a [Container] or [DecoratedBox].
///
/// [BaseMenuPanel] automatically lays out its [children] along the provided
/// [orientation]. If [orientation] is null, the [orientation] of the nearest
/// ancestor [BaseMenu] is used. If there is no ancestor [BaseMenu], the
/// [orientation] defaults to [Axis.vertical].
///
/// The [onPointerEnter], [onPointerExit], and [onPointerHover] callbacks are
/// triggered when the pointer enters, exits, or hovers over a hit-testable
/// child of the panel. This is useful for implementing common desktop menu
/// behavior, such as focusing the menu anchor button when [onPointerExit] is
/// triggered.
class BaseMenuPanel extends StatelessWidget {
  /// Creates a [BaseMenuPanel].
  ///
  /// The [children] argument is required.
  const BaseMenuPanel({
    super.key,
    this.constraints,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisSize = MainAxisSize.min,
    this.verticalDirection = VerticalDirection.down,
    this.padding = EdgeInsets.zero,
    this.scrollPadding = EdgeInsets.zero,
    this.scrollable = true,
    this.spacing = 0,
    this.clipBehavior = Clip.none,
    this.onPointerEnter,
    this.onPointerExit,
    this.onPointerHover,
    this.orientation,
    this.textBaseline,
    required this.children,
  }) : assert(
         identical(scrollPadding, EdgeInsets.zero) || scrollable,
         'scrollPadding is ignored when scrollable is false',
       ),
       assert(
         !identical(crossAxisAlignment, CrossAxisAlignment.baseline) || textBaseline != null,
         'textBaseline is required if you specify the crossAxisAlignment with CrossAxisAlignment.baseline',
       );

  /// The constraints to apply to the menu surface.
  ///
  /// If null, the menu will be allowed to expand to the intrinsic size of its
  /// children.
  final BoxConstraints? constraints;

  /// The menu items that should be displayed by this [BaseMenuPanel].
  final List<Widget> children;

  /// How the children should be placed along the main axis.
  ///
  /// For example, [MainAxisAlignment.start], the default, places the children
  /// at the start (i.e., the left for a [Row] or the top for a [Column]) of the
  /// main axis.
  final MainAxisAlignment mainAxisAlignment;

  /// How much space should be occupied in the main axis.
  ///
  /// After allocating space to children, there might be some remaining free
  /// space. This value controls whether to maximize or minimize the amount of
  /// free space, subject to the incoming layout constraints.
  ///
  /// If some children have a non-zero flex factors (and none have a fit of
  /// [FlexFit.loose]), they will expand to consume all the available space and
  /// there will be no remaining free space to maximize or minimize, making this
  /// value irrelevant to the final layout.
  final MainAxisSize mainAxisSize;

  /// How the children should be placed along the cross axis.
  ///
  /// For example, [CrossAxisAlignment.center], the default, centers the
  /// children in the cross axis (e.g., horizontally for a [Column]).
  ///
  /// When the cross axis is vertical (as for a [Row]) and the children
  /// contain text, consider using [CrossAxisAlignment.baseline] instead.
  /// This typically produces better visual results if the different children
  /// have text with different font metrics, for example because they differ in
  /// [TextStyle.fontSize] or other [TextStyle] properties, or because
  /// they use different fonts due to being written in different scripts.
  final CrossAxisAlignment crossAxisAlignment;

  /// Determines the order to lay children out vertically and how to interpret
  /// `start` and `end` in the vertical direction.
  ///
  /// Defaults to [VerticalDirection.down].
  ///
  /// If the [direction] is [Axis.vertical], this controls which order children
  /// are painted in (down or up), the meaning of the [mainAxisAlignment]
  /// property's [MainAxisAlignment.start] and [MainAxisAlignment.end] values.
  ///
  /// If the [direction] is [Axis.vertical], and either the [mainAxisAlignment]
  /// is either [MainAxisAlignment.start] or [MainAxisAlignment.end], or there's
  /// more than one child, then the [verticalDirection] must not be null.
  ///
  /// If the [direction] is [Axis.horizontal], this controls the meaning of the
  /// [crossAxisAlignment] property's [CrossAxisAlignment.start] and
  /// [CrossAxisAlignment.end] values.
  ///
  /// If the [direction] is [Axis.horizontal], and the [crossAxisAlignment] is
  /// either [CrossAxisAlignment.start] or [CrossAxisAlignment.end], then the
  /// [verticalDirection] must not be null.
  final VerticalDirection verticalDirection;

  /// If aligning items according to their baseline, which baseline to use.
  ///
  /// This must be set if using baseline alignment. There is no default because there is no
  /// way for the framework to know the correct baseline _a priori_.
  final TextBaseline? textBaseline;

  /// The [EdgeInsetsGeometry] applied to the menu surface.
  ///
  /// When a [BaseMenuPanel] is used with a [BaseMenu], [padding] applied to the
  /// menu surface can be ignored during layout by supplying an equivalent
  /// amount of [padding] to the [BaseMenu.positionDelegate]. This is useful
  /// when aligning a submenu with its anchor.
  ///
  /// Defaults to null, which applies no padding.
  final EdgeInsetsGeometry padding;

  /// The [EdgeInsetsGeometry] applied within the scrollable area of the menu
  /// surface.
  ///
  /// The [scrollable] property must be true for this property to have any
  /// effect. If [scrollable] is false, this property is ignored.
  final EdgeInsetsGeometry scrollPadding;

  /// The spacing to apply between menu items.
  ///
  /// Defaults to 0, which applies no spacing.
  final double spacing;

  /// The orientation in which the menu items are displayed.
  final Axis? orientation;

  /// The [ui.Clip] applied to the panel's scrollable.
  final ui.Clip clipBehavior;

  /// Called when a pointer enters any hit-testable member of [children].
  final PointerEnterEventListener? onPointerEnter;

  /// Called when a pointer leaves all hit-testable [children].
  ///
  /// This callback is intended to be used to focus the menu anchor button when
  /// the pointer enters the menu surface, which is a common behavior in desktop
  /// menus.
  ///
  /// If a [child] is wrapped in an [IgnorePointer], it will not trigger this
  /// callback.
  final PointerExitEventListener? onPointerExit;

  /// Called when a pointer hovers over a hit-testable member of [children].
  final PointerHoverEventListener? onPointerHover;

  /// Whether the menu panel should be scrollable when its contents exceed the
  /// available space within the overlay.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final Axis orientation = this.orientation ?? MenuScope.maybeOf(context)?.axis ?? Axis.vertical;
    Widget child = Flex(
      direction: orientation,
      mainAxisSize: mainAxisSize,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      verticalDirection: verticalDirection,
      spacing: spacing,
      textBaseline: textBaseline,
      children: children,
    );

    if (onPointerEnter != null || onPointerExit != null || onPointerHover != null) {
      child = MouseRegion(
        onEnter: onPointerEnter,
        onExit: onPointerExit,
        onHover: onPointerHover,
        opaque: false,
        hitTestBehavior: .deferToChild,
        child: child,
      );
    }

    if (scrollable) {
      child = SingleChildScrollView(
        scrollDirection: orientation,
        clipBehavior: clipBehavior,
        padding: scrollPadding,
        child: child,
      );
    } else {
      child = ClipRect(clipBehavior: clipBehavior, child: child);
    }

    child = Padding(padding: padding, child: child);

    var applyIntrinsics = true;
    if (constraints != null) {
      child = ConstrainedBox(constraints: constraints!, child: child);
      applyIntrinsics = switch (orientation) {
        Axis.vertical => !constraints!.hasTightWidth,
        Axis.horizontal => !constraints!.hasTightHeight,
      };
    }

    if (applyIntrinsics) {
      return switch (orientation) {
        Axis.vertical => IntrinsicWidth(child: child),
        Axis.horizontal => IntrinsicHeight(child: child),
      };
    }

    return child;
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[for (final Widget child in children) child.toDiagnosticsNode()];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    // Layout Constraints
    properties.add(DiagnosticsProperty('constraints', constraints, defaultValue: null));

    // Flex Layout Properties
    properties.add(
      EnumProperty('mainAxisAlignment', mainAxisAlignment, defaultValue: MainAxisAlignment.start),
    );
    properties.add(EnumProperty('mainAxisSize', mainAxisSize, defaultValue: MainAxisSize.min));
    properties.add(
      EnumProperty(
        'crossAxisAlignment',
        crossAxisAlignment,
        defaultValue: CrossAxisAlignment.stretch,
      ),
    );
    properties.add(
      EnumProperty('verticalDirection', verticalDirection, defaultValue: VerticalDirection.down),
    );

    // Conditionally show textBaseline: only relevant if baseline alignment is used.
    properties.add(
      EnumProperty(
        'textBaseline',
        textBaseline,
        defaultValue: null,
        level: crossAxisAlignment == CrossAxisAlignment.baseline
            ? DiagnosticLevel.info
            : DiagnosticLevel.hidden,
      ),
    );

    // Spacing and Padding
    properties.add(DoubleProperty('spacing', spacing, defaultValue: 0));
    properties.add(DiagnosticsProperty('padding', padding, defaultValue: EdgeInsets.zero));

    // Only show scrollPadding if the menu is actually scrollable.
    properties.add(
      DiagnosticsProperty(
        'scrollPadding',
        scrollPadding,
        defaultValue: EdgeInsets.zero,
        level: scrollable ? DiagnosticLevel.info : DiagnosticLevel.hidden,
      ),
    );

    // Use a flag for non-scrollable status to make it stand out only when it's NOT the default.
    properties.add(
      FlagProperty('scrollable', value: scrollable, ifFalse: 'non-scrollable', defaultValue: true),
    );

    // Inherited/Optional
    properties.add(EnumProperty('orientation', orientation, defaultValue: null));
    properties.add(EnumProperty('clipBehavior', clipBehavior, defaultValue: ui.Clip.none));

    // Listener Flags
    // These are omitted entirely if null because ObjectFlagProperty.has only shows "has ..."
    // when the value is present.
    properties.add(ObjectFlagProperty.has('onPointerEnter', onPointerEnter));
    properties.add(ObjectFlagProperty.has('onPointerExit', onPointerExit));
    properties.add(ObjectFlagProperty.has('onPointerHover', onPointerHover));
  }
}
