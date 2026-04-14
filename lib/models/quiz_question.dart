/// Represents a Quiz Question
///
/// This model includes the question, a list of its options
/// and the correct answer.
class QuizQuestion {
  /// Question
  final String question;
  /// Possible options (4)
  final List<String> options;
  /// Denotes the correct answer to the question
  final String correctAnswer;

  /// Creates an instance of [QuizQuestion].
  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });
}
