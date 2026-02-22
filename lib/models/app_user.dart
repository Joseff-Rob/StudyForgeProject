class AppUser {
  final String uid;
  final String email;
  final String username;
  final String usernameLower;

  AppUser({
    required this.uid,
    required this.email,
    required this.username,
    required this.usernameLower,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'username_lower': usernameLower,
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
