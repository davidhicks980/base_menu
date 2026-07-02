import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class Range extends StatefulWidget {
  const Range({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.knobDecoration,
    this.trackDecoration,
    this.knobRadius,
    this.thickness = 12.0,
    this.axis = Axis.horizontal,
    this.direction,
  })  : assert(value >= min && value <= max),
        assert(divisions == null || divisions > 0);

  final double value;
  final Axis axis;

  final ValueChanged<double>? onChanged;

  final ValueChanged<double>? onChangeStart;

  final ValueChanged<double>? onChangeEnd;

  final double min;

  final double max;

  final int? divisions;

  // final BoxDecoration? activePaint;

  final Decoration? knobDecoration;

  final Decoration? trackDecoration;

  final double thickness;
  final double? knobRadius;
  final SliderDirection? direction;

  @override
  State<Range> createState() => _RangeState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('value', value));
    properties.add(DoubleProperty('min', min));
    properties.add(DoubleProperty('max', max));
  }
}

class _RangeState extends State<Range> with TickerProviderStateMixin {
  void _handleChanged(double value) {
    assert(widget.onChanged != null);
    final double lerpValue = ui.lerpDouble(widget.min, widget.max, value)!;
    if (lerpValue != widget.value) {
      widget.onChanged!(lerpValue);
    }
  }

  void _handleDragStart(double value) {
    assert(widget.onChangeStart != null);
    widget.onChangeStart!(ui.lerpDouble(widget.min, widget.max, value)!);
  }

  void _handleDragEnd(double value) {
    assert(widget.onChangeEnd != null);
    widget.onChangeEnd!(ui.lerpDouble(widget.min, widget.max, value)!);
  }

  @override
  Widget build(BuildContext context) {
    return _RangeRenderObjectWidget(
      value: (widget.value - widget.min) / (widget.max - widget.min),
      divisions: widget.divisions,
      knobPaint: widget.knobDecoration ??
          const BoxDecoration(
            color: CupertinoColors.white,
          ),
      trackPaint: widget.trackDecoration ??
          const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CupertinoColors.systemGrey5,
                CupertinoColors.systemGrey5,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
      onChanged: widget.onChanged != null ? _handleChanged : null,
      onChangeStart: widget.onChangeStart != null ? _handleDragStart : null,
      onChangeEnd: widget.onChangeEnd != null ? _handleDragEnd : null,
      direction: widget.direction,
      vsync: this,
      thickness: widget.thickness,
      knobRadius: widget.knobRadius ?? (widget.thickness / 1.5),
    );
  }
}

class _RangeRenderObjectWidget extends LeafRenderObjectWidget {
  const _RangeRenderObjectWidget({
    this.divisions,
    this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.direction,
    required this.value,
    required this.knobPaint,
    required this.trackPaint,
    required this.thickness,
    required this.knobRadius,
    required this.vsync,
  });

  final double value;
  final double thickness;
  final double knobRadius;
  final int? divisions;
  final Decoration knobPaint;
  final Decoration trackPaint;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final TickerProvider vsync;
  final SliderDirection? direction;

  BoxConstraints get _constraints => BoxConstraints.tightFor(
        width: math.max(knobRadius * 2, thickness),
        height: 44,
      );

  @override
  _RenderRange createRenderObject(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    return _RenderRange(
        value: value,
        divisions: divisions,
        // activePaint: activePaint,
        knobDecoration: knobPaint,
        trackDecoration: trackPaint,
        thickness: thickness,
        knobRadius: knobRadius,
        additionalConstraints: _constraints,
        onChanged: onChanged,
        onChangeStart: onChangeStart,
        onChangeEnd: onChangeEnd,
        vsync: vsync,
        cursor: kIsWeb ? SystemMouseCursors.click : MouseCursor.defer,
        direction: direction ??
            switch (Directionality.of(context)) {
              TextDirection.rtl => SliderDirection.rightToLeft,
              TextDirection.ltr => SliderDirection.leftToRight,
            });
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderRange renderObject,
  ) {
    assert(debugCheckHasDirectionality(context));
    renderObject
      ..value = value
      ..divisions = divisions
      // ..activeDecoration = activePaint
      ..knobDecoration = knobPaint
      ..trackDecoration = trackPaint
      ..additionalConstraints = _constraints
      ..onChanged = onChanged
      ..onChangeStart = onChangeStart
      ..onChangeEnd = onChangeEnd
      ..thickness = thickness
      ..knobRadius = knobRadius
      ..direction = direction ??
          switch (Directionality.of(context)) {
            TextDirection.rtl => SliderDirection.rightToLeft,
            TextDirection.ltr => SliderDirection.leftToRight,
          };
    // Ticker provider cannot change since there's a 1:1 relationship between
    // the _SliderRenderObjectWidget object and the _SliderState object.
  }
}

const Duration _kDiscreteTransitionDuration = Duration(milliseconds: 500);

const double _kAdjustmentUnit =
    0.1; // Matches iOS implementation of material slider.

enum SliderDirection {
  topToBottom,
  bottomToTop,
  leftToRight,
  rightToLeft,
}

class _RenderRange extends RenderConstrainedBox
    implements MouseTrackerAnnotation {
  _RenderRange({
    required double value,
    int? divisions,
    // required BoxDecoration activePaint,
    required Decoration knobDecoration,
    required Decoration trackDecoration,
    required double thickness,
    required double knobRadius,
    SliderDirection direction = SliderDirection.topToBottom,
    ValueChanged<double>? onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    required TickerProvider vsync,
    MouseCursor cursor = MouseCursor.defer,
    required super.additionalConstraints,
  })  : assert(value >= 0.0 && value <= 1.0),
        _cursor = cursor,
        _value = value,
        _divisions = divisions,
        _knobDecoration = knobDecoration,
        _trackDecoration = trackDecoration,
        _onChanged = onChanged,
        _thickness = thickness,
        _direction = direction,
        _knobRadius = knobRadius {
    _updateAdditionalConstraints();
    _resetGestures(direction);
    _position = AnimationController(
      value: value,
      duration: _kDiscreteTransitionDuration,
      vsync: vsync,
    )..addListener(() {
        _value = _position.value;
        markNeedsPaint();
      });
  }

  SliderDirection get direction => _direction;
  SliderDirection _direction;
  set direction(SliderDirection value) {
    if (_direction != value) {
      _direction = value;
      _resetGestures(value);
      markNeedsPaint();
    }
  }

  void _resetGestures(SliderDirection value) {
    _drag?.dispose();
    _tap?.dispose();
    switch (value) {
      case SliderDirection.topToBottom:
      case SliderDirection.bottomToTop:
        _drag = VerticalDragGestureRecognizer()
          ..onStart = _handleDragStart
          ..onUpdate = _handleDragUpdate
          ..onEnd = _handleDragEnd;
        _tap = TapGestureRecognizer()..onTapDown = _handleTap;
        break;
      case SliderDirection.leftToRight:
      case SliderDirection.rightToLeft:
        _drag = HorizontalDragGestureRecognizer()
          ..onStart = _handleDragStart
          ..onUpdate = _handleDragUpdate
          ..onEnd = _handleDragEnd;
        _tap = TapGestureRecognizer()..onTapDown = _handleTap;
        break;
    }
  }

  double get value => _value;
  double _value;
  set value(double newValue) {
    assert(newValue >= 0.0 && newValue <= 1.0);
    if (newValue == _value) {
      return;
    }
    _value = newValue;
    if (divisions != null) {
      _position.animateTo(newValue, curve: Curves.fastOutSlowIn);
    } else {
      _position.value = newValue;
    }
    markNeedsSemanticsUpdate();
  }

  int? get divisions => _divisions;
  int? _divisions;
  set divisions(int? value) {
    if (value == _divisions) {
      return;
    }
    _divisions = value;
    markNeedsPaint();
  }

  Decoration get knobDecoration => _knobDecoration;
  Decoration _knobDecoration;
  BoxPainter? _knobPainter;
  set knobDecoration(Decoration value) {
    if (value == _knobDecoration) {
      return;
    }
    _knobDecoration = value;
    _knobPainter?.dispose();
    _knobPainter = null;
    markNeedsPaint();
  }

  Decoration get trackDecoration => _trackDecoration;
  Decoration _trackDecoration;
  BoxPainter? _trackPainter;
  set trackDecoration(Decoration value) {
    if (value != _trackDecoration) {
      _trackDecoration = value;
      _trackPainter?.dispose();
      _trackPainter = null;
      markNeedsPaint();
    }
  }

  double get thickness => _thickness;
  double _thickness;
  set thickness(double value) {
    if (value != _thickness) {
      _thickness = value;
      _updateAdditionalConstraints();
      markNeedsPaint();
    }
  }

  double get knobRadius => _knobRadius;
  double _knobRadius;
  set knobRadius(double value) {
    if (value == _knobRadius) {
      return;
    }
    _knobRadius = value;
    _updateAdditionalConstraints();
    markNeedsPaint();
  }

  ValueChanged<double>? onChangeStart;
  ValueChanged<double>? onChangeEnd;
  ValueChanged<double>? get onChanged => _onChanged;
  ValueChanged<double>? _onChanged;
  set onChanged(ValueChanged<double>? value) {
    if (value == _onChanged) {
      return;
    }
    final bool wasInteractive = isInteractive;
    _onChanged = value;
    if (wasInteractive != isInteractive) {
      markNeedsSemanticsUpdate();
    }
  }

  late AnimationController _position;
  TapGestureRecognizer? _tap;
  DragGestureRecognizer? _drag;
  double _currentDragValue = 0.0;

  double get _discretizedCurrentDragValue {
    double dragValue = ui.clampDouble(_currentDragValue, 0.0, 1.0);
    if (divisions != null) {
      dragValue = (dragValue * divisions!).round() / divisions!;
    }
    return dragValue;
  }

  double get _crossAxisLength => math.max(_knobRadius * 2, _thickness);
  double get _mainAxisLength => switch (direction) {
        SliderDirection.topToBottom ||
        SliderDirection.bottomToTop =>
          hasSize ? size.height : 0.0,
        SliderDirection.leftToRight ||
        SliderDirection.rightToLeft =>
          hasSize ? size.width : 0.0,
      };

  Size get _size => switch (direction) {
        SliderDirection.topToBottom || SliderDirection.bottomToTop => Size(
            _crossAxisLength,
            _mainAxisLength,
          ),
        SliderDirection.leftToRight || SliderDirection.rightToLeft => Size(
            _mainAxisLength,
            _crossAxisLength,
          ),
      };
  double get _mainAxisStart => switch (direction) {
        SliderDirection.topToBottom ||
        SliderDirection.leftToRight =>
          0.0 + _knobRadius,
        SliderDirection.bottomToTop ||
        SliderDirection.rightToLeft =>
          _mainAxisLength - _knobRadius,
      };

  double get _mainAxisEnd => switch (direction) {
        SliderDirection.bottomToTop ||
        SliderDirection.rightToLeft =>
          0.0 + _knobRadius,
        SliderDirection.topToBottom ||
        SliderDirection.leftToRight =>
          _mainAxisLength - _knobRadius,
      };

  bool get isInteractive => onChanged != null;

  void _updateAdditionalConstraints() {
    additionalConstraints = BoxConstraints.tightFor(width: _size.width);
  }

  Future<void> _moveTo(
    double value, {
    double delta = 1.0,
  }) async {
    if (delta > 0.1 && divisions == null) {
      try {
        _position.stop();
        await _position.animateTo(
          value,
          curve: Curves.fastOutSlowIn,
          duration: const Duration(milliseconds: 75) * delta.abs(),
        );
      } catch (e) {
        assert(() {
          return true;
        }());
        return;
      }
    }
    this.value = value;
  }

  void _updateDragValue(Offset localPosition) {
    final dragValue = switch (direction) {
      SliderDirection.leftToRight => localPosition.dx / _size.width,
      SliderDirection.topToBottom => localPosition.dy / _size.height,
      SliderDirection.rightToLeft => 1 - localPosition.dx / _size.width,
      SliderDirection.bottomToTop => 1 - localPosition.dy / _size.height,
    };
    _currentDragValue = ui.clampDouble(dragValue, 0, 1);
  }

  void _handleTap(TapDownDetails details) async {
    if (isInteractive) {
      _updateDragValue(details.localPosition);
      await _moveTo(_currentDragValue);
      onChanged!(_discretizedCurrentDragValue);
    }
  }

  void _handleDragStart(DragStartDetails details) =>
      _startInteraction(details.localPosition);

  void _handleDragUpdate(DragUpdateDetails details) {
    if (isInteractive) {
      _updateDragValue(details.localPosition);
      final double delta = (details.primaryDelta! / _size.height).abs();
      _moveTo(_currentDragValue, delta: delta.abs());
      onChanged!(_discretizedCurrentDragValue);
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    _endInteraction();
  }

  void _startInteraction(Offset localPosition) {
    if (isInteractive) {
      onChangeStart?.call(_discretizedCurrentDragValue);
      _currentDragValue = _value;
      onChanged!(_discretizedCurrentDragValue);
    }
  }

  void _endInteraction() {
    onChangeEnd?.call(_discretizedCurrentDragValue);
    _currentDragValue = 0.0;
  }

  @override
  bool hitTestSelf(Offset position) {
    return size.contains(position);
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent && isInteractive) {
      _tap?.addPointer(event);
      _drag?.addPointer(event);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _trackPainter ??= trackDecoration.createBoxPainter(markNeedsPaint);
    _knobPainter ??= knobDecoration.createBoxPainter(markNeedsPaint);
    double trackTop;
    double trackRight;
    double trackBottom;
    double trackLeft;
    Offset knobCenter;
    double crossAxisMidpoint;
    double knobMainAxisPosition = ui.lerpDouble(
      _mainAxisStart,
      _mainAxisEnd,
      _position.value,
    )!;
    switch (direction) {
      case SliderDirection.topToBottom:
      case SliderDirection.bottomToTop:
        crossAxisMidpoint = offset.dx + size.width / 2.0;
        trackLeft = crossAxisMidpoint - _thickness / 2.0;
        trackRight = crossAxisMidpoint + _thickness / 2.0;
        trackTop = offset.dy;
        trackBottom = offset.dy + size.height;
        knobCenter = Offset(
          crossAxisMidpoint,
          trackTop + knobMainAxisPosition,
        );
        break;
      case SliderDirection.leftToRight:
      case SliderDirection.rightToLeft:
        crossAxisMidpoint = offset.dy + size.height / 2.0;
        trackTop = crossAxisMidpoint - _thickness / 2.0;
        trackBottom = crossAxisMidpoint + _thickness / 2.0;
        trackLeft = offset.dx;
        trackRight = offset.dx + size.width;
        knobCenter = Offset(
          trackLeft + knobMainAxisPosition,
          crossAxisMidpoint,
        );
        break;
    }

    final Canvas canvas = context.canvas;
    if (_position.value <= 1.0) {
      _trackPainter?.paint(
        canvas,
        Offset(trackLeft, trackTop),
        ImageConfiguration(
          size: Size(trackRight - trackLeft, trackBottom - trackTop),
        ),
      );
    }

    _knobPainter?.paint(
      canvas,
      knobCenter.translate(-_knobRadius, -_knobRadius),
      ImageConfiguration(size: Size.fromRadius(_knobRadius)),
    );
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = isInteractive;
    config.isSlider = true;
    config.textDirection = direction == SliderDirection.leftToRight
        ? TextDirection.ltr
        : TextDirection.rtl;
    if (isInteractive) {
      config.onIncrease = _increaseAction;
      config.onDecrease = _decreaseAction;
      config.value = '${(value * 100).round()}%';
      config.increasedValue =
          '${(ui.clampDouble(value + _semanticActionUnit, 0.0, 1.0) * 100).round()}%';
      config.decreasedValue =
          '${(ui.clampDouble(value - _semanticActionUnit, 0.0, 1.0) * 100).round()}%';
    }
  }

  double get _semanticActionUnit =>
      divisions != null ? 1.0 / divisions! : _kAdjustmentUnit;

  void _increaseAction() {
    if (isInteractive) {
      onChanged!(ui.clampDouble(value + _semanticActionUnit, 0.0, 1.0));
    }
  }

  void _decreaseAction() {
    if (isInteractive) {
      onChanged!(ui.clampDouble(value - _semanticActionUnit, 0.0, 1.0));
    }
  }

  @override
  MouseCursor get cursor => _cursor;
  MouseCursor _cursor;
  set cursor(MouseCursor value) {
    if (_cursor != value) {
      _cursor = value;
      // A repaint is needed in order to trigger a device update of
      // [MouseTracker] so that this new value can be found.
      markNeedsPaint();
    }
  }

  @override
  PointerEnterEventListener? onEnter;

  @override
  PointerExitEventListener? onExit;

  PointerHoverEventListener? onHover;

  @override
  bool get validForMouseTracker => false;

  @override
  void dispose() {
    _drag?.dispose();
    _tap?.dispose();
    _position.dispose();
    super.dispose();
  }
}
