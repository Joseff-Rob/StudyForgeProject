import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id; // Firestore document ID
  final String targetType; // "set" or "user"
  final String targetId; // setId or userId
  final String targetTitle; // setTitle or username
  final String reportedBy; // user ID
  final String reason;
  final DateTime timestamp;

  Report({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.targetTitle,
    required this.reportedBy,
    required this.reason,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'targetType': targetType,
      'targetId': targetId,
      'targetTitle': targetTitle,
      'reportedBy': reportedBy,
      'reason': reason,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory Report.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Report(
      id: doc.id,
      targetType: data['targetType'] ?? '',
      targetId: data['targetId'] ?? '',
      targetTitle: data['targetTitle'] ?? '',
      reportedBy: data['reportedBy'] ?? '',
      reason: data['reason'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}