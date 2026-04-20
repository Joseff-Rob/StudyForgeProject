import 'dart:convert';
import 'package:http/http.dart' as http;

class FlashcardGeneratorService {
  final String geminiApiKey;

  FlashcardGeneratorService({required this.geminiApiKey});

  final List<String> models = [
    'gemini-2.5-pro',
    'gemini-2.5-flash'
  ];

  Future<List<Map<String, String>>> generateFlashcards(String text) async {
    const maxRetries = 2;

    for (final model in models) {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$geminiApiKey',
      );

      for (int attempt = 0; attempt < maxRetries; attempt++) {
        try {
          final response = await http.post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {
                      "text": """
Generate flashcards from this text.

Return ONLY valid JSON:
[
  {"question": "...", "answer": "..."}
]

Rules:
- concise
- accurate
- no duplicates

Text:
$text
"""
                    }
                  ]
                }
              ]
            }),
          );

          print("[$model] flashcards status: ${response.statusCode}");

          // ✅ success
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            String raw = data['candidates'][0]['content']['parts'][0]['text'];

            raw = raw.replaceAll("```json", "").replaceAll("```", "").trim();

            final decoded = jsonDecode(raw) as List<dynamic>;

            return decoded
                .map((e) => {
              "question": e["question"].toString(),
              "answer": e["answer"].toString(),
            })
                .toList();
          }

          // 🔥 overload → retry same model
          if (response.statusCode == 503 || response.statusCode == 429) {
            final delay = Duration(seconds: 2 * (attempt + 1));
            await Future.delayed(delay);
            continue;
          }

          // ❌ other error → switch model
          break;

        } catch (e) {
          print("[$model] error: $e");
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      print("Switching flashcard model fallback → $model");
    }

    throw Exception("Gemini is busy. Try again later.");
  }
}