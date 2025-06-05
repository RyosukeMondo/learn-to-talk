part of 'speech_bloc.dart';

/// Base class for all speech recognition states
abstract class SpeechState extends Equatable {
  const SpeechState();
  
  @override
  List<Object?> get props => [];
}

/// Initial state when speech recognition is not initialized
class SpeechInitial extends SpeechState {
  const SpeechInitial();
}

/// State when speech recognition is actively listening
class SpeechListening extends SpeechState {
  const SpeechListening();
}

/// State when speech recognition is not listening
class SpeechNotListening extends SpeechState {
  final String finalText;
  
  const SpeechNotListening({this.finalText = ''});
  
  @override
  List<Object?> get props => [finalText];
}

/// State when speech has been recognized
class SpeechRecognized extends SpeechState {
  final String text;
  
  const SpeechRecognized({required this.text});
  
  @override
  List<Object?> get props => [text];
}

/// State when an error occurs during speech recognition
class SpeechFailure extends SpeechState {
  final String error;
  
  const SpeechFailure({required this.error});
  
  @override
  List<Object?> get props => [error];
}
