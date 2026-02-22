import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  State<ViewFlashcardsScreen> createState() =>
      _ViewFlashcardsScreenState();
}

class _ViewFlashcardsScreenState extends State<ViewFlashcardsScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  bool _showFront = true;
  int _currentIndex = 0;

  final _flashcardService = FlashcardService();
  List<Map<String, dynamic>> _cards = [];

  bool _isOwner = false;

  // -------------------------

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _checkOwnership();

    _flashcardService.streamFlashcards(widget.setId).listen((cards) {
      if (!mounted) return;

      setState(() {
        _cards = cards;
        if (_currentIndex >= _cards.length) _currentIndex = 0;
      });
    });
  }

  Future<void> _checkOwnership() async {
    final user = FirebaseAuth.instance.currentUser;

    final doc = await FirebaseFirestore.instance
        .collection('flashcard_sets')
        .doc(widget.setId)
        .get();

    if (!mounted) return;

    setState(() {
      _isOwner = user != null && user.uid == doc['ownerId'];
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // -------------------------
  // EDIT SET TITLE
  // -------------------------

  void _showEditSetDialog(String currentTitle) {
    if (!_isOwner) return;

    final controller = TextEditingController(text: currentTitle);

    showDialog(
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
          ),
          child: Center(
            child: Material(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Edit Set Title",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),

                    const SizedBox(height: 20),

                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: "Title",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel")),

                        ElevatedButton(
                          onPressed: () async {
                            await _flashcardService.updateFlashcardSetTitle(
                              widget.setId,
                              controller.text.trim(),
                            );

                            Navigator.pop(context);
                          },
                          child: const Text("Save"),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // -------------------------
  // EDIT FLASHCARD
  // -------------------------

  void _showEditFlashcardDialog(Map<String, dynamic> card) {
    if (!_isOwner) return;

    final qController =
    TextEditingController(text: card['question']);
    final aController =
    TextEditingController(text: card['answer']);

    showDialog(
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20),
          child: Center(
            child: Material(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Edit Flashcard",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),

                    const SizedBox(height: 15),

                    TextField(
                      controller: qController,
                      maxLines: 2,
                      decoration:
                      const InputDecoration(labelText: "Question"),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: aController,
                      maxLines: 3,
                      decoration:
                      const InputDecoration(labelText: "Answer"),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel")),

                        ElevatedButton(
                          onPressed: () async {
                            await _flashcardService.updateFlashcard(
                              setId: widget.setId,
                              flashcardId: card['id'],
                              question: qController.text.trim(),
                              answer: aController.text.trim(),
                            );

                            Navigator.pop(context);
                          },
                          child: const Text("Save"),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // -------------------------
  // CARD CONTROLS
  // -------------------------

  void _flipCard() {
    if (_controller.isAnimating || _cards.isEmpty) return;

    _controller.forward(from: 0).then((_) {
      if (!mounted) return;

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
      _currentIndex =
          (_currentIndex - 1 + _cards.length) % _cards.length;
    });
  }

  // -------------------------

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('flashcard_sets')
          .doc(widget.setId)
          .snapshots(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final data =
        snapshot.data!.data() as Map<String, dynamic>;

        final liveTitle = data['title'] ?? widget.setTitle;

        if (_cards.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: Text(liveTitle),
              backgroundColor: Colors.blueGrey,
              actions: [
                if (_isOwner)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () =>
                        _showEditSetDialog(liveTitle),
                  ),
              ],
            ),
            body: const Center(
              child: Text("No flashcards in this set."),
            ),
          );
        }

        final card = _cards[_currentIndex];

        return Scaffold(
          backgroundColor: const Color(0xFFDCE6F0),
          appBar: AppBar(
            backgroundColor: Colors.blueGrey,
            title: Text(liveTitle),
            actions: [
              if (_isOwner)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      _showEditSetDialog(liveTitle),
                ),

              if (_isOwner)
                IconButton(
                  icon: const Icon(Icons.edit_note),
                  onPressed: () =>
                      _showEditFlashcardDialog(card),
                ),
            ],
          ),

          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [

                  const SizedBox(height: 40),

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
                            width:
                            MediaQuery.of(context).size.width *
                                0.85,
                            height: 240,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                              BorderRadius.circular(22),
                              boxShadow: const [
                                BoxShadow(
                                    blurRadius: 10,
                                    color: Colors.black26,
                                    offset: Offset(0, 5))
                              ],
                            ),
                            child: Center(
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(
                                    angle > pi / 2 ? pi : 0),
                                child: Text(
                                  _showFront
                                      ? card['question']
                                      : card['answer'],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600),
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

                      Text(
                        "${_currentIndex + 1} of ${_cards.length}",
                        style: const TextStyle(
                            fontWeight: FontWeight.w600),
                      ),

                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed: _nextCard,
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  const Text("Tap card to flip"),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}