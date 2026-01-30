import 'package:StudyForgeProject/consts.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TeachToLearnAi extends StatefulWidget {
  const TeachToLearnAi({super.key});

  @override
  State<TeachToLearnAi> createState() => _TeachToLearnAIState();
}

class _TeachToLearnAIState extends State<TeachToLearnAi> {
  final ChatUser _currentUser = ChatUser(id: '1', firstName: "Student");
  final ChatUser _geminiUser = ChatUser(id: '2', firstName: "Gemini");

  List<ChatMessage> _messages = <ChatMessage>[];
  List<ChatUser> _typingUser = <ChatUser>[];

  final String geminiApiKey = GEMINI_API_KEY; // define this in consts.dart
  final String modelName = 'gemini-2.5-flash'; // change to the Gemini model you have access to

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFDCE6F0),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: const Text(
          "Teach-to-Learn with Gemini",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: DashChat(
        currentUser: _currentUser,
        typingUsers: _typingUser,
        messageOptions: const MessageOptions(
          currentUserContainerColor: Colors.black,
          containerColor: Color.fromRGBO(0, 166, 126, 1),
          textColor: Colors.white,
        ),
        onSend: (ChatMessage m) {
          getChatResponse(m);
        },
        messages: _messages,
      ),
    );
  }

  Future<void> getChatResponse(ChatMessage m) async {
    setState(() {
      _messages.insert(0, m);
      _typingUser.add(_geminiUser);
    });

    try {
      final responseText = await generateGeminiResponse(m.text);

      setState(() {
        _messages.insert(
          0,
          ChatMessage(
            user: _geminiUser,
            createdAt: DateTime.now(),
            text: responseText,
          ),
        );
      });
    } catch (e) {
      setState(() {
        _messages.insert(
          0,
          ChatMessage(
            user: _geminiUser,
            createdAt: DateTime.now(),
            text: "Error: $e",
          ),
        );
      });
    } finally {
      setState(() {
        _typingUser.remove(_geminiUser);
      });
    }
  }

  Future<String> generateGeminiResponse(String prompt) async {
    // Build a full conversation history string
    String conversationContext = '';
    // Iterate in reverse to keep messages in order
    for (var msg in _messages.reversed) {
      final sender = msg.user.id == _currentUser.id ? 'Student' : 'Gemini';
      conversationContext += '$sender: ${msg.text}\n';
    }
    // Add the new user message at the end
    conversationContext += 'Student: $prompt\nGemini:';

    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent'
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': geminiApiKey,
      },
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": conversationContext}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;
        if (parts != null && parts.isNotEmpty) {
          return parts.map((p) => p['text'] ?? '').join('');
        }
      }
      return 'No content returned';
    } else {
      throw Exception('Gemini API error: ${response.statusCode} ${response.body}');
    }
  }

}
