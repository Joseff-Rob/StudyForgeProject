import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey;
  final String modelName;

  GeminiService({
    required this.apiKey,
    this.modelName = 'gemini-2.5-flash', // model you want to use
  });

  Future<String> generateText(String prompt) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent'
    );

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

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // The response contains a list of candidates → we take the first one
      final candidates = data['candidates'] as List<dynamic>?;

      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;

        if (parts != null && parts.isNotEmpty) {
          // Join all text parts into one string
          return parts.map((p) => p['text'] ?? "").join("");
        }
      }
      return "No content returned";
    } else {
      throw Exception(
          "Gemini API error: ${response.statusCode} ${response.body}"
      );
    }
  }
}
