import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/tts/tts_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/tts/tts_event.dart';
import 'package:learn_to_talk/presentation/blocs/tts/tts_state.dart';

/// A simplified Text-to-Speech widget without download option
class SimpleTTSWidget extends StatelessWidget {
  /// The text to be spoken
  final String text;
  
  /// The language code for speech synthesis (e.g., 'en-US', 'ja-JP')
  final String languageCode;

  const SimpleTTSWidget({
    super.key,
    required this.text,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TTSBloc, TTSState>(
      builder: (context, state) {
        final isCurrentlySpeakingThisText = 
            state.isSpeaking && 
            state.currentText == text && 
            state.currentLanguageCode == languageCode;
            
        return IconButton(
          icon: Icon(
            isCurrentlySpeakingThisText ? Icons.stop : Icons.volume_up,
            size: 24,
            color: isCurrentlySpeakingThisText 
                ? Colors.red 
                : Theme.of(context).primaryColor,
          ),
          onPressed: () => _handleTTSAction(context, state),
          constraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        );
      },
    );
  }

  void _handleTTSAction(BuildContext context, TTSState state) {
    final ttsBloc = context.read<TTSBloc>();
    
    // If currently speaking this text, stop speaking
    if (state.isSpeaking && 
        state.currentText == text && 
        state.currentLanguageCode == languageCode) {
      ttsBloc.add(const StopSpeaking());
    } else {
      // Otherwise, start speaking this text
      ttsBloc.add(SpeakText(
        text: text,
        languageCode: languageCode,
      ));
    }
  }
}
