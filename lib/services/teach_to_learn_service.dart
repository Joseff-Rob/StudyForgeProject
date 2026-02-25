import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeachToLearnService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ------------------------
  // CREATE LESSON
  // ------------------------
  Future<String> createLesson({required String topic}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Not logged in");

    final docRef = await _firestore.collection('teach_lessons').add({
      'topic': topic,
      'ownerId': user.uid,
      'messageCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  // ------------------------
  // ADD MESSAGE
  // ------------------------
  Future<void> addMessage({
    required String lessonId,
    required String text,
    required String sender,
  }) async {

    final lessonRef =
    _firestore.collection('teach_lessons').doc(lessonId);

    final lessonDoc = await lessonRef.get();

    // 🔥 If lesson does not exist → create it first
    if (!lessonDoc.exists) {
      await lessonRef.set({
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'messageCount': 0,
        'ownerId': FirebaseAuth.instance.currentUser?.uid,
      });
    }

    await lessonRef.collection('messages').add({
      'text': text,
      'sender': sender,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await lessonRef.update({
      'messageCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------------
  // STREAM USER LESSONS
  // ------------------------
  Stream<List<Map<String, dynamic>>> streamUserLessons() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    final query = _firestore
        .collection('teach_lessons')
        .where('ownerId', isEqualTo: user.uid)
        .orderBy('updatedAt', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // ------------------------
  // STREAM MESSAGES IN LESSON
  // ------------------------
  Stream<List<Map<String, dynamic>>> streamMessages(String lessonId) {
    return _firestore
        .collection('teach_lessons')
        .doc(lessonId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // ------------------------
  // DELETE LESSON
  // ------------------------
  Future<void> deleteLesson(String lessonId) async {
    final lessonRef =
    _firestore.collection('teach_lessons').doc(lessonId);

    final messages =
    await lessonRef.collection('messages').get();

    for (var doc in messages.docs) {
      await doc.reference.delete();
    }

    await lessonRef.delete();
  }

  Future<Map<String, dynamic>?> getLesson(String lessonId) async {
    final doc = await FirebaseFirestore.instance
        .collection('teach_lessons')
        .doc(lessonId)
        .get();

    if (!doc.exists) return null;

    return {
      'id': doc.id,
      ...doc.data()!,
    };
  }

  Future<List<Map<String, dynamic>>> getMessagesOnce(String lessonId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('teach_lessons')
        .doc(lessonId)
        .collection('messages')
        .orderBy('createdAt')
        .get();

    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();
  }
}