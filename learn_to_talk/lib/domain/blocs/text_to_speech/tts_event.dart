part of 'tts_bloc.dart';

/// Base class for all TTS events
abstract class TTSEvent extends Equatable {
  const TTSEvent();

  @override
  List<Object?> get props => [];
}

/// Event to speak text with TTS
class SpeakText extends TTSEvent {
  final String text;
  final String languageCode;
  
  const SpeakText({
    required this.text,
    required this.languageCode,
  });
  
  @override
  List<Object?> get props => [text, languageCode];
}

/// Event to stop TTS playback
class StopSpeaking extends TTSEvent {
  const StopSpeaking();
}

/// Event to check if voice data for a language is available
class CheckVoiceData extends TTSEvent {
  final String languageCode;
  
  const CheckVoiceData({required this.languageCode});
  
  @override
  List<Object?> get props => [languageCode];
}

/// Event to download voice data for a language
class DownloadVoiceData extends TTSEvent {
  final String languageCode;
  
  const DownloadVoiceData({required this.languageCode});
  
  @override
  List<Object?> get props => [languageCode];
}
