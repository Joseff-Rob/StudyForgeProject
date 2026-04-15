import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_flashcard_service.dart';
import 'view_flashcards_screen.dart';

// TODO Merge this file with user_flashcards_screen.dart.

/// Class that handles logic to view other flashcard sets from a specific
/// user profile.
///
/// Including:
/// - Viewing a list of flashcard sets (click to view full set).
/// - Editing set title, publicity and deleting set on a long hold of a set.
/// - Display which sets are private.
class PublicUserFlashcardSetsScreen extends StatelessWidget {
  final String userId;
  final String username;

  /// Creates a [PublicUserFlashcardSetsScreen].
  const PublicUserFlashcardSetsScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  /// Confirmation popup when deleting a flashcard set.
  Future<void> _deleteSet(BuildContext context, String setId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Set"),
        content: const Text("Are you sure you want to delete this set?"),
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

    // Delete set.
    if (confirm ?? false) {
      await FlashcardService().deleteFlashcardSet(setId);
    }
  }

  /// Popup for editing a flashcard set title.
  Future<void> _editTitle(
      BuildContext context, String setId, String currentTitle) async {

    final controller = TextEditingController(text: currentTitle);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Title"),
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
              // Update title.
              await FlashcardService().updateFlashcardSetTitle(
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

  /// Builds the user interface for a list of flashcard sets owned by
  /// a specific user.
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnerProfile = currentUser != null && currentUser.uid == userId;

    final FlashcardService _flashcardService  = FlashcardService();

    return Scaffold(
      appBar: AppBar(
        // Custom title depending on flashcard sets owner.
        title: Text("$username's Flashcards"),
        backgroundColor: Colors.blueGrey,
      ),

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _flashcardService.streamFlashcardSetsForProfile(userId),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final sets = snapshot.data ?? [];

          // If user has no flashcard sets.
          if (sets.isEmpty) {
            return const Center(
              child: Text("No flashcard sets available"),
            );
          }

          // List of flashcards UI.
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sets.length,
            itemBuilder: (context, index) {

              final set = sets[index];
              final title = set['title'] ?? "Untitled";
              final count = set['flashcardCount'] ?? 0;

              return GestureDetector(
                // Long press to edit title, publicity or delete set if owned.
                onLongPress: isOwnerProfile
                    ? () {
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
                              _editTitle(context, set['id'], title);
                            },
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            title: const Text(
                              "Delete Set",
                              style: TextStyle(color: Colors.red),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _deleteSet(context, set['id']);
                            },
                          ),
                          StatefulBuilder(
                            builder: (context, setStateSheet) {
                              return SwitchListTile(
                                title: const Text("Public"),
                                value: isPublic,
                                onChanged: (val) async {
                                  setStateSheet(() {
                                    isPublic = val;
                                  });

                                  // Update Firestore
                                  await _flashcardService
                                      .updateFlashcardSetIsPublic(
                                          set['id'], val
                                      );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }
                : null,

                child: Card(
                  child: ListTile(
                    title: Text(title),
                    subtitle: Text("$count cards"),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Show lock icon on private sets.
                        if (!set['isPublic'] && isOwnerProfile)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(Icons.lock,
                                size: 18, color: Colors.grey),
                          ),

                        const Icon(Icons.arrow_forward_ios),
                      ],
                    ),

                    // Navigate to flashcard set.
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
    );
  }
}
