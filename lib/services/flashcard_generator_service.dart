import 'dart:convert';
import 'package:http/http.dart' as http;

class FlashcardGeneratorService {
  final String geminiApiKey;

  FlashcardGeneratorService({required this.geminiApiKey});

  Future<List<Map<String, String>>> generateFlashcards(String text) async {
    final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$geminiApiKey");

    final prompt = """
Convert the following study material into flashcards.

Rules:
- Return ONLY valid JSON
- No explanations
- MAXIMUM LENGTH OF 180 CHARACTERS FOR A QUESTION/ANSWER.
- Format:

[
 { "question": "...", "answer": "..." }
]

Material:
$text
""";

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
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

    if (response.statusCode != 200) {
      throw Exception("Gemini API error: ${response.body}");
    }

    final data = jsonDecode(response.body);

    final textResponse =
    data["candidates"][0]["content"]["parts"][0]["text"];

    final jsonStart = textResponse.indexOf("[");
    final jsonEnd = textResponse.lastIndexOf("]");

    final cleanJson = textResponse.substring(jsonStart, jsonEnd + 1);

    final List decoded = jsonDecode(cleanJson);

    return decoded.map((e) {
      return {
        "question": e["question"].toString(),
        "answer": e["answer"].toString(),
      };
    }).toList();
  }
}