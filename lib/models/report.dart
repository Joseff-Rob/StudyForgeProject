import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a Report that is stored in firestore.
///
/// This model includes a unique identifier, a type of report (flashcard set
/// or user) and their ID's and title/username, ID of the reporter and a
/// reason for the report
/// It also includes helper methods for serialisation to and from a map,
/// Something that is very useful for use in firestore.
class Report {
  /// Unique identifier
  final String id;
  /// Type of report (Flashcard set or User)
  final String targetType;
  /// Unique identifier of the reported resource (setID or userID)
  final String targetId;
  /// Name of the reported resource (setTitle or Username)
  final String targetTitle;
  /// Unique identifier of the reporter
  final String reportedBy;
  /// Reason for the report
  final String reason;

  final DateTime timestamp;

  /// Creates an instance of [Report].
  Report({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.targetTitle,
    required this.reportedBy,
    required this.reason,
    required this.timestamp,
  });

  /// Creates the instance into a map for firestore storage.
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

  /// Creates a [Report] instance from a firestore map.
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
