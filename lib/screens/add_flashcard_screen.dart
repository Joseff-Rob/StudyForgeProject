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

  // --------------------------
  // ADD FLASHCARD
  // --------------------------

  Future<void> _addFlashcard() async {
    final question = _questionController.text.trim();
    final answer = _answerController.text.trim();

    if (question.isEmpty || answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter question + answer")),
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

  // --------------------------
  // EDIT FLASHCARD
  // --------------------------

  void _showEditFlashcardDialog(Map<String, dynamic> card) {
    final questionController =
    TextEditingController(text: card['question']);
    final answerController =
    TextEditingController(text: card['answer']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Flashcard"),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionController,
                  decoration:
                  const InputDecoration(labelText: "Question"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: answerController,
                  decoration:
                  const InputDecoration(labelText: "Answer"),
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () async {
                await _flashcardService.updateFlashcard(
                  setId: widget.setId,
                  flashcardId: card['id'],
                  question: questionController.text.trim(),
                  answer: answerController.text.trim(),
                );

                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // --------------------------
  // DELETE FLASHCARD
  // --------------------------

  Future<void> _deleteFlashcard(String id) async {
    try {
      await _flashcardService.deleteFlashcard(
        setId: widget.setId,
        flashcardId: id,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete failed: $e")),
      );
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  // --------------------------
  // UI
  // --------------------------

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

            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: "Question",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _answerController,
              decoration: const InputDecoration(
                labelText: "Answer",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAdding ? null : _addFlashcard,
                child: _isAdding
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )
                    : const Text("Add Flashcard"),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.popUntil(
                      context, (route) => route.isFirst);
                },
                child: const Text("Submit Set"),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream:
                _flashcardService.streamFlashcards(widget.setId),
                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  final flashcards = snapshot.data!;

                  return ListView.builder(
                    itemCount: flashcards.length,
                    itemBuilder: (context, index) {
                      final card = flashcards[index];

                      return Card(
                        child: ListTile(
                          title: Text(card['question']),
                          subtitle: Text(card['answer']),

                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [

                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _showEditFlashcardDialog(card),
                              ),

                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    _deleteFlashcard(card['id']),
                              ),
                            ],
                          ),
                        ),
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