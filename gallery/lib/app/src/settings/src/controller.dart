import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'model.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({SettingsModel? settings}) : _settings = settings ?? const SettingsModel();

  SettingsModel get settings => _settings;
  SettingsModel _settings;

  void updateAimAssist(bool newValue) {
    if (_settings.aimAssist == newValue) {
      return;
    }
    _settings = _settings.copyWith(aimAssist: newValue);
    notifyListeners();
  }

  void updateDirectionality(TextDirection newDirectionality) {
    if (_settings.directionality == newDirectionality) {
      return;
    }
    _settings = _settings.copyWith(directionality: newDirectionality);
    notifyListeners();
  }

  void updateVisualizeAimAssist(bool newValue) {
    if (_settings.visualizeAimAssist == newValue) {
      return;
    }
    _settings = _settings.copyWith(visualizeAimAssist: newValue);
    notifyListeners();
  }
}
