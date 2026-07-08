import 'dart:ui' as ui;

import 'package:base_menu/base_menu.dart';
import 'package:flutter/widgets.dart';

import '../app/app.dart';
import '../checkbox_menu_item/src/checkbox_menu_item.dart';
import 'checkbox.dart';
import 'grid_slider.dart';
import 'package.dart';

class _ChangeNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}

class AlignmentTemplate extends StatefulWidget {
  const AlignmentTemplate({super.key, required this.build, this.title, required this.controller});
  final Widget Function(BuildContext context, DefaultMenuPositioningDelegate delegate) build;
  final MenuController controller;
  final Widget? title;

  @override
  State<AlignmentTemplate> createState() => _AlignmentTemplateState();
}

class _AlignmentTemplateState extends State<AlignmentTemplate> {
  final _ChangeNotifier notifier = _ChangeNotifier();

  @override
  void dispose() {
    notifier.dispose();
    super.dispose();
  }

  void notify() {
    notifier.notify();
  }

  ui.Brightness brightness = ui.Brightness.dark;
  (double, double) _menuPosition = (0, 0);
  (double, double) _menuAttachment = (-1, 1);
  (double, double) _anchorAttachment = (1, -1);
  (double, double) _anchorPosition = (0, 0);
  (double, double) _alignmentOffset = (0, 0);

  bool _horizontalFlip = true;
  bool _horizontalShift = true;
  bool _horizontalConstrain = true;
  bool _verticalFlip = true;
  bool _verticalShift = true;
  bool _verticalConstrain = true;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.title != null) widget.title!,
                FocusTraversalGroup(
                  policy: WidgetOrderTraversalPolicy(),
                  child: Column(
                    spacing: 20,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: <Widget>[
                          StatefulBuilder(
                            builder: (context, setState) {
                              return GridSlider(
                                size: const Size(110, 110),
                                x: _anchorPosition.$1,
                                y: _anchorPosition.$2,
                                title: const TextSpan(text: 'Button Alignment'),
                                onChange: (double x, double y) {
                                  setState(() {
                                    _anchorPosition = (x, y);
                                  });
                                  notify();
                                },
                              );
                            },
                          ),
                          StatefulBuilder(
                            builder: (context, setState) {
                              return GridSlider(
                                size: const Size(110, 110),
                                x: _menuPosition.$1,
                                y: _menuPosition.$2,
                                title: const TextSpan(text: 'Controller Offset'),
                                formatter: const GridSliderFormatter.pixel(magnitude: 200),
                                onChange: (double x, double y) {
                                  setState(() {
                                    _menuPosition = (x, y);
                                    widget.controller.open(position: Offset(x * 200, y * 200));
                                  });
                                  notify();
                                },
                              );
                            },
                          ),
                          StatefulBuilder(
                            builder: (context, setState) {
                              return GridSlider(
                                size: const Size(110, 110),
                                x: _anchorAttachment.$1,
                                y: _anchorAttachment.$2,
                                title: const TextSpan(text: 'Anchor Alignment'),
                                onChange: (double x, double y) {
                                  setState(() {
                                    _anchorAttachment = (x, y);
                                  });
                                  notify();
                                },
                              );
                            },
                          ),
                          StatefulBuilder(
                            builder: (context, setState) {
                              return GridSlider(
                                size: const Size(110, 110),
                                x: _alignmentOffset.$1 * 10,
                                y: _alignmentOffset.$2 * 10,
                                title: const TextSpan(text: 'Alignment Offset'),
                                formatter: const GridSliderFormatter.pixel(magnitude: 10),
                                onChange: (double x, double y) {
                                  setState(() {
                                    _alignmentOffset = (x / 10, y / 10);
                                  });
                                  notify();
                                },
                              );
                            },
                          ),
                          StatefulBuilder(
                            builder: (context, setState) {
                              return GridSlider(
                                size: const Size(110, 110),
                                x: _menuAttachment.$1,
                                y: _menuAttachment.$2,
                                title: const TextSpan(text: 'Menu Alignment'),
                                onChange: (double x, double y) {
                                  setState(() {
                                    _menuAttachment = (x, y);
                                  });
                                  notify();
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 20,
                        alignment: WrapAlignment.center,
                        children: [
                          _BehaviorColumn(
                            title: 'Horizontal Behavior',
                            children: [
                              StatefulBuilder(
                                builder: (context, setState) {
                                  return WebCheckboxMenuItem(
                                    checkbox: const WebCheckbox(),
                                    isChecked: _horizontalFlip,
                                    onChange: (v) {
                                      setState(() {
                                        _horizontalFlip = v;
                                      });
                                      notify();
                                    },
                                    child: const Text('Flip'),
                                  );
                                },
                              ),
                              StatefulBuilder(
                                builder: (context, setState) {
                                  return WebCheckboxMenuItem(
                                    checkbox: const WebCheckbox(),
                                    isChecked: _horizontalShift,
                                    onChange: (value) {
                                      setState(() {
                                        _horizontalShift = value;
                                      });
                                      notify();
                                    },
                                    child: const Text('Shift'),
                                  );
                                },
                              ),
                              StatefulBuilder(
                                builder: (context, setState) {
                                  return WebCheckboxMenuItem(
                                    checkbox: const WebCheckbox(),
                                    isChecked: _horizontalConstrain,
                                    onChange: (value) {
                                      setState(() {
                                        _horizontalConstrain = value;
                                      });
                                      notify();
                                    },
                                    child: const Text('Constrain'),
                                  );
                                },
                              ),
                            ],
                          ),

                          // Add Vertical Edge Behavior toggles
                          _BehaviorColumn(
                            title: 'Vertical Behavior',
                            children: [
                              StatefulBuilder(
                                builder: (context, setState) {
                                  return WebCheckboxMenuItem(
                                    checkbox: const WebCheckbox(),
                                    isChecked: _verticalFlip,
                                    onChange: (value) {
                                      setState(() {
                                        _verticalFlip = value;
                                      });
                                      notify();
                                    },
                                    child: const Text('Flip'),
                                  );
                                },
                              ),
                              StatefulBuilder(
                                builder: (context, setState) {
                                  return WebCheckboxMenuItem(
                                    checkbox: const WebCheckbox(),
                                    isChecked: _verticalShift,
                                    onChange: (value) {
                                      setState(() {
                                        _verticalShift = value;
                                      });
                                      notify();
                                    },
                                    child: const Text('Shift'),
                                  );
                                },
                              ),
                              StatefulBuilder(
                                builder: (context, setState) {
                                  return WebCheckboxMenuItem(
                                    checkbox: const WebCheckbox(),
                                    isChecked: _verticalConstrain,
                                    onChange: (value) {
                                      setState(() {
                                        _verticalConstrain = value;
                                      });
                                      notify();
                                    },
                                    child: const Text('Constrain'),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListenableBuilder(
              listenable: notifier,
              builder: (context, child) {
                final anchorAlignment = AlignmentDirectional(
                  _anchorAttachment.$1,
                  _anchorAttachment.$2,
                );
                final menuAlignment = AlignmentDirectional(_menuAttachment.$1, _menuAttachment.$2);
                final offset = Offset(_alignmentOffset.$1 * 200, _alignmentOffset.$2 * 200);
                return Align(
                  alignment: AlignmentDirectional(_anchorPosition.$1, _anchorPosition.$2),
                  child: widget.build(
                    context,
                    DefaultMenuPositioningDelegate(
                      anchorAlignment: anchorAlignment,
                      menuAlignment: menuAlignment,
                      offset: offset,
                      edgeBehavior: EdgeBehavior(
                        horizontal: EdgeBehaviorStrategy(
                          flip: _horizontalFlip,
                          shift: _horizontalShift,
                          constrain: _horizontalConstrain,
                        ),
                        vertical: EdgeBehaviorStrategy(
                          flip: _verticalFlip,
                          shift: _verticalShift,
                          constrain: _verticalConstrain,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _BehaviorColumn extends StatefulWidget {
  const _BehaviorColumn({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  State<_BehaviorColumn> createState() => _BehaviorColumnState();
}

class _BehaviorColumnState extends State<_BehaviorColumn> {
  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: TextStyle(
        fontFamily: 'RobotoFlex',
        package: kPackage,
        fontSize: 12,
        color: AppColorScheme.of(context).brightness == Brightness.dark ? white : black,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          BaseMenuBar(
            orientation: Axis.vertical,
            child: BaseMenuPanel(children: widget.children),
          ),
        ],
      ),
    );
  }
}
