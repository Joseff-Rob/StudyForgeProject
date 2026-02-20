import 'package:cloud_firestore/cloud_firestore.dart';

class FlashcardSet {
  final String id;
  final String title;
  final String ownerId;
  final bool isPublic;
  final int flashcardCount;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  FlashcardSet({
    required this.id,
    required this.title,
    required this.ownerId,
    required this.isPublic,
    required this.flashcardCount,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'titleLowercase': title.toLowerCase(),
      'ownerId': ownerId,
      'isPublic': isPublic,
      'flashcardCount': flashcardCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}