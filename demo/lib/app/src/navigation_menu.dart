import 'package:base_menu/base_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class _NavigationScope<T> extends InheritedWidget {
  const _NavigationScope({super.key, required super.child, required this.data, this.currentKey});
  final _NavigationMenuState<T> data;
  final Object? currentKey;

  @override
  bool updateShouldNotify(_NavigationScope<T> oldWidget) {
    return data != oldWidget.data || currentKey != oldWidget.currentKey;
  }
}

class NavigationMenu<T> extends StatefulWidget {
  const NavigationMenu({
    super.key,
    required this.label,
    required this.children,
    this.selected,
    this.header,
    this.footer,
    this.onDestinationSelected,
  });

  final String label;
  final List<Widget> children;
  final T? selected;
  final void Function(T)? onDestinationSelected;
  final Widget? header;
  final Widget? footer;

  static _NavigationScope<T> _of<T>(BuildContext context) {
    final _NavigationScope<T>? result = context
        .dependOnInheritedWidgetOfExactType<_NavigationScope<T>>();
    assert(
      result != null,
      'NavigationMenuDestination must be a descendant of a NavigationMenu of the same type.',
    );
    return result!;
  }

  @override
  State<NavigationMenu<T>> createState() => _NavigationMenuState<T>();
}

class _NavigationMenuState<T> extends State<NavigationMenu<T>> {
  late T? _currentKey = widget.selected;
  List<Widget>? children;

  void select(T key) {
    setState(() {
      _currentKey = key;
    });
    if (widget.onDestinationSelected != null) {
      widget.onDestinationSelected!(key);
    }
  }

  @override
  void didUpdateWidget(NavigationMenu<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      _currentKey = widget.selected;
    }

    if (widget.children != oldWidget.children) {
      children = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (children == null) {
      children = [];
      var section = <Widget>[];
      for (final child in widget.children) {
        switch (child) {
          case NavigationMenuGroup():
            if (section.isNotEmpty) {
              children!.add(NavigationMenuGroup._withoutHeader(children: section));
              section = <Widget>[];
            }
            children!.add(child);
          default:
            section.add(child);
        }
      }

      if (section.isNotEmpty) {
        children!.add(NavigationMenuGroup._withoutHeader(children: section));
      }
    }

    return _NavigationScope(
      data: this,
      currentKey: _currentKey,
      child: Semantics.fromProperties(
        explicitChildNodes: true,
        properties: SemanticsProperties(role: SemanticsRole.navigation, label: widget.label),
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(crossAxisAlignment: .stretch, mainAxisSize: .min, children: children!),
        ),
      ),
    );
  }
}

class NavigationMenuGroup extends StatelessWidget {
  /// Builds a section to use in a Material 3 [NavigationMenu].
  const NavigationMenuGroup({
    super.key,
    required Widget this.header,
    required String this.groupLabel,
    required this.children,
  });

  const NavigationMenuGroup._withoutHeader({required this.children})
    : header = null,
      groupLabel = null;

  final Widget? header;
  final String? groupLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (header == null && groupLabel == null) {
      return Semantics.fromProperties(
        explicitChildNodes: true,
        properties: const SemanticsProperties(role: .list),
        child: Column(crossAxisAlignment: .start, mainAxisSize: .min, children: children),
      );
    }

    return Semantics.fromProperties(
      explicitChildNodes: true,
      properties: SemanticsProperties(label: groupLabel),
      child: Column(
        crossAxisAlignment: .start,
        mainAxisSize: .min,
        children: [
          ExcludeSemantics(child: header),
          Flexible(
            child: Semantics.fromProperties(
              container: true,
              explicitChildNodes: true,
              properties: const SemanticsProperties(role: .list),
              child: Column(crossAxisAlignment: .start, mainAxisSize: .min, children: children),
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationMenuDestination<T> extends StatelessWidget {
  /// Builds a destination (icon + label) to use in a Material 3 [NavigationMenu].
  const NavigationMenuDestination({
    super.key,
    required this.child,
    this.enabled = true,
    required this.identifier,
  });

  final Widget child;
  final T identifier;
  final bool enabled;

  static Set<WidgetState> statesOf(BuildContext context) {
    final Set<WidgetState>? result = context
        .dependOnInheritedWidgetOfExactType<_NavigationDestinationScope>()
        ?.states;
    assert(
      result != null,
      'NavigationMenuDestination.statesOf should only be called within a NavigationMenuDestination.',
    );
    return result!;
  }

  @override
  Widget build(BuildContext context) {
    final _NavigationScope<T> scope = NavigationMenu._of<T>(context);
    return Semantics(
      container: true,
      role: .listItem,
      child: Semantics(
        link: true,
        selected: scope.currentKey == identifier,
        child: BaseControl<NavigationMenuDestination<T>>(
          onPressed: enabled ? () => scope.data.select(identifier) : null,
          mouseCursor: WidgetStateMouseCursor.adaptiveClickable,
          child: Builder(
            builder: (context) {
              return _NavigationDestinationScope(
                states: {
                  if (scope.currentKey == identifier) WidgetState.selected,
                  if (!enabled) WidgetState.disabled,
                  ...BaseControl.statesOf<NavigationMenuDestination<T>>(context),
                },
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavigationDestinationScope extends InheritedWidget {
  const _NavigationDestinationScope({required super.child, required this.states});
  final Set<WidgetState> states;

  @override
  bool updateShouldNotify(_NavigationDestinationScope oldWidget) {
    return !setEquals(states, oldWidget.states);
  }
}
