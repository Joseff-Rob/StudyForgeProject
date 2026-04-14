import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a Chat Message in the AI discussion that is stored in firestore.
///
/// This model includes a unique identifier, the content of the message and
/// its sender
/// It also includes helper methods for serialisation to and from a map,
/// Something that is very useful for use in firestore.
class TeachMessage {
  /// Unique identifier
  final String id;
  /// Content of the sent message
  final String text;
  /// Who sent the message ("student" or "gemini")
  final String sender;

  final Timestamp createdAt;

  /// Creates an instance of [TeachMessage].
  TeachMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.createdAt,
  });

  /// Creates the instance into a map for firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'sender': sender,
      'createdAt': createdAt,
    };
  }

  /// Creates a [TeachMessage] instance from a firestore map.
  factory TeachMessage.fromMap(String id, Map<String, dynamic> map) {
    return TeachMessage(
      id: id,
      text: map['text'] ?? '',
      sender: map['sender'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }
}
