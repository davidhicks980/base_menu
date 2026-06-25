import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../utilities/colors.dart';
import 'editable.dart';

class TitleField extends StatefulWidget {
  const TitleField({super.key});

  @override
  State<TitleField> createState() => _TitleFieldState();
}

class _TitleFieldState extends State<TitleField> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textEditingController = TextEditingController(
    text: 'Untitled document',
  );
  final WidgetStatesController _widgetStatesController = WidgetStatesController();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textEditingController.dispose();
    _widgetStatesController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    _widgetStatesController.update(WidgetState.focused, _focusNode.hasFocus);
  }

  void _handleHover(PointerEvent event) {
    _widgetStatesController.update(WidgetState.hovered, event is PointerEnterEvent);
  }

  static const _inputDecoration = WidgetStateProperty<BoxDecoration>.fromMap({
    WidgetState.focused: BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      border: Border.fromBorderSide(
        BorderSide(color: FloogleColors.titleInputFocusBorder, width: 2),
      ),
    ),
    WidgetState.hovered: BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      border: Border.fromBorderSide(BorderSide(color: FloogleColors.greyOutline)),
    ),
    WidgetState.any: BoxDecoration(),
  });

  static const _textStyle = kIsWeb
      ? TextStyle(
          fontSize: 18.5,
          fontFamily: 'GoogleSansFlex',
          fontFamilyFallback: ['GoogleSans'],
          height: 1.2,
          letterSpacing: -0.4,
          overflow: TextOverflow.ellipsis,
          fontVariations: [
            FontVariation.weight(470),
            FontVariation.opticalSize(17),
            FontVariation.width(95),
          ],
          color: FloogleColors.darkGray,
        )
      : TextStyle(
          fontSize: 18,
          fontFamily: 'GoogleSans',
          height: 1.2,
          overflow: TextOverflow.ellipsis,
          color: FloogleColors.darkGray,
        );

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: MouseRegion(
        cursor: SystemMouseCursors.text,
        onEnter: _handleHover,
        onExit: _handleHover,
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: ListenableBuilder(
            listenable: _widgetStatesController,
            builder: (context, child) {
              return DecoratedBox(
                decoration: _inputDecoration.resolve(_widgetStatesController.value),
                child: child,
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
              child: ListenableBuilder(
                listenable: _focusNode,
                builder: (context, child) {
                  return Stack(
                    textDirection: .ltr,
                    children: [
                      if (!_focusNode.hasFocus)
                        Text(
                          _textEditingController.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _textStyle.copyWith(color: FloogleColors.grey),
                        ),
                      Opacity(
                        opacity: _focusNode.hasFocus ? 1.0 : 0.0,
                        child: Editable(
                          textController: _textEditingController,
                          focusNode: _focusNode,
                          style: _textStyle,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
