import 'package:cloud_firestore/cloud_firestore.dart';

class TeachMessage {
  final String id;
  final String text;
  final String sender; // "student" or "gemini"
  final Timestamp createdAt;

  TeachMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'sender': sender,
      'createdAt': createdAt,
    };
  }

  factory TeachMessage.fromMap(String id, Map<String, dynamic> map) {
    return TeachMessage(
      id: id,
      text: map['text'] ?? '',
      sender: map['sender'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }
}