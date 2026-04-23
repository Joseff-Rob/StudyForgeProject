import 'package:flutter/material.dart';
import '../main.dart';

/// Class that plays an animation on application load up.
class SplashScreen extends StatefulWidget {

  /// Creates a [SplashScreen].
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Initialises the state of the splash screen.
  ///
  /// Plays the splash screen animation.
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _initializeApp();
  }

  /// Initialises the screen after the splash screen plays for three seconds.
  ///
  /// If logged in -> load main menu.
  /// If not logged in -> load log in/registration screen.
  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 3));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
    );
  }

  /// Disposes controllers when the widget is removed.
  ///
  /// Stops splash screen animation.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Builds the UI of the splash screen.
  @override
  Widget build(BuildContext context) {
    final double logoSize = MediaQuery.of(context).size.width * 0.25;

    return Scaffold(
      backgroundColor: const Color(0xFFDCE6F0),
      body: Center(
        // Loading indicator surrounds the StudyForge logo.
        child: SizedBox(
          width: logoSize,
          height: logoSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: logoSize,
                height: logoSize,
                // Loading indicator.
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                ),
              ),
              // StudyForge logo.
              Image.asset(
                'assets/images/StudyForgeLogo.png',
                width: logoSize * 0.8,
                height: logoSize * 0.8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
