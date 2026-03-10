import 'package:StudyForgeProject/screens/quiz_results_screen.dart';
import 'package:flutter/material.dart';

import '../models/quiz_question.dart';
import '../services/firestore_flashcard_service.dart';

class QuizScreen extends StatefulWidget {
  final String setId;

  const QuizScreen({super.key, required this.setId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final FlashcardService _flashcardService = FlashcardService();

  List<QuizQuestion> _quiz = [];
  int _currentQuestion = 0;
  int _score = 0;
  bool _loading = true;
  bool _answered = false;
  String? _selectedAnswer;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    final quiz = await _flashcardService.generateQuizFromSet(widget.setId);

    setState(() {
      _quiz = quiz;
      _loading = false;
    });
  }

  void _selectAnswer(String answer) {
    if (_answered) return;

    setState(() {
      _selectedAnswer = answer;
      _answered = true;

      if (answer == _quiz[_currentQuestion].correctAnswer) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestion < _quiz.length - 1) {
      setState(() {
        _currentQuestion++;
        _answered = false;
        _selectedAnswer = null;
      });
    } else {
      _showResults();
    }
  }

  void _showResults() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(
          score: _score,
          total: _quiz.length,
          onRetry: () {
            Navigator.pop(context);

            setState(() {
              _currentQuestion = 0;
              _score = 0;
              _answered = false;
              _selectedAnswer = null;
              _quiz.shuffle();
            });
          },
        ),
      ),
    );
  }

  Color _getButtonColor(String option) {
    if (!_answered) return Colors.blue;

    final correct = _quiz[_currentQuestion].correctAnswer;

    if (option == correct) return Colors.green;

    if (option == _selectedAnswer) return Colors.red;

    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final question = _quiz[_currentQuestion];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Flashcard Quiz"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            LinearProgressIndicator(
              value: (_currentQuestion + 1) / _quiz.length,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),

            /// Progress
            Text(
              "Question ${_currentQuestion + 1} / ${_quiz.length}",
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 20),

            /// Question
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            /// Options
            ...question.options.map((option) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getButtonColor(option),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                    onPressed: () => _selectAnswer(option),
                    child: Text(
                      option,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              );
            }),

            const Spacer(),

            /// Next button
            if (_answered)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextQuestion,
                  child: Text(
                    _currentQuestion == _quiz.length - 1
                        ? "Finish Quiz"
                        : "Next Question",
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}