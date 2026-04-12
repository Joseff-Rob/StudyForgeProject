import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy Policy"),
        backgroundColor: Colors.blueGrey,
      ),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Text(
              '''
Privacy Policy

StudyForge is committed to protecting your privacy.

1. Data Collection
We collect the following data:
- User account information (email, username)
- Flashcard sets and learning content
- Interaction data (e.g. AI conversations)

2. How Your Data Is Used
Your data is used to:
- Provide and improve application features
- Personalise your learning experience
- Store and retrieve your content securely

3. Data Storage
All data is securely stored using Firebase services. We take reasonable measures to protect your data.

4. AI Features Disclaimer
This application uses AI to generate educational content. While we aim for accuracy, AI-generated responses may contain errors. Users should verify important information.

5. User Rights
You have the right to:
- Access your data
- Request deletion of your account/data
- Control what content you share publicly

6. Security
We use authentication and secure database rules to protect your data.

7. Contact
If you have any concerns, please contact:
2325284@swansea.ac.uk

By using this application, you agree to this Privacy Policy.
              ''',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}