import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/speech/speech_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/speech/speech_event.dart';
import 'package:learn_to_talk/presentation/blocs/speech/speech_state.dart';
import 'package:lottie/lottie.dart';

/// A reusable Speech-to-Text widget that provides speech recognition functionality
/// 
/// This widget handles the speech recognition flow, UI states, and callbacks
/// when speech is recognized. It can be easily integrated into any screen.
class SpeechRecognitionWidget extends StatelessWidget {
  /// The language code for speech recognition (e.g., 'en-US', 'ja-JP')
  final String languageCode;
  
  /// Callback function that receives the recognized text
  final Function(String) onRecognized;
  
  /// Optional custom animation widget to replace the default animation
  final Widget? customAnimation;
  
  /// Controls whether to display a compact or full-sized version
  final bool compact;
  
  /// Controls whether to automatically start listening when widget is built
  final bool autoStart;
  
  /// Custom styling for the recognition button
  final ButtonStyle? buttonStyle;

  const SpeechRecognitionWidget({
    super.key,
    required this.languageCode,
    required this.onRecognized,
    this.customAnimation,
    this.compact = false,
    this.autoStart = false,
    this.buttonStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Auto-start listener if configured
    if (autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final speechBloc = context.read<SpeechBloc>();
        if (!speechBloc.state.isListening) {
          speechBloc.add(StartListening(languageCode: languageCode));
        }
      });
    }

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
        return compact 
          ? _buildCompactVersion(context, state) 
          : _buildFullVersion(context, state);
      },
    );
  }

  /// Builds a compact version of the widget with minimal UI
  Widget _buildCompactVersion(BuildContext context, SpeechState state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            state.isListening ? Icons.mic_off : Icons.mic,
            color: state.isListening ? Colors.red : Theme.of(context).primaryColor,
          ),
          onPressed: () => _handleSpeechAction(context, state),
        ),
        if (state.isListening)
          SizedBox(
            width: 30,
            height: 30,
            child: Lottie.asset(
              'assets/animations/speech_animation.json',
              repeat: true,
              animate: true,
            ),
          ),
      ],
    );
  }

  /// Builds the full version of the widget with all UI elements
  Widget _buildFullVersion(BuildContext context, SpeechState state) {
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
      onPressed: () => _handleSpeechAction(context, state),
      icon: Icon(state.isListening ? Icons.stop : Icons.mic),
      label: Text(state.isListening ? 'Stop' : 'Start Speaking'),
      style: buttonStyle ?? ElevatedButton.styleFrom(
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

  void _handleSpeechAction(BuildContext context, SpeechState state) {
    final speechBloc = context.read<SpeechBloc>();
    if (state.isListening) {
      speechBloc.add(const StopListening());
    } else {
      speechBloc.add(StartListening(languageCode: languageCode));
    }
  }
}
