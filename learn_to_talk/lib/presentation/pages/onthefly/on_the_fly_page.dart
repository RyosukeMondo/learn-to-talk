import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_to_talk/core/features/stt/speech_recognition_widget.dart';
import 'package:learn_to_talk/core/features/tts/text_to_speech_widget.dart';
import 'package:learn_to_talk/presentation/blocs/language/language_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/language/language_state.dart';
import 'package:learn_to_talk/presentation/blocs/translation/translation_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/translation/translation_event.dart';
import 'package:audioplayers/audioplayers.dart';

class OnTheFlyPage extends StatefulWidget {
  // Initial language codes that will be updated from LanguageBloc
  final String initialSourceLanguageCode;
  final String initialTargetLanguageCode;

  const OnTheFlyPage({
    super.key,
    required this.initialSourceLanguageCode,
    required this.initialTargetLanguageCode,
  });

  @override
  State<OnTheFlyPage> createState() => _OnTheFlyPageState();
}

class _OnTheFlyPageState extends State<OnTheFlyPage> {
  String? _sourceText;
  String? _translatedText;
  String? _userAttemptText;
  String? _userAttemptTranslation;
  bool _showTranslation = false;
  bool _isCheckingPronunciation = false;
  bool _pronunciationMatched = false;
  bool _pronunciationChecked = false;
  bool _loadingReverseTranslation = false;
  final _audioPlayer = AudioPlayer();
  StreamSubscription? _translationSubscription;

  // Current language codes that will be updated when language changes
  late String _sourceLanguageCode;
  late String _targetLanguageCode;

  // Reset all state to practice a new sentence
  void _resetState() {
    setState(() {
      _sourceText = null;
      _translatedText = null;
      _userAttemptText = null;
      _userAttemptTranslation = null;
      _showTranslation = false;
      _isCheckingPronunciation = false;
      _pronunciationMatched = false;
      _pronunciationChecked = false;
      _loadingReverseTranslation = false;
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialize with provided language codes
    _sourceLanguageCode = widget.initialSourceLanguageCode;
    _targetLanguageCode = widget.initialTargetLanguageCode;
    _setupTranslationListener();
  }

  void _setupTranslationListener() {
    final translationBloc = context.read<TranslationBloc>();
    _translationSubscription = translationBloc.stream.listen(
      (state) {
        // Always check if widget is still mounted before updating state
        if (!mounted) return;

        if (state.translatedText != null) {
          try {
            // Handle forward translation (source language -> target language)
            if (state.sourceLanguageCode == _sourceLanguageCode &&
                state.targetLanguageCode == _targetLanguageCode) {
              setState(() {
                _translatedText = state.translatedText;
                _showTranslation = true;
              });
            }
            // Handle reverse translation (target language -> source language)
            else if (state.sourceLanguageCode == _targetLanguageCode &&
                state.targetLanguageCode == _sourceLanguageCode &&
                state.sourceText == _userAttemptText) {
              setState(() {
                _userAttemptTranslation = state.translatedText;
                _loadingReverseTranslation = false;
              });
            }
          } catch (e) {
            // Safely handle any errors that might occur during setState
            debugPrint('Error updating state in translation listener: $e');
          }
        }
      },
      onError: (error) {
        // Handle stream errors properly
        debugPrint('Error in translation stream: $error');
      },
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _translationSubscription?.cancel();
    super.dispose();
  }

  // Method to update language codes when they change in the LanguageBloc
  void _updateLanguageCodes(LanguageState state) {
    if (state.sourceLanguage != null && state.targetLanguage != null) {
      // Only update if the languages have changed to avoid unnecessary state changes
      if (_sourceLanguageCode != state.sourceLanguage!.code ||
          _targetLanguageCode != state.targetLanguage!.code) {
        setState(() {
          _sourceLanguageCode = state.sourceLanguage!.code;
          _targetLanguageCode = state.targetLanguage!.code;
          // Reset state since we have new languages
          _resetState();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the LanguageBloc to update language codes when they change
    return BlocListener<LanguageBloc, LanguageState>(
      listener: (context, state) {
        _updateLanguageCodes(state);
      },
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ElevatedButton.icon(
                    onPressed: _resetState,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[100],
                      foregroundColor: Colors.red[800],
                    ),
                  ),
                ),
              ),
              if (!_isCheckingPronunciation) _buildInstructions(),
              const SizedBox(height: 24),
              _isCheckingPronunciation
                  ? _buildPronunciationCheck()
                  : _buildSourceRecognition(),
              const SizedBox(height: 24),
              if (_showTranslation &&
                  _translatedText != null &&
                  !_isCheckingPronunciation)
                _buildTranslation(),
              if (_pronunciationChecked) _buildPronunciationFeedback(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'On-the-Fly Practice',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _isCheckingPronunciation
                  ? 'Listen to the translation and try to mimic it. Press the microphone button and speak.'
                  : 'Press the microphone button and speak in your mother language. The app will translate it for you to practice.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceRecognition() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Speak in your language',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SpeechRecognitionWidget(
              languageCode: _sourceLanguageCode,
              onRecognized: (text) {
                if (!mounted) return; // Guard against setState after dispose
                setState(() {
                  _sourceText = text;
                });
                // Move the translation out of setState to avoid nested async calls
                _translateText(text);
              },
            ),
            if (_sourceText != null && _sourceText!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _sourceText!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslation() {
    return Card(
      elevation: 3,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Translation', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Text(
              _translatedText!,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextToSpeechWidget(
                    text: _translatedText!,
                    languageCode: _targetLanguageCode,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isCheckingPronunciation = true;
                      _pronunciationChecked = false;
                    });
                  },
                  child: const Text('Practice Speaking'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPronunciationCheck() {
    return Card(
      elevation: 3,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Try to pronounce this in $_targetLanguageCode',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.blue.shade900),
            ),
            const SizedBox(height: 16),
            Text(
              _translatedText ?? '',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextToSpeechWidget(
              text: _translatedText ?? '',
              languageCode: _targetLanguageCode,
            ),
            const SizedBox(height: 24),
            Text(
              'Now try to say it:',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            SpeechRecognitionWidget(
              languageCode: _targetLanguageCode,
              onRecognized: (text) {
                if (!mounted) return;
                setState(() {
                  _userAttemptText = text;
                  _pronunciationChecked = false;
                });
                _checkPronunciation();
              },
            ),
            if (_userAttemptText != null && _userAttemptText!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  'You said: $_userAttemptText',
                  style: const TextStyle(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isCheckingPronunciation = false;
                  _pronunciationChecked = false;
                });
              },
              child: const Text('Back to Translation'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPronunciationFeedback() {
    return Card(
      elevation: 3,
      color:
          _pronunciationMatched
              ? Colors.green.shade100
              : Colors.orange.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              _pronunciationMatched
                  ? Icons.check_circle
                  : Icons.record_voice_over,
              size: 48,
              color: _pronunciationMatched ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              _pronunciationMatched
                  ? 'Great job! Your pronunciation matched.'
                  : 'Let\'s try again. Listen to your pronunciation:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color:
                    _pronunciationMatched
                        ? Colors.green.shade800
                        : Colors.orange.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            if (!_pronunciationMatched && _userAttemptText != null) ...[
              // What you said
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  'You said: $_userAttemptText',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),

              // Listen to your pronunciation
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextToSpeechWidget(
                  text: _userAttemptText!,
                  languageCode: _targetLanguageCode,
                ),
              ),

              // Translation back to source language
              if (_userAttemptTranslation != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'In your language: $_userAttemptTranslation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],

              if (_loadingReverseTranslation)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _translateText(String text) {
    context.read<TranslationBloc>().add(
      TranslateText(
        text: text,
        sourceLanguageCode: _sourceLanguageCode,
        targetLanguageCode: _targetLanguageCode,
      ),
    );
  }

  void _checkPronunciation() {
    if (_userAttemptText != null && _translatedText != null) {
      if (!mounted) return; // Guard against setState after dispose

      // Simple string comparison for now - could be enhanced with fuzzy matching
      // or more sophisticated pronunciation comparison algorithms
      final normalizedTranslation = _translatedText!.toLowerCase().trim();
      final normalizedUserAttempt = _userAttemptText!.toLowerCase().trim();
      final matched = normalizedUserAttempt == normalizedTranslation;

      setState(() {
        _pronunciationMatched = matched;
        _pronunciationChecked = true;
      });

      // Play sound feedback based on match result
      _playFeedbackSound(matched);

      // If pronunciation doesn't match, translate user's attempt back to source language
      if (!matched && _userAttemptText!.isNotEmpty) {
        _translateUserAttemptToSource();
      }
    }
  }

  Future<void> _playFeedbackSound(bool matched) async {
    try {
      if (matched) {
        // Play success sound
        await _audioPlayer.play(AssetSource('sounds/success.mp3'));
      } else {
        // Play try again sound
        await _audioPlayer.play(AssetSource('sounds/try_again.mp3'));
      }
    } catch (e) {
      // Silently handle errors with sound playback
      debugPrint('Error playing sound: $e');

      // Check if widget is still mounted before using BuildContext
      if (mounted) {
        // Give visual feedback in case sound doesn't work
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(matched ? 'Great job!' : 'Try again')),
        );
      }
    }
  }

  // Translate user's attempt back to their source language
  void _translateUserAttemptToSource() {
    if (_userAttemptText == null || _userAttemptText!.isEmpty) return;

    // Guard against setState after dispose
    if (!mounted) return;

    setState(() {
      _loadingReverseTranslation = true;
      _userAttemptTranslation = null;
    });

    // Since we checked mounted above, context should be safe to use
    final translationBloc = context.read<TranslationBloc>();
    translationBloc.add(
      TranslateText(
        text: _userAttemptText!,
        sourceLanguageCode: _targetLanguageCode,
        targetLanguageCode: _sourceLanguageCode,
      ),
    );
    // No need to create a new listener here - using the one in _setupTranslationListener
  }
}
