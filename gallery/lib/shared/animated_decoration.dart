import 'package:flutter/widgets.dart';

class AnimatedDecoration extends ImplicitlyAnimatedWidget {
  const AnimatedDecoration({
    super.key,
    required this.decoration,
    required super.duration,
    super.curve = Curves.linear,
    this.position = DecorationPosition.background,
    required this.child,
  });

  final Decoration decoration;
  final DecorationPosition position;
  final Widget child;

  @override
  AnimatedWidgetBaseState<AnimatedDecoration> createState() => _AnimatedDecorationState();
}

class _AnimatedDecorationState extends AnimatedWidgetBaseState<AnimatedDecoration> {
  DecorationTween? _decoration;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _decoration =
        visitor(
              _decoration,
              widget.decoration,
              (dynamic value) => DecorationTween(begin: value as Decoration),
            )
            as DecorationTween?;
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _decoration!.evaluate(animation),
      position: widget.position,
      child: widget.child,
    );
  }
}
