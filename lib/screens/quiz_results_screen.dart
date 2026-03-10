import 'package:flutter/material.dart';

class QuizResultScreen extends StatelessWidget {
  final int score;
  final int total;
  final VoidCallback onRetry;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {

    final percent = (score / total * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz Results"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const Text(
                "Quiz Complete!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),

              /// Score circle
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: percent / 100),
                duration: const Duration(milliseconds: 900),
                builder: (context, double value, _) {

                  return SizedBox(
                    width: 180,
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [

                        /// Background circle
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: CircularProgressIndicator(
                            value: 1,
                            strokeWidth: 12,
                            color: Colors.red.shade200,
                          ),
                        ),

                        /// Green score portion
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 12,
                            color: Colors.green,
                            backgroundColor: Colors.transparent,
                          ),
                        ),

                        /// Score text
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "$percent%",
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text("$score / $total"),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 50),

              /// Try again
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "Try Again",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              /// Return to flashcards
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Return to Flashcards",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}