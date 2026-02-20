import 'package:StudyForgeProject/screens/view_flashcards_screen.dart';
import 'package:flutter/material.dart';
import '../services/firestore_flashcard_service.dart';
import 'add_flashcard_screen.dart';

class UserFlashcardSetsScreen extends StatefulWidget {
  const UserFlashcardSetsScreen({super.key});

  @override
  State<UserFlashcardSetsScreen> createState() => _UserFlashcardSetsScreenState();
}

class _UserFlashcardSetsScreenState extends State<UserFlashcardSetsScreen> {
  final FlashcardService _flashcardService = FlashcardService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Flashcard Sets"),
        backgroundColor: Colors.blueGrey,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _flashcardService.streamUserFlashcardSets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final sets = snapshot.data ?? [];

          if (sets.isEmpty) {
            return const Center(child: Text("No flashcard sets yet"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sets.length,
            itemBuilder: (context, index) {
              final set = sets[index];
              final title = set['title'] ?? "Untitled";
              final count = set['flashcardCount'] ?? 0;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("$count card${count == 1 ? '' : 's'}"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewFlashcardsScreen(
                          setId: set['id'],
                          setTitle: title,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}