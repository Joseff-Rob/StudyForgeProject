import 'package:cloud_firestore/cloud_firestore.dart';

class Flashcard {
  final String id;
  final String question;
  final String answer;
  final int orderIndex;
  final Timestamp createdAt;

  Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    required this.orderIndex,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'answer': answer,
      'orderIndex': orderIndex,
      'createdAt': createdAt,
    };
  }
}