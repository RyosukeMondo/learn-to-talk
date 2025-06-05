import 'package:learn_to_talk/data/datasources/translation_data_source.dart';
import 'package:learn_to_talk/domain/entities/language.dart';
import 'package:learn_to_talk/domain/repositories/translation_repository.dart';
import 'package:logging/logging.dart';

class TranslationRepositoryImpl implements TranslationRepository {
  final TranslationDataSource _translationDataSource;
  final Logger _logger = Logger('TranslationRepositoryImpl');

  TranslationRepositoryImpl(this._translationDataSource);

  @override
  Future<void> initTranslation() {
    return _translationDataSource.initialize();
  }

  @override
  Future<List<Language>> getTranslationLanguages() async {
    final languageModels = await _translationDataSource.getSupportedLanguages();
    // Convert from LanguageModel to Language entities
    return languageModels
        .map(
          (model) => Language(
            code: model.code,
            name: model.name,
            isOfflineAvailable: model.isOfflineAvailable,
          ),
        )
        .toList();
  }

  @override
  Future<bool> isModelDownloaded(
    String sourceLanguageCode,
    String targetLanguageCode,
  ) {
    return _translationDataSource.isModelDownloaded(
      sourceLanguageCode,
      targetLanguageCode,
    );
  }

  @override
  Future<void> downloadModel(
    String sourceLanguageCode,
    String targetLanguageCode,
  ) {
    return _translationDataSource.downloadModel(
      sourceLanguageCode,
      targetLanguageCode,
    );
  }

  @override
  Future<void> deleteModel(
    String sourceLanguageCode,
    String targetLanguageCode,
  ) {
    return _translationDataSource.deleteModel(
      sourceLanguageCode,
      targetLanguageCode,
    );
  }

  /// Convert language code to format expected by translation service (usually short codes like 'en', 'fr')
  String _formatTranslationLanguageCode(String languageCode) {
    _logger.info(
      'TranslationRepositoryImpl: Formatting translation language code: $languageCode',
    );

    // If it's already a short code, keep it
    if (languageCode.length <= 2) {
      return languageCode;
    }

    // Extract base language code (e.g., 'en' from 'en-US' or 'en_US')
    if (languageCode.contains('-') || languageCode.contains('_')) {
      final baseCode = languageCode.split(RegExp(r'[-_]'))[0].toLowerCase();
      _logger.info(
        'TranslationRepositoryImpl: Extracted base code: $baseCode from $languageCode',
      );
      return baseCode;
    }

    // Handle special cases where we have full names
    switch (languageCode) {
      case 'English':
      case 'English (US)':
        return 'en';
      case 'Japanese':
        return 'ja';
      case 'French':
        return 'fr';
      case 'German':
        return 'de';
      case 'Spanish':
        return 'es';
      case 'Chinese':
      case 'Chinese (Simplified)':
        return 'zh';
    }

    _logger.info('TranslationRepositoryImpl: Using code as-is: $languageCode');
    return languageCode;
  }

  @override
  Future<String> translateText(
    String text,
    String sourceLanguageCode,
    String targetLanguageCode,
  ) {
    // Format the language codes for translation service
    final formattedSource = _formatTranslationLanguageCode(sourceLanguageCode);
    final formattedTarget = _formatTranslationLanguageCode(targetLanguageCode);
    _logger.info(
      'TranslationRepositoryImpl: Translating with codes: $sourceLanguageCode -> $formattedSource, $targetLanguageCode -> $formattedTarget',
    );

    return _translationDataSource.translate(
      text,
      formattedSource,
      formattedTarget,
    );
  }

  @override
  Future<void> dispose() {
    return _translationDataSource.dispose();
  }
}
