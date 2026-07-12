import 'package:base_menu/base_menu.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const Example());
}

class Example extends StatelessWidget {
  const Example({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Material(color: Color(0xFFF3F4F8), child: BaseMenuApp()),
    );
  }
}

class BaseMenuApp extends StatefulWidget {
  const BaseMenuApp({super.key});

  @override
  State<BaseMenuApp> createState() => _BaseMenuAppState();
}

class _BaseMenuAppState extends State<BaseMenuApp> {
  final MenuController controllerOne = MenuController();
  final MenuController controllerTwo = MenuController();
  String message = 'Nothing';

  static const panelDecoration = BoxDecoration(
    color: Color(0xFFFFFFFF),
    boxShadow: [BoxShadow(color: Color(0x28000000), blurRadius: 4, offset: Offset(0, 2))],
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: .center,
      mainAxisSize: .max,
      spacing: 16,
      children: [
        const Text('BaseMenu Example', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text('Pressed $message', style: const TextStyle(fontSize: 16)),
        BaseMenuBar(
          child: BaseMenuPanel(
            constraints: const BoxConstraints.tightFor(height: 30),
            children: <Widget>[
              BaseSubmenu(
                controller: controllerOne,
                requestCloseOnPointerExit: false,
                menu: DecoratedBox(
                  decoration: panelDecoration,
                  child: BaseMenuPanel(
                    constraints: const BoxConstraints.tightFor(width: 100),
                    children: <Widget>[
                      BaseMenuItem(
                        onPressed: () {
                          setState(() {
                            message = 'New';
                          });
                        },
                        child: const Label(child: Text('New')),
                      ),
                      BaseMenuItem(
                        onPressed: () {
                          setState(() {
                            message = 'Open';
                          });
                        },
                        child: const Label(child: Text('Open...')),
                      ),
                    ],
                  ),
                ),
                child: const Label(
                  color: Color(0xFFB1D2FF),
                  padding: .symmetric(horizontal: 30),
                  child: Text('File'),
                ),
              ),
              BaseSubmenu(
                controller: controllerTwo,
                requestCloseOnPointerExit: false,
                menu: DecoratedBox(
                  decoration: panelDecoration,
                  child: BaseMenuPanel(
                    constraints: const BoxConstraints.tightFor(width: 100),
                    children: <Widget>[
                      BaseMenuItem(
                        onPressed: () {
                          setState(() {
                            message = 'Undo';
                          });
                        },
                        child: const Label(child: Text('Undo')),
                      ),
                      BaseMenuItem(
                        onPressed: () {
                          setState(() {
                            message = 'Redo';
                          });
                        },
                        child: const Label(child: Text('Redo')),
                      ),
                    ],
                  ),
                ),
                child: const Label(
                  color: Color(0xFFFFDEB1),
                  padding: .symmetric(horizontal: 30),
                  child: Text('Edit'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

const Color kSeedColor = Color(0xFF445E91); // Primary
const Color kPressedColor = Color(0xFF2B4678); // onPrimaryContainer
const Color kDarkPressedColor = Color(0xFF1B2E55); // Darker version of primary
const Color kHoverBg = Color(0xFFD8E2FF); // primaryContainer
const Color kFocusBg = Color(0xFFDBE2F9); // secondaryContainer
const Color kDefaultText = Color(0xFF1A1B20); // onSurface
const Color kDisabledText = Color(0xFF74777F); // outline
const Color kTransparent = Color(0x00000000);
const Color kTransparentLight = Color(0x00FFFFFF);
const Color kBlack = Color(0xFF000000);
const Color kWhite = Color(0xFFFFFFFF);

class Label extends StatelessWidget {
  const Label({
    super.key,
    required this.child,
    this.color,
    this.alignment = .centerStart,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });
  final Widget child;
  final Color? color;
  final AlignmentGeometry alignment;
  final EdgeInsetsGeometry padding;

  static const WidgetStateProperty<BoxDecoration> decoration = WidgetStateProperty.fromMap({
    WidgetState.pressed: BoxDecoration(
      color: Color(0xFF2B4678),
      border: Border.fromBorderSide(BorderSide(color: Color(0xFF2B4678), width: 1.5)),
    ),
    WidgetState.focused: BoxDecoration(
      color: Color(0xFF445E91),
      border: Border.fromBorderSide(BorderSide(color: Color(0xFF445E91), width: 1.5)),
    ),
    WidgetState.any: BoxDecoration(
      color: Color(0x00000000),
      border: Border.fromBorderSide(BorderSide(color: Color(0x00000000), width: 1.5)),
    ),
  });

  static const WidgetStateProperty<TextStyle> textStyle = WidgetStateProperty.fromMap({
    WidgetState.disabled: TextStyle(color: Color(0xFF74777F)),
    WidgetState.pressed: TextStyle(color: Color(0xFFFFFFFF)),
    WidgetState.focused: TextStyle(color: Color(0xFFFFFFFF)),
    WidgetState.any: TextStyle(color: Color(0xFF1A1B20)),
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BaseMenuItem.isFocusHighlightShownOf(context)
          ? BoxDecoration(border: Border.all(width: 2), color: color)
          : BoxDecoration(color: color),
      child: Padding(
        padding: padding,
        child: Align(alignment: alignment, child: child),
      ),
    );
  }
}
