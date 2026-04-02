import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../utils/font_scale.dart';
import '../utils/tts_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FlutterTts _flutterTts = FlutterTts();

  List<Map<String, String>> _availableVoices = [];
  bool _loadingVoices = true;
  bool _testingVoice = false;

  static const String _testText =
      "Hello. This is a sample of the selected text to speech voice.";

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await loadTtsVoice();
    await _loadVoices();
    await _applySavedVoiceIfAvailable();
  }

  Future<List<Map<String, String>>> _fetchVoicesOnce() async {
    final voices = await _flutterTts.getVoices;
    final parsed = <Map<String, String>>[];

    for (final voice in voices) {
      if (voice is Map) {
        final map = Map<String, dynamic>.from(voice);
        final name = map['name']?.toString();
        final locale = map['locale']?.toString();

        if (name != null && name.isNotEmpty) {
          parsed.add({
            'name': name,
            'locale': locale ?? '',
          });
        }
      }
    }

    final seen = <String>{};
    final unique = parsed.where((voice) {
      final key = '${voice['name']}|${voice['locale']}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();

    unique.sort((a, b) {
      final localeCompare = a['locale']!.compareTo(b['locale']!);
      if (localeCompare != 0) return localeCompare;
      return a['name']!.compareTo(b['name']!);
    });

    return unique;
  }

  Future<void> _loadVoices() async {
    if (mounted) {
      setState(() {
        _loadingVoices = true;
      });
    }

    List<Map<String, String>> voices = [];

    try {
      voices = await _fetchVoicesOnce();

      if (kIsWeb && voices.isEmpty) {
        for (int i = 0; i < 8; i++) {
          await Future.delayed(const Duration(milliseconds: 400));
          voices = await _fetchVoicesOnce();
          if (voices.isNotEmpty) break;
        }
      }
    } catch (_) {
      voices = [];
    }

    if (!mounted) return;

    setState(() {
      _availableVoices = voices;
      _loadingVoices = false;
    });
  }

  Future<void> _applySavedVoiceIfAvailable() async {
    final savedVoice = ttsVoiceNotifier.value;
    final matched = _findMatchingVoice(savedVoice);

    if (matched != null) {
      await _flutterTts.setVoice(matched);
    }
  }

  String _voiceKey(Map<String, String> voice) {
    return '${voice['name']}|${voice['locale']}';
  }

  String _voiceLabel(Map<String, String> voice) {
    final name = voice['name'] ?? 'Unknown';
    final locale = voice['locale'] ?? '';
    return locale.isEmpty ? name : '$name ($locale)';
  }

  Map<String, String>? _findMatchingVoice(Map<String, String>? selected) {
    if (selected == null || _availableVoices.isEmpty) return null;

    for (final voice in _availableVoices) {
      if (voice['name'] == selected['name'] &&
          voice['locale'] == selected['locale']) {
        return voice;
      }
    }

    return null;
  }

  Future<void> _onVoiceChanged(Map<String, String> voice) async {
    await saveTtsVoice(voice);
    await _flutterTts.setVoice(voice);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _testSelectedVoice() async {
    setState(() => _testingVoice = true);

    try {
      await _flutterTts.stop();

      final selectedVoice = _findMatchingVoice(ttsVoiceNotifier.value);
      if (selectedVoice != null) {
        await _flutterTts.setVoice(selectedVoice);
      }

      await _flutterTts.setSpeechRate(kIsWeb ? 0.9 : 0.5);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(_testText);
    } finally {
      if (mounted) {
        setState(() => _testingVoice = false);
      }
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            const Text(
              "Font Size",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<double>(
              valueListenable: fontScaleNotifier,
              builder: (context, fontScale, _) {
                return Slider(
                  value: fontScale,
                  min: 0.8,
                  max: 1.5,
                  divisions: 7,
                  label: fontScale.toStringAsFixed(1),
                  onChanged: (value) {
                    fontScaleNotifier.value = value;
                    saveFontScale(value);
                  },
                );
              },
            ),
            const SizedBox(height: 40),
            const Text(
              "TTS Voice",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (kIsWeb)
              const Text(
                "Voice not changeable on Web.",
                style: TextStyle(fontSize: 16),
              )
            else if (_loadingVoices)
              const Center(child: CircularProgressIndicator())
            else if (_availableVoices.isEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Selectable voices have not loaded yet on this browser. Default text to speech may still work.",
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _testingVoice ? null : _testSelectedVoice,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      _testingVoice ? "Testing..." : "Test default voice",
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _loadVoices,
                    child: const Text("Reload voices"),
                  ),
                ],
              )
            else
              ValueListenableBuilder<Map<String, String>?>(
                valueListenable: ttsVoiceNotifier,
                builder: (context, selectedVoice, _) {
                  final matchedVoice =
                      _findMatchingVoice(selectedVoice) ?? _availableVoices.first;
                  final selectedKey = _voiceKey(matchedVoice);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedKey,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Choose voice",
                        ),
                        items: _availableVoices.map((voice) {
                          return DropdownMenuItem<String>(
                            value: _voiceKey(voice),
                            child: Text(_voiceLabel(voice)),
                          );
                        }).toList(),
                        onChanged: (key) async {
                          if (key == null) return;

                          final voice = _availableVoices.firstWhere(
                                (v) => _voiceKey(v) == key,
                          );

                          await _onVoiceChanged(voice);
                        },
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _testingVoice ? null : _testSelectedVoice,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(_testingVoice ? "Testing..." : "Test voice"),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _loadVoices,
                        child: const Text("Reload voices"),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}