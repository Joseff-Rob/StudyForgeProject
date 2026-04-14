import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a Flashcard Set that is stored in firestore.
///
/// This model includes a unique identifier, a set title, owner and count
/// as well as an isPublic variable for hidden or published sets.
/// It also includes helper methods for serialisation to a map,
/// Something that is very useful for use in firestore.
class FlashcardSet {
  /// Unique Identifier
  final String id;
  /// Flashcard set title
  final String title;
  /// Flashcard set title, converted to lowercase for search capabilities.
  final String titleLowercase;
  /// Set owners unique identifier.
  final String ownerId;
  /// Boolean defining whether the set is available to others or not.
  final bool isPublic;
  /// Count of flashcards.
  final int flashcardCount;

  final Timestamp createdAt;
  final Timestamp updatedAt;

  /// Creates an instance of [FlashcardSet].
  FlashcardSet({
    required this.id,
    required this.title,
    required this.titleLowercase,
    required this.ownerId,
    required this.isPublic,
    required this.flashcardCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates the instance into a map for firestore storage.
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
