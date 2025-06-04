import 'package:equatable/equatable.dart';

enum TranslationStatus { initial, loading, available, translating, completed, downloading, error }
enum ModelAvailability { unknown, checking, available, unavailable, downloading }

class TranslationState extends Equatable {
  final TranslationStatus status;
  final String? sourceText;
  final String? translatedText;
  final String? sourceLanguageCode;
  final String? targetLanguageCode;
  final ModelAvailability modelAvailability;
  final double? downloadProgress;
  final String? errorMessage;

  const TranslationState({
    this.status = TranslationStatus.initial,
    this.sourceText,
    this.translatedText,
    this.sourceLanguageCode,
    this.targetLanguageCode,
    this.modelAvailability = ModelAvailability.unknown,
    this.downloadProgress,
    this.errorMessage,
  });

  TranslationState copyWith({
    TranslationStatus? status,
    String? sourceText,
    bool clearSourceText = false,
    String? translatedText,
    bool clearTranslatedText = false,
    String? sourceLanguageCode,
    bool clearSourceLanguageCode = false,
    String? targetLanguageCode,
    bool clearTargetLanguageCode = false,
    ModelAvailability? modelAvailability,
    double? downloadProgress,
    bool clearDownloadProgress = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return TranslationState(
      status: status ?? this.status,
      sourceText: clearSourceText ? null : sourceText ?? this.sourceText,
      translatedText: clearTranslatedText ? null : translatedText ?? this.translatedText,
      sourceLanguageCode: clearSourceLanguageCode ? null : sourceLanguageCode ?? this.sourceLanguageCode,
      targetLanguageCode: clearTargetLanguageCode ? null : targetLanguageCode ?? this.targetLanguageCode,
      modelAvailability: modelAvailability ?? this.modelAvailability,
      downloadProgress: clearDownloadProgress ? null : downloadProgress ?? this.downloadProgress,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        sourceText,
        translatedText,
        sourceLanguageCode,
        targetLanguageCode,
        modelAvailability,
        downloadProgress,
        errorMessage,
      ];
}
