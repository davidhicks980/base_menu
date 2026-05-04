import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../utilities/colors.dart';
import '../utilities/localized_shortcut_labeler.dart';
import 'widget_state_decorated_box.dart';

class SubmenuActionLabel extends StatelessWidget {
  const SubmenuActionLabel({
    super.key,
    required this.child,
    required this.axis,
    this.leadingWidth = 34,
    this.leadingMidpointAlignment = const AlignmentDirectional(0.23529412, 0),
    this.leading,
    this.trailing,
    this.shortcut,
  });

  final Axis axis;
  final Widget? leading;
  final double leadingWidth;
  final AlignmentGeometry leadingMidpointAlignment;
  final Widget? trailing;
  final MenuSerializableShortcut? shortcut;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MenuActionLabel(
      leading: leading,
      leadingWidth: leadingWidth,
      leadingMidpointAlignment: leadingMidpointAlignment,
      trailing: const _Arrow(),
      shortcut: shortcut,

      child: child,
    );
  }
}

class MenuActionLabel extends StatelessWidget {
  const MenuActionLabel({
    super.key,
    required this.child,
    this.decoration,
    this.leading,
    this.leadingWidth = 34,
    this.leadingMidpointAlignment = const AlignmentDirectional(0.23529412, 0),
    this.trailing,
    this.shortcut,
  });

  final Widget? leading;
  final double leadingWidth;
  final AlignmentGeometry leadingMidpointAlignment;
  final WidgetStateProperty<Decoration>? decoration;
  final Widget? trailing;
  final MenuSerializableShortcut? shortcut;
  final Widget child;

  static const labelTextStyle = TextStyle(
    fontFamily: 'RobotoFlex',
    fontSize: kIsWeb ? 14.25 : 14,
    color: FloogleColors.darkGray,
    fontWeight: kIsWeb ? FontWeight(475) : FontWeight.w400,
    fontVariations: kIsWeb ? [FontVariation.width(96)] : [],
    overflow: TextOverflow.ellipsis,
    letterSpacing: kIsWeb ? 0.1 : 0.2,
    height: 1.0,
    decoration: TextDecoration.none,
  );

  static const _acceleratorTextStyle = TextStyle(
    fontFamily: 'RobotoFlex',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    color: FloogleColors.lightGray,
    height: 20 / 14,
    decoration: TextDecoration.none,
  );

  static const WidgetStateProperty<BoxDecoration> _decoration = WidgetStateProperty.fromMap({
    WidgetState.pressed: BoxDecoration(color: FloogleColors.menuItemPressedColor),
    WidgetState.focused: BoxDecoration(color: FloogleColors.menuItemFocusColor),
    WidgetState.any: BoxDecoration(),
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: labelTextStyle,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      softWrap: false,
      child: WidgetStateDecoratedBox(
        decoration: decoration ?? _decoration,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            SizedBox(
              width: leadingWidth,
              child: leading != null
                  ? _AlignMidpoint(
                      alignment: leadingMidpointAlignment,
                      child: IconTheme.merge(
                        data: const IconThemeData(size: 18, color: FloogleColors.grey, grade: 150),
                        child: leading!,
                      ),
                    )
                  : null,
            ),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 512, minHeight: 33),
                child: Align(alignment: Alignment.centerLeft, child: child),
              ),
            ),
            const SizedBox(width: 16),
            if (shortcut != null)
              _ShortcutLabel(accelTextStyle: _acceleratorTextStyle, shortcut: shortcut),
            if (trailing != null) trailing!,
            const SizedBox(width: 15),
          ],
        ),
      ),
    );
  }
}

class _ShortcutLabel extends StatelessWidget {
  const _ShortcutLabel({required this.accelTextStyle, required this.shortcut});

  final TextStyle accelTextStyle;
  final MenuSerializableShortcut? shortcut;

  @override
  Widget build(BuildContext context) {
    var label = LocalizedShortcutLabeler.instance.getShortcutLabel(
      shortcut!,
      MaterialLocalizations.of(context),
    );
    if (label.length <= 3) {
      label = label.replaceAll(RegExp(r'\s'), '');
    } else {
      label = label.replaceAll(RegExp(r'\s'), '+');
    }
    return DefaultTextStyle(style: accelTextStyle, child: Text(label));
  }
}

class _AlignMidpoint extends SingleChildRenderObjectWidget {
  const _AlignMidpoint({required this.alignment, required super.child});
  final AlignmentGeometry alignment;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderAlignMidpoint(
      alignment: alignment,
      textDirection: Directionality.maybeOf(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderAlignMidpoint renderObject) {
    renderObject
      ..alignment = alignment
      ..textDirection = Directionality.maybeOf(context);
  }
}

class _RenderAlignMidpoint extends RenderPositionedBox {
  _RenderAlignMidpoint({super.alignment, super.textDirection});

  @override
  void alignChild() {
    assert(child != null);
    assert(!child!.debugNeedsLayout);
    assert(child!.hasSize);
    assert(hasSize);
    final childParentData = child!.parentData! as BoxParentData;
    final ui.Offset offset = resolvedAlignment.alongSize(size) - child!.size.center(Offset.zero);
    final double dx = ui.clampDouble(offset.dx, 0.0, size.width - child!.size.width);
    final double dy = ui.clampDouble(offset.dy, 0.0, size.height - child!.size.height);

    childParentData.offset = Offset(dx, dy);
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow();

  @override
  Widget build(BuildContext context) {
    final highlightArrow =
        CoreButton.isHoveredOf(context) ||
        CoreButton.isFocusedOf(context) ||
        MenuController.maybeIsOpenOf(context) == true;
    return highlightArrow
        ? const CustomPaint(
            size: Size(8, 8),
            painter: _ArrowPainter(color: FloogleColors.darkGray),
          )
        : const CustomPaint(
            size: Size(8, 8),
            painter: _ArrowPainter(color: FloogleColors.darkGray, opacity: 0.5),
          );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.color, this.opacity = 1});
  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final vertices = ui.Vertices(ui.VertexMode.triangles, [
      Offset.zero,
      Offset(size.width, size.height / 2),
      Offset(0, size.height),
    ]);

    canvas.drawVertices(vertices, BlendMode.srcOver, paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) => color != oldDelegate.color;
}
