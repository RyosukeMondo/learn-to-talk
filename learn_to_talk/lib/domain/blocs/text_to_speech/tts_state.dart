part of 'tts_bloc.dart';

/// Base class for all TTS states
abstract class TTSState extends Equatable {
  const TTSState();
  
  @override
  List<Object?> get props => [];
}

/// Initial state when TTS is not initialized
class TTSInitial extends TTSState {}

/// State when TTS is speaking text
class TTSSpeaking extends TTSState {
  final String text;
  
  const TTSSpeaking({required this.text});
  
  @override
  List<Object?> get props => [text];
}

/// State when TTS has completed speaking
class TTSCompleted extends TTSState {
  final String text;
  
  const TTSCompleted({required this.text});
  
  @override
  List<Object?> get props => [text];
}

/// State when TTS has been stopped
class TTSStopped extends TTSState {}

/// State when TTS has encountered an error
class TTSFailure extends TTSState {
  final String error;
  
  const TTSFailure({required this.error});
  
  @override
  List<Object?> get props => [error];
}

/// State when checking if voice data is available
class TTSChecking extends TTSState {}

/// State when voice data is available for a language
class TTSVoiceDataAvailable extends TTSState {
  final String languageCode;
  
  const TTSVoiceDataAvailable({required this.languageCode});
  
  @override
  List<Object?> get props => [languageCode];
}

/// State when voice data is missing for a language
class TTSVoiceDataMissing extends TTSState {
  final String languageCode;
  
  const TTSVoiceDataMissing({required this.languageCode});
  
  @override
  List<Object?> get props => [languageCode];
}

/// State when downloading voice data
class TTSDownloading extends TTSState {
  final String languageCode;
  
  const TTSDownloading({required this.languageCode});
  
  @override
  List<Object?> get props => [languageCode];
}

/// State when voice data download has failed
class TTSDownloadFailed extends TTSState {
  final String languageCode;
  
  const TTSDownloadFailed({required this.languageCode});
  
  @override
  List<Object?> get props => [languageCode];
}
