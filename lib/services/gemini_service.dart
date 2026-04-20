import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey;
  final String modelName;

  GeminiService({
    required this.apiKey,
    this.modelName = 'gemini-2.5-flash',
  });

  Future<String> generateText(String prompt) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent'
    );

    for (int attempt = 0; attempt < 3; attempt++) {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      // ✅ Success
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final candidates = data['candidates'] as List<dynamic>?;

        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;

          if (parts != null && parts.isNotEmpty) {
            return parts.map((p) => p['text'] ?? "").join("");
          }
        }

        return "No content returned";
      }

      // 🔁 Retry only on overload errors
      if (response.statusCode == 503 || response.statusCode == 429) {
        await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
        continue;
      }

      // ❌ Real failure (bad key, bad request, etc.)
      throw Exception(
          "Gemini API error: ${response.statusCode} ${response.body}"
      );
    }

    return "AI is temporarily overloaded. Please try again.";
  }
}
