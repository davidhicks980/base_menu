// ignore_for_file: avoid_print, public_member_api_docs
import 'dart:ui';

import 'package:base_menu/base_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Moves the mouse from [start] to [end] over [duration], sending [steps] pointer events.
Future<void> moveMouse(
  TestGesture gesture, {
  required WidgetTester tester,
  required Offset start,
  required Offset end,
  required Duration duration,
  required int steps,
  ValueChanged<Offset>? onStep,
}) async {
  final int intervalMicros = duration.inMicroseconds ~/ steps;
  for (var i = 1; i <= steps; i++) {
    final double t = i / steps;
    final Offset location = Offset.lerp(start, end, t)!;

    // Advance the mock clock before the move to simulate elapsed time.
    await tester.pump(Duration(microseconds: intervalMicros));
    await gesture.moveTo(location);
    onStep?.call(location);
  }
}

/// Allows the creation of arbitrarily-nested tags in tests.
@immutable
abstract class Tag {
  const Tag();

  static const NestedTag anchor = NestedTag('anchor');
  static const NestedTag outside = NestedTag('outside');
  static const NestedTag inner = NestedTag('inner');
  static const NestedTag middle = NestedTag('middle');
  static const NestedTag outer = NestedTag('outer');
  static const NestedTag root = NestedTag('root');
  static const NestedTag overlay = NestedTag('overlay');
  static const NestedTag leading = NestedTag('leading');
  static const NestedTag trailing = NestedTag('trailing');
  static const NestedTag a = NestedTag('a');
  static const NestedTag b = NestedTag('b');
  static const NestedTag c = NestedTag('c');
  static const NestedTag d = NestedTag('d');
  static const NestedTag e = NestedTag('e');

  static const List<NestedTag> values = <NestedTag>[a, b, c, d, e];

  Tag reparent(Tag parent) {
    return NestedTag(_name, prefix: parent, level: parent.level + 1);
  }

  String get _name;
  String get text;
  String get focusNode;
  int get level;

  @override
  String toString() {
    return 'Tag($text, level: $level)';
  }
}

@immutable
class NestedTag extends Tag {
  const NestedTag(String name, {Tag? prefix, this.level = 0})
    : assert(
        // Limit the nesting level to prevent stack overflow.
        level < 9,
        'NestedTag.level must be less than 9 (was $level).',
      ),
      _name = name,
      _prefix = prefix;

  @override
  final String _name;
  final Tag? _prefix;

  @override
  final int level;

  NestedTag get a => NestedTag('a', prefix: this, level: level + 1);
  NestedTag get b => NestedTag('b', prefix: this, level: level + 1);
  NestedTag get c => NestedTag('c', prefix: this, level: level + 1);
  NestedTag get d => NestedTag('d', prefix: this, level: level + 1);
  NestedTag get e => NestedTag('e', prefix: this, level: level + 1);

  @override
  String get text {
    if (level == 0 || _prefix == null) {
      return _name;
    }
    return '${_prefix.text}.$_name';
  }

  @override
  String get focusNode {
    return 'Focus[$text]';
  }

  Key get key => ValueKey<String>('${text}_Key');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is NestedTag &&
        other._name == _name &&
        other._prefix == _prefix &&
        other.level == level;
  }

  @override
  int get hashCode => _name.hashCode ^ _prefix.hashCode ^ level.hashCode;
}

final WidgetStateProperty<BoxDecoration> testButtonDecoration = WidgetStateProperty.fromMap({
  WidgetState.pressed: const BoxDecoration(
    color: Color.fromARGB(255, 212, 21, 155),
    border: Border.symmetric(horizontal: BorderSide(color: Color.fromARGB(255, 255, 0, 242))),
  ),
  WidgetState.focused: const BoxDecoration(
    color: Color.fromARGB(255, 57, 15, 155),
    border: Border.symmetric(horizontal: BorderSide(color: Color.fromARGB(255, 76, 0, 255))),
  ),
  WidgetState.focused & WidgetState.hovered: const BoxDecoration(
    color: Color.fromARGB(255, 10, 46, 148),
    border: Border.symmetric(horizontal: BorderSide(color: Color.fromARGB(255, 76, 0, 254))),
  ),
  WidgetState.hovered: const BoxDecoration(color: Color.fromARGB(255, 62, 43, 106)),
  WidgetState.disabled: const BoxDecoration(color: Color.fromARGB(255, 64, 61, 71)),
  WidgetState.any: const BoxDecoration(
    color: Color.fromARGB(255, 33, 27, 47),
    border: Border(bottom: BorderSide(color: Color.fromARGB(255, 8, 5, 14))),
  ),
});

class Button extends StatefulWidget {
  const Button(
    this.child, {
    super.key,
    this.onPressed = _defaultCallback,
    this.focusNode,
    this.autofocus = false,
    this.onFocusChange,
    String? focusNodeLabel,
    BoxConstraints? constraints,
    this.role,
    this.requestFocusOnHover = false,
    this.requestCloseOnActivate = false,
  }) : constraints = constraints ?? const BoxConstraints.tightFor(width: 225, height: 32),
       _focusNodeLabel = focusNodeLabel;

  factory Button.text(
    String text, {
    Key? key,
    VoidCallback? onPressed = _defaultCallback,
    FocusNode? focusNode,
    bool autofocus = false,
    BoxConstraints? constraints,
    void Function(bool isFocused)? onFocusChange,
    SemanticsRole? role,
    bool requestFocusOnHover = false,
    bool requestCloseOnActivate = false,
  }) {
    return Button(
      Text(text),
      key: key,
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      constraints: constraints,
      onFocusChange: onFocusChange,
      focusNodeLabel: text,
      role: role,
      requestFocusOnHover: requestFocusOnHover,
      requestCloseOnActivate: requestCloseOnActivate,
    );
  }

  factory Button.tag(
    Tag tag, {
    Key? key,
    VoidCallback? onPressed = _defaultCallback,
    FocusNode? focusNode,
    bool autofocus = false,
    BoxConstraints? constraints,
    void Function(bool isFocused)? onFocusChange,
    SemanticsRole? role,
    bool requestFocusOnHover = false,
    bool requestCloseOnActivate = false,
  }) {
    return Button(
      Text(tag.text),
      key: key,
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      constraints: constraints,
      onFocusChange: onFocusChange,
      focusNodeLabel: tag.focusNode,
      role: role,
      requestFocusOnHover: requestFocusOnHover,
      requestCloseOnActivate: requestCloseOnActivate,
    );
  }

  final Widget child;
  final VoidCallback? onPressed;
  final void Function(bool)? onFocusChange;
  final FocusNode? focusNode;
  final bool autofocus;
  final BoxConstraints constraints;
  final String? _focusNodeLabel;
  final SemanticsRole? role;
  final bool requestFocusOnHover;
  final bool requestCloseOnActivate;

  static void _defaultCallback() {}

  @override
  State<Button> createState() => _ButtonState();
}

class _ButtonState extends State<Button> {
  FocusNode? internalFocusNode;
  FocusNode get effectiveFocusNode => widget.focusNode ?? internalFocusNode!;

  @override
  void dispose() {
    internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.focusNode == null) {
      internalFocusNode ??= FocusNode(debugLabel: widget._focusNodeLabel);
    } else {
      internalFocusNode?.dispose();
      internalFocusNode = null;
    }

    // Only apply the widget's label if the node doesn't already have one
    effectiveFocusNode.debugLabel ??= widget._focusNodeLabel;
    return BaseMenuItem(
      onPressed: widget.onPressed,
      focusNode: effectiveFocusNode,
      autofocus: widget.autofocus,
      onFocusChange: widget.onFocusChange,
      role: widget.role,
      requestFocusOnHover: widget.requestFocusOnHover,
      requestCloseOnActivate: widget.requestCloseOnActivate,
      child: Builder(
        builder: (context) {
          return ConstrainedBox(
            constraints: widget.constraints,
            child: DecoratedBox(
              decoration: testButtonDecoration.resolve(BaseMenuItem.statesOf(context)),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: widget.child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AnchorButton extends StatelessWidget {
  const AnchorButton(
    this.tag, {
    super.key,
    this.onPressed,
    this.constraints,
    this.autofocus = false,
    this.focusNode,
  });

  factory AnchorButton.small(NestedTag tag) {
    return AnchorButton(tag, constraints: BoxConstraints.tight(const Size(225, 30)));
  }

  final NestedTag tag;
  final void Function(NestedTag)? onPressed;
  final bool autofocus;
  final BoxConstraints? constraints;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final MenuController? controller = MenuController.maybeOf(context);
    return Button.tag(
      tag,
      key: tag.key,
      onPressed: () {
        onPressed?.call(tag);
        if (controller != null) {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
          }
        }
      },
      focusNode: focusNode,
      constraints: constraints,
      autofocus: autofocus,
    );
  }
}

class App extends StatefulWidget {
  const App(
    this.child, {
    super.key,
    this.textDirection,
    this.alignment = Alignment.center,
    this.actions,
    this.shortcuts,
    this.backgroundColor = const Color(0xff000000),
    this.localizationsDelegates,
  });
  final Widget child;
  final TextDirection? textDirection;
  final AlignmentGeometry alignment;
  final Map<Type, Action<Intent>>? actions;
  final Map<ShortcutActivator, Intent>? shortcuts;
  final Color backgroundColor;
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  TextDirection? _directionality;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _directionality = Directionality.maybeOf(context);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: widget.backgroundColor,
      child: FocusScope(
        autofocus: true,
        debugLabel: Tag.root.focusNode,
        child: WidgetsApp(
          localizationsDelegates: widget.localizationsDelegates,
          actions: widget.actions ?? WidgetsApp.defaultActions,
          shortcuts: widget.shortcuts ?? WidgetsApp.defaultShortcuts,
          color: widget.backgroundColor,
          onGenerateRoute: (RouteSettings settings) {
            return PageRouteBuilder<void>(settings: settings, pageBuilder: _buildPage);
          },
        ),
      ),
    );
  }

  Widget _buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Directionality(
      textDirection: widget.textDirection ?? _directionality ?? TextDirection.ltr,
      child: Align(alignment: widget.alignment, child: widget.child),
    );
  }
}

class MenuSystem extends StatelessWidget {
  const MenuSystem({
    super.key,
    this.layers = const [.horizontal, .vertical, .vertical, .vertical],
    this.disabledItems = const {},
    this.isMenuBar = true,
    this.autofocus,
    this.leading,
    this.trailing,
  });

  final List<Axis> layers;
  final bool isMenuBar;
  final Tag? autofocus;
  final Set<Tag> disabledItems;

  /// An optional widget to place before the first menu. This is useful for
  /// testing that focus traversal works correctly with non-menu widgets in the
  /// tree.
  final Widget? leading;

  /// An optional widget to place after the last menu. This is useful for
  /// testing that focus traversal works correctly with non-menu widgets in the
  /// tree.
  final Widget? trailing;

  Widget _buildLevel({required int depth, Tag? parentTag}) {
    Iterable<Tag> currentTags = Tag.values;
    if (parentTag != null) {
      currentTags = currentTags.map((t) => t.reparent(parentTag));
    }

    // Otherwise, build a submenu and recurse to the next depth level
    return DefaultTextStyle(
      style: const TextStyle(color: Color(0xFFFFFFFF)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.25),
              blurRadius: 4,
              spreadRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: BaseMenuPanel(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 4, vertical: 4),
          orientation: layers[depth],
          children: [
            ?leading,
            for (final tag in currentTags)
              if (depth < layers.length - 1)
                _Submenu(
                  autofocus: autofocus == tag && depth == 0,
                  tag: tag,
                  orientation: layers[depth + 1],
                  trailing: layers[depth] == Axis.vertical ? '>' : 'v',
                  menu: _buildLevel(depth: depth + 1, parentTag: tag),
                  enabled: !disabledItems.contains(tag),
                )
              else
                Button.tag(
                  tag,
                  role: .menuItem,
                  requestFocusOnHover: true,
                  requestCloseOnActivate: true,
                  autofocus: autofocus == tag && depth == 0,
                  onPressed: disabledItems.contains(tag) ? null : () {},
                ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isMenuBar) {
      return BaseMenuBar(orientation: layers.first, child: _buildLevel(depth: 0));
    } else {
      return BaseMenu(
        directionalFocusEdgeBehavior: .closedLoop,
        orientation: layers.first,
        menu: _buildLevel(depth: 0),
        child: AnchorButton(Tag.anchor, autofocus: autofocus == Tag.anchor, onPressed: (tag) {}),
      );
    }
  }
}

class _Submenu extends StatefulWidget {
  const _Submenu({
    required this.tag,
    required this.menu,
    required this.trailing,
    required this.orientation,
    this.enabled = true,
    this.autofocus = false,
  });

  final Tag tag;
  final Widget menu;
  final String trailing;
  final Axis orientation;
  final bool autofocus;
  final bool enabled;

  @override
  State<_Submenu> createState() => _SubmenuState();
}

class _SubmenuState extends State<_Submenu> {
  final controller = MenuController();
  late final FocusNode internalFocusNode;

  @override
  void initState() {
    super.initState();
    internalFocusNode = FocusNode(debugLabel: widget.tag.focusNode);
  }

  @override
  void dispose() {
    internalFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: widget.tag.level == 0
          ? const BoxConstraints.tightFor(width: 150, height: 32)
          : const BoxConstraints.tightFor(width: 225, height: 32),
      child: BaseSubmenu(
        role: widget.tag == Tag.anchor ? null : .menuItem,
        directionalFocusEdgeBehavior: .closedLoop,
        positionDelegate: const DefaultMenuPositioningDelegate(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 4, vertical: 4),
        ),
        autofocus: widget.autofocus,
        controller: controller,
        orientation: widget.orientation,
        focusNode: internalFocusNode,
        enabled: widget.enabled,
        onPressed: widget.enabled
            ? () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              }
            : null,
        menu: widget.menu,
        child: SubmenuChild(tag: widget.tag, trailing: widget.trailing),
      ),
    );
  }
}

class MockSemanticsGestureDelegate extends SemanticsGestureDelegate {
  @override
  void assignSemantics(RenderSemanticsGestureHandler renderObject) {}
}

class SubmenuChild extends StatelessWidget {
  const SubmenuChild({super.key, required this.tag, this.trailing});
  final Tag tag;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: tag.level == 0
          ? const BoxConstraints.tightFor(width: 150, height: 32)
          : const BoxConstraints.tightFor(width: 225, height: 32),
      child: DecoratedBox(
        decoration: testButtonDecoration.resolve(BaseMenuItem.statesOf(context)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tag.text),
              Text(
                trailing ?? (tag.level == 0 ? '>' : 'v'),
                style: const TextStyle(fontSize: 12, color: Color(0xFFFFFFFF)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MenuItemChild extends StatelessWidget {
  const MenuItemChild({super.key, required this.tag});
  final Tag tag;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: tag.level == 0
          ? const BoxConstraints.tightFor(width: 150, height: 32)
          : const BoxConstraints.tightFor(width: 225, height: 32),
      child: DecoratedBox(
        decoration: testButtonDecoration.resolve(BaseMenuItem.statesOf(context)),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text(tag.text)),
      ),
    );
  }
}
