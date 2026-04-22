import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Class to handle TTS voice choice accessibility in the application.
final ValueNotifier<Map<String, String>?> ttsVoiceNotifier =
ValueNotifier<Map<String, String>?>(null);

/// Loads the chosen TTS voice.
Future<void> loadTtsVoice() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('ttsVoice');

  if (raw == null || raw.isEmpty) {
    ttsVoiceNotifier.value = null;
    return;
  }

  try {
    final decoded = jsonDecode(raw);
    ttsVoiceNotifier.value = Map<String, String>.from(decoded);
  } catch (_) {
    ttsVoiceNotifier.value = null;
    await prefs.remove('ttsVoice');
  }
}

/// Saves the chosen TTS voice.
Future<void> saveTtsVoice(Map<String, String>? voice) async {
  final prefs = await SharedPreferences.getInstance();

  if (voice == null) {
    await prefs.remove('ttsVoice');
    ttsVoiceNotifier.value = null;
    return;
  }

  await prefs.setString('ttsVoice', jsonEncode(voice));
  ttsVoiceNotifier.value = voice;
}
