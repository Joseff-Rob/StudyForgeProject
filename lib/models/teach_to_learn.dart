import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an AI discussion that is stored in firestore.
///
/// This model includes a unique identifier, a topic (title), the user and
/// a message count.
/// It also includes helper methods for serialisation to and from a map,
/// Something that is very useful for use in firestore.
class TeachToLearn {
  /// Unique identifier
  final String id;
  /// Teach-To-Learn lesson topic/title.
  final String topic;
  /// Owner of the lesson.
  final String ownerId;
  /// Number of messages in the discussions.
  final int messageCount;

  final Timestamp createdAt;
  final Timestamp updatedAt;

  /// Creates an instance of a [TeachToLearn] lesson.
  TeachToLearn({
    required this.id,
    required this.topic,
    required this.ownerId,
    required this.messageCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates the instance into a map for firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'topic': topic,
      'ownerId': ownerId,
      'messageCount': messageCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Creates a [TeachToLearn] lesson instance from a firestore map.
  factory TeachToLearn.fromMap(String id, Map<String, dynamic> map) {
    return TeachToLearn(
      id: id,
      topic: map['topic'] ?? '',
      ownerId: map['ownerId'] ?? '',
      messageCount: map['messageCount'] ?? 0,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
    );
  }
}
