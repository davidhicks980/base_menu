import 'dart:ui' as ui;

import 'package:base_menu/base_menu.dart';
import 'package:flutter/widgets.dart';

import '../app/app.dart';
import '../checkbox_menu_item/src/checkbox_menu_item.dart';
import 'checkbox.dart';
import 'grid_slider.dart';
import 'package.dart';

class AlignmentTemplate extends StatefulWidget {
  const AlignmentTemplate({super.key, required this.build, this.title, required this.controller});
  final Widget Function(BuildContext context, DefaultMenuPositioningDelegate delegate) build;

  final MenuController controller;

  final Widget? title;

  @override
  State<AlignmentTemplate> createState() => _AlignmentTemplateState();
}

class _AlignmentTemplateState extends State<AlignmentTemplate> {
  final FocusNode anchorFocusNode = FocusNode();
  final FocusNode anchorFocusNode2 = FocusNode();
  final FocusNode anchorFocusNode3 = FocusNode();
  ScrollController scrollController = ScrollController();

  ui.Brightness brightness = ui.Brightness.dark;
  (double, double) _menuPosition = (0, 0);
  (double, double) _menuAttachment = (-1, 1);
  (double, double) _anchorAttachment = (1, -1);
  (double, double) _anchorPosition = (0, 0);
  (double, double) _alignmentOffset = (0, 0);

  bool _hFlip = true;
  bool _hShift = true;
  bool _hConstrain = true;
  bool _vFlip = true;
  bool _vShift = true;
  bool _vConstrain = true;

  @override
  Widget build(BuildContext context) {
    final anchorAlignment = AlignmentDirectional(_anchorAttachment.$1, _anchorAttachment.$2);
    final menuAlignment = AlignmentDirectional(_menuAttachment.$1, _menuAttachment.$2);
    final offset = Offset(_alignmentOffset.$1 * 200, _alignmentOffset.$2 * 200);
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: <Widget>[
          if (widget.title != null) widget.title!,
          FocusTraversalGroup(
            policy: WidgetOrderTraversalPolicy(),
            child: Column(
              spacing: 20,
              children: [
                Wrap(
                  alignment: .center,
                  children: <Widget>[
                    GridSlider(
                      size: const Size(100, 100),
                      x: _anchorPosition.$1,
                      y: _anchorPosition.$2,
                      title: const TextSpan(text: 'Anchor Position'),
                      onChange: (double x, double y) {
                        setState(() {
                          _anchorPosition = (x, y);
                        });
                      },
                    ),
                    GridSlider(
                      size: const Size(100, 100),
                      x: _menuPosition.$1,
                      y: _menuPosition.$2,
                      title: const TextSpan(text: 'Controller Position'),
                      onChange: (double x, double y) {
                        setState(() {
                          _menuPosition = (x, y);
                          widget.controller.open(position: Offset(x * 200, y * 200));
                        });
                      },
                    ),
                    GridSlider(
                      size: const Size(100, 100),
                      x: _anchorAttachment.$1,
                      y: _anchorAttachment.$2,
                      title: const TextSpan(text: 'Alignment'),
                      onChange: (double x, double y) {
                        setState(() {
                          _anchorAttachment = (x, y);
                        });
                      },
                    ),
                    GridSlider(
                      size: const Size(100, 100),
                      x: _alignmentOffset.$1 * 10,
                      y: _alignmentOffset.$2 * 10,
                      title: const TextSpan(text: 'Alignment Offset'),
                      onChange: (double x, double y) {
                        setState(() {
                          _alignmentOffset = (x / 10, y / 10);
                        });
                      },
                    ),
                    GridSlider(
                      size: const Size(100, 100),
                      x: _menuAttachment.$1,
                      y: _menuAttachment.$2,
                      title: const TextSpan(text: 'Menu Alignment'),
                      onChange: (double x, double y) {
                        setState(() {
                          _menuAttachment = (x, y);
                        });
                      },
                    ),
                  ],
                ),
                Row(
                  spacing: 20,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Add Horizontal Edge Behavior toggles
                    _BehaviorColumn(
                      title: 'Horizontal Behavior',
                      children: [
                        WebCheckboxMenuItem(
                          checkbox: const WebCheckbox(),
                          isChecked: _hFlip,
                          onChange: (v) {
                            setState(() {
                              _hFlip = v;
                            });
                          },
                          child: const Text('Flip'),
                        ),
                        WebCheckboxMenuItem(
                          checkbox: const WebCheckbox(),
                          isChecked: _hShift,
                          onChange: (v) {
                            setState(() {
                              _hShift = v;
                            });
                          },
                          child: const Text('Shift'),
                        ),
                        WebCheckboxMenuItem(
                          checkbox: const WebCheckbox(),
                          isChecked: _hConstrain,
                          onChange: (v) {
                            setState(() {
                              _hConstrain = v;
                            });
                          },
                          child: const Text('Constrain'),
                        ),
                      ],
                    ),

                    // Add Vertical Edge Behavior toggles
                    _BehaviorColumn(
                      title: 'Vertical Behavior',
                      children: [
                        WebCheckboxMenuItem(
                          checkbox: const WebCheckbox(),
                          isChecked: _vFlip,
                          onChange: (v) {
                            setState(() {
                              _vFlip = v;
                            });
                          },
                          child: const Text('Flip'),
                        ),
                        WebCheckboxMenuItem(
                          checkbox: const WebCheckbox(),
                          isChecked: _vShift,
                          onChange: (v) {
                            setState(() {
                              _vShift = v;
                            });
                          },
                          child: const Text('Shift'),
                        ),
                        WebCheckboxMenuItem(
                          checkbox: const WebCheckbox(),
                          isChecked: _vConstrain,
                          onChange: (v) {
                            setState(() {
                              _vConstrain = v;
                            });
                          },
                          child: const Text('Constrain'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional(_anchorPosition.$1, _anchorPosition.$2),
              child: widget.build(
                context,
                DefaultMenuPositioningDelegate(
                  anchorAlignment: anchorAlignment,
                  menuAlignment: menuAlignment,
                  offset: offset,
                  edgeBehavior: EdgeBehavior(
                    horizontal: EdgeBehaviorStrategy(
                      flip: _hFlip,
                      shift: _hShift,
                      constrain: _hConstrain,
                    ),
                    vertical: EdgeBehaviorStrategy(
                      flip: _vFlip,
                      shift: _vShift,
                      constrain: _vConstrain,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BehaviorColumn extends StatelessWidget {
  const _BehaviorColumn({required this.title, required this.children});
  final String title;
  final List<Widget> children;

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
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          BaseMenuBar(
            orientation: Axis.vertical,
            child: BaseMenuPanel(children: children),
          ),
        ],
      ),
    );
  }
}
