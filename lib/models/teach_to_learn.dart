import 'package:cloud_firestore/cloud_firestore.dart';

class TeachToLearn {
  final String id;
  final String topic;
  final String ownerId;
  final int messageCount;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  TeachToLearn({
    required this.id,
    required this.topic,
    required this.ownerId,
    required this.messageCount,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'topic': topic,
      'ownerId': ownerId,
      'messageCount': messageCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

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