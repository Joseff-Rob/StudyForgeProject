import 'package:flutter/material.dart';
import '../services/firestore_flashcard_service.dart';

class AddFlashcardScreen extends StatefulWidget {
  final String setId;
  final String setTitle;

  const AddFlashcardScreen({
    super.key,
    required this.setId,
    required this.setTitle,
  });

  @override
  State<AddFlashcardScreen> createState() => _AddFlashcardScreenState();
}

class _AddFlashcardScreenState extends State<AddFlashcardScreen> {
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  final _flashcardService = FlashcardService();

  bool _isAdding = false;

  Future<void> _addFlashcard() async {
    final question = _questionController.text.trim();
    final answer = _answerController.text.trim();

    if (question.isEmpty || answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both question and answer")),
      );
      return;
    }

    setState(() => _isAdding = true);

    try {
      await _flashcardService.addFlashcard(
        setId: widget.setId,
        question: question,
        answer: answer,
      );

      _questionController.clear();
      _answerController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding flashcard: $e")),
      );
    }

    setState(() => _isAdding = false);
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Flashcards: ${widget.setTitle}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Question input
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: "Question",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Answer input
            TextField(
              controller: _answerController,
              decoration: const InputDecoration(
                labelText: "Answer",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Add flashcard button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAdding ? null : _addFlashcard,
                child: _isAdding
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Add Flashcard"),
              ),
            ),

            const SizedBox(height: 12),

            // Submit button: goes back to MainMenu
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  "Submit Set",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // List of current flashcards
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _flashcardService.streamFlashcards(widget.setId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  final flashcards = snapshot.data!;
                  return ListView.builder(
                    itemCount: flashcards.length,
                    itemBuilder: (context, index) {
                      final card = flashcards[index];
                      return ListTile(
                        title: Text(card['question']),
                        subtitle: Text(card['answer']),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}