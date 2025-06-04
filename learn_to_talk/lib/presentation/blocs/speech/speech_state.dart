import 'package:equatable/equatable.dart';

enum SpeechStatus { initial, unavailable, available, listening, processing, error }

class SpeechState extends Equatable {
  final SpeechStatus status;
  final String? recognizedText;
  final String? errorMessage;
  final String? languageCode;
  final bool isListening;

  const SpeechState({
    this.status = SpeechStatus.initial,
    this.recognizedText,
    this.errorMessage,
    this.languageCode,
    this.isListening = false,
  });

  SpeechState copyWith({
    SpeechStatus? status,
    String? recognizedText,
    bool clearRecognizedText = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? languageCode,
    bool clearLanguageCode = false,
    bool? isListening,
  }) {
    return SpeechState(
      status: status ?? this.status,
      recognizedText: clearRecognizedText ? null : recognizedText ?? this.recognizedText,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      languageCode: clearLanguageCode ? null : languageCode ?? this.languageCode,
      isListening: isListening ?? this.isListening,
    );
  }

  @override
  List<Object?> get props => [
        status,
        recognizedText,
        errorMessage,
        languageCode,
        isListening,
      ];
}
