import 'package:flutter/material.dart';
import 'package:learn_to_talk/presentation/pages/onthefly/widgets/simple_tts_widget.dart';

class PronunciationFeedbackWidget extends StatelessWidget {
  final bool pronunciationMatched;
  final String? userAttemptText;
  final String? userAttemptTranslation;
  final String targetLanguageCode;
  final bool loadingReverseTranslation;

  const PronunciationFeedbackWidget({
    super.key,
    required this.pronunciationMatched,
    required this.userAttemptText,
    required this.userAttemptTranslation,
    required this.targetLanguageCode,
    required this.loadingReverseTranslation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: pronunciationMatched
          ? Colors.green.shade100
          : Colors.orange.shade100,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(
              pronunciationMatched
                  ? Icons.check_circle
                  : Icons.record_voice_over,
              size: 24,
              color: pronunciationMatched ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 4),
            Text(
              pronunciationMatched
                  ? 'Great job! Your pronunciation matched.'
                  : 'Let\'s try again. Listen to your pronunciation:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: pronunciationMatched
                    ? Colors.green.shade800
                    : Colors.orange.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            if (!pronunciationMatched && userAttemptText != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'You said: $userAttemptText',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: SimpleTTSWidget(
                  text: userAttemptText!,
                  languageCode: targetLanguageCode,
                ),
              ),
              if (userAttemptTranslation != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'In your language: $userAttemptTranslation',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
              if (loadingReverseTranslation)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
