import 'dart:math';
import 'package:StudyForgeProject/screens/profile_page.dart';
import 'package:StudyForgeProject/screens/quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_flashcard_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import '../utils/tts_settings.dart';

/// Class that handles the UI and logic of a flashcard practise screen.
///
/// Including:
/// - Correct display of terms and definitions with animation to revise
/// with the set cards.
/// - Link to view flashcard set owner.
/// - Set actions for owners (Edit title, set publicity).
/// - Individual Card actions for owners (Edit card term and definition,
/// add flashcard to set and delete card).
/// - Set reporting for all users.
/// - TTS functionality.
/// - Link to complete a quiz of custom length based on flashcards in set.
class ViewFlashcardsScreen extends StatefulWidget {
  final String setId;
  final String setTitle;

  /// Creates a [ViewFlashcardsScreen].
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

  bool _isPublic = false;

  final FlutterTts _tts = FlutterTts();

  /// Initialises the state of a flashcard set screen.
  ///
  /// Loads the animation controller for flashcard flipping.
  /// Checks for flashcard set ownership.
  /// Ensures the displayed card index remains valid when the dataset updates.
  /// Loads the lesson and TTS state for different voice preferences.
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

    _initTTS();
  }

  /// Sets up the initial state of the TTS voice.
  Future<void> _initTTS() async {
    if (!kIsWeb) {
      await loadTtsVoice(); // Load saved voice from SharedPreferences

      final savedVoice = ttsVoiceNotifier.value;

      if (savedVoice != null) {
        try {
          await _tts.setVoice(savedVoice);
        } catch (e) {
          print("Error setting saved voice: $e");
        }
      }
      await _tts.setLanguage("en-GB"); // UK voice
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
    }
  }

  /// Activates the Text-To-Speech, reading what is pressed (text).
  Future<void> _speak(String text) async {
    if (text.isEmpty) return;

    if (kIsWeb) {
      final savedVoice = {
        "name": "Google UK English Female",
        "locale": "en-GB"
      };

      await _tts.setVoice(savedVoice);
      await _tts.speak(text);
    } else {
      await _tts.stop();
      final savedVoice = ttsVoiceNotifier.value;
      if (savedVoice != null) {
        await _tts.setVoice(savedVoice);
      }
      await _tts.speak(text);
    }
  }

  /// Stops Text-To-Speech from talking.
  void _stopTTS() {
    if (kIsWeb) {
      //web.window.speechSynthesis.cancel(); // Not applicable for mobile.
    } else {
      _tts.stop();
    }
  }

  /// Checks for flashcard set ownership.
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

  /// Disposes controllers when the widget is removed.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Popup for editing flashcard set title.
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
                            // Update set title in Firestore.
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

  /// Edit the currently displayed flashcard term and/or definition.
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
                          child: const Text("Cancel"),
                        ),

                        ElevatedButton(
                          onPressed: () async {
                            // Update flashcard in Firestore.
                            await _flashcardService.updateFlashcard(
                              setId: widget.setId,
                              flashcardId: card['id'],
                              question: qController.text.trim(),
                              answer: aController.text.trim(),
                            );

                            Navigator.pop(context);
                          },
                          child: const Text("Save"),
                        ),

                        // Delete button with confirmation.
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            // Show confirmation dialog.
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Delete Flashcard"),
                                content: const Text(
                                  "Are you sure you want to "
                                      "delete this flashcard?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      "Delete",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            // If confirmed, delete the flashcard.
                            if (confirm == true) {
                              await _flashcardService.deleteFlashcard(
                                setId: widget.setId,
                                flashcardId: card['id'],
                              );

                              Navigator.pop(context); // close the edit dialog.
                            }
                          },
                          child: const Text("Delete Card"),
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

  /// Flashcard deletion flashcard popup.
  void _deleteFlashcard(String flashcardId) async {
    if (!_isOwner) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Flashcard"),
        content: const Text("Are you sure you want to delete this flashcard?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    // Delete card.
    await _flashcardService.deleteFlashcard(
      setId: widget.setId,
      flashcardId: flashcardId,
    );
  }

  /// Add new flashcard with term and definition popup.
  void _showAddFlashcardDialog() {
    if (!_isOwner) return;

    final questionController = TextEditingController();
    final answerController = TextEditingController();

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
                width: MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      const Text(
                        "Add New Flashcard",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: questionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: "Question",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: answerController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: "Answer",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 25),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),

                          ElevatedButton(
                            onPressed: () async {
                              if (questionController.text.trim().isEmpty ||
                                  answerController.text.trim().isEmpty) {
                                return;
                              }
                              // Add card.
                              await _flashcardService.addFlashcard(
                                setId: widget.setId,
                                question: questionController.text.trim(),
                                answer: answerController.text.trim(),
                              );

                              Navigator.pop(context);
                            },
                            child: const Text("Add"),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Report set with reason popup.
  void _reportFlashcardSet() {
    final TextEditingController reportController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Report Flashcard Set"),
        content: TextField(
          controller: reportController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: "Reason for reporting",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final reason = reportController.text.trim();
              if (reason.isNotEmpty) {
                // Submits the report to Firebase.
                await FirebaseFirestore.instance.collection('reports').add({
                  'targetType': 'set',
                  'targetId': widget.setId,
                  'targetTitle': widget.setTitle,
                  'reportedBy': FirebaseAuth.instance.currentUser?.uid,
                  'reason': reason,
                  'timestamp': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
              }
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  /// Flip card animation (stops TTS from playing if a card is flipped).
  void _flipCard() {
    if (_controller.isAnimating || _cards.isEmpty) return;

    _stopTTS();

    _controller.forward(from: 0).then((_) {
      if (!mounted) return;

      setState(() {
        _showFront = !_showFront;
      });

      _controller.reset();
    });
  }

  /// Moves to the next card in the set.
  void _nextCard() {
    if (_cards.isEmpty) return;

      setState(() {
        _showFront = true;
        _currentIndex = (_currentIndex + 1) % _cards.length;
      });
    }

        /// Moves to the previous card in the set.
        void _prevCard() {
      if (_cards.isEmpty) return;

      setState(() {
      _showFront = true;
      _currentIndex =
          (_currentIndex - 1 + _cards.length) % _cards.length;
    });
  }

  /// Popup for users to create a quiz with a custom amount of questions
  /// (length of quiz between 4 and all cards).
  void _showQuizOptionsDialog() {
    int selectedAmount = min(4, _cards.length); // default

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Start Quiz"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("How many questions would you like?"),
                  const SizedBox(height: 20),

                  Text(
                    "$selectedAmount questions",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Slider(
                    value: selectedAmount.toDouble(),
                    min: 4,
                    max: _cards.length.toDouble(),
                    divisions: null,
                    label: selectedAmount.toString(),
                    onChanged: (value) {
                      setStateDialog(() {
                        selectedAmount = value.round();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      // Navigates to the quiz screen.
                      MaterialPageRoute(
                        builder: (_) => QuizScreen(
                          setId: widget.setId,
                          setName: widget.setTitle,
                          questionLimit: selectedAmount,
                        ),
                      ),
                    );
                  },
                  child: const Text("Start"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Builds the UI for flashcard revision, modifications and quiz loading.
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

        final data = snapshot.data!.data() as Map<String, dynamic>;
        _isPublic = data['isPublic'] ?? false;
        final liveTitle = data['title'] ?? widget.setTitle;

        // Fallback for empty set (second add card button for owners).
        if (_cards.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.blueGrey,
              title: Text(liveTitle),
              actions: [
                if (_isOwner)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditSetDialog(liveTitle),
                  ),
              ],
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.note_alt_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "This set has no flashcards yet",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),

                  if (_isOwner)
                    const Text(
                      "Add your first flashcard to get started",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 25),
                  if (_isOwner)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Add Flashcard"),
                      onPressed: _showAddFlashcardDialog,
                    ),

                  const SizedBox(height: 12),

                  TextButton.icon(
                    icon: const Icon(Icons.report, color: Colors.red),
                    label: const Text(
                      "Report Set",
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: _reportFlashcardSet,
                  ),
                ],
              ),
            ),
          );
        }

        final card = _cards[_currentIndex];

        return Scaffold(
          backgroundColor: const Color(0xFFDCE6F0),
          appBar: AppBar(
            backgroundColor: Colors.blueGrey,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(liveTitle),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(data['ownerId'])
                      .get(),
                  builder: (context, ownerSnapshot) {
                    if (!ownerSnapshot.hasData) {
                      return const Text(
                        "Loading owner...",
                        style: TextStyle(fontSize: 12),
                      );
                    }

                    final ownerData =
                    ownerSnapshot.data!.data() as Map<String, dynamic>;

                    final username = ownerData['username'] ?? "Unknown";

                    // Navigate to set owners profile.
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfilePage(
                                userId: data['ownerId']
                            ),
                          ),
                        );
                      },
                      child: Text(
                        "by $username (click for more info)",
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.report, color: Colors.red),
                tooltip: "Report Flashcard Set",
                onPressed: _reportFlashcardSet,
              ),
              if (_isOwner)
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: "Add Flashcard",
                  onPressed: _showAddFlashcardDialog,
                ),
              if (_isOwner)
                // Edit set title.
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditSetDialog(liveTitle),
                ),
              if (_isOwner)
                // Edit individual flashcard term/definition.
                IconButton(
                  icon: const Icon(Icons.edit_note),
                  onPressed: () => _showEditFlashcardDialog(card),
                ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Flashcard display
                  GestureDetector(
                    onTap: () {
                      // only flip if not scrolling.
                      FocusScope.of(context).unfocus();
                      _flipCard();
                    },
                    onLongPress: () {
                      if (!_isOwner) return;

                      showModalBottomSheet(
                        context: context,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        builder: (context) => StatefulBuilder(
                          builder: (context, setStateSheet) => SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.edit),
                                  title: const Text("Edit Flashcard"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showEditFlashcardDialog(card);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.add),
                                  title: const Text("Add Flashcard"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showAddFlashcardDialog();
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.delete, color: Colors.red),
                                  title: const Text(
                                    "Delete Flashcard",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _deleteFlashcard(card['id']);
                                  },
                                ),
                                SwitchListTile(
                                  title: const Text("Public"),
                                  value: _isPublic,
                                  onChanged: (val) async {
                                    // update inside the sheet
                                    setStateSheet(() => _isPublic = val);
                                    // update firestore
                                    await _flashcardService.updateFlashcardSetIsPublic(widget.setId, val);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.person),
                                  title: const Text(
                                    "Vier Owner Profile",
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProfilePage(
                                            userId: data['ownerId']
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    // Card flip animation.
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
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: const [
                                BoxShadow(
                                  blurRadius: 10,
                                  color: Colors.black26,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(
                                    angle > pi / 2 ? pi : 0
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SizedBox(
                                      height: double.infinity,
                                      child: Center(
                                        child: SingleChildScrollView(
                                          physics:
                                              const BouncingScrollPhysics(),
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              minHeight: constraints.maxHeight,
                                            ),
                                            child: Center(
                                              child: Padding(
                                                padding: const EdgeInsets
                                                    .symmetric(horizontal: 8),
                                                child: Text(
                                                  _showFront ? card['question']
                                                      : card['answer'],
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Navigation controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: _prevCard,
                      ),
                      Text(
                        "${_currentIndex + 1} of ${_cards.length}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
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

                  // Quiz button
                  if (_cards.length >= 4)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.quiz),
                          label: const Text(
                            "Complete a quiz on this flashcard set",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            _showQuizOptionsDialog();
                          },
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.volume_up),
            onPressed: () {
              final text = _cards.isNotEmpty
                  ? (_showFront ? _cards[_currentIndex]['question']
                  : _cards[_currentIndex]['answer'])
                  : '';
              _speak(text);
            },
          ),
        );
      },
    );
  }
}
