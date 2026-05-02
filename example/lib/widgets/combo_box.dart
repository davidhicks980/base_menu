import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../utilities/colors.dart';
import 'editable.dart';
import 'menu_action_label.dart';
import 'menu_panel.dart';

class ComboBoxTraversePreviousIntent extends Intent {
  const ComboBoxTraversePreviousIntent();
}

class ComboBoxTraverseNextIntent extends Intent {
  const ComboBoxTraverseNextIntent();
}

class _ComboBoxValue extends InheritedWidget {
  const _ComboBoxValue({required super.child, required this.value});

  final String value;
  static String of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ComboBoxValue>()!.value;
  }

  @override
  bool updateShouldNotify(_ComboBoxValue oldWidget) {
    return value != oldWidget.value;
  }
}

class ComboBoxOption extends StatelessWidget {
  const ComboBoxOption({super.key, required this.value, this.onPressed});

  final String value;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // This should be a SemanticsRole.option, but this is currently not
    // supported by Flutter's semantics system.
    return CoreMenuItem(
      requestFocusOnHover: false,
      onPressed: onPressed,
      child: Builder(
        builder: (context) {
          final query = _ComboBoxValue.of(context);
          final isSelected = query == value;
          return ColoredBox(
            color: isSelected ? const Color(0xFFf2f2f2) : FloogleColors.transparent,
            child: MenuActionLabel(leadingWidth: 16, child: Text(value)),
          );
        },
      ),
    );
  }
}

class ComboBox extends StatefulWidget {
  const ComboBox({
    super.key,
    required this.children,
    this.onSelect,
    this.trailing,
    this.inputConstraints = const BoxConstraints(minHeight: 28, maxHeight: 28),
    required this.selected,
    this.focusNode,
    this.textStyle = const TextStyle(
      fontFamily: 'GoogleSans',
      fontSize: 14,
      color: FloogleColors.gray,
      decoration: TextDecoration.none,
      fontWeight: kIsWeb ? FontWeight.w500 : FontWeight.w400,
    ),
    this.menuController,
  });

  final List<Widget> children;
  final ValueChanged<String>? onSelect;
  final String selected;
  final Widget? trailing;
  final BoxConstraints inputConstraints;
  final FocusNode? focusNode;
  final MenuController? menuController;
  final TextStyle textStyle;

  @override
  State<ComboBox> createState() => _ComboBoxState();
}

class _ComboBoxState extends State<ComboBox> {
  late final TextEditingController _textController;
  FocusNode? _internalFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.selected);
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }
  }

  @override
  void didUpdateWidget(covariant ComboBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _textController.text = widget.selected;
    }

    if (oldWidget.focusNode != widget.focusNode) {
      if (widget.focusNode == null) {
        _internalFocusNode = FocusNode();
      } else {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      }
    }
  }

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CoreMenu(
      controller: widget.menuController,
      padding: MenuPanel.defaultPadding,
      alignmentOffset: const Offset(0, 6),
      panel: ValueListenableBuilder(
        valueListenable: _textController,
        builder: (context, value, child) {
          return _ComboBoxValue(value: widget.selected, child: child!);
        },
        child: MenuPanel(children: widget.children),
      ),
      builder: (BuildContext context, MenuController controller, Widget? child) {
        return _Anchor(
          focusNode: _focusNode,
          textController: _textController,
          constraints: widget.inputConstraints,
          menuController: controller,
          trailing: widget.trailing,
          onSelect: widget.onSelect,
          selected: widget.selected,
          textStyle: widget.textStyle,
        );
      },
    );
  }
}

class _Anchor extends StatelessWidget {
  const _Anchor({
    required this.focusNode,
    required this.textController,
    required this.constraints,
    this.menuController,
    this.trailing,
    this.onSelect,
    required this.textStyle,
    required this.selected,
  });
  final FocusNode focusNode;
  final TextEditingController textController;
  final MenuController? menuController;
  final BoxConstraints constraints;
  final Widget? trailing;
  final ValueChanged<String>? onSelect;
  final String selected;
  final TextStyle textStyle;

  static const _shortcuts = {
    SingleActivator(LogicalKeyboardKey.arrowUp): ComboBoxTraversePreviousIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown): ComboBoxTraverseNextIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft): ExtendSelectionByCharacterIntent(
      forward: false,
      collapseSelection: true,
    ),
    SingleActivator(LogicalKeyboardKey.arrowRight): ExtendSelectionByCharacterIntent(
      forward: true,
      collapseSelection: true,
    ),
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): ExtendSelectionByCharacterIntent(
      forward: false,
      collapseSelection: false,
    ),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): ExtendSelectionByCharacterIntent(
      forward: true,
      collapseSelection: false,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final isOpen = MenuController.maybeIsOpenOf(context) ?? false;
    final Widget field = ListenableBuilder(
      listenable: focusNode,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 3),
        child: Center(
          child: Builder(
            builder: (context) {
              final defaultTextStyle = DefaultTextStyle.of(context).style;
              return isOpen
                  ? Editable(
                      focusNode: focusNode,
                      controller: textController,
                      textAlign: TextAlign.center,
                      textInputAction: TextInputAction.done,
                      onSubmitted: onSelect,
                      blurredSelectionColor: FloogleColors.transparent,
                      style: defaultTextStyle.copyWith(
                        color: FloogleColors.darkGray,
                        decoration: TextDecoration.none,
                        fontWeight: const FontWeight(450),
                      ),
                      selectionColor: const Color.fromRGBO(211, 227, 253, 1),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: ExcludeSemantics(child: Text(selected, style: defaultTextStyle)),
                    );
            },
          ),
        ),
      ),
      builder: (context, child) {
        final isOpen = MenuController.maybeIsOpenOf(context) ?? false;
        Widget field = Center(child: child);
        if (trailing != null) {
          field = Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [field, trailing!],
          );
        }
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: isOpen
                ? Border.all(color: const Color.fromARGB(255, 10, 86, 207), width: 2)
                : Border.all(color: FloogleColors.transparent, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ConstrainedBox(constraints: constraints, child: field),
          ),
        );
      },
    );

    Widget listenable;
    if (!isOpen) {
      listenable = CoreTappable(
        child: Builder(
          builder: (context) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: CoreTappable.isFocusedOf(context) ? const Color.fromARGB(15, 0, 0, 0) : null,
                borderRadius: BorderRadius.circular(4),
              ),
              child: field,
            );
          },
        ),
        onPressed: () {
          menuController?.open();
          focusNode.requestFocus();
        },
      );
    } else {
      listenable = field;
    }
    return MergeSemantics(
      child: Semantics.fromProperties(
        properties: SemanticsProperties(expanded: isOpen, selected: true),
        child: Shortcuts(
          shortcuts: _shortcuts,
          child: DefaultTextStyle.merge(
            style: textStyle,
            overflow: TextOverflow.ellipsis,
            child: listenable,
          ),
        ),
      ),
    );
  }
}
