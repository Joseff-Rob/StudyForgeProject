import 'dart:async';

import 'package:StudyForgeProject/screens/create_flashcard_set_screen.dart';
import 'package:StudyForgeProject/screens/user_flashcards_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'profile_page.dart';
import 'teach_to_learn_ai.dart';
import 'settings.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

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

  void _performDebouncedSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchUsers(query);
    });
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final lowerQuery = query.toLowerCase();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username_lower', isGreaterThanOrEqualTo: lowerQuery)
          .where('username_lower', isLessThanOrEqualTo: lowerQuery + '\uf8ff')
          .limit(3)
          .get();

      final results = snapshot.docs
          .map((doc) => {
        'uid': doc.id,
        'username': doc['username'],
      })
          .toList();

      setState(() => _searchResults = results);
    } catch (e) {
      debugPrint("Search error: $e");
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 70), // height of bottom nav
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
                        builder: (_) =>
                        const TeachToLearnAi(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
    } else if (index == 1) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 70), // height of bottom nav
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
                  title: const Text("Add a New Flashcard Set"),
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
          );
        },
      );
    } else if (index == 4) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 70), // height of bottom nav
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.visibility),
                  title: const Text("View Profile"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfilePage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 70), // height of bottom nav
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.question_mark),
                  title: const Text("Coming soon"),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        },
      );
    }

    setState(() {
      _selectedIndex = index;
    });
  }

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
                          builder: (_) => const SettingsPage()),
                    );
                  },
                ),
                // Place Logout button to bottom of menu.
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
                    await FirebaseAuth.instance.signOut();
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
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: "Search users...",
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),

      body: Stack(
        children: [
          // Main Content
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
                          fontWeight: FontWeight.bold),
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

          if (_searchResults.isNotEmpty)
            Positioned(
              top: 10, left: 16, right: 16,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      color: Colors.white,
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];

                          return Material(
                            color: Colors.white,
                            child: InkWell(
                              hoverColor: Colors.grey.shade200,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProfilePage(userId: user['uid']),
                                  ),
                                );

                                setState(() {
                                  _searchResults = [];
                                  _searchController.clear();
                                  _searchFocusNode.unfocus();
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Text(
                                  user['username'],
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
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