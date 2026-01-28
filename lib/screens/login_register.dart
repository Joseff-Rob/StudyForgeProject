import 'package:flutter/material.dart';
import 'main_menu.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginRegisterPage extends StatefulWidget {
  const LoginRegisterPage({super.key});

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage> {
  bool isLogin = true; // Toggle between Login/Register
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;


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
                onPressed: () async {
                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });

                  try {
                    if (isLogin) {
                      // LOGIN
                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );
                    } else {
                      // REGISTER
                      await FirebaseAuth.instance.createUserWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );
                    }

                    // SUCCESS → navigate to MainMenu
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MainMenu()),
                    );
                  } on FirebaseAuthException catch (e) {
                    setState(() {
                      errorMessage = e.message;
                    });
                  } finally {
                    setState(() {
                      isLoading = false;
                    });
                  }
                },

                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isLogin ? "Login" : "Register"),

              ),
              const SizedBox(height: 16),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],

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
