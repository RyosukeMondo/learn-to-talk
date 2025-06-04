import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/speech/speech_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/speech/speech_event.dart';
import 'package:learn_to_talk/presentation/blocs/speech/speech_state.dart';
import 'package:lottie/lottie.dart';

class SpeechRecognitionWidget extends StatelessWidget {
  final String languageCode;
  final Function(String) onRecognized;
  final Widget? customAnimation;

  const SpeechRecognitionWidget({
    super.key,
    required this.languageCode,
    required this.onRecognized,
    this.customAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SpeechBloc, SpeechState>(
      listenWhen: (previous, current) {
        return previous.recognizedText != current.recognizedText && 
               current.recognizedText != null;
      },
      listener: (context, state) {
        if (state.recognizedText != null && state.recognizedText!.isNotEmpty) {
          onRecognized(state.recognizedText!);
        }
      },
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAnimationArea(context, state),
            const SizedBox(height: 16),
            _buildRecognizedText(context, state),
            const SizedBox(height: 16),
            _buildActionButton(context, state),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 8),
              _buildErrorMessage(context, state),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAnimationArea(BuildContext context, SpeechState state) {
    if (customAnimation != null) {
      return customAnimation!;
    }

    if (state.isListening) {
      return SizedBox(
        height: 150,
        child: Lottie.asset(
          'assets/animations/speech_animation.json',
          repeat: true,
          animate: true,
        ),
      );
    } else {
      return SizedBox(
        height: 150,
        child: Icon(
          Icons.mic,
          size: 80,
          color: Theme.of(context).primaryColor,
        ),
      );
    }
  }

  Widget _buildRecognizedText(BuildContext context, SpeechState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      width: double.infinity,
      child: Text(
        state.recognizedText ?? 'Speak to see your words here...',
        style: TextStyle(
          fontSize: 18,
          color: state.recognizedText != null ? Colors.black : Colors.grey[600],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, SpeechState state) {
    return ElevatedButton.icon(
      onPressed: () {
        final speechBloc = context.read<SpeechBloc>();
        if (state.isListening) {
          speechBloc.add(const StopListening());
        } else {
          speechBloc.add(StartListening(languageCode: languageCode));
        }
      },
      icon: Icon(state.isListening ? Icons.stop : Icons.mic),
      label: Text(state.isListening ? 'Stop' : 'Start Speaking'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context, SpeechState state) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        state.errorMessage!,
        style: const TextStyle(color: Colors.red),
        textAlign: TextAlign.center,
      ),
    );
  }
}
