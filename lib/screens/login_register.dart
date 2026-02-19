import 'package:flutter/material.dart';
import 'main_menu.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../services/firestore_user_service.dart';

class LoginRegisterPage extends StatefulWidget {
  const LoginRegisterPage({super.key});

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage> {
  bool isLogin = true;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  final FirestoreUserService userService = FirestoreUserService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCE6F0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/images/StudyForgeLogo.png',
                height: 150,
              ),
              const SizedBox(height: 16),
              const Text(
                "Where knowledge is forged.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                isLogin ? "Login" : "Register",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Username (only for registration)
              if (!isLogin) ...[
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: "Username",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Email
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Password
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
                      final username = usernameController.text.trim();

                      if (username.isEmpty) {
                        setState(() {
                          errorMessage = "Username cannot be empty";
                        });
                        return;
                      }

                      // Check username uniqueness
                      if (await userService.isUsernameTaken(username)) {
                        setState(() {
                          errorMessage = "Username already taken";
                        });
                        return;
                      }

                      // Create user
                      UserCredential userCredential = await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );

                      final user = userCredential.user;
                      if (user == null || user.email == null) {
                        setState(() {
                          errorMessage = "Failed to create user";
                        });
                        return;
                      }

                      // Update displayName in FirebaseAuth
                      await user.updateDisplayName(username);

                      // Save in Firestore with lowercase username for search
                      AppUser newUser = AppUser(
                        uid: user.uid,
                        email: user.email!,
                        username: username,
                        usernameLower: username.toLowerCase(),
                      );
                      await userService.createUser(newUser);
                    }

                  } on FirebaseAuthException catch (e) {
                    setState(() {
                      errorMessage = e.message;
                    });
                  } catch (e, stack) {
                    print("Error: $e");
                    print(stack);
                    setState(() {
                      errorMessage = e.toString();
                    });
                  } finally {
                    setState(() {
                      isLoading = false;
                    });
                  }
                },
                child: isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
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
