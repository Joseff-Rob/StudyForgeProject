import 'package:StudyForgeProject/screens/view_flashcards_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_flashcard_service.dart';
import 'add_flashcard_screen.dart';

class UserFlashcardSetsScreen extends StatefulWidget {
  const UserFlashcardSetsScreen({super.key});

  @override
  State<UserFlashcardSetsScreen> createState() =>
      _UserFlashcardSetsScreenState();
}

class _UserFlashcardSetsScreenState extends State<UserFlashcardSetsScreen> {
  final FlashcardService _flashcardService = FlashcardService();

  // ---------------------------
  // DELETE SET
  // ---------------------------
  Future<void> _deleteSet(String setId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Set"),
        content: const Text("Are you sure you want to delete this flashcard set?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      await _flashcardService.deleteFlashcardSet(setId);
    }
  }

  // ---------------------------
  // EDIT SET TITLE
  // ---------------------------
  Future<void> _editSetTitle(String setId, String currentTitle) async {
    final controller = TextEditingController(text: currentTitle);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Set Title"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Title"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _flashcardService.updateFlashcardSetTitle(
                setId,
                controller.text.trim(),
              );
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ---------------------------
  // BUILD
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Flashcard Sets"),
        backgroundColor: Colors.blueGrey,
      ),

      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _flashcardService.streamUserFlashcardSets(),
            builder: (context, snapshot) {

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
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

                  return GestureDetector(
                    onLongPress: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => SafeArea(
                          child: Wrap(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.edit),
                                title: const Text("Edit Title"),
                                onTap: () {
                                  Navigator.pop(context);
                                  _editSetTitle(set['id'], title);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.delete, color: Colors.red),
                                title: const Text(
                                  "Delete Set",
                                  style: TextStyle(color: Colors.red),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  _deleteSet(set['id']);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "$count card${count == 1 ? '' : 's'}",
                        ),
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
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}