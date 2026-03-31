import 'dart:math';

import 'package:StudyForgeProject/screens/quiz_results_screen.dart';
import 'package:flutter/material.dart';

import '../models/quiz_question.dart';
import '../services/firestore_flashcard_service.dart';

class QuizScreen extends StatefulWidget {
  final String setId;
  final int? questionLimit;

  const QuizScreen({super.key, required this.setId, this.questionLimit});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with TickerProviderStateMixin {
  final FlashcardService _flashcardService = FlashcardService();
  Map<String, AnimationController> _optionControllers = {};
  late AnimationController _shakeController;

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

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    for (var c in _optionControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    final quiz = await _flashcardService.generateQuizFromSet(
        widget.setId,
        questionLimit: widget.questionLimit
    );

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

      final correct = _quiz[_currentQuestion].correctAnswer;
      if (answer == correct) {
        _score++;

        // Pulse animation for correct answer
        _optionControllers[answer]?.forward(from: 0);
      } else {
        // Shake animation for wrong answer
        _shakeController.forward(from: 0);
        // Also pulse correct answer
        _optionControllers[correct]?.forward(from: 0);
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 70),
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
              // Create controller if not exist
              _optionControllers.putIfAbsent(option, () => AnimationController(
                vsync: this,
                duration: const Duration(milliseconds: 300),
                lowerBound: 0.0,
                upperBound: 0.1,
              ));

              final scale = Tween<double>(begin: 1.0, end: 1.1)
                  .animate(CurvedAnimation(
                parent: _optionControllers[option]!,
                curve: Curves.easeOut,
              ));

              return AnimatedBuilder(
                animation: Listenable.merge([_shakeController, scale]),
                builder: (context, child) {
                  double offset = 0;
                  if (_selectedAnswer == option && _selectedAnswer != _quiz[_currentQuestion].correctAnswer) {
                    // shake animation
                    offset = 8 * sin(_shakeController.value * pi * 4);
                  }

                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: Transform.scale(
                      scale: (_selectedAnswer == option && _selectedAnswer == _quiz[_currentQuestion].correctAnswer)
                          ? scale.value
                          : 1.0,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getButtonColor(option),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _selectAnswer(option),
                      child: Text(
                        option,
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

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
      ),
    );
  }
}