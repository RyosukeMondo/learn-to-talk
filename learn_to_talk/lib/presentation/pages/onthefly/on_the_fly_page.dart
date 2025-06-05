import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_to_talk/core/features/stt/speech_recognition_widget.dart';
import 'package:learn_to_talk/presentation/blocs/language/language_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/language/language_state.dart';
import 'package:learn_to_talk/presentation/blocs/translation/translation_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/translation/translation_event.dart';
import 'package:audioplayers/audioplayers.dart';

// Import our widget components
import 'package:learn_to_talk/presentation/pages/onthefly/widgets/instructions_widget.dart';
import 'package:learn_to_talk/presentation/pages/onthefly/widgets/source_recognition_widget.dart';
import 'package:learn_to_talk/presentation/pages/onthefly/widgets/translation_widget.dart';
import 'package:learn_to_talk/presentation/pages/onthefly/widgets/pronunciation_check_widget.dart';
import 'package:learn_to_talk/presentation/pages/onthefly/widgets/pronunciation_feedback_widget.dart';

class OnTheFlyPage extends StatefulWidget {
  // Initial language codes that will be updated from LanguageBloc
  final String initialSourceLanguageCode;
  final String initialTargetLanguageCode;
  
  // Text size configuration
  final double textSizeFactor;
  final double? targetTextSize;

  const OnTheFlyPage({
    super.key,
    required this.initialSourceLanguageCode,
    required this.initialTargetLanguageCode,
    this.textSizeFactor = 3.0,
    this.targetTextSize,
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
    
    // Ensure we're using the latest language settings from the LanguageBloc
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = context.read<LanguageBloc>().state;
        if (state.sourceLanguage != null && state.targetLanguage != null) {
          _updateLanguageCodes(state);
        }
      }
    });
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
        
        debugPrint('OnTheFlyPage: Language changed - Source: $_sourceLanguageCode, Target: $_targetLanguageCode');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the LanguageBloc to update language codes when they change
    return BlocListener<LanguageBloc, LanguageState>(
      listenWhen: (previous, current) {
        // Only trigger listener when language codes change
        return (previous.sourceLanguage?.code != current.sourceLanguage?.code) ||
               (previous.targetLanguage?.code != current.targetLanguage?.code);
      },
      listener: (context, state) {
        _updateLanguageCodes(state);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Reset button - compact and positioned at top right
          Align(
            alignment: Alignment.topRight,
            child: TextButton.icon(
              onPressed: _resetState,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(60, 30),
                foregroundColor: Colors.red[800],
              ),
            ),
          ),
          
          // Main content area with reduced padding
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Only show instructions if not checking pronunciation
                    if (!_isCheckingPronunciation) 
                      InstructionsWidget(
                        isCheckingPronunciation: _isCheckingPronunciation,
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // Either show pronunciation check or source recognition based on state
                    _isCheckingPronunciation
                        ? PronunciationCheckWidget(
                            translatedText: _translatedText ?? '',
                            targetLanguageCode: _targetLanguageCode,
                            userAttemptText: _userAttemptText,
                            textSizeFactor: widget.textSizeFactor,
                            fontSize: widget.targetTextSize,
                            onRecognized: (text) {
                              if (!mounted) return;
                              setState(() {
                                _userAttemptText = text;
                                _pronunciationChecked = false;
                              });
                              _checkPronunciation();
                            },
                            onBackPressed: () {
                              setState(() {
                                _isCheckingPronunciation = false;
                                _pronunciationChecked = false;
                              });
                            },
                          )
                        : SourceRecognitionWidget(
                            languageCode: _sourceLanguageCode,
                            sourceText: _sourceText,
                            onRecognized: (text) {
                              if (!mounted) return;
                              setState(() {
                                _sourceText = text;
                              });
                              _translateText(text);
                            },
                          ),
                    
                    const SizedBox(height: 8),
                    
                    // Show translation if available and not checking pronunciation
                    if (_showTranslation &&
                        _translatedText != null &&
                        !_isCheckingPronunciation)
                      TranslationWidget(
                        translatedText: _translatedText!,
                        targetLanguageCode: _targetLanguageCode,
                        textSizeFactor: widget.textSizeFactor,
                        fontSize: widget.targetTextSize,
                        onPracticePressed: () {
                          setState(() {
                            _isCheckingPronunciation = true;
                            _pronunciationChecked = false;
                          });
                        },
                      ),
                    
                    // Show pronunciation feedback if checked
                    if (_pronunciationChecked)
                      PronunciationFeedbackWidget(
                        pronunciationMatched: _pronunciationMatched,
                        userAttemptText: _userAttemptText,
                        userAttemptTranslation: _userAttemptTranslation,
                        targetLanguageCode: _targetLanguageCode,
                        loadingReverseTranslation: _loadingReverseTranslation,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
  }
}
