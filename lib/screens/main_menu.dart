import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'teach_to_learn_ai.dart';
import 'flashcard_page.dart';
import 'profile_page.dart';
import 'settings.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  final FocusNode _searchFocusNode = FocusNode();
  int _selectedIndex = 0;

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

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
                  MaterialPageRoute(
                    builder: (_) => const TeachToLearnAi(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("View Old Lessons"),
              onTap: () {
                Navigator.pop(context);
              },
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
                  MaterialPageRoute(
                    builder: (_) => const FlashcardsPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text("Create New Flashcard Set"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    } else {
      // Placeholder Buttons
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFDCE6F0),

      endDrawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.75,
        child: Drawer(
          child: SafeArea(
            child: Column(
              children: [
                const ListTile(
                  title: Text(
                    "Menu",
                    style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text("View Profile"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfilePage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text("Settings"),
                  onTap: () {
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
                  leading: const Icon(Icons.logout),
                  title: const Text("Log Out"),
                  onTap: () async {
                    // Close drawer first
                    Navigator.pop(context);

                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Logout"),
                        content: const Text("Are you sure you want to log out?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Logout"),
                          ),
                        ],
                      ),
                    );

                    if (confirm ?? false) {
                      await FirebaseAuth.instance.signOut();
                      // Optional: navigate to login screen
                    }
                  },
                ),

              ],
            ),
          ),
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: SizedBox(
          height: 36,
          child: TextField(
            focusNode: _searchFocusNode,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: "Search...",
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
            onSubmitted: (value) {
              debugPrint("Search submitted: $value");
            },
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

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .snapshots(),
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
