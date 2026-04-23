import 'package:flutter/material.dart';
import '../services/firestore_flashcard_service.dart';

/// Class that handles the logic and UI for filling flashcard sets with
/// cards.
/// Including:
/// - Adding Flashcard.
/// - Editing Flashcard.
/// - Deleting Flashcard.
/// - Displaying existing flashcards in real time.
///
/// Works alongside [FlashcardService] to perform operations.
class AddFlashcardScreen extends StatefulWidget {
  /// Flashcard set unique identifier
  final String setId;
  /// Flashcard set title
  final String setTitle;

  /// Creates an [AddFlashcardScreen] for a specific set.
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

  bool _hasFlashcards = false;

  /// Adds a new flashcard to the current set.
  Future<void> _addFlashcard() async {
    final question = _questionController.text.trim();
    final answer = _answerController.text.trim();

    // Validation (not empty fields)
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

  /// Displays a dialog allowing the user to edit a selected flashcard.
  void _showEditFlashcardDialog(Map<String, dynamic> card) {
    // Pre-fills fields with current flashcard terms and definition.
    final questionController =
    TextEditingController(text: card['question']);
    final answerController =
    TextEditingController(text: card['answer']);

    showDialog(
      context: context,
      builder: (context) {
        // Popup Dialog
        return AlertDialog(
          title: const Text("Edit Flashcard"),

          // SingleChildScroller used to prevent pixel overflow.
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

  /// Deletes a selected flashcard.
  Future<void> _deleteFlashcard(String id) async {
    try {
      await _flashcardService.deleteFlashcard(
        setId: widget.setId,
        flashcardId: id,
      );
    // Error handling.
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete failed: $e")),
      );
    }
  }

  /// Disposes text controllers when the widget is removed.
  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  /// Builds the user interface for managing flashcards.
  ///
  /// Including:
  /// - Input fields for question and answer (each side of the flashcard)
  /// - Buttons to add card and submit set.
  /// - Live updating list of flashcards.
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

            // Question text field (one side of the flashcard)
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: "Question",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            // Answer text field (other side of the flashcard)
            TextField(
              controller: _answerController,
              decoration: const InputDecoration(
                labelText: "Answer",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            // Add flashcard button.
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

            // Set submission button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _hasFlashcards
                    ? () {
                  Navigator.popUntil(
                      context, (route) => route.isFirst);
                }
                    : null,
                child: const Text("Submit Set"),
              ),
            ),

            const SizedBox(height: 20),

            // Live list of flashcards in the current set
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
                  if (_hasFlashcards != flashcards.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _hasFlashcards = flashcards.isNotEmpty;
                      });
                    });
                  }

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

                              // edit flashcard button
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _showEditFlashcardDialog(card),
                              ),

                              // Delete flashcard button
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
