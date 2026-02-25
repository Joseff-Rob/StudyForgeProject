import 'package:StudyForgeProject/screens/teach_to_learn_ai.dart';
import 'package:flutter/material.dart';
import '../services/teach_to_learn_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserLessonsScreen extends StatefulWidget {
  const UserLessonsScreen({super.key});

  @override
  State<UserLessonsScreen> createState() => _UserLessonsScreenState();
}

class _UserLessonsScreenState extends State<UserLessonsScreen> {

  final TeachToLearnService _lessonService =
  TeachToLearnService();

  Future<void> _deleteLesson(String lessonId) async {
    try {
      await _lessonService.deleteLesson(lessonId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lesson deleted")),
      );

    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Lessons"),
        backgroundColor: Colors.blueGrey,
      ),

      body: user == null
          ? const Center(
        child: Text("Please login to view lessons"),
      )

          : StreamBuilder<List<Map<String, dynamic>>>(
        stream: _lessonService.streamUserLessons(),

        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text("Error loading lessons"),
            );
          }

          final lessons = snapshot.data ?? [];

          if (lessons.isEmpty) {
            return const Center(
              child: Text("No lessons yet"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: lessons.length,

            itemBuilder: (context, index) {

              final lesson = lessons[index];

              final topic =
                  lesson['topic']?.toString() ??
                      "Untitled Lesson";

              final count =
                  lesson['messageCount']?.toString() ??
                      "0";

              return GestureDetector(
                onLongPress: () async {

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Delete Lesson?"),
                      content: const Text(
                          "This will permanently delete this lesson."),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, true),
                          child: const Text(
                            "Delete",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await _deleteLesson(lesson['id']);
                  }
                },

                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),

                  child: ListTile(
                    title: Text(
                      topic,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    subtitle: Text("$count messages"),

                    trailing: const Icon(Icons.chevron_right),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeachToLearnAi(
                            lessonId: lesson['id'],
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