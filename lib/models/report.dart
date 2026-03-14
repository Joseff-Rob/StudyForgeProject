import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id; // Firestore document ID
  final String setId;
  final String setTitle;
  final String reportedBy; // user ID
  final String reason;
  final DateTime timestamp;

  Report({
    required this.id,
    required this.setId,
    required this.setTitle,
    required this.reportedBy,
    required this.reason,
    required this.timestamp,
  });

  // Convert Report to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'setId': setId,
      'setTitle': setTitle,
      'reportedBy': reportedBy,
      'reason': reason,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  // Create from Firestore DocumentSnapshot
  factory Report.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Report(
      id: doc.id, // use the document ID here
      setId: data['setId'] ?? '',
      setTitle: data['setTitle'] ?? '',
      reportedBy: data['reportedBy'] ?? '',
      reason: data['reason'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}