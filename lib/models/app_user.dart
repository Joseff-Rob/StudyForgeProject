/// Represents a user that is stored in firestore.
///
/// This model includes a unique identifier, authentication details and
/// role description.
/// It also includes helper methods for serialisation to and from a map,
/// Something that is very useful for use in firestore.
class AppUser {
  /// Unique identifier
  final String uid;
  /// User email address
  final String email;
  /// User's username
  final String username;
  /// User's username, converted to lowercase for search capabilities.
  final String usernameLower;
  /// Indicates whether the user has admin privileges.
  final bool isAdmin;

  /// Creates an instance of [AppUser].
  /// (Admin privileges set to false by default).
  AppUser({
    required this.uid,
    required this.email,
    required this.username,
    required this.usernameLower,
    this.isAdmin = false,
  });

  /// Creates the instance into a map for firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'username_lower': usernameLower,
      'isAdmin': isAdmin,
    };
  }

  /// Creates an [AppUser] instance from a firestore map.
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      usernameLower: map['username_lower'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
    );
  }
}
