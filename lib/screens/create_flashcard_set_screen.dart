import 'package:flutter/material.dart';
import '../services/firestore_flashcard_service.dart';

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

  Future<void> _createSet() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a title")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final setId = await _flashcardService.createFlashcardSet(
        title: _titleController.text.trim(),
        isPublic: _isPublic,
      );

      if (!mounted) return;

      Navigator.pop(context, setId);
      // Later you can navigate to AddFlashcardsScreen(setId: setId)

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => _isLoading = false);
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