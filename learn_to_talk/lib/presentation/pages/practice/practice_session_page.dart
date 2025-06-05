import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_to_talk/domain/entities/practice.dart';
import 'package:learn_to_talk/presentation/blocs/practice/practice_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/practice/practice_event.dart';
import 'package:learn_to_talk/presentation/blocs/practice/practice_state.dart';
import 'package:learn_to_talk/presentation/blocs/speech/speech_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/speech/speech_event.dart';
import 'package:learn_to_talk/core/features/stt/speech_recognition_widget.dart';
import 'package:learn_to_talk/core/features/tts/text_to_speech_widget.dart';
import 'package:lottie/lottie.dart';

class PracticeSessionPage extends StatefulWidget {
  final int sessionId;
  final List<Practice> practices;
  final String sourceLanguageCode;
  final String targetLanguageCode;

  const PracticeSessionPage({
    super.key,
    required this.sessionId,
    required this.practices,
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
  });

  @override
  State<PracticeSessionPage> createState() => _PracticeSessionPageState();
}

class _PracticeSessionPageState extends State<PracticeSessionPage> {
  int _currentIndex = 0;
  String _recognizedText = '';
  bool _isEvaluating = false;

  @override
  void initState() {
    super.initState();
    // Initialize speech recognition
    context.read<SpeechBloc>().add(const InitializeSpeech());
  }

  Practice get _currentPractice => widget.practices[_currentIndex];

  void _onRecognized(String text) {
    setState(() {
      _recognizedText = text;
    });
  }

  void _evaluatePractice() {
    if (_recognizedText.isEmpty) return;

    setState(() {
      _isEvaluating = true;
    });

    context.read<PracticeBloc>().add(EvaluatePracticeAttempt(
      practiceId: _currentPractice.id,
      spokenText: _recognizedText,
      expectedText: _currentPractice.translatedText,
      sessionId: widget.sessionId,
    ));
  }

  void _moveToNextPractice() {
    if (_currentIndex < widget.practices.length - 1) {
      setState(() {
        _currentIndex++;
        _recognizedText = '';
        _isEvaluating = false;
      });
    } else {
      // End of session
      _showSessionCompleteDialog();
    }
  }

  void _showSessionCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Complete'),
        content: const Text('You have completed all practice items in this session!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to practice list
            },
            child: const Text('Return to Practice List'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Session'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitConfirmationDialog(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isEvaluating ? null : _evaluatePractice,
            icon: const Icon(Icons.check),
            label: const Text('Check'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
      body: BlocConsumer<PracticeBloc, PracticeState>(
        listenWhen: (previous, current) =>
            previous.status != current.status &&
            (current.status == PracticeStatus.success ||
                current.status == PracticeStatus.failure),
        listener: (context, state) {
          if (state.status == PracticeStatus.success ||
              state.status == PracticeStatus.failure) {
            _showFeedbackBottomSheet(context, state);
          }
        },
        builder: (context, state) {
          if (state.status == PracticeStatus.evaluating) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProgressIndicator(),
                  const SizedBox(height: 24),
                  _buildPracticeCard(context),
                  const SizedBox(height: 24),
                  _buildSpeechRecognition(context),
                  // Added bottom padding to ensure content isn't cut off
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: (_currentIndex + 1) / widget.practices.length,
          backgroundColor: Colors.grey[300],
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        Text(
          'Practice ${_currentIndex + 1} of ${widget.practices.length}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPracticeCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.record_voice_over, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Say this in ${_getLanguageName(widget.targetLanguageCode)}:',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _currentPractice.sourceText,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextToSpeechWidget(
              text: _currentPractice.sourceText,
              languageCode: widget.sourceLanguageCode,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.translate, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Translation (${_getLanguageName(widget.targetLanguageCode)}):',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _currentPractice.translatedText,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextToSpeechWidget(
              text: _currentPractice.translatedText,
              languageCode: widget.targetLanguageCode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeechRecognition(BuildContext context) {
    return SpeechRecognitionWidget(
      languageCode: widget.targetLanguageCode,
      onRecognized: _onRecognized,
    );
  }

  void _showFeedbackBottomSheet(BuildContext context, PracticeState state) {
    final isSuccess = state.status == PracticeStatus.success;
    final similarityScore = state.similarityScore ?? 0.0;
    final feedbackDetails = state.feedbackDetails;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 120,
              child: isSuccess
                  ? Lottie.asset(
                      'assets/animations/success_animation.json',
                      repeat: false,
                    )
                  : Lottie.asset(
                      'assets/animations/failure_animation.json',
                      repeat: false,
                    ),
            ),
            Text(
              isSuccess ? 'Great job!' : 'Keep practicing!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSuccess ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your pronunciation score: ${(similarityScore * 100).toInt()}%',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            if (feedbackDetails != null) _buildFeedbackDetails(feedbackDetails),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet
                  _moveToNextPractice();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Next Practice',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackDetails(Map<String, dynamic> feedbackDetails) {
    final missingWords = feedbackDetails['missingWords'] as List<dynamic>;
    final extraWords = feedbackDetails['extraWords'] as List<dynamic>;
    final correctWords = feedbackDetails['correctWords'] as List<dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (correctWords.isNotEmpty) ...[
          const Text(
            'Correct words:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: correctWords
                .map((word) => Chip(
                      label: Text(word),
                      backgroundColor: Colors.green[100],
                    ))
                .toList()
                .cast<Widget>(),
          ),
          const SizedBox(height: 8),
        ],
        if (missingWords.isNotEmpty) ...[
          const Text(
            'Missing words:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: missingWords
                .map((word) => Chip(
                      label: Text(word),
                      backgroundColor: Colors.red[100],
                    ))
                .toList()
                .cast<Widget>(),
          ),
          const SizedBox(height: 8),
        ],
        if (extraWords.isNotEmpty) ...[
          const Text(
            'Extra words:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: extraWords
                .map((word) => Chip(
                      label: Text(word),
                      backgroundColor: Colors.orange[100],
                    ))
                .toList()
                .cast<Widget>(),
          ),
        ],
      ],
    );
  }

  void _showExitConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Session?'),
        content: const Text('Are you sure you want to exit this practice session? Your progress will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to practice list
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Exit Session'),
          ),
        ],
      ),
    );
  }

  // This is a placeholder. In a real app, we would get this from a language service
  String _getLanguageName(String languageCode) {
    final Map<String, String> languageNames = {
      'en': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'ja': 'Japanese',
      'ko': 'Korean',
      'zh': 'Chinese',
      'ru': 'Russian',
    };
    
    // Handle language codes with region (e.g., 'en-US')
    final baseCode = languageCode.split('-')[0].toLowerCase();
    return languageNames[baseCode] ?? languageCode;
  }
}
