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
