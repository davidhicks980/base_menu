import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Adopted from material/menu_anchor.dart.

typedef _KeyLabelMap = Map<LogicalKeyboardKey, String>;
typedef _ShortcutMap = Map<MaterialLocalizations, _KeyLabelMap>;

/// A helper class used to generate shortcut labels for a
/// [MenuSerializableShortcut] (a subset of the subclasses of
/// [ShortcutActivator]).
///
/// This helper class is typically used by the [MenuItemButton] and
/// [SubmenuButton] classes to display a label for their assigned shortcuts.
///
/// Call [getShortcutLabel] with the [MenuSerializableShortcut] to get a label
/// for it.
///
/// For instance, calling [getShortcutLabel] with `SingleActivator(trigger:
/// LogicalKeyboardKey.keyA, control: true)` would return "⌃ A" on macOS, "Ctrl
/// A" in an US English locale, and "Strg A" in a German locale.
class LocalizedShortcutLabeler {
  LocalizedShortcutLabeler._();

  static LocalizedShortcutLabeler? _instance;

  static final _KeyLabelMap _shortcutGraphicEquivalents = {
    .arrowLeft: '←',
    .arrowRight: '→',
    .arrowUp: '↑',
    .arrowDown: '↓',
    .enter: '↵',
  };

  static final _modifiers = <LogicalKeyboardKey>{
    .alt,
    .control,
    .meta,
    .shift,
    .altLeft,
    .controlLeft,
    .metaLeft,
    .shiftLeft,
    .altRight,
    .controlRight,
    .metaRight,
    .shiftRight,
  };

  /// Return the instance for this singleton.
  static LocalizedShortcutLabeler get instance {
    return _instance ??= LocalizedShortcutLabeler._();
  }

  // Caches the created shortcut key maps so that creating one of these isn't
  // expensive after the first time for each unique localizations object.
  final _ShortcutMap _cachedShortcutKeys = {};
  static final RegExp _functionKeyRegExp = RegExp(r'F\d{1,2}');

  bool get _usesSymbolicModifiers =>
      defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;

  String getFormattedShortcutLabel(
    MenuSerializableShortcut shortcut,
    MaterialLocalizations localizations,
  ) {
    final label = instance.getShortcutLabel(shortcut, localizations);
    if (label.length <= 3) {
      return label.replaceAll(RegExp(r'\s'), '');
    } else {
      return label.replaceAll(RegExp(r'\s'), '+');
    }
  }

  /// Returns the label to be shown to the user in the UI when a
  /// [MenuSerializableShortcut] is used as a keyboard shortcut.
  ///
  /// When [defaultTargetPlatform] is [TargetPlatform.macOS] or
  /// [TargetPlatform.iOS], this will return graphical key representations when
  /// it can. For instance, the default [LogicalKeyboardKey.shift] will return
  /// '⇧', and the arrow keys will return arrows. The key
  /// [LogicalKeyboardKey.meta] will show as '⌘', [LogicalKeyboardKey.control]
  /// will show as '˄', and [LogicalKeyboardKey.alt] will show as '⌥'.
  ///
  /// The keys are joined by spaces on macOS and iOS, and by "+" on other
  /// platforms.
  String getShortcutLabel(MenuSerializableShortcut shortcut, MaterialLocalizations localizations) {
    final ShortcutSerialization serialized = shortcut.serializeForMenu();
    final String keySeparator;
    if (_usesSymbolicModifiers) {
      // Use "⌃ ⇧ A" style on macOS and iOS.
      keySeparator = ' ';
    } else {
      // Use "Ctrl+Shift+A" style.
      keySeparator = '+';
    }
    if (serialized.trigger != null) {
      final LogicalKeyboardKey trigger = serialized.trigger!;
      final modifiers = <String>[
        if (_usesSymbolicModifiers) ...<String>[
          // macOS/iOS platform convention uses this ordering, with ⌘ always last.
          if (serialized.control!) _getModifierLabel(LogicalKeyboardKey.control, localizations),
          if (serialized.alt!) _getModifierLabel(LogicalKeyboardKey.alt, localizations),
          if (serialized.shift!) _getModifierLabel(LogicalKeyboardKey.shift, localizations),
          if (serialized.meta!) _getModifierLabel(LogicalKeyboardKey.meta, localizations),
        ] else ...<String>[
          // This order matches the LogicalKeySet version.
          if (serialized.alt!) _getModifierLabel(LogicalKeyboardKey.alt, localizations),
          if (serialized.control!) _getModifierLabel(LogicalKeyboardKey.control, localizations),
          if (serialized.meta!) _getModifierLabel(LogicalKeyboardKey.meta, localizations),
          if (serialized.shift!) _getModifierLabel(LogicalKeyboardKey.shift, localizations),
        ],
      ];
      String? shortcutTrigger;
      final int logicalKeyId = trigger.keyId;
      if (_shortcutGraphicEquivalents.containsKey(trigger)) {
        shortcutTrigger = _shortcutGraphicEquivalents[trigger];
      } else {
        // Otherwise, look it up, and if we don't have a translation for it,
        // then fall back to the key label.
        shortcutTrigger = _getLocalizedName(trigger, localizations);
        if (shortcutTrigger == null && logicalKeyId & LogicalKeyboardKey.planeMask == 0x0) {
          if (_functionKeyRegExp.hasMatch(trigger.keyLabel)) {
            // If the key label is a single alphanumeric character, then use that.
            shortcutTrigger = trigger.keyLabel.toUpperCase();
          } else {
            // If the trigger is a Unicode-character-producing key, then use the
            // character.
            shortcutTrigger = String.fromCharCode(
              logicalKeyId & LogicalKeyboardKey.valueMask,
            ).toUpperCase();
          }
        }
        // Fall back to the key label if all else fails.
        shortcutTrigger ??= trigger.keyLabel;
      }
      return <String>[
        ...modifiers,
        if (shortcutTrigger != null && shortcutTrigger.isNotEmpty) shortcutTrigger,
      ].join(keySeparator);
    } else if (serialized.character != null) {
      final modifiers = <String>[
        // Character based shortcuts cannot check shifted keys.
        if (_usesSymbolicModifiers) ...<String>[
          // macOS/iOS platform convention uses this ordering, with ⌘ always last.
          if (serialized.control!) _getModifierLabel(LogicalKeyboardKey.control, localizations),
          if (serialized.alt!) _getModifierLabel(LogicalKeyboardKey.alt, localizations),
          if (serialized.meta!) _getModifierLabel(LogicalKeyboardKey.meta, localizations),
        ] else ...<String>[
          // This order matches the LogicalKeySet version.
          if (serialized.alt!) _getModifierLabel(LogicalKeyboardKey.alt, localizations),
          if (serialized.control!) _getModifierLabel(LogicalKeyboardKey.control, localizations),
          if (serialized.meta!) _getModifierLabel(LogicalKeyboardKey.meta, localizations),
        ],
      ];
      return <String>[...modifiers, serialized.character!].join(keySeparator);
    }
    throw UnimplementedError(
      'Shortcut labels for ShortcutActivators that do not implement '
      'MenuSerializableShortcut (e.g. ShortcutActivators other than SingleActivator or '
      'CharacterActivator) are not supported.',
    );
  }

  // Tries to look up the key in an internal table, and if it can't find it,
  // then fall back to the key's keyLabel.
  String? _getLocalizedName(LogicalKeyboardKey key, MaterialLocalizations localizations) {
    // Since this is an expensive table to build, we cache it based on the
    // localization object. There's currently no way to clear the cache, but
    // it's unlikely that more than one or two will be cached for each run, and
    // they're not huge.
    _cachedShortcutKeys[localizations] ??= <LogicalKeyboardKey, String>{
      .altGraph: localizations.keyboardKeyAltGraph,
      .backspace: localizations.keyboardKeyBackspace,
      .capsLock: localizations.keyboardKeyCapsLock,
      .channelDown: localizations.keyboardKeyChannelDown,
      .channelUp: localizations.keyboardKeyChannelUp,
      .delete: localizations.keyboardKeyDelete,
      .eject: localizations.keyboardKeyEject,
      .end: localizations.keyboardKeyEnd,
      .escape: localizations.keyboardKeyEscape,
      .fn: localizations.keyboardKeyFn,
      .home: localizations.keyboardKeyHome,
      .insert: localizations.keyboardKeyInsert,
      .numLock: localizations.keyboardKeyNumLock,
      .numpad1: localizations.keyboardKeyNumpad1,
      .numpad2: localizations.keyboardKeyNumpad2,
      .numpad3: localizations.keyboardKeyNumpad3,
      .numpad4: localizations.keyboardKeyNumpad4,
      .numpad5: localizations.keyboardKeyNumpad5,
      .numpad6: localizations.keyboardKeyNumpad6,
      .numpad7: localizations.keyboardKeyNumpad7,
      .numpad8: localizations.keyboardKeyNumpad8,
      .numpad9: localizations.keyboardKeyNumpad9,
      .numpad0: localizations.keyboardKeyNumpad0,
      .numpadAdd: localizations.keyboardKeyNumpadAdd,
      .numpadComma: localizations.keyboardKeyNumpadComma,
      .numpadDecimal: localizations.keyboardKeyNumpadDecimal,
      .numpadDivide: localizations.keyboardKeyNumpadDivide,
      .numpadEnter: localizations.keyboardKeyNumpadEnter,
      .numpadEqual: localizations.keyboardKeyNumpadEqual,
      .numpadMultiply: localizations.keyboardKeyNumpadMultiply,
      .numpadParenLeft: localizations.keyboardKeyNumpadParenLeft,
      .numpadParenRight: localizations.keyboardKeyNumpadParenRight,
      .numpadSubtract: localizations.keyboardKeyNumpadSubtract,
      .pageDown: localizations.keyboardKeyPageDown,
      .pageUp: localizations.keyboardKeyPageUp,
      .power: localizations.keyboardKeyPower,
      .powerOff: localizations.keyboardKeyPowerOff,
      .printScreen: localizations.keyboardKeyPrintScreen,
      .scrollLock: localizations.keyboardKeyScrollLock,
      .select: localizations.keyboardKeySelect,
      .space: localizations.keyboardKeySpace,
    };
    return _cachedShortcutKeys[localizations]![key];
  }

  String _getModifierLabel(LogicalKeyboardKey modifier, MaterialLocalizations localizations) {
    assert(_modifiers.contains(modifier), '${modifier.keyLabel} is not a modifier key');

    return switch (modifier) {
      .meta || .metaLeft || .metaRight => switch (defaultTargetPlatform) {
        .android || .fuchsia || .linux => localizations.keyboardKeyMeta,
        .windows => localizations.keyboardKeyMetaWindows,
        .iOS || .macOS => '⌘',
      },

      .alt || .altLeft || .altRight => switch (defaultTargetPlatform) {
        .android || .fuchsia || .linux || .windows => localizations.keyboardKeyAlt,
        .iOS || .macOS => '⌥',
      },
      .control || .controlLeft || .controlRight => switch (defaultTargetPlatform) {
        .android || .fuchsia || .linux || .windows => localizations.keyboardKeyControl,
        .iOS || .macOS => '⌃',
      },
      .shift || .shiftLeft || .shiftRight => switch (defaultTargetPlatform) {
        .android || .fuchsia || .linux || .windows => localizations.keyboardKeyShift,
        .iOS || .macOS => localizations.keyboardKeyShift,
      },
      _ => throw ArgumentError('Keyboard key ${modifier.keyLabel} is not a modifier.'),
    };
  }
}
