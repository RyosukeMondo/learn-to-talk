import 'package:flutter/material.dart';

class InstructionsWidget extends StatelessWidget {
  final bool isCheckingPronunciation;

  const InstructionsWidget({
    super.key,
    required this.isCheckingPronunciation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
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
            const SizedBox(height: 4),
            Text(
              isCheckingPronunciation
                  ? 'Listen to the translation and try to mimic it. Press the microphone button and speak.'
                  : 'Press the microphone button and speak in your mother language. The app will translate it for you to practice.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
