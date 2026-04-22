import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

///Class to handle font scaling accessibility in the application.
final ValueNotifier<double> fontScaleNotifier = ValueNotifier<double>(1.0);

/// Loads the saved font scale (default = 1.0)
Future<void> loadFontScale() async {
  final prefs = await SharedPreferences.getInstance();
  fontScaleNotifier.value = prefs.getDouble('fontScale') ?? 1.0;
}

/// Saves the selected font scale (from 0.8 to 1.5)
Future<void> saveFontScale(double scale) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('fontScale', scale);
}
