import 'dart:async';

import 'package:StudyForgeProject/consts.dart';
import 'package:StudyForgeProject/services/teach_to_learn_service.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeachToLearnAi extends StatefulWidget {
  final String lessonId;

  const TeachToLearnAi({
    super.key,
    required this.lessonId,
  });

  @override
  State<TeachToLearnAi> createState() => _TeachToLearnAIState();
}

class _TeachToLearnAIState extends State<TeachToLearnAi> {

  final TeachToLearnService _service = TeachToLearnService();

  final ChatUser _currentUser =
  ChatUser(id: '1', firstName: "Student");

  final ChatUser _geminiUser =
  ChatUser(id: '2', firstName: "Gemini");

  List<ChatMessage> _messages = [];
  List<ChatUser> _typingUser = [];

  final String geminiApiKey = GEMINI_API_KEY;
  final String modelName = 'gemini-2.5-flash';

  final TextEditingController _topicController =
  TextEditingController();

  bool _lessonStarted = false;
  String _currentTopic = "";

  StreamSubscription? _messageSub;

  @override
  void initState() {
    super.initState();
    _loadLesson();
    _listenToMessages();
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    super.dispose();
  }

  // --------------------------------------------------
  // MESSAGE STREAM
  // --------------------------------------------------

  void _listenToMessages() {
    _messageSub =
        _service.streamMessages(widget.lessonId).listen((messages) {

          if (!mounted) return;

          setState(() {
            _messages = messages.map((m) {
              return ChatMessage(
                text: m['text'] ?? '',
                user: m['sender'] == "student"
                    ? _currentUser
                    : _geminiUser,
                createdAt:
                (m['createdAt'] as Timestamp).toDate(),
              );
            }).toList();
          });
        });
  }

  Future<void> _loadLesson() async {
    final lesson = await _service.getLesson(widget.lessonId);

    if (lesson != null &&
        lesson['topic'] != null &&
        lesson['topic'].toString().isNotEmpty) {
      _currentTopic = lesson['topic'];
      _lessonStarted = true;
    }

    if (mounted) {
      setState(() {});
    }
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------

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

            const Icon(Icons.school,
                size: 80, color: Colors.blueGrey),

            const SizedBox(height: 20),

            const Text(
              "Teach-To-Learn",
              style:
              TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            const Text(
              "Enter a topic and teach it back to Gemini.",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            TextField(
              controller: _topicController,
              decoration: InputDecoration(
                hintText: "Enter topic",
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
          padding: const EdgeInsets.all(12),
          color: Colors.amber.shade200,
          child: Text(
            "Topic: $_currentTopic\n⚠️ Gemini can make mistakes. Verify Important Information",
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),

        Expanded(
          child: DashChat(
            currentUser: _currentUser,
            typingUsers: _typingUser,
            onSend: (ChatMessage m) {
              getChatResponse(m);
            },
            messages: _messages,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // START LESSON
  // --------------------------------------------------

  Future<void> _startLesson(String topic) async {

    await FirebaseFirestore.instance
        .collection('teach_lessons')
        .doc(widget.lessonId)
        .update({
      'topic': topic,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      _lessonStarted = true;
      _currentTopic = topic;
      _typingUser.add(_geminiUser);
    });

    // Do NOT block UI waiting for API response
    Future.microtask(() async {

      try {

        final responseText = await generateGeminiResponse(
            "You are a curious beginner. "
                "You are learning about $topic. "
                "Ask the student to start teaching you.");

        await _service.addMessage(
          lessonId: widget.lessonId,
          text: responseText,
          sender: "gemini",
        );

      } catch (e) {

        await _service.addMessage(
          lessonId: widget.lessonId,
          text: "Ready! Please start teaching me about $topic",
          sender: "gemini",
        );
      }

      if (mounted) {
        setState(() {
          _typingUser.remove(_geminiUser);
        });
      }

    });
  }

  // --------------------------------------------------
  // CHAT RESPONSE
  // --------------------------------------------------

  Future<void> getChatResponse(ChatMessage m) async {

    try {

      await _service.addMessage(
        lessonId: widget.lessonId,
        text: m.text,
        sender: "student",
      );

      setState(() {
        _typingUser.add(_geminiUser);
      });

      final responseText = await generateGeminiResponse("""
Topic: $_currentTopic

Student message:
${m.text}

You are a curious student learning this topic.
Ask questions and stay in learning mode.
""");

      await _service.addMessage(
        lessonId: widget.lessonId,
        text: responseText,
        sender: "gemini",
      );

    } catch (e) {

      await _service.addMessage(
        lessonId: widget.lessonId,
        text: "Error: $e",
        sender: "gemini",
      );

    } finally {

      if (mounted) {
        setState(() {
          _typingUser.remove(_geminiUser);
        });
      }
    }
  }

  // --------------------------------------------------
  // GEMINI API
  // --------------------------------------------------

  Future<String> generateGeminiResponse(String prompt) async {

    try {

      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$geminiApiKey');

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
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

      print("Gemini status: ${response.statusCode}");
      print(response.body);

      if (response.statusCode != 200) {
        return "Gemini is not available right now.";
      }

      final data = jsonDecode(response.body);

      return data['candidates'][0]['content']['parts'][0]['text'];

    } catch (e) {
      print("Gemini error: $e");
      return "Error contacting Gemini.";
    }
  }
}