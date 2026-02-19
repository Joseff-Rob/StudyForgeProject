class AppUser {
  final String uid;
  final String email;
  final String username;
  final String usernameLower; // ✅ new field

  AppUser({
    required this.uid,
    required this.email,
    required this.username,
    required this.usernameLower, // ✅ required in constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'username_lower': usernameLower, // ✅ stored in Firestore
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      usernameLower: map['username_lower'] ?? '',
    );
  }
}
