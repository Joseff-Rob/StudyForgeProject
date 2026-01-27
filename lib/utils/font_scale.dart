import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<double> fontScaleNotifier = ValueNotifier<double>(1.0);

Future<void> loadFontScale() async {
  final prefs = await SharedPreferences.getInstance();
  fontScaleNotifier.value = prefs.getDouble('fontScale') ?? 1.0;
}

Future<void> saveFontScale(double scale) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('fontScale', scale);
}
