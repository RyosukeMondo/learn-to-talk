import 'package:flutter/material.dart';
import 'package:learn_to_talk/presentation/pages/onthefly/widgets/simple_speech_widget.dart';
import 'package:learn_to_talk/presentation/pages/onthefly/widgets/simple_tts_widget.dart';

class PronunciationCheckWidget extends StatelessWidget {
  final String translatedText;
  final String targetLanguageCode;
  final String? userAttemptText;
  final Function(String) onRecognized;
  final VoidCallback onBackPressed;

  const PronunciationCheckWidget({
    super.key,
    required this.translatedText,
    required this.targetLanguageCode,
    required this.userAttemptText,
    required this.onRecognized,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Try to pronounce this:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.blue.shade900),
                  ),
                ),
                SimpleTTSWidget(
                  text: translatedText,
                  languageCode: targetLanguageCode,
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(
              translatedText,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Say it:',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SimpleSpeechWidget(
                  languageCode: targetLanguageCode,
                  onRecognized: onRecognized,
                ),
              ],
            ),
            if (userAttemptText != null && userAttemptText!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'You said: $userAttemptText',
                  style: const TextStyle(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onBackPressed,
              child: const Text('Back to Translation'),
            ),
          ],
        ),
      ),
    );
  }
}
