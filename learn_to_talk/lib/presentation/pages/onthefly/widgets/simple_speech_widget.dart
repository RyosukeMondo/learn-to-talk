import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/speech/speech_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/speech/speech_event.dart';
import 'package:learn_to_talk/presentation/blocs/speech/speech_state.dart';

/// A simplified speech recognition widget without animations
/// Uses minimal UI elements to save screen space
class SimpleSpeechWidget extends StatefulWidget {
  /// The language code for speech recognition (e.g., 'en-US', 'ja-JP')
  final String languageCode;
  
  /// Callback function that receives the recognized text
  final Function(String) onRecognized;
  
  /// Silence timeout in seconds - stops listening after this many seconds without speech input
  final int silenceTimeoutSeconds;
  
  /// Whether to show a countdown timer for silence detection
  final bool showSilenceIndicator;

  const SimpleSpeechWidget({
    super.key,
    required this.languageCode,
    required this.onRecognized,
    this.silenceTimeoutSeconds = 3,
    this.showSilenceIndicator = true,
  });
  
  @override
  State<SimpleSpeechWidget> createState() => _SimpleSpeechWidgetState();
}

class _SimpleSpeechWidgetState extends State<SimpleSpeechWidget> {
  Timer? _silenceTimer;
  DateTime? _lastSpeechDetected;
  int _silenceSeconds = 0;

  @override
  void dispose() {
    _cancelSilenceTimer();
    super.dispose();
  }
  
  void _startSilenceDetection(BuildContext context) {
    _cancelSilenceTimer();
    _lastSpeechDetected = DateTime.now();
    _silenceSeconds = 0;
    
    // Check for silence every 500ms
    _silenceTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      final now = DateTime.now();
      final silenceDuration = now.difference(_lastSpeechDetected ?? now);
      
      setState(() {
        // Convert to seconds and round up
        _silenceSeconds = silenceDuration.inMilliseconds ~/ 1000;
        
        // If silence exceeds threshold
        if (_silenceSeconds >= widget.silenceTimeoutSeconds) {
          _stopListening(context);
          _cancelSilenceTimer();
        }
      });
    });
  }
  
  void _resetSilenceTimer() {
    _lastSpeechDetected = DateTime.now();
    _silenceSeconds = 0;
  }
  
  void _cancelSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = null;
  }
  
  void _stopListening(BuildContext context) {
    final speechBloc = context.read<SpeechBloc>();
    speechBloc.add(const StopListening());
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SpeechBloc, SpeechState>(
      listenWhen: (previous, current) {
        return previous.recognizedText != current.recognizedText && 
               current.recognizedText != null;
      },
      listener: (context, state) {
        if (state.recognizedText != null && state.recognizedText!.isNotEmpty) {
          widget.onRecognized(state.recognizedText!);
          // Reset the silence timer when we detect speech
          if (state.isListening) {
            _resetSilenceTimer();
          }
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.isListening 
                  ? 'Stop'
                  : 'Speak',
                style: const TextStyle(color: Colors.white),
              ),
              if (state.isListening && widget.showSilenceIndicator) 
                const SizedBox(width: 4),
              if (state.isListening && widget.showSilenceIndicator)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.silenceTimeoutSeconds - _silenceSeconds}',
                      style: const TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.mic_none, size: 14, color: Colors.white70),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  void _handleSpeechAction(BuildContext context, SpeechState state) {
    final speechBloc = context.read<SpeechBloc>();
    
    if (state.isListening) {
      _cancelSilenceTimer();
      speechBloc.add(const StopListening());
    } else {
      speechBloc.add(StartListening(languageCode: widget.languageCode));
      _startSilenceDetection(context);
    }
  }
}
