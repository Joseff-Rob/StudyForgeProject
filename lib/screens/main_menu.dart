import 'package:flutter/material.dart';
import 'message_page.dart';
import 'settings.dart';
import 'login_register.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  void navigateTo(BuildContext context, String message) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagePage(message: message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFDCE6F0),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          },
        ),
        title: const Text("StudyForge"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                navigateTo(context, "View Profile pressed");
              } else if (value == 'Logout') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Logout"),
                    content: const Text("Are you sure you want to log out?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginRegisterPage()),
                              (route) => false,
                          );
                        },
                        child: const Text("Logout"),
                      ),
                    ],
                  )
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'profile',
                child: Text('View Profile'),
              ),
              PopupMenuItem(
                value: 'Logout',
                child: Text('Log Out')
              )
            ],
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // LOGO
              Image.asset(
                'assets/images/StudyForgeLogo.png',
                height: 160,
              ),
              const SizedBox(height: 32),

              // BUTTONS
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () =>
                    navigateTo(context, "Start a lesson with AI pressed"),
                child: const Text("Start a lesson with AI"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () =>
                    navigateTo(context, "Create Flashcards pressed"),
                child: const Text("Create Flashcards"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () =>
                    navigateTo(context, "View Flashcards pressed"),
                child: const Text("View Flashcards"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
