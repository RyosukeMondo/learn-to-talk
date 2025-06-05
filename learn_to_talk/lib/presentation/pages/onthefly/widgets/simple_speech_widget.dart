import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/speech/speech_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/speech/speech_event.dart';
import 'package:learn_to_talk/presentation/blocs/speech/speech_state.dart';

/// A simplified speech recognition widget without animations
/// Uses minimal UI elements to save screen space
class SimpleSpeechWidget extends StatelessWidget {
  /// The language code for speech recognition (e.g., 'en-US', 'ja-JP')
  final String languageCode;
  
  /// Callback function that receives the recognized text
  final Function(String) onRecognized;

  const SimpleSpeechWidget({
    super.key,
    required this.languageCode,
    required this.onRecognized,
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
        return ElevatedButton(
          onPressed: () => _handleSpeechAction(context, state),
          style: ElevatedButton.styleFrom(
            backgroundColor: state.isListening ? Colors.red : Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: const Size(100, 36),
          ),
          child: Text(
            state.isListening ? 'Stop' : 'Speak',
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }

  void _handleSpeechAction(BuildContext context, SpeechState state) {
    final speechBloc = context.read<SpeechBloc>();
    
    if (state.isListening) {
      speechBloc.add(const StopListening());
    } else {
      speechBloc.add(StartListening(languageCode: languageCode));
    }
  }
}
