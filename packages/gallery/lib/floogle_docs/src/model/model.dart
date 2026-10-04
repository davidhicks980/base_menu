import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../widgets/selectable_menu_item.dart';
import 'intents.dart';

@immutable
class IconConfiguration {
  const IconConfiguration({
    this.size,
    this.fill,
    this.weight,
    this.grade,
    this.opticalSize,
    this.affinity = .leading,
  });
  final double? size;
  final double? fill;
  final double? weight;
  final double? grade;
  final double? opticalSize;
  final CheckboxMenuItemControlAffinity affinity;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is IconConfiguration &&
        other.size == size &&
        other.fill == fill &&
        other.weight == weight &&
        other.grade == grade &&
        other.opticalSize == opticalSize &&
        other.affinity == affinity;
  }

  @override
  int get hashCode {
    return size.hashCode ^
        fill.hashCode ^
        weight.hashCode ^
        grade.hashCode ^
        opticalSize.hashCode ^
        affinity.hashCode;
  }
}

@immutable
sealed class BaseMenuEntry {
  const BaseMenuEntry();
}

@immutable
class MenuEntry extends BaseMenuEntry {
  const MenuEntry(this.label, {this.icon, this.iconConfig});

  final String label;
  final IconData? icon;
  final IconConfiguration? iconConfig;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is MenuEntry &&
        other.label == label &&
        other.icon == icon &&
        other.iconConfig == iconConfig;
  }

  @override
  int get hashCode {
    return label.hashCode ^ icon.hashCode ^ iconConfig.hashCode;
  }
}

@optionalTypeArgs
class MenuEntryWithIntent<T extends Intent> extends MenuEntry {
  const MenuEntryWithIntent(
    super.label, {
    super.icon,
    super.iconConfig,
    required this.intent,
    this.shortcut,
  });

  final T intent;
  final MenuSerializableShortcut? shortcut;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is MenuEntryWithIntent &&
        super == other &&
        other.intent == intent &&
        other.shortcut == shortcut;
  }

  @override
  int get hashCode => super.hashCode ^ intent.hashCode ^ shortcut.hashCode;
}

@immutable
class SubmenuEntry<T extends BaseMenuEntry> extends BaseMenuEntry {
  const SubmenuEntry(this.child, this.children);
  final MenuEntry child;
  final List<T> children;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is SubmenuEntry && other.child == child && listEquals(other.children, children);
  }

  @override
  int get hashCode {
    return child.hashCode ^ Object.hashAll(children);
  }

  SubmenuEntry<T> copyWith({MenuEntry? child, List<T>? children}) {
    return SubmenuEntry<T>(child ?? this.child, children ?? this.children);
  }
}

@immutable
class SelectableMenuEntry<V> extends MenuEntryWithIntent<FloogleSelectableIntent<V>> {
  const SelectableMenuEntry(
    super.label, {
    this.subtitle,
    super.icon,
    super.iconConfig,
    super.shortcut,
    required super.intent,
  });

  final String? subtitle;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is SelectableMenuEntry && super == other && other.subtitle == subtitle;
  }

  @override
  int get hashCode => super.hashCode ^ subtitle.hashCode;
}

@optionalTypeArgs
@immutable
class TileGroupMenuEntry<V> extends BaseMenuEntry {
  const TileGroupMenuEntry(
    this.children, {
    required this.size,
    required this.columns,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
  });
  final List<TileMenuEntry<V>> children;
  final Size size;
  final EdgeInsetsGeometry padding;
  final int columns;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is TileGroupMenuEntry &&
        size == other.size &&
        columns == other.columns &&
        padding == other.padding &&
        listEquals(other.children, children);
  }

  @override
  int get hashCode {
    return Object.hash(size, columns, padding, Object.hashAll(children));
  }
}

@immutable
class TileLineMenuEntry {
  const TileLineMenuEntry(
    this.indentLevel, {
    this.prefix,
    this.columns = 1,
    this.strikeThrough = false,
  }) : assert(indentLevel >= 0, 'Indent level cannot be negative'),
       assert(columns > 0, 'Columns must be at least 1');

  final int indentLevel;
  final String? prefix;
  final int columns;
  final bool strikeThrough;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is TileLineMenuEntry &&
        other.indentLevel == indentLevel &&
        other.prefix == prefix &&
        other.columns == columns &&
        other.strikeThrough == strikeThrough;
  }

  @override
  int get hashCode =>
      indentLevel.hashCode ^ prefix.hashCode ^ columns.hashCode ^ strikeThrough.hashCode;
}

@optionalTypeArgs
@immutable
class TileMenuEntry<V> extends SelectableMenuEntry<V> {
  const TileMenuEntry(super.label, {required this.tileLines, required super.intent});

  final List<TileLineMenuEntry> tileLines;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is TileMenuEntry && super == other && listEquals(other.tileLines, tileLines);
  }

  @override
  int get hashCode => super.hashCode ^ Object.hashAll(tileLines);
}

class DimensionalPickerMenuEntry extends MenuEntryWithIntent {
  const DimensionalPickerMenuEntry(super.label, {super.shortcut, required super.intent});
}

@immutable
class SeparatorMenuEntry extends BaseMenuEntry {
  const SeparatorMenuEntry();
}
