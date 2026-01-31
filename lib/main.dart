import 'package:flutter/material.dart';
import 'utils/font_scale.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/main_menu.dart';
import 'screens/login_register.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: fontScaleNotifier,
      builder: (context, fontScale, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'StudyForge',
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaleFactor: fontScale,
              ),
              child: child!,
            );
          },

          // 👇 Start with splash
          home: const SplashScreen(),
        );
      },
    );
  }
}

/// 🔥 CENTRAL AUTH ROUTER
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Logged in
        if (snapshot.hasData) {
          return const MainMenu();
        }

        // Logged out
        return const LoginRegisterPage();
      },
    );
  }
}
