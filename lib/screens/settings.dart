import 'package:flutter/material.dart';
import '../utils/font_scale.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
          ],
        ),
      ),
    );
  }
}
