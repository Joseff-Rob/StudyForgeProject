import 'dart:math';
import 'dart:typed_data' show Uint8List;

import 'package:StudyForgeProject/consts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/quiz_question.dart';
import 'flashcard_generator_service.dart';


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
      'titleLowercase': title.toLowerCase(),
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

  Stream<List<Map<String, dynamic>>> streamFlashcardSetsForProfile(String viewedUserId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Stream.empty();

    final isOwner = currentUser.uid == viewedUserId;

    Query query = _firestore
        .collection('flashcard_sets')
        .where('ownerId', isEqualTo: viewedUserId)
        .orderBy('createdAt', descending: true);

    if (!isOwner) {
      query = query.where('isPublic', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> updateFlashcardSetTitle(String setId, String newTitle) async {
    await _firestore.collection('flashcard_sets').doc(setId).update({
      'title': newTitle,
    });
  }

  Future<void> updateFlashcard({
    required String setId,
    required String flashcardId,
    required String question,
    required String answer,
  }) async {
    await _firestore
        .collection('flashcard_sets')
        .doc(setId)
        .collection('flashcards')
        .doc(flashcardId)
        .update({
      'question': question,
      'answer': answer,
    });
  }

  Future<void> updateFlashcardSetIsPublic(String setId, bool isPublic) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('flashcard_sets')
        .doc(setId)
        .update({
      'isPublic': isPublic,
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamFlashcardSet(String setId) {
    return _firestore
        .collection('flashcard_sets')
        .doc(setId)
        .snapshots();
  }

  Future<void> deleteFlashcard({
    required String setId,
    required String flashcardId,
  }) async {
    await _firestore
        .collection('flashcard_sets')
        .doc(setId)
        .collection('flashcards')
        .doc(flashcardId)
        .delete();

    await _firestore
        .collection('flashcard_sets')
        .doc(setId)
        .update({
      'flashcardCount': FieldValue.increment(-1),
    });
  }

  Future<void> deleteFlashcardSet(String setId) async {
    final setRef =
    _firestore.collection('flashcard_sets').doc(setId);

    // Get all flashcards inside set
    final cardsSnapshot =
    await setRef.collection('flashcards').get();

    // Delete flashcards first
    for (var doc in cardsSnapshot.docs) {
      await doc.reference.delete();
    }

    // Then delete the set itself
    await setRef.delete();
  }

  Future<List<QuizQuestion>> generateQuizFromSet(
      String setId, {
        int optionsPerQuestion = 4,
        int? questionLimit
      }) async {
    final snapshot = await _firestore
        .collection('flashcard_sets')
        .doc(setId)
        .collection('flashcards')
        .get();

    final flashcards = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'question': data['question'] as String,
        'answer': data['answer'] as String,
      };
    }).toList();

    if (flashcards.length < optionsPerQuestion) {
      throw Exception("Not enough flashcards to generate MCQ quiz.");
    }

    final random = Random();
    flashcards.shuffle();

    final selectedQuestions = questionLimit == null
        ? flashcards
        : flashcards.take(min(questionLimit, flashcards.length)).toList();

    List<QuizQuestion> quiz = [];

    for (var card in selectedQuestions) {
      final correctAnswer = card['answer'];

      // collect wrong answers
      List<String> wrongAnswers = flashcards
          .where((f) => f['answer'] != correctAnswer)
          .map((f) => f['answer']!)
          .toList();

      wrongAnswers.shuffle();

      final options = [
        correctAnswer!,
        ...wrongAnswers.take(optionsPerQuestion - 1),
      ];

      options.shuffle();

      quiz.add(
        QuizQuestion(
          question: card['question']!,
          options: options,
          correctAnswer: correctAnswer,
        ),
      );
    }
    return quiz;
  }

  Future<void> importTextAsFlashcards({
    required String rawText,
    required String setTitle,
    required String apiKey,
    bool isPublic = false,
  }) async {

    final generator = FlashcardGeneratorService(geminiApiKey: GEMINI_API_KEY);

    final truncatedText =
    rawText.length > 12000 ? rawText.substring(0, 12000) : rawText;

    final flashcards = await generator.generateFlashcards(truncatedText);

    if (flashcards.isEmpty) {
      throw Exception("No flashcards generated");
    }

    final setId = await createFlashcardSet(
      title: setTitle,
      isPublic: isPublic,
    );

    for (final card in flashcards) {
      await addFlashcard(
        setId: setId,
        question: card["question"]!,
        answer: card["answer"]!,
      );
    }
  }
}
