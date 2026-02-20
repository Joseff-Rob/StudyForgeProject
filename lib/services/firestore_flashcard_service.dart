import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FlashcardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> createFlashcardSet({
    required String title,
    required bool isPublic,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final docRef = await _firestore
        .collection('flashcard_sets')
        .add({
      'title': title,
      'titleLowercase': title.toLowerCase(),
      'ownerId': user.uid,
      'isPublic': isPublic,
      'flashcardCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  Future<void> addFlashcard(
      String setId,
      String question,
      String answer,
      int orderIndex,
      ) async {
    final setRef =
    _firestore.collection('flashcard_sets').doc(setId);

    await setRef.collection('flashcards').add({
      'question': question,
      'answer': answer,
      'orderIndex': orderIndex,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await setRef.update({
      'flashcardCount': FieldValue.increment(1),
    });
  }
}