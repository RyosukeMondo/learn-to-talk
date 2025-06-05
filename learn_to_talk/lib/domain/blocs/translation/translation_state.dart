part of 'translation_bloc.dart';

/// Base class for all translation states
abstract class TranslationState extends Equatable {
  const TranslationState();
  
  @override
  List<Object?> get props => [];
}

/// Initial state when no translation has been performed
class TranslationInitial extends TranslationState {
  const TranslationInitial();
}

/// State when translation is in progress
class TranslationLoading extends TranslationState {
  final String sourceText;
  
  const TranslationLoading({required this.sourceText});
  
  @override
  List<Object?> get props => [sourceText];
}

/// State when translation is successful
class TranslationSuccess extends TranslationState {
  final String sourceText;
  final String translatedText;
  final String sourceLanguageCode;
  final String targetLanguageCode;
  
  const TranslationSuccess({
    required this.sourceText,
    required this.translatedText,
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
  });
  
  @override
  List<Object?> get props => [sourceText, translatedText, sourceLanguageCode, targetLanguageCode];
}

/// State when translation has failed
class TranslationFailure extends TranslationState {
  final String error;
  
  const TranslationFailure({required this.error});
  
  @override
  List<Object?> get props => [error];
}

/// State when checking for translation model availability
class TranslationModelChecking extends TranslationState {
  final String sourceLanguageCode;
  final String targetLanguageCode;
  
  const TranslationModelChecking({
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
  });
  
  @override
  List<Object?> get props => [sourceLanguageCode, targetLanguageCode];
}

/// State when translation model is available
class TranslationModelAvailable extends TranslationState {
  final String sourceLanguageCode;
  final String targetLanguageCode;
  
  const TranslationModelAvailable({
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
  });
  
  @override
  List<Object?> get props => [sourceLanguageCode, targetLanguageCode];
}

/// State when translation model is missing
class TranslationModelMissing extends TranslationState {
  final String sourceLanguageCode;
  final String targetLanguageCode;
  
  const TranslationModelMissing({
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
  });
  
  @override
  List<Object?> get props => [sourceLanguageCode, targetLanguageCode];
}

/// State when translation model is downloading
class TranslationModelDownloading extends TranslationState {
  final String sourceLanguageCode;
  final String targetLanguageCode;
  
  const TranslationModelDownloading({
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
  });
  
  @override
  List<Object?> get props => [sourceLanguageCode, targetLanguageCode];
}

/// State when translation model download has failed
class TranslationModelDownloadFailed extends TranslationState {
  final String sourceLanguageCode;
  final String targetLanguageCode;
  final String error;
  
  const TranslationModelDownloadFailed({
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
    required this.error,
  });
  
  @override
  List<Object?> get props => [sourceLanguageCode, targetLanguageCode, error];
}
