import 'package:StudyForgeProject/consts.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
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

  final String geminiApiKey = GEMINI_API_KEY;
  final String modelName = 'gemini-2.5-flash';

  final TextEditingController _topicController = TextEditingController();

  bool _lessonStarted = false;
  String _currentTopic = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCE6F0),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: const Text(
          "Teach-to-Learn with Gemini",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _lessonStarted ? _buildChatUI() : _buildIntroScreen(),
    );
  }


  Widget _buildIntroScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 20),
            const Text(
              "Teach-To-Learn",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Enter a topic and teach it back to Gemini.\nActive recall improves retention.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _topicController,
              decoration: InputDecoration(
                hintText: "Enter topic (e.g. Binary Trees)",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_topicController.text.trim().isNotEmpty) {
                  _startLesson(_topicController.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              child: const Text("Start Lesson"),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildChatUI() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding:
          const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          color: Colors.amber.shade200,
          child: Text(
            "Topic: $_currentTopic\n⚠️ Gemini can make mistakes. Verify important info.",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: DashChat(
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
        ),
      ],
    );
  }

  // ===============================
  // 🔹 START LESSON
  // ===============================

  Future<void> _startLesson(String topic) async {
    setState(() {
      _lessonStarted = true;
      _currentTopic = topic;
      _typingUser.add(_geminiUser);
    });

    final structuredPrompt = """
      You are participating in a Teach-To-Learn session.
      
      The student will teach YOU the topic: "$topic".
      
      Your role:
      - Act like a curious beginner who knows nothing.
      - Ask the student to explain the topic in their own words.
      - Ask follow-up questions when explanations are unclear.
      - Identify missing key concepts.
      - Point out misunderstandings politely.
      - Encourage deeper thinking.
      - DO NOT fully teach the topic yourself unless correcting mistakes.
      - Make sure to confirm with student often that they are still within scope of their learning.
      
      Start by saying you are ready to learn and ask the student to begin explaining.
      """;

    final responseText = await generateGeminiResponse(structuredPrompt);

    setState(() {
      _messages.insert(
        0,
        ChatMessage(
          user: _geminiUser,
          createdAt: DateTime.now(),
          text: responseText,
        ),
      );
      _typingUser.remove(_geminiUser);
    });
  }

  // ===============================
  // 🔹 CHAT RESPONSE
  // ===============================

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

  // ===============================
  // 🔹 GEMINI CALL
  // ===============================

  Future<String> generateGeminiResponse(String prompt) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent');

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
              {"text": prompt}
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
      throw Exception(
          'Gemini API error: ${response.statusCode} ${response.body}');
    }
  }
}
