import 'package:learn_to_talk/domain/repositories/translation_repository.dart';

class TranslationUseCase {
  final TranslationRepository _translationRepository;

  TranslationUseCase({required TranslationRepository translationRepository})
      : _translationRepository = translationRepository;

  /// Initialize the translation engine
  Future<void> initialize() async {
    await _translationRepository.initTranslation();
  }

  /// Translate text from source language to target language
  Future<String> translateText(
    String text,
    String sourceLanguageCode,
    String targetLanguageCode,
  ) async {
    return await _translationRepository.translateText(
      text,
      sourceLanguageCode,
      targetLanguageCode,
    );
  }

  /// Check if translation model is available offline
  Future<bool> isModelAvailableOffline(
    String sourceLanguageCode,
    String targetLanguageCode,
  ) async {
    return await _translationRepository.isModelDownloaded(
      sourceLanguageCode,
      targetLanguageCode,
    );
  }

  /// Download translation model for offline use
  Future<void> downloadModel(
    String sourceLanguageCode,
    String targetLanguageCode,
  ) async {
    await _translationRepository.downloadModel(
      sourceLanguageCode,
      targetLanguageCode,
    );
  }

  /// Delete translation model to free up space
  Future<void> deleteModel(
    String sourceLanguageCode,
    String targetLanguageCode,
  ) async {
    await _translationRepository.deleteModel(
      sourceLanguageCode,
      targetLanguageCode,
    );
  }

  /// Clean up resources
  Future<void> dispose() async {
    await _translationRepository.dispose();
  }
}
