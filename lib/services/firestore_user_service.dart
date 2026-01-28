import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class FirestoreUserService {
  final CollectionReference usersCollection =
  FirebaseFirestore.instance.collection('users');

  Future<void> createUser(AppUser user) async {
    await usersCollection.doc(user.uid).set(user.toMap());
  }

  Future<bool> isUsernameTaken(String username) async {
    final snapshot =
    await usersCollection.where('username', isEqualTo: username).get();
    return snapshot.docs.isNotEmpty;
  }
}
