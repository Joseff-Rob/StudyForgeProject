import 'package:StudyForgeProject/screens/public_user_flashcard_sets_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatelessWidget {
  final String? userId;

  const ProfilePage({super.key, this.userId});

  // ----------------------------
  // REPORT USER
  // ----------------------------
  Future<void> _reportUser(
      BuildContext context, String userId, String username) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Report User"),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: "Reason for reporting",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final reason = controller.text.trim();
              if (reason.isEmpty) return;

              await FirebaseFirestore.instance.collection('reports').add({
                'targetType': 'user',
                'targetId': userId,
                'targetTitle': username,
                'reportedBy': FirebaseAuth.instance.currentUser?.uid,
                'reason': reason,
                'timestamp': FieldValue.serverTimestamp(),
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("User reported")),
              );
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  // ----------------------------
  // DELETE ACCOUNT
  // ----------------------------
  Future<void> _deleteAccount(
      BuildContext context, String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
            "Are you sure you want to delete this account? "
                "This action will remove all flashcard sets and cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Delete all flashcard sets by this user
    final setsSnapshot = await FirebaseFirestore.instance
        .collection('flashcard_sets')
        .where('ownerId', isEqualTo: uid)
        .get();

    for (final doc in setsSnapshot.docs) {
      await FirebaseFirestore.instance
          .collection('flashcard_sets')
          .doc(doc.id)
          .delete();
    }

    // Delete the user document
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();

    // If current user deletes their own account, delete Firebase Auth account
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid == uid) {
      await currentUser.delete();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Account deleted")),
    );

    Navigator.pop(context); // go back after deletion
  }

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

  Widget _buildInfoCard({
    required String title,
    required String value,
    required bool isEditable,
    required VoidCallback onEdit,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (isEditable)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            ),
        ],
      ),
    );
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
      backgroundColor: const Color(0xFFDCE6F0),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Text(isCurrentUser ? "Your Profile" : "User Profile"),
        actions: [
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser?.uid)
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final currentData =
                  snapshot.data!.data() as Map<String, dynamic>? ?? {};
              final isAdmin = currentData['isAdmin'] ?? false;

              if (isCurrentUser || isAdmin) {
                return IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: "Delete Account",
                  onPressed: () => _deleteAccount(context, uidToShow),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uidToShow)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text("Profile data not found."));
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final username = data['username'] ?? 'Unknown';
              final email = data['email'] ?? 'No email';
              final isAdmin = data['isAdmin'] ?? false;
              final isCurrentUser =
                  uidToShow == FirebaseAuth.instance.currentUser?.uid;

              return Column(
                children: [
                  // ---------------- PROFILE HEADER ----------------
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, size: 40, color: Colors.blueGrey),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          username,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade700,
                                borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "ADMIN",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ---------------- USER INFO CARD ----------------
                  _buildInfoCard(
                    title: "Username",
                    value: username,
                    isEditable: isCurrentUser,
                    onEdit: () =>
                        _editUsername(context, uidToShow, username),
                  ),

                  const SizedBox(height: 16),

                  _buildInfoCard(
                    title: "Email",
                    value: email,
                    isEditable: isCurrentUser,
                    onEdit: () =>
                        _editEmail(context, uidToShow, email),
                  ),

                  const SizedBox(height: 24),

                  // ---------------- ACTION BUTTONS ----------------
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.style),
                      label: const Text("View Flashcards"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PublicUserFlashcardSetsScreen(
                              userId: uidToShow,
                              username: username,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  if (!isCurrentUser) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.report),
                        label: const Text("Report User"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () =>
                            _reportUser(context, uidToShow, username),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}