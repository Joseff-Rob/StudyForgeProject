import 'package:flutter/material.dart';
import '../services/firestore_flashcard_service.dart';
import 'add_flashcard_screen.dart';
import 'add_flashcard_screen.dart';

class CreateFlashcardSetScreen extends StatefulWidget {
  const CreateFlashcardSetScreen({super.key});

  @override
  State<CreateFlashcardSetScreen> createState() =>
      _CreateFlashcardSetScreenState();
}

class _CreateFlashcardSetScreenState
    extends State<CreateFlashcardSetScreen> {
  final _titleController = TextEditingController();
  final FlashcardService _flashcardService = FlashcardService();

  bool _isPublic = false;
  bool _isLoading = false;

  /// Create a flashcard set and navigate to AddFlashcardsScreen
  Future<void> _createSet() async {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a title")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create the flashcard set in Firestore
      final setId = await _flashcardService.createFlashcardSet(
        title: title,
        isPublic: _isPublic,
      );

      if (!mounted) return;

      // Navigate immediately to AddFlashcardsScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AddFlashcardScreen(
            setId: setId,
            setTitle: title,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating set: $e")),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Flashcard Set"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Set Title",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: "Enter set title...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              value: _isPublic,
              onChanged: (value) {
                setState(() => _isPublic = value);
              },
              title: const Text("Make Public"),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createSet,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create Set"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}