import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'profile_page.dart';
import 'teach_to_learn_ai.dart';
import 'flashcard_page.dart';
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

    // Listen for text changes and perform live search
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

  // ------------------------
  // DEBOUNCE SEARCH
  // ------------------------
  void _performDebouncedSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchUsers(query);
    });
  }

  // ------------------------
  // SEARCH USERS
  // ------------------------
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
          .limit(10)
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

  // ------------------------
  // BOTTOM NAVIGATION
  // ------------------------
  void _onItemTapped(int index) {
    if (index == 0) {
      // Teach to Learn Menu
      showModalBottomSheet(
        context: context,
        builder: (_) => Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text("Start New Lesson (Gemini)"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TeachToLearnAi()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("View Old Lessons"),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else if (index == 1) {
      // Flashcards Menu
      showModalBottomSheet(
        context: context,
        builder: (_) => Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text("View Flashcards"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FlashcardsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text("Create New Flashcard Set"),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      // Placeholder buttons
      showModalBottomSheet(
        context: context,
        builder: (_) => const Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            "Coming Soon...",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  // ------------------------
  // BUILD
  // ------------------------
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFDCE6F0),

      // Right-side drawer
      endDrawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.75,
        child: Drawer(
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 24, horizontal: 16),
                  color: Colors.blueGrey,
                  child: const Text(
                    "Menu",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                                ProfilePage(userId: currentUser.uid)),
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
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    );
                  },
                ),
                const Spacer(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Log Out",
                      style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context); // close drawer
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Logout"),
                        content: const Text(
                            "Are you sure you want to log out?"),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text("Cancel")),
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text("Logout")),
                        ],
                      ),
                    );
                    if (confirm ?? false) {
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

      // AppBar with Search
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Column(
          children: [
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: "Search users...",
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, size: 20),
              ),
            ),
            if (_searchResults.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      title: Text(user['username']),
                      onTap: () {
                        // Open read-only profile for searched user
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfilePage(userId: user['uid']),
                          ),
                        );
                        setState(() {
                          _searchResults = [];
                          _searchController.clear();
                        });
                      },
                    );
                  },
                ),
              ),
          ],
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

      body: StreamBuilder<DocumentSnapshot>(
        stream: currentUser != null
            ? FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .snapshots()
            : null,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Welcome!"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final username = data['username'] ?? "User";

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Welcome, $username 👋",
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold),
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

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: "Teach",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.style),
            label: "Flashcards",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: "Coming",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Coming",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Coming",
          ),
        ],
      ),
    );
  }
}
