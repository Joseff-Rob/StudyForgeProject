import 'dart:async';

import 'package:StudyForgeProject/screens/create_flashcard_set_screen.dart';
import 'package:StudyForgeProject/screens/flashcard_generate_screen.dart';
import 'package:StudyForgeProject/screens/privacy_policy_screen.dart';
import 'package:StudyForgeProject/screens/report_logs_screen.dart';
import 'package:StudyForgeProject/screens/user_flashcards_screen.dart';
import 'package:StudyForgeProject/screens/user_lessons_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/teach_to_learn_service.dart';
import 'profile_page.dart';
import 'teach_to_learn_ai.dart';
import 'settings.dart';
import 'view_flashcards_screen.dart';

/// Screen for the main menu of the application.
///
/// Includes:
/// - Search functionality (Search for users and Flashcard sets).
/// - Menu bar (Includes: View Profile, Settings, Privacy Policy and Log Out.
/// For admins: Report logs.
/// - Main menu layout (Includes: Welcome "Username" and StudyForge logo.
/// - Navigation bar at bottom (Includes: Teach to learn lessons, Flashcards
/// and Profile.
///
/// Mainly used for navigation to other application fearures.
class MainMenu extends StatefulWidget {

  /// Creates a [MainMenu] screen
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _userResults = [];
  List<Map<String, dynamic>> _flashcardSetResults = [];

  int _selectedIndex = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      _performDebouncedSearch(_searchController.text.trim());
    });
  }

  /// Disposes text controllers when the widget is removed (searching).
  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// Performs a debounced search to reduce the number of search calls.
  void _performDebouncedSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(
      const Duration(milliseconds: 300),
          () => _search(query),
    );
  }

  /// Search functionality to search for users and flashcard sets.
  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _userResults = [];
        _flashcardSetResults = [];
      });
      return;
    }

    final lowerQuery = query.toLowerCase();

    try {
      // Users Search
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username_lower', isGreaterThanOrEqualTo: lowerQuery)
          .where('username_lower',
          isLessThanOrEqualTo: lowerQuery + '\uf8ff')
          .limit(5)
          .get();

      final users = userSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['username'],
        };
      }).toList();

      // Flashcard sets search
      final setSnapshot = await FirebaseFirestore.instance
          .collection('flashcard_sets')
          .where('isPublic', isEqualTo: true)
          .where('titleLowercase',
          isGreaterThanOrEqualTo: lowerQuery)
          .where('titleLowercase',
          isLessThanOrEqualTo: lowerQuery + '\uf8ff')
          .limit(5)
          .get();

      // Collect owner IDs.
      final ownerIds = setSnapshot.docs
          .map((doc) => doc['ownerId'] as String)
          .toSet()
          .toList();

      // Fetch owner usernames in one batch query.
      Map<String, String> ownerUsernames = {};

      if (ownerIds.isNotEmpty) {
        final userDocs = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: ownerIds)
            .get();

        for (var doc in userDocs.docs) {
          ownerUsernames[doc.id] = doc['username'] ?? "Unknown";
        }
      }

      /*
       * Build final flashcard set results
       *(includes set title, flashcard count and owner username).
       */
      final sets = setSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['title'],
          'cards': doc['flashcardCount'] ?? 0,
          'ownerName':
          ownerUsernames[doc['ownerId']] ?? "Unknown",
        };
      }).toList();

      // Display results to User Interface.
      setState(() {
        _userResults = users;
        _flashcardSetResults = sets;
      });
    } catch (e) {
      debugPrint("Search error: $e");
    }
  }

  /// Clear search results.
  void _clearSearch() {
    setState(() {
      _userResults = [];
      _flashcardSetResults = [];
      _searchController.clear();
      _searchFocusNode.unfocus();
    });
  }

  /// Bottom navigation bar handling
  void _onItemTapped(int index) {
    // Navigate to teach to learn features (new or existing lessons).
    if (index == 0) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => Padding(
          padding: const EdgeInsets.only(bottom: 70),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text("New Lesson With Gemini"),
                  onTap: () async {
                    Navigator.pop(context);

                    final lessonId = await TeachToLearnService()
                        .createLesson(topic: ""); // create empty topic initially

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeachToLearnAi(
                          lessonId: lessonId,
                        ),
                      ),
                    );
                  }
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text("View old Gemini Lessons"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserLessonsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );

    /*
     * Navigate to flashcard features
     * (manual creation, generation or existing sets).
     */
    } else if (index == 1) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => Padding(
          padding: const EdgeInsets.only(bottom: 70),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text("View Flashcards"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserFlashcardSetsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text("Add New Flashcard Set"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const CreateFlashcardSetScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_snippet),
                title: const Text("Generate Cards"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => FlashcardGenerateScreen()
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );

    // Navigate to user profile.
    } else if (index == 2) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => Padding(
          padding: const EdgeInsets.only(bottom: 70),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text("View Profile"),
                onTap: () {
                  Navigator.pop(context);

                  final currentUser =
                      FirebaseAuth.instance.currentUser;

                  if (currentUser != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProfilePage(userId: currentUser.uid),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      );
    }
    setState(() => _selectedIndex = index);
  }

  /// Builds the user interface for the main menu of the application.
  @override
  Widget build(BuildContext context) {
    /// Current user token from firebase authentication.
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: currentUser != null
          ? FirebaseFirestore.instance.collection('users')
          .doc(currentUser.uid)
          .snapshots()
          : null,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(
                  child: CircularProgressIndicator()
              )
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final username = data['username'] ?? "User";
        final isAdmin = data['isAdmin'] ?? false;

        return Scaffold(
          backgroundColor: isAdmin ? const Color(0xFFFFCDD2)
              : const Color(0xFFDCE6F0),
          // Menu Drawer
          endDrawer: SizedBox(
            width: MediaQuery.of(context).size.width * 0.75,
            child: Drawer(
              child: SafeArea(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      color: Colors.blueGrey,
                      child: Text(
                        // Additional drawer options for admins.
                        isAdmin ? "Admin Menu" : "Menu",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // View Profile
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text("View Profile"),
                      onTap: () {
                        Navigator.pop(context);
                        if (currentUser != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ProfilePage(
                                    userId: currentUser.uid)
                            ),
                          );
                        }
                      },
                    ),

                    // Go to settings.
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text("Settings"),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsPage()
                          ),
                        );
                      },
                    ),

                    // Admin-only option (Report Logs).
                    if (isAdmin)
                      ListTile(
                        leading: const Icon(Icons.report),
                        title: const Text("Report Logs"),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReportLogsScreen(),
                            ),
                          );
                        },
                      ),

                    // Other options pushed to the bottom
                    const Spacer(),

                    // Application privacy policy.
                    ListTile(
                      leading: const Icon(Icons.privacy_tip),
                      title: const Text("Privacy Policy"),
                      iconColor: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen()
                          ),
                        );
                      },
                    ),

                    // Log Out (return to login/register page)
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        "Log Out",
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog( // Confirmation
                            title: const Text("Log Out"),
                            content: const Text(
                                "Are you sure you want to log out?"
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  "Log Out",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await FirebaseAuth.instance.signOut();
                        }
                      },
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          // Top App bar.
          appBar: AppBar(
            backgroundColor: isAdmin ? Colors.red.shade700 : Colors.blueGrey,
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              // Search bar.
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: "Search users or flashcard sets...",
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10
                  ),
                ),
              ),
            ),
            actions: [
              // Menu drawer opener.
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
            ],
          ),

          // Main body of menu.
          body: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Clear differentiation of admin users.
                    if (isAdmin)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "ADMIN",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    // Welcome message.
                    Text(
                      "Welcome, $username 👋",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // StudyForge Logo
                    Image.asset(
                      'assets/images/StudyForgeLogo.png',
                      height: 180,
                    ),
                  ],
                ),
              ),

              // Display Search bar results.
              if (_userResults.isNotEmpty || _flashcardSetResults.isNotEmpty
                  || _searchController.text.isNotEmpty)
                Positioned(
                  top: 10,
                  left: 16,
                  right: 16,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 350),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.only(bottom: 12),
                      // SingleChildScroller to avoid pixel overflows.
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User results.
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                "Users",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16
                                ),
                              ),
                            ),
                            if (_userResults.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text("No users found"),
                              ),
                            ..._userResults.map((user) {
                              return ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(user['name']),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ProfilePage(
                                            userId: user['id']
                                        )
                                    ),
                                  );
                                  _clearSearch();
                                },
                              );
                            }),
                            const Divider(),
                            // Flashcard Sets results.
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                "Flashcard Sets",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16
                                ),
                              ),
                            ),
                            if (_flashcardSetResults.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text("No flashcard sets found"),
                              ),
                            ..._flashcardSetResults.map((set) {
                              return ListTile(
                                leading: const Icon(Icons.style),
                                // Normalised UI output for search results.
                                title: Text(
                                    "${set['name']} | "
                                    "${set['cards']} cards | by "
                                    "${set['ownerName']}"
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ViewFlashcardsScreen(
                                        setId: set['id'],
                                        setTitle: set['name'],
                                      ),
                                    ),
                                  );
                                  _clearSearch();
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          /*
           * Bottom navigation bar UI, which open their corresponding options
           * defined earlier in the class (_onItemTapped function).
           */
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.school), label: "Teach"
              ),
              BottomNavigationBarItem(
                  icon: Icon(Icons.style), label: "Flashcards"
              ),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline), label: "Profile"
              ),
            ],
          ),
        );
      },
    );
  }
}
