import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'editable.dart';

const _textStyle = kIsWeb
    ? TextStyle(
        fontSize: 18,
        fontFamily: 'GoogleSans',
        letterSpacing: -0.4,
        fontVariations: [
          FontVariation('YTLC', 525),
          FontVariation('XTRA', 500),
          FontVariation('GRAD', 50),
          FontVariation.width(100),
        ],
        height: 1.2,
        overflow: TextOverflow.ellipsis,
        color: Color(0xFF1F1F1F),
      )
    : TextStyle(
        fontSize: 18,
        fontFamily: 'GoogleSans',
        height: 1.2,
        overflow: TextOverflow.ellipsis,
        color: Color(0xFF1F1F1F),
      );

const _inputDecoration = WidgetStateProperty<BoxDecoration>.fromMap({
  WidgetState.focused: BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(4.0)),
    border: Border.fromBorderSide(
      BorderSide(color: Color.from(alpha: 1, red: 0.043, green: 0.341, blue: 0.816), width: 2),
    ),
  ),
  WidgetState.hovered: BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(4.0)),
    border: Border.fromBorderSide(
      BorderSide(color: Color.from(alpha: 1, red: 0.455, green: 0.467, blue: 0.459)),
    ),
  ),
  WidgetState.any: BoxDecoration(),
});

class TitleField extends StatefulWidget {
  const TitleField({super.key});

  @override
  State<TitleField> createState() => _TitleFieldState();
}

class _TitleFieldState extends State<TitleField> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textEditingController = TextEditingController(
    text: 'Untitled Document',
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
                    children: [
                      if (!_focusNode.hasFocus)
                        Text(
                          _textEditingController.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _textStyle,
                        ),
                      Opacity(
                        opacity: _focusNode.hasFocus ? 1.0 : 0.0,
                        child: Editable(
                          controller: _textEditingController,
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
