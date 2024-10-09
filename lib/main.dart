import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';

void main() async {
  print('Current Directory: ${Directory.current.path}');

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Error al cargar el archivo .env: $e');
    return;
  }

  // Verificar si la clave API existe
  final apiKey = dotenv.env['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Error: La clave de API no está configurada. Por favor, agrégala en el archivo .env');
    return;
  }

  final settingsController = SettingsController(SettingsService());
  await settingsController.loadSettings();

  runApp(MyApp(settingsController: settingsController));
}
