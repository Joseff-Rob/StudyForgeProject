import 'dart:async';

import 'package:StudyForgeProject/consts.dart';
import 'package:StudyForgeProject/services/teach_to_learn_service.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

import '../utils/tts_settings.dart';
// import 'package:web/web.dart' as web;

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

  bool _isGeneratingFlashcards = false;

  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _loadLesson();
    _listenToMessages();
    _initTTS();
  }

  Future<void> _initTTS() async {
    if (!kIsWeb) {
      await loadTtsVoice(); // Load saved voice from SharedPreferences

      final savedVoice = ttsVoiceNotifier.value;

      if (savedVoice != null) {
        try {
          await _tts.setVoice(savedVoice);
        } catch (e) {
          print("Error setting saved voice: $e");
        }
      }

      await _tts.setLanguage("en-GB");
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
    }
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    super.dispose();
  }

  // TTS
  Future<void> _speak(String text) async {
    if (text.isEmpty) return;

    final cleanedText = _cleanTextForTTS(text);

    _stopTTS(); // 🔥 prevent overlap

    if (kIsWeb) {
      final savedVoice = {
        "name": "Google UK English Female",
        "locale": "en-GB"
      };

      await _tts.setVoice(savedVoice);
      await _tts.speak(cleanedText);
    } else {
      final savedVoice = ttsVoiceNotifier.value;
      if (savedVoice != null) {
        await _tts.setVoice(savedVoice);
      }
      await _tts.speak(cleanedText);
    }
  }

  void _stopTTS() {
    if (kIsWeb) {
      // web.window.speechSynthesis.cancel();
    } else {
      _tts.stop();
    }
  }

  String _cleanTextForTTS(String text) {
    return text
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'_+'), '')
        .replaceAll(RegExp(r'`+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[-•] '), '')
        .replaceAll(RegExp(r'\n'), '. ')
        .trim();
  }

  // --------------------------------------------------
  // MESSAGE STREAM
  // --------------------------------------------------

  void _listenToMessages() {
    _messageSub =
        _service.streamMessages(widget.lessonId).listen((messages) {

          if (!mounted) return;

          final newMessages = messages.map((m) {
            return ChatMessage(
              text: m['text'] ?? '',
              user: m['sender'] == "student"
                  ? _currentUser
                  : _geminiUser,
              createdAt:
              (m['createdAt'] as Timestamp).toDate(),
            );
          }).toList();

          /// 🔥 Detect newest Gemini message
          if (_messages.isNotEmpty && newMessages.length > _messages.length) {
            final latest = newMessages.first;

            if (latest.user.id == _geminiUser.id) {
              _speak(latest.text); // 🔊 AUTO READ AI
            }
          }

          setState(() {
            _messages = newMessages;
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

  // ---------------- FLASHCARD GENERATION ----------------

  Future<void> _generateFlashcards(bool isPublic) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final history = _messages.map((msg) {
        final role = msg.user.id == '1' ? "Student" : "AI";
        return "$role: ${msg.text}";
      }).join("\n");

      final prompt = """
You are an expert educator.

From the following conversation, generate a set of high-quality flashcards.

Rules:
- Focus on key concepts, mistakes, and important explanations
- Create clear question-answer pairs
- Keep answers concise but informative
- Avoid duplicates
- Ensure correctness
- MAXIMUM LENGTH OF 180 CHARACTERS FOR A QUESTION/ANSWER.

Return ONLY JSON:
[
  {"question": "...", "answer": "..."}
]

Conversation:
$history
""";

      final response = await generateGeminiResponse(prompt);

      if (!mounted) return;

      String cleaned = response.trim();

      if (cleaned.startsWith("```")) {
        cleaned = cleaned
            .replaceAll("```json", "")
            .replaceAll("```", "")
            .trim();
      }

      final List<dynamic> decoded = jsonDecode(cleaned);

      final setRef = await FirebaseFirestore.instance
          .collection('flashcard_sets')
          .add({
        'title': _currentTopic,
        'titleLowercase': _currentTopic.toLowerCase(),
        'ownerId': currentUser.uid,
        'isPublic': isPublic,
        'flashcardCount': decoded.length,
        'createdAt': FieldValue.serverTimestamp(),
      });

      for (var card in decoded) {
        await FirebaseFirestore.instance
            .collection('flashcard_sets')
            .doc(setRef.id)
            .collection('flashcards')
            .add({
          'question': card['question'],
          'answer': card['answer'],
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Flashcards generated!")),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingFlashcards = false;
        });
      }
    }
  }

  Future<void> _showGeneratePopup() async {
    bool isPublic = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Generate Flashcards"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      "Generate flashcards from this conversation?"),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text("Public"),
                      Switch(
                        value: isPublic,
                        onChanged: (val) {
                          setDialogState(() {
                            isPublic = val;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);

                    if (mounted) {
                      setState(() {
                        _isGeneratingFlashcards = true;
                      });
                    }

                    await _generateFlashcards(isPublic);
                  },
                  child: const Text("Generate"),
                ),
              ],
            );
          },
        );
      },
    );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.stop, color: Colors.white,),
            onPressed: _stopTTS,
          ),
        ],
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
    return Stack(
      children: [
        Column(
          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.amber.shade200,
              child: Text(
                "Topic: $_currentTopic\n⚠️ Gemini can make mistakes. Verify Important Information!",
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text("Generate Flashcards"),
                  onPressed: _showGeneratePopup,
                ),
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

                messageOptions: MessageOptions(
                  messageTextBuilder: (message, previousMessage, nextMessage) {
                    final isUser = message.user.id == _currentUser.id;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// TEXT
                        Expanded(
                          child: Text(
                            message.text,
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black,
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        /// 🔊 TTS BUTTON
                        GestureDetector(
                          onTap: () => _speak(message.text),
                          child: Icon(
                            Icons.volume_up,
                            size: 18,
                            color: isUser ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),

        // ✅ FULLSCREEN LOADING
        if (_isGeneratingFlashcards)
          Container(
            color: Colors.black.withOpacity(0.4),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    "Generating flashcards...",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
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

    Future.microtask(() async {

      try {

        final responseText = await generateGeminiResponse("""
You are participating in a Teach-To-Learn session.

The student will teach YOU the topic: "$topic".

Behavior rules:

If the student is explaining:
- Evaluate their answer
- Identify missing concepts
- Ask follow-up questions

If the student expresses confusion or asks for help:
- Switch to teaching mode
- Clearly explain the concept
- Keep explanation concise
- Then ask a follow-up question to continue learning

Do NOT:
- Repeat the same correction multiple times
- Bring up past mistakes unless directly relevant

Goal:
Continuously push the student toward a complete and correct understanding.

Start by saying you are ready to learn and ask the student to begin explaining.
""");

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
  // CHAT RESPONSE (UPDATED WITH HISTORY)
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

      // 🔥 Build conversation history (last 10 messages for safety)
      final recentMessages = _messages.take(10);

      final history = [
        ...recentMessages.map((msg) {
          final role = msg.user.id == '1' ? "Student" : "Gemini";
          return "$role: ${msg.text}";
        }),
        "Student: ${m.text}"
      ].join("\n");

      final responseText = await generateGeminiResponse("""
Topic: $_currentTopic

Conversation so far:
$history

Behavior rules:

If the student is explaining:
- Evaluate their answer
- Identify missing concepts
- Ask follow-up questions

If the student expresses confusion or asks for help:
- Switch to teaching mode
- Clearly explain the concept
- Keep explanation concise
- Then ask a follow-up question to continue learning

EXTRA TIPS:
- Keep responses under 6 sentences unless explaining a concept to the student.
- Assume the student remembers all prior explanations.
- Do not repeat or re-summarize unless explicitly asked.
- Ask about the next concept or missing piece only.
- Never loop back to a topic that’s already resolved.

Do NOT:
- Repeat the same correction multiple times
- Bring up past mistakes unless directly relevant
- Ask the same question multiple times

Goal:
Continuously push the student toward a complete and correct understanding.
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