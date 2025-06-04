import 'package:equatable/equatable.dart';

enum TTSStatus { initial, unavailable, available, speaking, completed, error }

class TTSState extends Equatable {
  final TTSStatus status;
  final String? currentText;
  final String? currentLanguageCode;
  final bool isLanguageAvailableOffline;
  final bool isSpeaking;
  final String? errorMessage;

  const TTSState({
    this.status = TTSStatus.initial,
    this.currentText,
    this.currentLanguageCode,
    this.isLanguageAvailableOffline = false,
    this.isSpeaking = false,
    this.errorMessage,
  });

  TTSState copyWith({
    TTSStatus? status,
    String? currentText,
    bool clearCurrentText = false,
    String? currentLanguageCode,
    bool clearCurrentLanguageCode = false,
    bool? isLanguageAvailableOffline,
    bool? isSpeaking,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return TTSState(
      status: status ?? this.status,
      currentText: clearCurrentText ? null : currentText ?? this.currentText,
      currentLanguageCode: clearCurrentLanguageCode ? null : currentLanguageCode ?? this.currentLanguageCode,
      isLanguageAvailableOffline: isLanguageAvailableOffline ?? this.isLanguageAvailableOffline,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentText,
        currentLanguageCode,
        isLanguageAvailableOffline,
        isSpeaking,
        errorMessage,
      ];
}
