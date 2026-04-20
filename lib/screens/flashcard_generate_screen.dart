import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/flashcard_generator_service.dart';
import '../services/firestore_flashcard_service.dart';
import '../consts.dart';

/// Screen that handles the logic and UI for generating a flashcard set from
/// digital notes (raw text or .txt file). Gemini is used to automatically
/// generate flashcards in correct JSON format
///
/// Works alongside [FlashcardGeneratorService] to generate a set.
class FlashcardGenerateScreen extends StatefulWidget {

  /// Creates a [FlashcardGenerateScreen]
  const FlashcardGenerateScreen({super.key});

  @override
  State<FlashcardGenerateScreen> createState() =>
      _FlashcardGenerateScreenState();
}

class _FlashcardGenerateScreenState extends State<FlashcardGenerateScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  final FlashcardService _flashcardService = FlashcardService();

  bool loading = false;
  bool _isPublic = false;
  String? _uploadedFileName;

  List<Map<String, String>> generatedCards = [];

  /// Opens a file picker allowing users to select a '.txt' file.
  ///
  /// If a file is selected, its contents are read and populated
  /// into the text input field.
  ///
  /// File name and option to remove is present in the UI of the screen.
  Future<void> pickTxtFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
      withData: true,
    );

    if (result == null) return;

    final fileBytes = result.files.single.bytes;

    if (fileBytes != null) {
      final text = String.fromCharCodes(fileBytes);

      setState(() {
        _textController.text = text;
        _uploadedFileName = result.files.single.name;
      });

    } else {
      final path = result.files.single.path;
      if (path != null) {
        final file = File(path);
        final text = await file.readAsString();

        setState(() {
          _textController.text = text;
          _uploadedFileName = result.files.single.name;
        });
      }
    }
  }

  /// Generates flashcards from the provided text input using AI.
  ///
  /// User's notes is displayed in the UI for user review
  /// Sends the user's notes to [FlashcardGeneratorService], which returns
  /// a list of question–answer pairs. with the generated cards showed to
  /// users before they choose to create the set.
  ///
  /// Displays a loading indicator during processing and shows an error
  /// message if generation fails.
  Future<void> generateFlashcards() async {
    if (_textController.text.isEmpty) return;

    setState(() {
      loading = true;
    });

    try {
      final generator =
      FlashcardGeneratorService(geminiApiKey: GEMINI_API_KEY);

      final cards =
      await generator.generateFlashcards(_textController.text);

      setState(() {
        generatedCards = cards;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() {
      loading = false;
    });
  }

  /// Creates the flashcard set based on the generated flashcards.
  Future<void> saveFlashcards() async {
    if (_titleController.text.isEmpty || generatedCards.isEmpty) return;

    setState(() {
      loading = true;
    });

    try {
      // Create set
      final setId = await _flashcardService.createFlashcardSet(
        title: _titleController.text,
        isPublic: _isPublic, // respect the toggle
      );

      // Add each flashcard to the set.
      for (final card in generatedCards) {
        await _flashcardService.addFlashcard(
          setId: setId,
          question: card["question"]!,
          answer: card["answer"]!,
        );
      }

      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Flashcard set '${_titleController.text}' created successfully!",
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        // Option to clear the form / navigate back after a short delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving flashcards: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /// Builds the user interface for generating a flashcard set.
  ///
  /// Includes:
  /// - Set title and publicity defining.
  /// - upload .txt file button.
  /// - generate cards button.
  /// - Raw text showed to user.
  /// - After generated, shows cards generated with option to create set.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Flashcard Generator"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Title field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Flashcard Set Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min, // shrink to fit content
              children: [
                const Text(
                  "Make Public",
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 10),
                // publicity switcher
                Switch(
                  value: _isPublic,
                  onChanged: (value) {
                    setState(() {
                      _isPublic = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                // Upload .txt file button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: pickTxtFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Upload .txt"),
                  ),
                ),
                const SizedBox(width: 10),

                // Generate cards button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: generateFlashcards,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text("Generate"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Display file name with removal capability
            if (_uploadedFileName != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Text(
                          _uploadedFileName!,
                          style: const TextStyle(fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _uploadedFileName = null;
                            _textController.clear();
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Digital notes text field
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: "Paste your study notes here...",
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Gemini Warner button for mistakes.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.amber.shade200,
              child: Text(
                "⚠️ Gemini can make mistakes. Verify Important Information!",
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),

            // Display generated cards.
            if (generatedCards.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: generatedCards.length,
                  itemBuilder: (context, index) {
                    final card = generatedCards[index];

                    return Card(
                      child: ListTile(
                        title: Text(card["question"]!),
                        subtitle: Text(card["answer"]!),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 10),

            // Save flashcard set button.
            if (generatedCards.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: saveFlashcards,
                  icon: const Icon(Icons.save),
                  label: const Text("Save Flashcard Set"),
                ),
              ),
            const SizedBox(height: 20),

            // Loading animation.
            if (loading)
              const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(),
              )
          ],
        ),
      ),

    );
  }
}
