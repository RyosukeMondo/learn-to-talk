part of 'translation_bloc.dart';

/// Base class for all translation events
abstract class TranslationEvent extends Equatable {
  const TranslationEvent();

  @override
  List<Object?> get props => [];
}

/// Event to translate text
class TranslateText extends TranslationEvent {
  final String text;
  final String sourceLanguageCode;
  final String targetLanguageCode;
  
  const TranslateText({
    required this.text,
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
  });
  
  @override
  List<Object?> get props => [text, sourceLanguageCode, targetLanguageCode];
}

/// Event to check if a translation model is available
class CheckTranslationModel extends TranslationEvent {
  final String sourceLanguageCode;
  final String targetLanguageCode;
  
  const CheckTranslationModel({
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
  });
  
  @override
  List<Object?> get props => [sourceLanguageCode, targetLanguageCode];
}

/// Event to download a translation model
class DownloadTranslationModel extends TranslationEvent {
  final String sourceLanguageCode;
  final String targetLanguageCode;
  
  const DownloadTranslationModel({
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
  });
  
  @override
  List<Object?> get props => [sourceLanguageCode, targetLanguageCode];
}

/// Event to clear the current translation
class ClearTranslation extends TranslationEvent {
  const ClearTranslation();
}
