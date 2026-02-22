import 'package:flutter/material.dart';
import '../services/firestore_flashcard_service.dart';
import 'view_flashcards_screen.dart';

class PublicUserFlashcardSetsScreen extends StatelessWidget {
  final String userId;
  final String username;

  const PublicUserFlashcardSetsScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    final flashcardService = FlashcardService();

    return Scaffold(
      appBar: AppBar(
        title: Text("$username's Flashcards"),
        backgroundColor: Colors.blueGrey,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: flashcardService.streamFlashcardSetsForProfile(userId),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final sets = snapshot.data ?? [];

          if (sets.isEmpty) {
            return const Center(
              child: Text("No public flashcard sets available."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sets.length,
            itemBuilder: (context, index) {
              final set = sets[index];

              return Card(
                child: ListTile(
                  title: Text(set['title']),
                  subtitle: Text("${set['flashcardCount']} cards"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (set['isPublic'] == false)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(
                            Icons.lock,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ),
                      const Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewFlashcardsScreen(
                          setId: set['id'],
                          setTitle: set['title'],
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