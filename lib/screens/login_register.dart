import 'package:flutter/material.dart';
import 'main_menu.dart';

class LoginRegisterPage extends StatefulWidget {
  const LoginRegisterPage({super.key});

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage> {
  bool isLogin = true; // Toggle between Login/Register
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFDCE6F0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Image.asset(
                'assets/images/StudyForgeLogo.png',
                height: 150,
              ),
              const SizedBox(height: 16),

              Text(
                "Where smart study begins.",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                isLogin ? "Login" : "Register",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Email field
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  // For now, just navigate to main menu
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MainMenu()),
                  );
                },
                child: Text(isLogin ? "Login" : "Register"),
              ),
              const SizedBox(height: 16),

              // Toggle Login/Register
              TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin;
                  });
                },
                child: Text(
                  isLogin
                      ? "Don't have an account? Register"
                      : "Already have an account? Login",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
