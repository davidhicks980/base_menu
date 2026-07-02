import 'package:base_menu/base_menu.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../theme/colors.dart';
import 'menu_item_radio_semantics.dart';

class TileGroup<T> extends StatefulWidget {
  const TileGroup({
    super.key,
    required this.tileSize,
    required this.columns,
    required this.value,
    required this.tilePadding,
    required this.children,
    required this.onTilePressed,
  });

  final Size tileSize;
  final EdgeInsetsGeometry tilePadding;
  final List<Widget> children;
  final int columns;
  final T value;
  final void Function(BuildContext context, int index) onTilePressed;

  @override
  State<TileGroup<T>> createState() => _TileGroupState<T>();
}

class _TileGroupState<T> extends State<TileGroup<T>> {
  final _actions = <Type, Action<Intent>>{DirectionalFocusIntent: DirectionalFocusAction()};
  final WidgetOrderTraversalPolicy _traversalPolicy = WidgetOrderTraversalPolicy();
  final FocusScopeNode _focusScopeNode = FocusScopeNode(
    traversalEdgeBehavior: TraversalEdgeBehavior.parentScope,
    directionalTraversalEdgeBehavior: TraversalEdgeBehavior.parentScope,
  );

  @override
  void dispose() {
    _focusScopeNode.dispose();
    super.dispose();
  }

  bool value = false;
  bool _exitStart = false;
  bool _exitEnd = false;

  @override
  Widget build(BuildContext context) {
    final rows = (widget.children.length / widget.columns).ceil();
    final directionality = Directionality.of(context);
    final isRtl = directionality == TextDirection.rtl;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: FocusTraversalGroup(
        policy: _traversalPolicy,
        child: Shortcuts(
          shortcuts: {
            const SingleActivator(LogicalKeyboardKey.arrowDown): const DirectionalFocusIntent(
              TraversalDirection.down,
            ),
            const SingleActivator(LogicalKeyboardKey.arrowUp): const DirectionalFocusIntent(
              TraversalDirection.up,
            ),
            if (isRtl ? !_exitEnd : !_exitStart)
              const SingleActivator(LogicalKeyboardKey.arrowLeft): const DirectionalFocusIntent(
                TraversalDirection.left,
              ),
            if (isRtl ? !_exitStart : !_exitEnd)
              const SingleActivator(LogicalKeyboardKey.arrowRight): const DirectionalFocusIntent(
                TraversalDirection.right,
              ),
          },
          child: Actions(
            actions: _actions,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                for (var row = 0; row < rows; row++)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 8,
                    children: [
                      for (
                        int column = 0, i = widget.columns * row;
                        column < widget.columns;
                        column += 1, i += 1
                      )
                        _Tile(
                          key: ValueKey(widget.children[i]),
                          checked: widget.children[i] == widget.value,
                          autofocus: widget.children[i] == widget.value,
                          onPressed: () => widget.onTilePressed(context, i),
                          onFocusChange: (isFocused) {
                            if (isFocused) {
                              _handleFocusChange(column);
                            }
                          },
                          child: widget.children[i],
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleFocusChange(int col) {
    final newExitStart = col == 0;
    final newExitEnd = col == widget.columns - 1;
    if (newExitStart != _exitStart || newExitEnd != _exitEnd) {
      setState(() {
        _exitStart = newExitStart;
        _exitEnd = newExitEnd;
      });
    }
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    this.onFocusChange,
    this.autofocus = false,
    required this.onPressed,
    required this.checked,
    required this.child,
  });

  final void Function(bool)? onFocusChange;
  final VoidCallback onPressed;
  final bool checked;
  final bool autofocus;
  final Widget child;

  static const hoveredFocusStyle = BoxDecoration(
    color: FloogleColors.white,
    border: Border.fromBorderSide(BorderSide(color: Color(0xFF747775))),
    boxShadow: [
      BoxShadow(
        offset: Offset(0, 1),
        blurRadius: 2,
        color: Color.from(alpha: 0.1, red: 0, green: 0, blue: 0),
      ),
    ],
  );
  static const selectedStyle = BoxDecoration(
    color: FloogleColors.white,
    border: Border.fromBorderSide(BorderSide(color: Color(0xFF747775), width: 2)),
    boxShadow: [
      BoxShadow(
        offset: Offset(0, 1),
        blurRadius: 2,
        color: Color.from(alpha: 0.1, red: 0, green: 0, blue: 0),
      ),
    ],
  );

  static const _decoration = WidgetStateProperty<BoxDecoration>.fromMap({
    WidgetState.hovered: hoveredFocusStyle,
    WidgetState.focused: hoveredFocusStyle,
    WidgetState.selected: selectedStyle,
    WidgetState.any: BoxDecoration(
      color: FloogleColors.white,
      border: Border.fromBorderSide(BorderSide(color: Color(0xFFC4C7C5))),
    ),
  });
  @override
  Widget build(BuildContext context) {
    return MenuItemRadioSemantics(
      checked: checked,
      child: BaseMenuItem(
        role: null,
        onPressed: onPressed,
        onFocusChange: onFocusChange,
        autofocus: autofocus,
        child: Builder(
          builder: (context) {
            return DecoratedBox(
              decoration: _decoration.resolve(
                BaseMenuItem.statesOf(context).union({if (checked) WidgetState.selected}),
              ),
              child: child,
            );
          },
        ),
      ),
    );
  }
}
