import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/report.dart';
import '../screens/view_flashcards_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportLogsScreen extends StatelessWidget {
  const ReportLogsScreen({super.key});

  Future<void> _deleteSet(BuildContext context, String setId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Flashcard Set"),
        content: const Text(
          "Are you sure you want to delete this flashcard set? This action cannot be undone.",
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

    if (confirm != true) return;

    // Delete the set
    await FirebaseFirestore.instance.collection('flashcard_sets').doc(setId).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Flashcard set deleted.")),
    );
  }

  Future<void> _resolveReport(BuildContext context, String reportId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Resolve Report"),
        content: const Text("Mark this report as resolved and remove it from the list?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Resolve",
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Delete the report from Firestore
    await FirebaseFirestore.instance.collection('reports').doc(reportId).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Report resolved.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Logs"),
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data!.docs
              .map((doc) => Report.fromDocument(doc))
              .toList();

          if (reports.isEmpty) {
            return const Center(child: Text("No reports yet."));
          }

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                child: ListTile(
                  title: Text(report.setTitle),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("Reason: ${report.reason}"),
                      const SizedBox(height: 2),
                      Text(
                        "Reported by: ${report.reportedBy}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        "Time: ${DateFormat.yMd().add_jm().format(report.timestamp)}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      // Go to Set Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text("Go to Set"),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ViewFlashcardsScreen(
                                setId: report.setId,
                                setTitle: report.setTitle,
                              ),
                            ),
                          );
                        },
                      ),

                      // Delete Set Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text("Delete Set"),
                        onPressed: () => _deleteSet(context, report.setId),
                      ),

                      // Resolve Report Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text("Resolve"),
                        onPressed: () => _resolveReport(context, report.id),
                      ),
                    ],
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