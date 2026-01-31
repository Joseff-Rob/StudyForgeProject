import 'package:flutter/material.dart';
import '../main.dart'; // contains AuthGate

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 3));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double logoSize = MediaQuery.of(context).size.width * 0.25;

    return Scaffold(
      backgroundColor: const Color(0xFFDCE6F0),
      body: Center(
        child: SizedBox(
          width: logoSize,
          height: logoSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: logoSize,
                height: logoSize,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                ),
              ),

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
