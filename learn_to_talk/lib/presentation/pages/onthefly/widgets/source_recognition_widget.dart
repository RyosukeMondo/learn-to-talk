import 'package:flutter/material.dart';
import 'package:learn_to_talk/presentation/pages/onthefly/widgets/simple_speech_widget.dart';

class SourceRecognitionWidget extends StatelessWidget {
  final String languageCode;
  final String? sourceText;
  final Function(String) onRecognized;

  const SourceRecognitionWidget({
    super.key,
    required this.languageCode,
    required this.sourceText,
    required this.onRecognized,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Speak in your language',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SimpleSpeechWidget(
                  languageCode: languageCode,
                  onRecognized: onRecognized,
                ),
              ],
            ),
            if (sourceText != null && sourceText!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  sourceText!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
