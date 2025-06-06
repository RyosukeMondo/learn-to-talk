import 'package:equatable/equatable.dart';
import 'package:learn_to_talk/domain/entities/language.dart';

abstract class LanguageEvent extends Equatable {
  const LanguageEvent();

  @override
  List<Object> get props => [];
}

class LoadLanguages extends LanguageEvent {
  const LoadLanguages();
}

class SelectSourceLanguage extends LanguageEvent {
  final Language language;

  const SelectSourceLanguage(this.language);

  @override
  List<Object> get props => [language];
}

class SelectTargetLanguage extends LanguageEvent {
  final Language language;

  const SelectTargetLanguage(this.language);

  @override
  List<Object> get props => [language];
}

class CheckOfflineAvailability extends LanguageEvent {
  final String sourceLanguageCode;
  final String targetLanguageCode;

  const CheckOfflineAvailability({
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
  });

  @override
  List<Object> get props => [sourceLanguageCode, targetLanguageCode];
}

// Download functionality is now handled by ModelDownloadWidget and ModelDownloadService

class SwapLanguages extends LanguageEvent {
  const SwapLanguages();
}

class SaveLanguagePreferences extends LanguageEvent {
  final String sourceLanguageCode;
  final String targetLanguageCode;

  const SaveLanguagePreferences({
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
  });

  @override
  List<Object> get props => [sourceLanguageCode, targetLanguageCode];
}

class LoadLanguagePreferences extends LanguageEvent {
  const LoadLanguagePreferences();
}
