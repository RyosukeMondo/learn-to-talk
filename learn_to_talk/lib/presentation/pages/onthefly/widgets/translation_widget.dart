import 'package:flutter/material.dart';
import 'package:learn_to_talk/presentation/pages/onthefly/widgets/simple_tts_widget.dart';

class TranslationWidget extends StatelessWidget {
  final String translatedText;
  final String targetLanguageCode;
  final VoidCallback onPracticePressed;

  const TranslationWidget({
    super.key,
    required this.translatedText,
    required this.targetLanguageCode,
    required this.onPracticePressed,
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
            Text('Translation', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(
              translatedText,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SimpleTTSWidget(
                  text: translatedText,
                  languageCode: targetLanguageCode,
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: onPracticePressed,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(100, 32),
                  ),
                  child: const Text('Practice'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
