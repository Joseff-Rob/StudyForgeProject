import 'dart:async';

import 'package:StudyForgeProject/screens/create_flashcard_set_screen.dart';
import 'package:StudyForgeProject/screens/user_flashcards_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'profile_page.dart';
import 'teach_to_learn_ai.dart';
import 'settings.dart';
import 'view_flashcards_screen.dart';

class MainMenu extends StatefulWidget {
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

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ---------------- SEARCH ----------------

  void _performDebouncedSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(
      const Duration(milliseconds: 300),
          () => _search(query),
    );
  }

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
      // ---------------- USERS SEARCH ----------------
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

      // ---------------- FLASHCARD SET SEARCH ----------------
      final setSnapshot = await FirebaseFirestore.instance
          .collection('flashcard_sets')
          .where('titleLowercase',
          isGreaterThanOrEqualTo: lowerQuery)
          .where('titleLowercase',
          isLessThanOrEqualTo: lowerQuery + '\uf8ff')
          .limit(5)
          .get();

      // Collect owner IDs
      final ownerIds = setSnapshot.docs
          .map((doc) => doc['ownerId'] as String)
          .toSet()
          .toList();

      // Fetch owner usernames in one batch query
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

      // Build final flashcard set results
      final sets = setSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['title'],
          'cards': doc['flashcardCount'] ?? 0,
          'ownerName':
          ownerUsernames[doc['ownerId']] ?? "Unknown",
        };
      }).toList();

      // ---------------- UPDATE UI ----------------
      setState(() {
        _userResults = users;
        _flashcardSetResults = sets;
      });
    } catch (e) {
      debugPrint("Search error: $e");
    }
  }

  void _clearSearch() {
    setState(() {
      _userResults = [];
      _flashcardSetResults = [];
      _searchController.clear();
      _searchFocusNode.unfocus();
    });
  }

  // ---------------- NAVIGATION ----------------

  void _onItemTapped(int index) {
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
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeachToLearnAi(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text("View old Gemini Lessons"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeachToLearnAi(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
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
            ],
          ),
        ),
      );
    } else if (index == 4) {
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
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => Padding(
          padding: const EdgeInsets.only(bottom: 70),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.question_mark),
                title: const Text("Coming soon"),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    }

    setState(() => _selectedIndex = index);
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFDCE6F0),

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
                  child: const Text(
                    "Menu",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text("View Profile"),
                  onTap: () {
                    Navigator.pop(context);

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

                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text("Settings"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsPage(),
                      ),
                    );
                  },
                ),

                const Spacer(),

                ListTile(
                  leading:
                  const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    "Log Out",
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(context);

                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Log Out"),
                        content: const Text("Are you sure you want to log out?"),
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

      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
                horizontal: 14,
                vertical: 10,
              ),
            ),
          ),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () =>
                  Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),

      body: Stack(
        children: [
          // Main Welcome Content
          StreamBuilder<DocumentSnapshot>(
            stream: currentUser != null
                ? FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .snapshots()
                : null,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              final data =
              snapshot.data!.data() as Map<String, dynamic>;
              final username = data['username'] ?? "User";

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Welcome, $username 👋",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Image.asset(
                      'assets/images/StudyForgeLogo.png',
                      height: 180,
                    ),
                  ],
                ),
              );
            },
          ),

          // ---------------- SEARCH RESULTS ----------------

          if (_userResults.isNotEmpty ||
              _flashcardSetResults.isNotEmpty ||
              _searchController.text.isNotEmpty)
            Positioned(
              top: 10,
              left: 16,
              right: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  constraints:
                  const BoxConstraints(maxHeight: 350),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [

                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            "Users",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),

                        if (_userResults.isEmpty)
                          const Padding(
                            padding:
                            EdgeInsets.symmetric(horizontal: 16),
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
                                      userId: user['id']),
                                ),
                              );
                              _clearSearch();
                            },
                          );
                        }),

                        const Divider(),

                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            "Flashcard Sets",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),

                        if (_flashcardSetResults.isEmpty)
                          const Padding(
                            padding:
                            EdgeInsets.symmetric(horizontal: 16),
                            child: Text("No flashcard sets found"),
                          ),

                        ..._flashcardSetResults.map((set) {
                          return ListTile(
                            leading: const Icon(Icons.style),
                              title: Text(
                                "${set['name']} | "
                                "${set['cards']} cards | by "
                                "${set['ownerName']}",
                              ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ViewFlashcardsScreen(
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

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.school), label: "Teach"),
          BottomNavigationBarItem(
              icon: Icon(Icons.style), label: "Flashcards"),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              label: "Coming"),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: "Coming"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: "Profile"),
        ],
      ),
    );
  }
}