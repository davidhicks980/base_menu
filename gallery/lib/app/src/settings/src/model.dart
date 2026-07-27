import 'package:flutter/widgets.dart';

@immutable
class SettingsModel {
  const SettingsModel({
    this.directionality = TextDirection.ltr,
    this.aimAssist = false,
    this.visualizeAimAssist = false,
  });

  final TextDirection directionality;
  final bool aimAssist;
  final bool visualizeAimAssist;

  // Use copyWith for specific updates to maintain immutability
  SettingsModel copyWith({
    TextDirection? directionality,
    bool? aimAssist,
    bool? visualizeAimAssist,
  }) {
    return SettingsModel(
      directionality: directionality ?? this.directionality,
      aimAssist: aimAssist ?? this.aimAssist,
      visualizeAimAssist: visualizeAimAssist ?? this.visualizeAimAssist,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is SettingsModel &&
        other.directionality == directionality &&
        other.aimAssist == aimAssist &&
        other.visualizeAimAssist == visualizeAimAssist;
  }

  @override
  int get hashCode => directionality.hashCode ^ aimAssist.hashCode ^ visualizeAimAssist.hashCode;
}
