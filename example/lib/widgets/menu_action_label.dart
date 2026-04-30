import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:menu_utilities/menu_utilities.dart';

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
    this.isOpen,
  });

  final Axis axis;
  final Widget? leading;
  final double leadingWidth;
  final AlignmentGeometry leadingMidpointAlignment;
  final Widget? trailing;
  final MenuSerializableShortcut? shortcut;

  final bool? isOpen;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isOpen = this.isOpen ?? MenuController.maybeIsOpenOf(context) ?? false;
    return MenuActionLabel(
      leading: leading,
      leadingWidth: leadingWidth,
      leadingMidpointAlignment: leadingMidpointAlignment,
      decoration: isOpen
          ? WidgetStateProperty.all(
              const BoxDecoration(
                color: Color.from(red: 0.929726, green: 0.929726, blue: 0.929726, alpha: 1),
              ),
            )
          : null,
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

  static const _labelTextStyle = TextStyle(
    fontFamily: 'RobotoFlex',
    fontSize: 14,
    color: Color.from(alpha: 1, red: 0.122, green: 0.122, blue: 0.122),
    fontWeight: kIsWeb ? FontWeight.w500 : FontWeight.w400,
    fontVariations: kIsWeb ? [FontVariation.width(90)] : [],
    overflow: TextOverflow.ellipsis,
    height: 1.0,
    decoration: TextDecoration.none,
  );

  static const _acceleratorTextStyle = TextStyle(
    fontFamily: 'RobotoFlex',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    color: Color(0xFFAAAAAA),
    height: 20 / 14,
    decoration: TextDecoration.none,
  );

  static const _activatedDecoration = BoxDecoration(
    color: Color.from(alpha: 1, red: 0.929726, blue: 0.929726, green: 0.929726),
  );

  static const WidgetStateProperty<BoxDecoration> _decoration = WidgetStateProperty.fromMap({
    WidgetState.pressed: BoxDecoration(
      color: Color.from(alpha: 1, red: 0.912156, blue: 0.912156, green: 0.912156),
    ),
    WidgetState.focused: _activatedDecoration,
    WidgetState.any: BoxDecoration(),
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: _labelTextStyle,
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
                        data: const IconThemeData(
                          size: 18,
                          color: Color.fromRGBO(69, 71, 70, 1),
                          grade: 150,
                        ),
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
  const _Arrow({super.key});

  @override
  Widget build(BuildContext context) {
    final highlightArrow =
        CoreTappable.isHoveredOf(context) ||
        CoreTappable.isFocusedOf(context) ||
        MenuController.maybeIsOpenOf(context) == true;
    return highlightArrow
        ? const CustomPaint(
            size: Size(8, 8),
            painter: _ArrowPainter(
              color: Color.from(alpha: 1, red: 0.122, green: 0.122, blue: 0.122),
            ),
          )
        : const CustomPaint(
            size: Size(8, 8),
            painter: _ArrowPainter(
              color: Color.from(alpha: 0.502, red: 0.122, green: 0.122, blue: 0.122),
            ),
          );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
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
