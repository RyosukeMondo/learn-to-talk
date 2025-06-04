import 'package:equatable/equatable.dart';

abstract class SpeechEvent extends Equatable {
  const SpeechEvent();

  @override
  List<Object?> get props => [];
}

class InitializeSpeech extends SpeechEvent {
  const InitializeSpeech();
}

class StartListening extends SpeechEvent {
  final String languageCode;

  const StartListening({required this.languageCode});

  @override
  List<Object> get props => [languageCode];
}

class StopListening extends SpeechEvent {
  const StopListening();
}

class SpeechResultReceived extends SpeechEvent {
  final String text;

  const SpeechResultReceived({required this.text});

  @override
  List<Object> get props => [text];
}

class SpeechErrorReceived extends SpeechEvent {
  final String error;

  const SpeechErrorReceived({required this.error});

  @override
  List<Object> get props => [error];
}
