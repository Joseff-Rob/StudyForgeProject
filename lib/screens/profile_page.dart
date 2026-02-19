import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatelessWidget {
  final String? userId; // If null → current user; otherwise → view another user

  const ProfilePage({super.key, this.userId});

  // ----------------------------
  // EDIT USERNAME
  // ----------------------------
  Future<void> _editUsername(
      BuildContext context, String uid, String currentUsername) async {
    final controller = TextEditingController(text: currentUsername);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Username"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Username",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final newUsername = controller.text.trim();
              if (newUsername.isEmpty) return;

              final taken = await isUsernameTaken(newUsername, uid);
              if (taken) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Username already taken")),
                );
                return;
              }

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .update({'username': newUsername});

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<bool> isUsernameTaken(String username, String currentUid) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    return query.docs.any((doc) => doc.id != currentUid);
  }

  // ----------------------------
  // EDIT EMAIL
  // ----------------------------
  Future<void> _editEmail(
      BuildContext context, String uid, String currentEmail) async {
    final controller = TextEditingController(text: currentEmail);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Email"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Email",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final newEmail = controller.text.trim();
              if (newEmail.isEmpty) return;

              final taken = await isEmailTaken(newEmail, uid);
              if (taken) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Email already taken")),
                );
                return;
              }

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .update({'email': newEmail});

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Email updated")),
              );
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<bool> isEmailTaken(String email, String currentUid) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    return query.docs.any((doc) => doc.id != currentUid);
  }

  // ----------------------------
  // UI
  // ----------------------------
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final uidToShow = userId ?? currentUser?.uid;

    if (uidToShow == null) {
      return const Scaffold(
        body: Center(child: Text("No user to display")),
      );
    }

    final isCurrentUser = uidToShow == currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCurrentUser ? "Your Profile" : "User Profile"),
      ),
      body: Center(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uidToShow)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Text("Profile data not found.");
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final username = data['username'] ?? 'Unknown';
            final email = data['email'] ?? 'No email';

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person, size: 80, color: Colors.blueGrey),
                const SizedBox(height: 20),

                // Username
                const Text(
                  "Username:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(username, style: const TextStyle(fontSize: 20)),
                    if (isCurrentUser)
                      const SizedBox(width: 8),
                    if (isCurrentUser)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            _editUsername(context, uidToShow, username),
                      ),
                  ],
                ),

                const SizedBox(height: 28),

                // Email
                const Text(
                  "Email:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(email, style: const TextStyle(fontSize: 16)),
                    if (isCurrentUser) const SizedBox(width: 8),
                    if (isCurrentUser)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editEmail(context, uidToShow, email),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
