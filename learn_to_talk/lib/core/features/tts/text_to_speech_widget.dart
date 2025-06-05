import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/tts/tts_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/tts/tts_event.dart';
import 'package:learn_to_talk/presentation/blocs/tts/tts_state.dart';

/// A reusable Text-to-Speech widget that provides speech synthesis functionality
/// 
/// This widget handles TTS playback, UI states, and offline language data management.
/// It can be used in any screen requiring text-to-speech capabilities.
class TextToSpeechWidget extends StatelessWidget {
  /// The text to be spoken
  final String text;
  
  /// The language code for speech synthesis (e.g., 'en-US', 'ja-JP')
  final String languageCode;
  
  /// Whether to use compact mode (icon only) or expanded mode (with button)
  final bool compact;
  
  /// Optional color for the TTS icon
  final Color? iconColor;
  
  /// Optional style for the TTS button
  final ButtonStyle? buttonStyle;
  
  /// Whether to show the option to download voice data
  final bool showDownloadOption;
  
  /// Custom button child widget (replaces default icon and label)
  final Widget? customButtonChild;

  const TextToSpeechWidget({
    super.key,
    required this.text,
    required this.languageCode,
    this.compact = false,
    this.iconColor,
    this.buttonStyle,
    this.showDownloadOption = true,
    this.customButtonChild,
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

  /// Builds a compact version with just an icon
  Widget _buildCompactVersion(BuildContext context, bool isSpeaking) {
    return IconButton(
      icon: Icon(
        isSpeaking ? Icons.stop : Icons.volume_up,
        color: iconColor ?? Theme.of(context).primaryColor,
      ),
      onPressed: () => _handleTtsAction(context, isSpeaking),
    );
  }

  /// Builds a full version with button and download options
  Widget _buildFullVersion(BuildContext context, bool isSpeaking, TTSState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: () => _handleTtsAction(context, isSpeaking),
          icon: Icon(isSpeaking ? Icons.stop : Icons.volume_up),
          label: Text(isSpeaking ? 'Stop' : 'Listen'),
          style: buttonStyle ?? ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        if (showDownloadOption && 
            !state.isLanguageAvailableOffline && 
            state.currentLanguageCode == languageCode) ...[
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
          _buildErrorMessage(state),
        ],
      ],
    );
  }

  /// Builds an error message display
  Widget _buildErrorMessage(TTSState state) {
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

  /// Handles the TTS button action (play/stop)
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
