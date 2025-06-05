import 'package:flutter/material.dart';
import 'package:learn_to_talk/domain/entities/practice.dart';
import 'package:learn_to_talk/core/features/tts/text_to_speech_widget.dart';

class PracticeItemWidget extends StatelessWidget {
  final Practice practice;
  final Function(Practice) onPracticeSelected;
  final bool isSelected;

  const PracticeItemWidget({
    super.key,
    required this.practice,
    required this.onPracticeSelected,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: isSelected 
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2.0)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => onPracticeSelected(practice),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          practice.sourceText,
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          practice.translatedText,
                          style: const TextStyle(
                            fontSize: 16.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      TextToSpeechWidget(
                        text: practice.sourceText,
                        languageCode: practice.sourceLanguageCode,
                        compact: true,
                      ),
                      const SizedBox(height: 8.0),
                      TextToSpeechWidget(
                        text: practice.translatedText,
                        languageCode: practice.targetLanguageCode,
                        compact: true,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              _buildProgressIndicator(context),
              const SizedBox(height: 8.0),
              _buildStats(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    final successRate = practice.attemptCount > 0 
        ? (practice.successCount / practice.attemptCount) 
        : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: successRate,
                backgroundColor: Colors.grey[300],
                color: _getProgressColor(successRate),
                minHeight: 8.0,
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
            const SizedBox(width: 8.0),
            Text(
              '${(successRate * 100).toInt()}%',
              style: TextStyle(
                color: _getProgressColor(successRate),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Attempts: ${practice.attemptCount}',
          style: textTheme.bodySmall,
        ),
        Text(
          'Successes: ${practice.successCount}',
          style: textTheme.bodySmall,
        ),
        Text(
          'Created: ${_formatDate(practice.createdAt)}',
          style: textTheme.bodySmall,
        ),
      ],
    );
  }

  Color _getProgressColor(double value) {
    if (value < 0.3) {
      return Colors.red;
    } else if (value < 0.7) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
