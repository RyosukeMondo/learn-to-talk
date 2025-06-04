import 'package:learn_to_talk/data/datasources/translation_data_source.dart';
import 'package:learn_to_talk/domain/entities/language.dart';
import 'package:learn_to_talk/domain/repositories/translation_repository.dart';

class TranslationRepositoryImpl implements TranslationRepository {
  final TranslationDataSource _translationDataSource;

  TranslationRepositoryImpl(this._translationDataSource);

  @override
  Future<void> initTranslation() {
    return _translationDataSource.initialize();
  }

  @override
  Future<List<Language>> getTranslationLanguages() async {
    final languageModels = await _translationDataSource.getSupportedLanguages();
    // Convert from LanguageModel to Language entities
    return languageModels.map((model) => Language(
      code: model.code,
      name: model.name,
      isOfflineAvailable: model.isOfflineAvailable,
    )).toList();
  }

  @override
  Future<bool> isModelDownloaded(String sourceLanguageCode, String targetLanguageCode) {
    return _translationDataSource.isModelDownloaded(sourceLanguageCode, targetLanguageCode);
  }

  @override
  Future<void> downloadModel(String sourceLanguageCode, String targetLanguageCode) {
    return _translationDataSource.downloadModel(sourceLanguageCode, targetLanguageCode);
  }

  @override
  Future<void> deleteModel(String sourceLanguageCode, String targetLanguageCode) {
    return _translationDataSource.deleteModel(sourceLanguageCode, targetLanguageCode);
  }

  @override
  Future<String> translateText(String text, String sourceLanguageCode, String targetLanguageCode) {
    return _translationDataSource.translate(text, sourceLanguageCode, targetLanguageCode);
  }

  @override
  Future<void> dispose() {
    return _translationDataSource.dispose();
  }
}
