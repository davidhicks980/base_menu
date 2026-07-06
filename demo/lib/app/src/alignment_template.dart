import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'grid_slider.dart';

class AlignmentTemplate extends StatefulWidget {
  const AlignmentTemplate({super.key, required this.build, this.title});
  final Widget Function(
    BuildContext context,
    AlignmentGeometry anchorAlignment,
    AlignmentGeometry menuAlignment,
    Offset alignmentOffset,
  )
  build;

  final Widget? title;

  @override
  State<AlignmentTemplate> createState() => _AlignmentTemplateState();
}

class _AlignmentTemplateState extends State<AlignmentTemplate> {
  final FocusNode anchorFocusNode = FocusNode();
  final FocusNode anchorFocusNode2 = FocusNode();
  final FocusNode anchorFocusNode3 = FocusNode();
  ScrollController scrollController = ScrollController();
  MenuController controller = MenuController();

  ui.Brightness brightness = ui.Brightness.dark;
  (double, double) _menuPosition = (0, 0);
  (double, double) _menuAttachment = (-1, 1);
  (double, double) _anchorAttachment = (1, -1);
  (double, double) _anchorPosition = (0, 0);
  (double, double) _alignmentOffset = (0, 0);

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
            child: Wrap(
              spacing: 20.0,
              runSpacing: 20.0,
              children: <Widget>[
                GridSlider(
                  x: _anchorPosition.$1,
                  y: _anchorPosition.$2,
                  title: const Text('Anchor Position'),
                  onChange: (double x, double y) {
                    setState(() {
                      _anchorPosition = (x, y);
                    });
                  },
                ),
                GridSlider(
                  x: _menuPosition.$1,
                  y: _menuPosition.$2,
                  title: const Text('Controller Position'),
                  onChange: (double x, double y) {
                    setState(() {
                      _menuPosition = (x, y);
                      controller.open(position: Offset(x * 200, y * 200));
                    });
                  },
                ),
                GridSlider(
                  x: _anchorAttachment.$1,
                  y: _anchorAttachment.$2,
                  title: const Text('Alignment'),
                  onChange: (double x, double y) {
                    setState(() {
                      _anchorAttachment = (x, y);
                    });
                  },
                ),
                GridSlider(
                  x: _alignmentOffset.$1,
                  y: _alignmentOffset.$2,
                  title: const Text('Alignment Offset'),
                  onChange: (double x, double y) {
                    setState(() {
                      _alignmentOffset = (x, y);
                    });
                  },
                ),
                GridSlider(
                  x: _menuAttachment.$1,
                  y: _menuAttachment.$2,
                  title: const Text('Menu Alignment'),
                  onChange: (double x, double y) {
                    setState(() {
                      _menuAttachment = (x, y);
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional(_anchorPosition.$1, _anchorPosition.$2),
              child: widget.build(context, anchorAlignment, menuAlignment, offset),
            ),
          ),
        ],
      ),
    );
  }
}
