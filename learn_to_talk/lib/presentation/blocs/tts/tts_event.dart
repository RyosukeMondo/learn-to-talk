import 'package:equatable/equatable.dart';

abstract class TTSEvent extends Equatable {
  const TTSEvent();

  @override
  List<Object?> get props => [];
}

class InitializeTTS extends TTSEvent {
  const InitializeTTS();
}

class SpeakText extends TTSEvent {
  final String text;
  final String languageCode;

  const SpeakText({
    required this.text,
    required this.languageCode,
  });

  @override
  List<Object> get props => [text, languageCode];
}

class StopSpeaking extends TTSEvent {
  const StopSpeaking();
}

class CheckLanguageAvailability extends TTSEvent {
  final String languageCode;

  const CheckLanguageAvailability({required this.languageCode});

  @override
  List<Object> get props => [languageCode];
}

class PromptLanguageInstallation extends TTSEvent {
  final String languageCode;

  const PromptLanguageInstallation({required this.languageCode});

  @override
  List<Object> get props => [languageCode];
}

class TTSCompletionReceived extends TTSEvent {
  const TTSCompletionReceived();
}
