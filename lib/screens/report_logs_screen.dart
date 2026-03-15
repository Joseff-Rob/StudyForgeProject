import 'package:StudyForgeProject/screens/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/report.dart';
import '../screens/view_flashcards_screen.dart';

class ReportLogsScreen extends StatefulWidget {
  const ReportLogsScreen({super.key});

  @override
  State<ReportLogsScreen> createState() => _ReportLogsScreenState();
}

class _ReportLogsScreenState extends State<ReportLogsScreen> {
  final List<Report> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .get();

    final reports = snapshot.docs.map((doc) => Report.fromDocument(doc)).toList();

    setState(() {
      _reports.clear();
      _reports.addAll(reports);
      _isLoading = false;
    });
  }

  List<Report> get _setReports =>
      _reports.where((r) => r.targetType == "set").toList();

  List<Report> get _userReports =>
      _reports.where((r) => r.targetType == "user").toList();

  Future<void> _resolveReport(Report report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Resolve Report"),
        content: const Text("Are you sure you want to mark this report as resolved?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Resolve")),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance.collection('reports').doc(report.id).delete();

    setState(() {
      _reports.remove(report);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Report Resolved"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteSet(Report report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Set"),
        content: const Text("Are you sure you want to delete this flashcard set?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection('flashcard_sets')
        .doc(report.targetId)
        .delete();

    await FirebaseFirestore.instance.collection('reports').doc(report.id).delete();

    setState(() {
      _reports.remove(report);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Set Deleted, Report Resolved"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteUser(Report report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete User"),
        content: const Text(
            "Are you sure you want to delete this user and all their flashcard sets?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final firestore = FirebaseFirestore.instance;

    try {
      // Find all sets by the user
      final sets = await firestore
          .collection('flashcard_sets')
          .where('ownerId', isEqualTo: report.targetId)
          .get();

      // Delete all sets
      for (final doc in sets.docs) {
        await doc.reference.delete();
      }

      // Delete the user document
      await firestore.collection('users').doc(report.targetId).delete();

      // Delete the report
      await firestore.collection('reports').doc(report.id).delete();

      setState(() {
        _reports.remove(report);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User and their flashcard sets deleted"),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting user: $e")),
      );
    }
  }

  Widget _buildReportList(List<Report> reports, {required bool isUserReport}) {
    if (reports.isEmpty) {
      return const Center(
        child: Text(
          "No reports to review.",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    }

    return ListView.builder(
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // TITLE
                Text(report.targetTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

                const SizedBox(height: 6),

                // REASON & REPORT INFO
                Text("Reason: ${report.reason}"),
                const SizedBox(height: 4),
                Text("Reported by: ${report.reportedBy}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text("Time: ${DateFormat.yMd().add_jm().format(report.timestamp)}", style: const TextStyle(fontSize: 12, color: Colors.grey)),

                const SizedBox(height: 12),

                // BUTTONS (stacked vertically)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    if (!isUserReport)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, padding: const EdgeInsets.symmetric(vertical: 8)),
                        child: const Text("Go to Set"),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ViewFlashcardsScreen(setId: report.targetId, setTitle: report.targetTitle),
                          ));
                        },
                      ),

                    if (isUserReport)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, padding: const EdgeInsets.symmetric(vertical: 8)),
                        child: const Text("View Account"),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ProfilePage(userId: report.targetId),
                          ));
                        },
                      ),

                    const SizedBox(height: 6),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 8)),
                      child: const Text("Resolve"),
                      onPressed: () => _resolveReport(report),
                    ),

                    const SizedBox(height: 6),

                    if (!isUserReport)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 8)),
                        child: const Text("Delete Set"),
                        onPressed: () => _deleteSet(report),
                      ),

                    if (isUserReport)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 8)),
                        child: const Text("Delete User"),
                        onPressed: () => _deleteUser(report),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Report Logs"),
          backgroundColor: Colors.redAccent,
          bottom: const TabBar(
            tabs: [
              Tab(text: "Set Reports"),
              Tab(text: "User Reports"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          children: [
            _buildReportList(_setReports, isUserReport: false),
            _buildReportList(_userReports, isUserReport: true),
          ],
        ),
      ),
    );
  }
}