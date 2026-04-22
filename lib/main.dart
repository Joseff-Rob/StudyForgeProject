import 'package:flutter/material.dart';
import 'utils/font_scale.dart';
import 'utils/tts_settings.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/main_menu.dart';
import 'screens/login_register.dart';

/// Initial build of the application.
///
/// Starting screen depends if user is logged in or not.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Loads "shared_preferences" (font scaling & TTS voice).
  await loadFontScale();
  await loadTtsVoice();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Navigates to the initial screen (SPLASH SCREEN)
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: fontScaleNotifier,
      builder: (context, fontScale, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'StudyForge',
          theme: ThemeData(
            fontFamily: 'NotoSans',
          ),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaleFactor: fontScale,
              ),
              child: child!,
            );
          },

          // Start with splash
          home: const SplashScreen(),
        );
      },
    );
  }
}

/// Central Authentication Router
///
/// Navigates to:
/// - Login/Register page if logged out.
/// - Main Menu if logged in.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Logged in -> Navigate to Main Menu after splash screen animation.
        if (snapshot.hasData) {
          return const MainMenu();
        }

        /*
         * Logged out -> Navigate to Login/Register
         * page after splash screen animation.
         */
        return const LoginRegisterPage();
      },
    );
  }
}
