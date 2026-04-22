import 'package:StudyForgeProject/screens/view_flashcards_screen.dart';
import 'package:flutter/material.dart';
import '../services/firestore_flashcard_service.dart';

/// Class that shows a list of the current users flashcards.
///
/// Includes:
/// - Clear, well-formatted list of owned flashcard sets.
/// - Set editing (title and publicity) and deletion.
/// - Clear distinguish between public and private sets.
class UserFlashcardSetsScreen extends StatefulWidget {

  /// Creates a [UserFlashcardSetsScreen].
  const UserFlashcardSetsScreen({super.key});

  @override
  State<UserFlashcardSetsScreen> createState() =>
      _UserFlashcardSetsScreenState();
}

class _UserFlashcardSetsScreenState extends State<UserFlashcardSetsScreen> {
  final FlashcardService _flashcardService = FlashcardService();

  /// Delete set confirmation popup.
  Future<void> _deleteSet(String setId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Set"),
        content: const Text(
            "Are you sure you want to delete this flashcard set?"
        ),
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
      // Deletes set.
      await _flashcardService.deleteFlashcardSet(setId);
    }
  }

  /// Set title editing popup.
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
              // Updates set title.
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

  /// Builds the UI for a list of owned flashcards and set actions.
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

              // No sets fallback.
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
                  final isPublic = set['isPublic'] ?? false;

                  return GestureDetector(
                    onLongPress: () {
                      bool isPublic = set['isPublic'] ?? false;
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
                              StatefulBuilder(
                                builder: (context, setStateSheet) {
                                  return SwitchListTile(
                                    title: const Text("Public"),
                                    value: isPublic,
                                    onChanged: (val) async {
                                      setStateSheet(() {
                                        // updates the switch inside the sheet
                                        isPublic = val;
                                      });

                                      // Update Firestore
                                      await _flashcardService
                                          .updateFlashcardSetIsPublic(
                                              set['id'], val
                                      );

                                      /*
                                       * Update local list so the UI reflects
                                       * the change immediately.
                                       */
                                      setState(() async {
                                        sets[index]['isPublic'] = val;
                                      });
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    // Individual set in the list UI.
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isPublic)
                              const Icon(Icons.lock, color: Colors.grey),
                            const SizedBox(width: 6),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            // Open set.
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
