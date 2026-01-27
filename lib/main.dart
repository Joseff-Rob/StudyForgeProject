import 'package:flutter/material.dart';
import 'screens/login_register.dart';
import 'utils/font_scale.dart';
//import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
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
          home: const LoginRegisterPage(),
        );
      },
    );
  }
}
