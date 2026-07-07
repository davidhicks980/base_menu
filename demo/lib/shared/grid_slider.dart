import 'dart:async';
import 'dart:ui' as ui;

import 'package:base_menu/base_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../app/app.dart';

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
  });

  final double x;
  final double y;
  final void Function(double x, double y)? onChange;
  final Size size;
  final InlineSpan title;

  @override
  State<GridSlider> createState() => _GridSliderState();
}

class _GridSliderState extends State<GridSlider> {
  Alignment _position = Alignment.center;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _showTextInputRow = false;
  final TextEditingController _xController = TextEditingController();
  final TextEditingController _yController = TextEditingController();
  static const Color dotColor = Color(0xFF1C64FF);

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    Alignment? amount = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowUp => const Alignment(0.00, -0.05),
      LogicalKeyboardKey.arrowDown => const Alignment(0.00, 0.05),
      LogicalKeyboardKey.arrowLeft => const Alignment(-0.05, 0.00),
      LogicalKeyboardKey.arrowRight => const Alignment(0.05, 0.00),
      _ => null,
    };

    if (amount == null) {
      return KeyEventResult.ignored;
    }

    if (_debounce != null) {
      return KeyEventResult.handled;
    }

    _debounce = Timer(const Duration(milliseconds: 80), () {
      _debounce = null;
    });

    if (HardwareKeyboard.instance.isShiftPressed) {
      amount *= 4;
    } else if (HardwareKeyboard.instance.isMetaPressed) {
      amount *= 0.25;
    }

    setState(() {
      _position = (_position + amount!).clamp(-1, 1);
      widget.onChange?.call(_position.x, _position.y);
    });
    return KeyEventResult.handled;
  }

  @override
  void initState() {
    super.initState();
    _position = Alignment(widget.x, widget.y);
  }

  @override
  void didUpdateWidget(covariant GridSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.x != oldWidget.x || widget.y != oldWidget.y) {
      _position = Alignment(widget.x, widget.y);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _xController.dispose();
    _yController.dispose();
    super.dispose();
  }

  void _moveTo(Alignment position) {
    if (_position != position) {
      setState(() {
        _position = position;
        widget.onChange?.call(position.x, position.y);
      });
    }

    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  void _moveBy(double dx, double dy) {
    _moveTo(Alignment(_position.x + dx, _position.y + dy).clamp(-1, 1));
  }

  void _handleManualInput() {
    final double? xPercent = double.tryParse(_xController.text);
    final double? yPercent = double.tryParse(_yController.text);

    if (xPercent != null && yPercent != null) {
      final double xCoord = ((xPercent.clamp(0, 100) / 100) * 2) - 1;
      final double yCoord = ((yPercent.clamp(0, 100) / 100) * 2) - 1;

      setState(() {
        _position = Alignment(xCoord, yCoord);
        widget.onChange?.call(xCoord, yCoord);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = AppColorScheme.of(context).brightness;
    return Material(
      type: .transparency,
      child: Column(
        children: [
          Row(
            mainAxisSize: .min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Tooltip(
                message: _showTextInputRow ? 'Show grid visualizer' : 'Type position manually',
                child: BaseControl(
                  onPressed: () {
                    setState(() {
                      _showTextInputRow = !_showTextInputRow;
                    });
                  },
                  child: Icon(_showTextInputRow ? Icons.grid_on : Icons.keyboard),
                ),
              ),
            ],
          ),
          Focus(
            focusNode: _focusNode,
            onKeyEvent: _handleKeyEvent,
            child: Semantics.fromProperties(
              container: true,
              properties: SemanticsProperties(
                label: '2D Grid Position Picker for ${widget.title.toPlainText()}',
                value:
                    'Horizontal: ${(_position.x * 100).round()}%, Vertical: ${(_position.y * 100).round()}%',
                slider: true,
                onIncrease: () => _moveBy(0.1, 0.0),
                onDecrease: () => _moveBy(-0.1, 0.0),
                hint:
                    'Double tap to activate. Enter numbers separated by a space to type explicit horizontal and vertical values.',

                customSemanticsActions: {
                  const CustomSemanticsAction(label: 'Move Up'): () => _moveBy(0.0, -0.1),
                  const CustomSemanticsAction(label: 'Move Down'): () => _moveBy(0.0, 0.1),
                },
              ),
              child: SizedBox.fromSize(
                size: widget.size,
                child: Stack(
                  alignment: .center,
                  children: <Widget>[
                    CustomPaint(
                      painter: GridPainter(_position, brightness),
                      size: Size(widget.size.width - 16, widget.size.height - 16),
                    ),
                    Align(
                      alignment: _position,
                      child: ListenableBuilder(
                        listenable: _focusNode,
                        builder: _buildFocusOutline,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: dotColor, shape: BoxShape.circle),
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

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _xController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Horizontal Position (0-100%)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (_) => _handleManualInput(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _yController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Vertical Position (0-100%)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (_) => _handleManualInput(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // void _handleTapUp(TapUpDetails details) {
  //   _moveTo(details.localPosition.relativeTo(widget.size).clamp(-1, 1));
  // }

  void _handleTapDown(TapDownDetails details) {
    _moveTo(details.localPosition.relativeTo(widget.size).clamp(-1, 1));
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _moveTo(details.localPosition.relativeTo(widget.size).clamp(-1, 1));
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
