import 'package:equatable/equatable.dart';
import 'package:learn_to_talk/domain/entities/language.dart';

enum LanguageStatus { initial, loading, loaded, error }
enum OfflineStatus { unknown, checking, available, unavailable, downloading }

class LanguageState extends Equatable {
  final LanguageStatus status;
  final List<Language> availableLanguages;
  final Language? sourceLanguage;
  final Language? targetLanguage;
  final OfflineStatus offlineStatus;
  final String? errorMessage;

  const LanguageState({
    this.status = LanguageStatus.initial,
    this.availableLanguages = const [],
    this.sourceLanguage,
    this.targetLanguage,
    this.offlineStatus = OfflineStatus.unknown,
    this.errorMessage,
  });

  LanguageState copyWith({
    LanguageStatus? status,
    List<Language>? availableLanguages,
    Language? sourceLanguage,
    bool clearSourceLanguage = false,
    Language? targetLanguage,
    bool clearTargetLanguage = false,
    OfflineStatus? offlineStatus,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return LanguageState(
      status: status ?? this.status,
      availableLanguages: availableLanguages ?? this.availableLanguages,
      sourceLanguage: clearSourceLanguage ? null : sourceLanguage ?? this.sourceLanguage,
      targetLanguage: clearTargetLanguage ? null : targetLanguage ?? this.targetLanguage,
      offlineStatus: offlineStatus ?? this.offlineStatus,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }

  bool get isLanguagePairSelected => sourceLanguage != null && targetLanguage != null;

  @override
  List<Object?> get props => [
        status,
        availableLanguages,
        sourceLanguage,
        targetLanguage,
        offlineStatus,
        errorMessage,
      ];
}
