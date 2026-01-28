import 'package:flutter/material.dart';
import 'screens/login_register.dart';
import 'screens/main_menu.dart';
import 'utils/font_scale.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

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
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Show a loading screen while checking
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasData) {
                // User is logged in
                return const MainMenu();
              }

              // User not logged in
              return const LoginRegisterPage();
            },
          ),

        );
      },
    );
  }
}
