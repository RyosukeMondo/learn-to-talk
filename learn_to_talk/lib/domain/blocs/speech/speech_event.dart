part of 'speech_bloc.dart';

/// Base class for all speech recognition events
abstract class SpeechEvent extends Equatable {
  const SpeechEvent();

  @override
  List<Object?> get props => [];
}

/// Event to start speech recognition
class StartListening extends SpeechEvent {
  final String languageCode;
  
  const StartListening({required this.languageCode});
  
  @override
  List<Object?> get props => [languageCode];
}

/// Event to stop speech recognition
class StopListening extends SpeechEvent {
  const StopListening();
}

/// Event triggered when speech is recognized
class RecognizedSpeech extends SpeechEvent {
  final String text;
  
  const RecognizedSpeech(this.text);
  
  @override
  List<Object?> get props => [text];
}

/// Event triggered when a speech error occurs
class SpeechError extends SpeechEvent {
  final String error;
  
  const SpeechError(this.error);
  
  @override
  List<Object?> get props => [error];
}
