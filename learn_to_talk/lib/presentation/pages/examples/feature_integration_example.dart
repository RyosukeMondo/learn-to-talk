import 'package:flutter/material.dart';
import 'package:learn_to_talk/core/features/app_features.dart';
import 'package:learn_to_talk/core/features/language_support/language_selector_widget.dart';
import 'package:learn_to_talk/core/features/settings/feature_settings_controller.dart';
import 'package:learn_to_talk/core/features/settings/feature_toggle_widget.dart';
import 'package:learn_to_talk/core/features/stt/speech_recognition_widget.dart';
import 'package:learn_to_talk/core/features/translation/translation_widget.dart';
import 'package:learn_to_talk/core/features/tts/text_to_speech_widget.dart';
import 'package:learn_to_talk/domain/entities/language.dart';
import 'package:provider/provider.dart';

/// Example page that demonstrates how to integrate all modular features
class FeatureIntegrationExample extends StatefulWidget {
  const FeatureIntegrationExample({super.key});

  @override
  State<FeatureIntegrationExample> createState() => _FeatureIntegrationExampleState();
}

class _FeatureIntegrationExampleState extends State<FeatureIntegrationExample> {
  String _recognizedText = '';
  String _textToSpeak = 'Hello, welcome to the app';

  @override
  Widget build(BuildContext context) {
    // Access AppFeatures for language settings
    final appFeatures = AppFeatures.of(context);
    final sourceLanguage = appFeatures.languageService.sourceLanguage;
    final targetLanguage = appFeatures.languageService.targetLanguage;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Features Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFeatureControlsCard(),
            const SizedBox(height: 16),
            _buildLanguageSelectionCard(appFeatures, sourceLanguage, targetLanguage),
            const SizedBox(height: 16),
            
            // Only show features that are enabled
            Consumer<FeatureSettingsController>(
              builder: (context, settings, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (settings.isTranslationEnabled)
                      _buildTranslationCard(sourceLanguage, targetLanguage, settings),
                    
                    if (settings.isSTTEnabled)
                      _buildSpeechRecognitionCard(sourceLanguage),
                    
                    if (settings.isTTSEnabled)
                      _buildTextToSpeechCard(targetLanguage),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the feature toggles card
  Widget _buildFeatureControlsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Feature Controls',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const FeatureToggleWidget(
              featureType: FeatureType.translation,
              icon: Icons.translate,
            ),
            const FeatureToggleWidget(
              featureType: FeatureType.speechToText,
              icon: Icons.mic,
            ),
            const FeatureToggleWidget(
              featureType: FeatureType.textToSpeech,
              icon: Icons.volume_up,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the language selection card
  Widget _buildLanguageSelectionCard(
    AppFeatures appFeatures, 
    Language language, 
    Language targetLanguage
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Language Selection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Source Language:'),
                      const SizedBox(height: 4),
                      LanguageSelectorWidget(
                        availableLanguages: appFeatures.languageService.availableLanguages,
                        selectedLanguageCode: language.languageCode,
                        onLanguageSelected: (code) {
                          appFeatures.languageService.setSourceLanguage(code);
                        },
                        compact: true,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: () {
                    appFeatures.languageService.swapLanguages();
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Target Language:'),
                      const SizedBox(height: 4),
                      LanguageSelectorWidget(
                        availableLanguages: appFeatures.languageService.availableTargetLanguages,
                        selectedLanguageCode: targetLanguage.languageCode,
                        onLanguageSelected: (code) {
                          appFeatures.languageService.setTargetLanguage(code);
                        },
                        compact: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the translation feature card
  Widget _buildTranslationCard(
    Language language, 
    Language targetLanguage, 
    FeatureSettingsController settings
  ) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Translation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TranslationWidget(
                  sourceLanguageCode: language.languageCode,
                  targetLanguageCode: targetLanguage.languageCode,
                  showTTS: settings.isTTSEnabled,
                  onTranslationComplete: (source, translated) {
                    setState(() {
                      // Store if needed for other UI components
                      _textToSpeak = translated;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Builds the speech recognition feature card
  Widget _buildSpeechRecognitionCard(Language language) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Speech Recognition',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SpeechRecognitionWidget(
                  languageCode: language.languageCode,
                  onRecognized: (text) {
                    setState(() {
                      _recognizedText = text;
                    });
                  },
                  compact: true,
                ),
                if (_recognizedText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Recognized: $_recognizedText'),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Builds the text-to-speech feature card
  Widget _buildTextToSpeechCard(Language targetLanguage) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Text to Speech',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Enter text to speak',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _textToSpeak = value;
                });
              },
              controller: TextEditingController(text: _textToSpeak),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(_textToSpeak),
                ),
                TextToSpeechWidget(
                  text: _textToSpeak,
                  languageCode: targetLanguage.languageCode,
                  compact: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
