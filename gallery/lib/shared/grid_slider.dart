import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app.dart';
import '../floogle_docs/src/widgets/editable.dart';
import 'package.dart';
import 'theme.dart';

const transparent = Color(0x00000000);
const white = Color(0xFFFFFFFF);
const black = Color(0xFF000000);
const whiteTransparent = ui.Color(0x63FFFFFF);
const blackTransparent = ui.Color(0x63000000);

extension AlongSize on Offset {
  Alignment relativeTo(Size size) {
    return Alignment((dx / size.width) * 2 - 1, (dy / size.height) * 2 - 1);
  }
}

extension Clamp on Alignment {
  Alignment clamp(double min, double max, [double? minY, double? maxY]) {
    return Alignment(ui.clampDouble(x, min, max), ui.clampDouble(y, minY ?? min, maxY ?? max));
  }
}

class GridSlider extends StatefulWidget {
  const GridSlider({
    super.key,
    this.onChange,
    required this.title,
    this.x = 0,
    this.y = 0,
    this.size = const Size(150, 150),
    required this.formatter,
  });

  final double x;
  final double y;
  final void Function(double x, double y)? onChange;
  final Size size;
  final InlineSpan title;
  final GridSliderFormatter formatter;

  @override
  State<GridSlider> createState() => _GridSliderState();
}

class _GridSliderState extends State<GridSlider> {
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  late final TextEditingController _xController;
  late final TextEditingController _yController;
  final xFocusNode = FocusNode();
  final yFocusNode = FocusNode();
  static const Color dotColor = Color(0xFF1C64FF);
  late double x = widget.x;
  late double y = widget.y;

  @override
  void initState() {
    super.initState();
    _xController = TextEditingController(text: widget.formatter.format(widget.x));
    _yController = TextEditingController(text: widget.formatter.format(widget.y));
  }

  @override
  void didUpdateWidget(covariant GridSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.x != oldWidget.x || widget.y != oldWidget.y) {
      x = widget.x;
      y = widget.y;
      _xController.value = TextEditingValue(text: widget.formatter.format(x));
      _yController.value = TextEditingValue(text: widget.formatter.format(y));
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _xController.dispose();
    _yController.dispose();
    _debounce?.cancel();
    xFocusNode.dispose();
    yFocusNode.dispose();
    super.dispose();
  }

  void _moveTo(double xCoord, double yCoord) {
    if (x != xCoord || y != yCoord) {
      x = ui.clampDouble(xCoord, -1, 1);
      y = ui.clampDouble(yCoord, -1, 1);
      widget.onChange?.call(x, y);
    }
  }

  void _moveToOffset(Offset offset) {
    _moveTo((offset.dx / widget.size.width) * 2 - 1, (offset.dy / widget.size.height) * 2 - 1);
  }

  void _moveBy(_GridSliderIntent intent) {
    _moveTo(x + intent.dx, y + intent.dy);
  }

  void _handleManualInput() {
    final double? xPercent = double.tryParse(_xController.text);
    final double? yPercent = double.tryParse(_yController.text);
    if (xPercent != null && yPercent != null) {
      final double xCoord = ((xPercent.clamp(0, 100) / 100) * 2) - 1;
      final double yCoord = ((yPercent.clamp(0, 100) / 100) * 2) - 1;
      _moveTo(xCoord, yCoord);
    }
  }

  static const step = 0.05;
  static const stepLarge = 0.2;
  static const stepSmall = 0.01;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = AppColorScheme.of(context).brightness;
    final alignment = Alignment(x, y);
    return Semantics(
      label: widget.title.toPlainText(),
      explicitChildNodes: true,
      child: Actions(
        actions: {
          _IncrementIntent: CallbackAction<_IncrementIntent>(onInvoke: _moveBy),
          _DecrementIntent: CallbackAction<_DecrementIntent>(onInvoke: _moveBy),
        },
        child: Column(
          mainAxisSize: .min,
          children: [
            ExcludeSemantics(
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
                child: Text.rich(widget.title, textAlign: TextAlign.start),
              ),
            ),

            Shortcuts(
              shortcuts: const {
                SingleActivator(.arrowUp): _DecrementIntent(0, step),
                SingleActivator(.arrowUp, shift: true): _DecrementIntent(0, stepLarge),
                SingleActivator(.arrowUp, meta: true): _DecrementIntent(0, stepSmall),
                SingleActivator(.arrowDown): _IncrementIntent(0, step),
                SingleActivator(.arrowDown, shift: true): _IncrementIntent(0, stepLarge),
                SingleActivator(.arrowDown, meta: true): _IncrementIntent(0, stepSmall),
                SingleActivator(.arrowLeft): _DecrementIntent(step, 0),
                SingleActivator(.arrowLeft, shift: true): _DecrementIntent(stepLarge, 0),
                SingleActivator(.arrowLeft, meta: true): _DecrementIntent(stepSmall, 0),
                SingleActivator(.arrowRight): _IncrementIntent(step, 0),
                SingleActivator(.arrowRight, meta: true): _IncrementIntent(stepSmall, 0),
                SingleActivator(.arrowRight, shift: true): _IncrementIntent(stepLarge, 0),
              },
              child: Focus(
                focusNode: _focusNode,
                skipTraversal: true,
                descendantsAreTraversable: false,
                includeSemantics: false,
                child: ExcludeSemantics(
                  excluding: true,
                  child: SizedBox.fromSize(
                    size: widget.size,
                    child: Stack(
                      alignment: .center,
                      children: <Widget>[
                        CustomPaint(
                          painter: GridPainter(alignment, brightness),
                          size: Size(widget.size.width - 16, widget.size.height - 16),
                        ),
                        Align(
                          alignment: alignment,
                          child: ListenableBuilder(
                            listenable: _focusNode,
                            builder: _buildFocusOutline,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: GestureDetector(
                            excludeFromSemantics: true,
                            onPanUpdate: _handlePanUpdate,
                            onTapDown: _handleTapDown,
                            behavior: .opaque,
                            dragStartBehavior: .down,
                            child: const ColoredBox(color: transparent, child: SizedBox.expand()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: widget.size.width,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: .min,
                  spacing: 4,
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          border: Border.all(color: const Color(0xFFCCCCCC), width: 1.0),
                        ),
                        child: Shortcuts(
                          shortcuts: const {
                            SingleActivator(.arrowUp): _IncrementIntent(step, 0),
                            SingleActivator(.arrowUp, shift: true): _IncrementIntent(stepLarge, 0),
                            SingleActivator(.arrowUp, meta: true): _IncrementIntent(stepSmall, 0),
                            SingleActivator(.arrowDown): _DecrementIntent(step, 0),
                            SingleActivator(.arrowDown, shift: true): _DecrementIntent(
                              stepLarge,
                              0,
                            ),
                            SingleActivator(.arrowDown, meta: true): _DecrementIntent(stepSmall, 0),
                          },
                          child: NumberField(
                            focusNode: xFocusNode,
                            textEditingController: _xController,
                            semanticsLabel: widget.formatter.semanticsLabel(.horizontal),
                            semanticsHint: widget.formatter.semanticsHint(.horizontal),
                            formatters: widget.formatter.inputFormatters,
                            onChanged: _handleManualInput,
                          ),
                        ),
                      ),
                    ),
                    ExcludeSemantics(
                      child: Text(
                        'x',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColorScheme.of(context).onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          border: Border.all(color: const Color(0xFFCCCCCC), width: 1.0),
                        ),
                        child: Shortcuts(
                          shortcuts: const {
                            SingleActivator(.arrowUp): _IncrementIntent(0, step),
                            SingleActivator(.arrowUp, shift: true): _IncrementIntent(0, stepLarge),
                            SingleActivator(.arrowUp, meta: true): _IncrementIntent(0, stepSmall),
                            SingleActivator(.arrowDown): _DecrementIntent(0, step),
                            SingleActivator(.arrowDown, shift: true): _DecrementIntent(
                              0,
                              stepLarge,
                            ),
                            SingleActivator(.arrowDown, meta: true): _DecrementIntent(0, stepSmall),
                          },
                          child: NumberField(
                            focusNode: yFocusNode,
                            textEditingController: _yController,
                            onChanged: _handleManualInput,
                            semanticsLabel: widget.formatter.semanticsLabel(.vertical),
                            semanticsHint: widget.formatter.semanticsHint(.vertical),
                            formatters: widget.formatter.inputFormatters,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTapDown(TapDownDetails details) {
    final localPosition = details.localPosition;
    _moveToOffset(localPosition);
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final localPosition = details.localPosition;
    _moveToOffset(localPosition);
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  Widget _buildFocusOutline(BuildContext context, Widget? child) {
    final outline = BoxDecoration(
      border: Border.fromBorderSide(
        BorderSide(
          color: _focusNode.hasFocus ? dotColor : transparent,
          width: _focusNode.hasFocus ? 1.5 : 0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      shape: BoxShape.circle,
    );
    return AnimatedContainer(
      width: 16,
      height: 16,
      decoration: outline,
      alignment: Alignment.center,
      duration: const Duration(milliseconds: 150),
      child: child,
    );
  }
}

class GridPainter extends CustomPainter {
  const GridPainter(this.dotAlignment, this.brightness);
  final Alignment dotAlignment;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final double tenthWidth = size.width / 10;
    final double tenthHeight = size.height / 10;
    final paint = Paint()
      ..color = brightness == Brightness.dark ? whiteTransparent : blackTransparent
      ..strokeWidth = 0.0
      ..isAntiAlias = false;

    double x = 0, y = 0;
    for (var i = 0; i <= 10; i++) {
      if (i % 5 == 0) {
        paint.strokeWidth = 1.0;
      } else {
        paint.strokeWidth = 0.0;
      }
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      x += tenthWidth;
      y += tenthHeight;
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) {
    return oldDelegate.dotAlignment != dotAlignment || oldDelegate.brightness != brightness;
  }
}

class _GridSliderIntent extends Intent {
  const _GridSliderIntent(this.dx, this.dy);
  final double dx;
  final double dy;
}

class _IncrementIntent extends _GridSliderIntent {
  const _IncrementIntent(super.dx, super.dy);
}

class _DecrementIntent extends _GridSliderIntent {
  const _DecrementIntent(double dx, double dy) : super(-dx, -dy);
}

class NumberField extends StatefulWidget {
  const NumberField({
    super.key,
    this.semanticsLabel,
    this.semanticsHint,
    required this.textEditingController,
    required this.onChanged,
    required this.focusNode,
    this.keyboardType = TextInputType.number,
    this.formatters,
  });
  final String? semanticsLabel;
  final String? semanticsHint;
  final TextEditingController textEditingController;
  final VoidCallback onChanged;
  final FocusNode focusNode;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? formatters;

  @override
  State<NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<NumberField> {
  final WidgetStatesController _widgetStatesController = WidgetStatesController();

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    _widgetStatesController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    _widgetStatesController.update(WidgetState.focused, widget.focusNode.hasFocus);
  }

  static const _inputDecoration = WidgetStateProperty<BoxDecoration>.fromMap({
    WidgetState.focused: BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      border: Border.fromBorderSide(BorderSide(color: kBlack, width: 2)),
    ),
    WidgetState.any: BoxDecoration(),
  });

  static const _textStyle = kIsWeb
      ? TextStyle(
          fontSize: 11,
          fontFamily: 'GoogleSansCode',
          fontFamilyFallback: ['InterVariable'],
          package: kPackage,
          height: 1.2,
          letterSpacing: -0.4,
          overflow: TextOverflow.ellipsis,
          color: kBlack,
          fontVariations: [
            FontVariation.weight(470),
            FontVariation.opticalSize(17),
            FontVariation.width(95),
          ],
        )
      : TextStyle(
          fontSize: 10.5,
          fontFamily: 'GoogleSansCode',
          fontFamilyFallback: ['InterVariable'],
          package: kPackage,
          height: 1.2,
          color: kBlack,

          overflow: TextOverflow.ellipsis,
        );

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ListenableBuilder(
        listenable: _widgetStatesController,
        builder: (context, child) {
          return DecoratedBox(
            decoration: _inputDecoration.resolve(_widgetStatesController.value),
            child: child,
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
          child: ListenableBuilder(
            listenable: widget.focusNode,
            builder: (context, child) {
              return Stack(
                textDirection: .ltr,
                children: [
                  if (!widget.focusNode.hasFocus)
                    Positioned(
                      left: 0,
                      right: 0,
                      child: Semantics(
                        label: widget.semanticsLabel,
                        hint: widget.semanticsHint,
                        child: ExcludeSemantics(
                          child: Text(
                            widget.textEditingController.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: .center,
                            style: _textStyle.copyWith(color: kBlack.withValues(alpha: 0.6)),
                          ),
                        ),
                      ),
                    ),
                  Opacity(
                    opacity: widget.focusNode.hasFocus ? 1.0 : 0.0,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 3),
                      child: Editable(
                        onChanged: (_) => widget.onChanged(),
                        semanticsLabel: widget.semanticsLabel,
                        semanticsHint: widget.semanticsHint,
                        inputFormatters: widget.formatters,
                        textController: widget.textEditingController,
                        keyboardType: widget.keyboardType,
                        focusNode: widget.focusNode,
                        style: _textStyle,
                        textAlign: .center,
                        forceLine: true,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

abstract class GridSliderFormatter {
  const GridSliderFormatter._();
  const factory GridSliderFormatter.pixel({required double magnitude, required String title}) =
      _PixelGridSliderFormatter;
  const factory GridSliderFormatter.alignment({required String title}) =
      _AlignmentGridSliderFormatter;

  /// Converts internal [-1, 1] value to display string (e.g., "10.0").
  String format(double value);

  /// Parses display string back to internal [-1, 1] value.
  double? parse(String text);

  /// Validation: restricts what the user can type (e.g., only numbers).
  List<TextInputFormatter>? get inputFormatters => null;

  /// Accessibility: screen reader label for the axis.
  String semanticsLabel(Axis axis);

  /// Accessibility: instructions for the screen reader.
  String semanticsHint(Axis axis);

  TextInputType get keyboardType => TextInputType.text;
}

class _PixelGridSliderFormatter extends GridSliderFormatter {
  const _PixelGridSliderFormatter({required this.magnitude, required this.title}) : super._();
  final double magnitude;
  final String title;

  @override
  String format(double value) => (value * magnitude).toStringAsFixed(0);

  @override
  double? parse(String text) {
    final px = double.tryParse(text);
    if (px == null) {
      return null;
    }
    return ui.clampDouble(px, -magnitude, magnitude) / magnitude;
  }

  @override
  List<TextInputFormatter>? get inputFormatters => [
    FilteringTextInputFormatter.allow(RegExp(r'^-?\d*$')),
  ];

  @override
  TextInputType get keyboardType =>
      const TextInputType.numberWithOptions(decimal: false, signed: true);

  @override
  String semanticsLabel(Axis axis) =>
      '${axis == Axis.horizontal ? 'Horizontal' : 'Vertical'} $title alignment offset in pixels';

  @override
  String semanticsHint(Axis axis) => 'Enter a value between -${magnitude}px and ${magnitude}px';
}

class _AlignmentGridSliderFormatter extends GridSliderFormatter {
  const _AlignmentGridSliderFormatter({required this.title}) : super._();
  final String title;

  @override
  String format(double value) => value.toStringAsFixed(2);

  @override
  double? parse(String text) => double.tryParse(text);

  @override
  List<TextInputFormatter>? get inputFormatters => [
    FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),
  ];

  @override
  TextInputType get keyboardType =>
      const TextInputType.numberWithOptions(decimal: true, signed: true);

  @override
  String semanticsLabel(Axis axis) =>
      '${axis == Axis.horizontal ? 'Horizontal' : 'Vertical'} $title alignment between -1 and 1';

  @override
  String semanticsHint(Axis axis) => 'Enter a value between -1 and 1';
}
