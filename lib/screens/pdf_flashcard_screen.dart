import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/flashcard_generator_service.dart';
import '../services/firestore_flashcard_service.dart';
import '../consts.dart';

class PdfFlashcardScreen extends StatefulWidget {
  const PdfFlashcardScreen({super.key});

  @override
  State<PdfFlashcardScreen> createState() =>
      _PdfFlashcardScreenState();
}

class _PdfFlashcardScreenState extends State<PdfFlashcardScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  final FlashcardService _flashcardService = FlashcardService();

  bool loading = false;
  bool _isPublic = false;
  String? _uploadedFileName;

  List<Map<String, String>> generatedCards = [];

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
      // fallback for platforms where path is available (mobile/desktop)
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

  Future<void> saveFlashcards() async {
    if (_titleController.text.isEmpty || generatedCards.isEmpty) return;

    setState(() {
      loading = true;
    });

    final setId = await _flashcardService.createFlashcardSet(
      title: _titleController.text,
      isPublic: _isPublic,
    );

    for (final card in generatedCards) {
      await _flashcardService.addFlashcard(
        setId: setId,
        question: card["question"]!,
        answer: card["answer"]!,
      );
    }

    setState(() {
      loading = false;
    });

    Navigator.pop(context);
  }

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
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: pickTxtFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Upload .txt"),
                  ),
                ),
                const SizedBox(width: 10),
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

            if (_uploadedFileName != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

            if (generatedCards.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: saveFlashcards,
                  icon: const Icon(Icons.save),
                  label: const Text("Save Flashcard Set"),
                ),
              ),

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