import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a Flashcard that is stored in firestore.
///
/// This model includes a unique identifier, a question and answer
/// (each side of the flashcard), and an order.
/// It also includes helper methods for serialisation to a map,
/// Something that is very useful for use in firestore.
class Flashcard {
  /// Unique Identifier
  final String id;
  /// Question (one side of a flashcard)
  final String question;
  /// Answer (other side of a flashcard)
  final String answer;
  /// Ordering
  final int orderIndex;

  final Timestamp createdAt;

  /// Creates an instance of [Flashcard].
  Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    required this.orderIndex,
    required this.createdAt,
  });

  /// Creates the instance into a map for firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'answer': answer,
      'orderIndex': orderIndex,
      'createdAt': createdAt,
    };
  }
}
