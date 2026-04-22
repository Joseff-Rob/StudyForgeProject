import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

/// Class to handle the storing of user backend Firestore logic.
class FirestoreUserService {
  final CollectionReference usersCollection =
  FirebaseFirestore.instance.collection('users');

  /// Creates a new user and adds to Firestore collection.
  Future<void> createUser(AppUser user) async {
    await usersCollection.doc(user.uid).set(user.toMap());
  }

  /// Checks against existing usernames to ensure that a username is unique
  /// before being accepted.
  Future<bool> isUsernameTaken(String username) async {
    final snapshot =
    await usersCollection.where('username', isEqualTo: username).get();
    return snapshot.docs.isNotEmpty;
  }
}
