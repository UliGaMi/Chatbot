import 'package:flutter/material.dart';

class SettingsService {
  Future<ThemeMode> themeMode() async => ThemeMode.system;

  Future<void> updateThemeMode(ThemeMode theme) async {
    // Aquí iría la lógica para guardar la configuración.
  }
}
