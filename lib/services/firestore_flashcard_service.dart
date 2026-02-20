import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FlashcardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ------------------------
  // CREATE FLASHCARD SET
  // ------------------------
  Future<String> createFlashcardSet({required String title, bool isPublic = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Not logged in");

    final docRef = await _firestore.collection('flashcard_sets').add({
      'title': title,
      'ownerId': user.uid,
      'isPublic': isPublic,
      'flashcardCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    print('Created flashcard set with ID: ${docRef.id}');
    return docRef.id;
  }

  // ------------------------
  // ADD FLASHCARD TO SET
  // ------------------------
  Future<void> addFlashcard({
    required String setId,
    required String question,
    required String answer,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Not logged in");

    final flashcardRef = _firestore
        .collection('flashcard_sets')
        .doc(setId)
        .collection('flashcards');

    await flashcardRef.add({
      'question': question,
      'answer': answer,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Increment flashcardCount in parent set
    final setDocRef = _firestore.collection('flashcard_sets').doc(setId);
    await setDocRef.update({
      'flashcardCount': FieldValue.increment(1),
    });
  }

  // ------------------------
  // STREAM FLASHCARDS IN A SET
  // ------------------------
  Stream<List<Map<String, dynamic>>> streamFlashcards(String setId) {
    final flashcardRef =
    _firestore.collection('flashcard_sets').doc(setId).collection('flashcards');

    return flashcardRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add doc id for reference
        return data;
      }).toList();
    });
  }

  // ------------------------
  // GET FLASHCARD SETS FOR CURRENT USER
  // ------------------------
  Stream<List<Map<String, dynamic>>> streamUserFlashcardSets() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    final setRef = _firestore
        .collection('flashcard_sets')
        .where('ownerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true);

    return setRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
}