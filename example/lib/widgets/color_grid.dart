import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../utilities/colors.dart';
import 'menu_action_label.dart';

// While the color grid is inspired by the default Google Docs palette, the
// colors themselves are custom.
const List<List<Color>> _kColorGrid = [
  [
    Color(0xFF000000),
    Color(0xFF434343),
    Color(0xFF666666),
    Color(0xFF999999),
    Color(0xFFB7B7B7),
    Color(0xFFCCCCCC),
    Color(0xFFD9D9D9),
    Color(0xFFEFEFEF),
    Color(0xFFF3F3F3),
    Color(0xFFFFFFFF),
  ],
  [
    Color(0xFFB00C00), // Maroon
    Color(0xFFFF0000), // Red
    Color(0xFFFF9900), // Orange
    Color(0xFFFFFF00), // Yellow
    Color(0xFF00FF00), // Green
    Color(0xFF00FFFF), // Cyan
    Color(0xFF478DFF), // Blue
    Color(0xFF0000FF), // Dark Blue
    Color(0xFF9900FF), // Purple
    Color(0xFFFF00FF), // Magenta
  ],
  [
    Color(0xFFEA9999),
    Color(0xFFFF9999),
    Color(0xFFFFD699),
    Color(0xFFFFE69B),
    Color(0xFF99FF99),
    Color(0xFF99FFFF),
    Color(0xFFB3CFFF),
    Color(0xFF9999FF),
    Color(0xFFCC99FF),
    Color(0xFFFF99FF),
  ],
  [
    Color(0xFFE44829),
    Color(0xFFF42D2D),
    Color(0xFFFFBD76),
    Color(0xFFFFD862),
    Color(0xFFA0E981),
    Color(0xFF6EE6E6),
    Color(0xFF658FEA),
    Color(0xFF417FEC),
    Color(0xFFA260D4),
    Color(0xFFEB35EB),
  ],
  [
    Color(0xFFB93217),
    Color(0xFFEA0B0B),
    Color(0xFFF6AE60),
    Color(0xFFFFD148),
    Color(0xFF82C565),
    Color(0xFF58D9D9),
    Color(0xFF4471D3),
    Color(0xFF286BDF),
    Color(0xFF8743BB),
    Color(0xFFDC10DC),
  ],
  [
    Color(0xFF85200C),
    Color(0xFFCC0000),
    Color(0xFFE69138),
    Color(0xFFF1C232),
    Color(0xFF6AA84F),
    Color(0xFF45BFBF),
    Color(0xFF3564C8),
    Color(0xFF1155CC),
    Color(0xFF7030A0),
    Color(0xFFBF00BF),
  ],
  [
    Color(0xFF5C1409),
    Color(0xFF990000),
    Color(0xFFB45F06),
    Color(0xFFBF9000),
    Color(0xFF38761D),
    Color(0xFF2D8080),
    Color(0xFF1F3D85),
    Color(0xFF0B3D91),
    Color(0xFF4A1980),
    Color(0xFF800080),
  ],
  [
    Color(0xFF3C0D06),
    Color(0xFF660000),
    Color(0xFF783F04),
    Color(0xFF7F6000),
    Color(0xFF274E13),
    Color(0xFF1A4D4D),
    Color(0xFF142759),
    Color(0xFF072562),
    Color(0xFF300D57),
    Color(0xFF560056),
  ],
];

const List<Color> _kCustomColors = [Color(0xFF1B2A4A), Color(0xFF2E7D6F)];

final _kColorNames = {
  const Color(0xFF000000): 'Black',
  const Color(0xFFFFFFFF): 'White',
  const Color(0xFFFF0000): 'Red',
  const Color(0xFFFF9900): 'Orange',
  const Color(0xFFFFFF00): 'Yellow',
  const Color(0xFF00FF00): 'Green',
  const Color(0xFF00FFFF): 'Cyan',
  const Color(0xFF0000FF): 'Blue',
  const Color(0xFF9900FF): 'Purple',
  const Color(0xFFFF00FF): 'Magenta',
};

// ...existing code...
String colorLabel(Color color) {
  // Exact name for exact match.
  final exact = _kColorNames[color];
  if (exact != null) {
    return exact;
  }

  // Find closest named color by Euclidean distance in RGB and return an "approximate"
  // if it's reasonably close.
  final int r = color.red, g = color.green, b = color.blue;
  Color? closest;
  double bestSqDist = double.infinity;
  for (final namedColor in _kColorNames.keys) {
    final dr = r - namedColor.red;
    final dg = g - namedColor.green;
    final db = b - namedColor.blue;
    final sqDist = (dr * dr + dg * dg + db * db).toDouble();
    if (sqDist < bestSqDist) {
      bestSqDist = sqDist;
      closest = namedColor;
    }
  }

  if (closest != null && bestSqDist <= 30 * 30) {
    return '${_kColorNames[closest]!} (approximate)';
  }

  // Fall back to a stable hex representation. Include alpha if not fully opaque.
  String twoHex(int v) => v.toRadixString(16).padLeft(2, '0').toUpperCase();
  final hexRgb = '#${twoHex(color.red)}${twoHex(color.green)}${twoHex(color.blue)}';
  return 'Color $hexRgb';
}

Brightness _estimateBrightnessForColor(Color color) {
  final double relativeLuminance = color.computeLuminance();

  // See <https://www.w3.org/TR/WCAG20/#contrast-ratiodef>
  // The spec says to use kThreshold=0.0525, but Material Design appears to bias
  // more towards using light text than WCAG20 recommends. Material Design spec
  // doesn't say what value to use, but 0.15 seemed close to what the Material
  // Design spec shows for its color palette on
  // <https://material.io/go/design-theming#color-color-palette>.
  const kThreshold = 0.15;
  if ((relativeLuminance + 0.05) * (relativeLuminance + 0.05) > kThreshold) {
    return Brightness.light;
  }
  return Brightness.dark;
}

class _ColorSwatch extends StatefulWidget {
  const _ColorSwatch({
    super.key,
    required this.color,
    required this.onTap,
    this.isSelected = false,
  });

  final Color color;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  State<_ColorSwatch> createState() => _ColorSwatchState();
}

class _ColorSwatchState extends State<_ColorSwatch> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = _estimateBrightnessForColor(widget.color) == Brightness.light;
    final borderColor = isLight
        ? const Color.from(alpha: 1, red: 0.741, green: 0.741, blue: 0.741)
        : FloogleColors.transparent;
    final icon = widget.isSelected
        ? Icon(
            Symbols.check,
            size: 12,
            color: isLight
                ? const Color.from(alpha: 0.867, red: 0, green: 0, blue: 0)
                : FloogleColors.white,
          )
        : null;
    return MergeSemantics(
      child: Semantics(
        label: colorLabel(widget.color),
        button: true,
        selected: widget.isSelected,
        child: BaseControl(
          focusNode: _focusNode,
          onTap: widget.onTap,
          onPointerEnter: (event) {
            // Announce the color name on hover for accessibility
            final label = colorLabel(widget.color);
            SemanticsService.announce(label, TextDirection.ltr);
            _focusNode.requestFocus();
          },
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
          child: Builder(
            builder: (context) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  border: Border.all(color: borderColor, width: 0.5),
                  boxShadow: BaseControl.isFocusedOf(context)
                      ? [
                          BoxShadow(
                            color: FloogleColors.black.withOpacity(0.6),
                            blurRadius: 3,
                            spreadRadius: 1,
                          ),
                        ]
                      : BaseControl.isHoveredOf(context) || widget.isSelected
                      ? [
                          BoxShadow(
                            color: FloogleColors.black.withOpacity(0.35),
                            blurRadius: 3,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: icon,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ColorGrid extends StatelessWidget {
  const _ColorGrid({
    required this.rows,
    required this.onColorSelected,
    required this.selectedColor,
  });

  final List<List<Color>> rows;
  final ValueChanged<Color> onColorSelected;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final color in row)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: _ColorSwatch(
                      key: ValueKey('swatch_${row.indexOf(color)}_${rows.indexOf(row)}'),
                      color: color,
                      isSelected: selectedColor == color,
                      onTap: () {
                        onColorSelected(color);
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class ColorPickerPanel extends StatefulWidget {
  const ColorPickerPanel({
    super.key,
    required this.onColorSelected,
    this.selectedColor,
    this.leading,
  });

  final ValueChanged<Color> onColorSelected;
  final Color? selectedColor;
  final Widget? leading;

  @override
  State<ColorPickerPanel> createState() => _ColorPickerPanelState();
}

class _ColorPickerPanelState extends State<ColorPickerPanel> {
  final FocusScopeNode _panelFocusScopeNode = FocusScopeNode(
    debugLabel: 'ColorPickerPanel Parent Focus Scope',
    directionalTraversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );

  final FocusScopeNode _gridFocusScopeNode = FocusScopeNode(
    debugLabel: 'ColorPickerPanel Focus Scope',
    directionalTraversalEdgeBehavior: TraversalEdgeBehavior.parentScope,
  );
  Color? _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.selectedColor;
  }

  void _handleColorSelected(Color color) {
    setState(() {
      _selectedColor = color;
    });
    widget.onColorSelected(color);
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        NextFocusIntent: CallbackAction<NextFocusIntent>(
          onInvoke: (intent) {
            _panelFocusScopeNode.nextFocus();
            return null;
          },
        ),
        PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(
          onInvoke: (intent) {
            _panelFocusScopeNode.previousFocus();
            return null;
          },
        ),
      },
      child: Shortcuts(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.arrowUp): const PreviousFocusIntent(),
          LogicalKeySet(LogicalKeyboardKey.arrowDown): const NextFocusIntent(),
          LogicalKeySet(LogicalKeyboardKey.arrowLeft): const PreviousFocusIntent(),
          LogicalKeySet(LogicalKeyboardKey.arrowRight): const NextFocusIntent(),
        },
        child: FocusScope(
          node: _panelFocusScopeNode,
          descendantsAreFocusable: true,
          descendantsAreTraversable: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ?widget.leading,
                Actions(
                  actions: {
                    DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
                      onInvoke: (intent) {
                        _gridFocusScopeNode.focusInDirection(intent.direction);
                        return null;
                      },
                    ),
                  },
                  child: Shortcuts(
                    shortcuts: {
                      LogicalKeySet(LogicalKeyboardKey.arrowUp): const DirectionalFocusIntent(
                        TraversalDirection.up,
                      ),
                      LogicalKeySet(LogicalKeyboardKey.arrowDown): const DirectionalFocusIntent(
                        TraversalDirection.down,
                      ),
                      LogicalKeySet(LogicalKeyboardKey.arrowLeft): const DirectionalFocusIntent(
                        TraversalDirection.left,
                      ),
                      LogicalKeySet(LogicalKeyboardKey.arrowRight): const DirectionalFocusIntent(
                        TraversalDirection.right,
                      ),
                    },
                    child: FocusScope(
                      node: _gridFocusScopeNode,
                      descendantsAreTraversable: true,
                      descendantsAreFocusable: true,
                      child: _ColorGrid(
                        rows: _kColorGrid,
                        onColorSelected: _handleColorSelected,
                        selectedColor: _selectedColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                BaseMenuItem(
                  onTap: () {},
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 28),
                      child: const MenuActionLabel(
                        leadingWidth: 2,
                        child: Text(
                          'CUSTOM',
                          style: TextStyle(
                            fontFamily: 'RobotoFlex',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: Color(0xFF5F6368),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 2),

                Row(
                  children: [
                    for (int i = 0; i < _kCustomColors.length; i++) ...[
                      _ColorSwatch(
                        color: _kCustomColors[i],
                        isSelected: _selectedColor == _kCustomColors[i],
                        onTap: () => _handleColorSelected(_kCustomColors[i]),
                      ),
                      const SizedBox(width: 2),
                    ],

                    const SizedBox(width: 4),

                    CustomAction(
                      icon: Symbols.add_circle_outline,
                      label: 'Add custom color',
                      onPressed: () {},
                    ),

                    const SizedBox(width: 4),

                    CustomAction(
                      icon: Symbols.colorize,
                      label: 'Pick color from screen',
                      onPressed: () {},
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
}

class CustomAction extends StatelessWidget {
  const CustomAction({super.key, required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: BaseControl(
        onTap: () {},
        child: Builder(
          builder: (context) {
            return DecoratedBox(
              decoration: BaseControl.isPressedOf(context)
                  ? const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                      color: Color.fromARGB(25, 0, 0, 0),
                    )
                  : BaseControl.isHoveredOf(context) || BaseControl.isFocusedOf(context)
                  ? const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                      color: Color.fromARGB(15, 0, 0, 0),
                    )
                  : const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                      color: FloogleColors.transparent,
                    ),
              child: Icon(
                icon,
                size: 22,
                color: const Color.from(alpha: 1, red: 0.38, green: 0.38, blue: 0.38),
              ),
            );
          },
        ),
      ),
    );
  }
}
