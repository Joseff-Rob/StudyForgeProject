class AppUser {
  final String uid;
  final String email;
  final String username;

  AppUser({required this.uid, required this.email, required this.username});

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
    };
  }
}
