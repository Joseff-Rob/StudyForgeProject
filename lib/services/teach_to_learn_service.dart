import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Class to handle Firestore backend actions for AI "Teach-To-Learn lessons.
class TeachToLearnService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a AI lesson with a specified topic.
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

  /// Adds an individual message to the discussion.
  Future<void> addMessage({
    required String lessonId,
    required String text,
    required String sender,
  }) async {

    final lessonRef =
    _firestore.collection('teach_lessons').doc(lessonId);

    final lessonDoc = await lessonRef.get();

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

  /// Streams lessons for the current logged in user in real time.
  ///
  /// This enables the UI to reactively update whenever lessons are created,
  /// or deleted in Firestore.
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

  /// Streams Messages for a given AI lesson in real time.
  ///
  /// This enables the UI to reactively update whenever messages in Firestore.
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

  /// Deletes a selected lesson from the Firestore collection.
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

  /// Retrieves all messages for a lesson.
  ///
  /// Unlike a stream, this method performs a single read operation and
  /// does not listen for real-time updates.
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
