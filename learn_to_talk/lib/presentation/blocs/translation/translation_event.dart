import 'package:equatable/equatable.dart';

abstract class TranslationEvent extends Equatable {
  const TranslationEvent();

  @override
  List<Object?> get props => [];
}

class InitializeTranslation extends TranslationEvent {
  const InitializeTranslation();
}

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
  List<Object> get props => [text, sourceLanguageCode, targetLanguageCode];
}

class CheckModelAvailability extends TranslationEvent {
  final String sourceLanguageCode;
  final String targetLanguageCode;

  const CheckModelAvailability({
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
  });

  @override
  List<Object> get props => [sourceLanguageCode, targetLanguageCode];
}

class DownloadTranslationModel extends TranslationEvent {
  final String sourceLanguageCode;
  final String targetLanguageCode;

  const DownloadTranslationModel({
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
  });

  @override
  List<Object> get props => [sourceLanguageCode, targetLanguageCode];
}

class DeleteTranslationModel extends TranslationEvent {
  final String sourceLanguageCode;
  final String targetLanguageCode;

  const DeleteTranslationModel({
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
  });

  @override
  List<Object> get props => [sourceLanguageCode, targetLanguageCode];
}
