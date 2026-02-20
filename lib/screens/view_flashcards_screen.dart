import 'dart:math';
import 'package:flutter/material.dart';
import '../services/firestore_flashcard_service.dart';

class ViewFlashcardsScreen extends StatefulWidget {
  final String setId;
  final String setTitle;

  const ViewFlashcardsScreen({
    super.key,
    required this.setId,
    required this.setTitle,
  });

  @override
  State<ViewFlashcardsScreen> createState() => _ViewFlashcardsScreenState();
}

class _ViewFlashcardsScreenState extends State<ViewFlashcardsScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  bool _showFront = true;
  int _currentIndex = 0;

  final _flashcardService = FlashcardService();
  List<Map<String, dynamic>> _cards = [];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _flashcardService.streamFlashcards(widget.setId).listen((cards) {
      setState(() {
        _cards = cards;
        if (_currentIndex >= _cards.length) _currentIndex = 0;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_controller.isAnimating || _cards.isEmpty) return;

    _controller.forward(from: 0).then((_) {
      setState(() {
        _showFront = !_showFront;
      });
      _controller.reset();
    });
  }

  void _nextCard() {
    if (_cards.isEmpty) return;

    setState(() {
      _showFront = true;
      _currentIndex = (_currentIndex + 1) % _cards.length;
    });
  }

  void _prevCard() {
    if (_cards.isEmpty) return;

    setState(() {
      _showFront = true;
      _currentIndex = (_currentIndex - 1 + _cards.length) % _cards.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.setTitle)),
        body: const Center(child: Text("No flashcards in this set.")),
      );
    }

    final card = _cards[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFDCE6F0),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Text(widget.setTitle),
      ),
      body: Column(
        children: [
          const SizedBox(height: 50),

          GestureDetector(
            onTap: _flipCard,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final angle = _controller.value * pi;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(angle),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: 240,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 10,
                          color: Colors.black26,
                          offset: Offset(0, 5),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(angle > pi / 2 ? pi : 0),
                      child: Text(
                        _showFront ? card['question'] : card['answer'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 40),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: _prevCard,
              ),
              const SizedBox(width: 10),
              Text(
                "${_currentIndex + 1} of ${_cards.length}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: _nextCard,
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Text(
            "Tap the card to flip",
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}