import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/tts/tts_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/tts/tts_event.dart';
import 'package:learn_to_talk/presentation/blocs/tts/tts_state.dart';

class TextToSpeechWidget extends StatelessWidget {
  final String text;
  final String languageCode;
  final bool compact;
  final Color? iconColor;

  const TextToSpeechWidget({
    super.key,
    required this.text,
    required this.languageCode,
    this.compact = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TTSBloc, TTSState>(
      builder: (context, state) {
        final isCurrentlySpeakingThisText = 
            state.isSpeaking && 
            state.currentText == text && 
            state.currentLanguageCode == languageCode;
        
        return compact ? _buildCompactVersion(context, isCurrentlySpeakingThisText) : 
                         _buildFullVersion(context, isCurrentlySpeakingThisText, state);
      },
    );
  }

  Widget _buildCompactVersion(BuildContext context, bool isSpeaking) {
    return IconButton(
      icon: Icon(
        isSpeaking ? Icons.stop : Icons.volume_up,
        color: iconColor ?? Theme.of(context).primaryColor,
      ),
      onPressed: () => _handleTtsAction(context, isSpeaking),
    );
  }

  Widget _buildFullVersion(BuildContext context, bool isSpeaking, TTSState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: () => _handleTtsAction(context, isSpeaking),
          icon: Icon(isSpeaking ? Icons.stop : Icons.volume_up),
          label: Text(isSpeaking ? 'Stop' : 'Listen'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        if (!state.isLanguageAvailableOffline && state.currentLanguageCode == languageCode) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              context.read<TTSBloc>().add(PromptLanguageInstallation(
                languageCode: languageCode,
              ));
            },
            child: const Text('Download voice data for offline use'),
          ),
        ],
        if (state.errorMessage != null) ...[
          const SizedBox(height: 8),
          Container(
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
          ),
        ],
      ],
    );
  }

  void _handleTtsAction(BuildContext context, bool isSpeaking) {
    final ttsBloc = context.read<TTSBloc>();
    
    if (isSpeaking) {
      ttsBloc.add(const StopSpeaking());
    } else {
      ttsBloc.add(SpeakText(
        text: text,
        languageCode: languageCode,
      ));
    }
  }
}
