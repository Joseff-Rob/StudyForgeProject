import 'package:flutter/material.dart';

/// Screen to handle UI of quiz results.
///
/// Includes:
/// - Animation of quiz score percentage.
/// - Quiz Score.
/// - Option to try quiz again or return to flashcard set.
class QuizResultScreen extends StatelessWidget {
  final int score;
  final int total;
  final String quizName;
  final VoidCallback onRetry;

  /// Creates a [QuizResultScreen].
  const QuizResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.quizName,
    required this.onRetry,
  });

  /// UI to display a results screen after the user has completed a quiz.
  @override
  Widget build(BuildContext context) {
    // Score percentage calculation.
    final percent = (score / total * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: Text("$quizName Results"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "$quizName Quiz Complete!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),

              // Score circle Animation.
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

                        // Background of circle.
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: CircularProgressIndicator(
                            value: 1,
                            strokeWidth: 12,
                            color: Colors.red.shade200,
                          ),
                        ),

                        // Foreground of circle (percentage correct).
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

                        // Score text.
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

              // Try quiz again button.
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

              // Return to flashcard set button.
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
