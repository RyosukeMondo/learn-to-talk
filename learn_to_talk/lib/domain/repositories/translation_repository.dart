import 'package:learn_to_talk/domain/entities/language.dart';

abstract class TranslationRepository {
  /// Initializes the translation engine
  Future<void> initTranslation();
  
  /// Returns a list of supported languages for translation
  Future<List<Language>> getTranslationLanguages();
  
  /// Checks if translation model is available offline for a language pair
  Future<bool> isModelDownloaded(String sourceLanguageCode, String targetLanguageCode);
  
  /// Downloads translation model for offline use
  Future<void> downloadModel(String sourceLanguageCode, String targetLanguageCode);
  
  /// Deletes a previously downloaded translation model
  Future<void> deleteModel(String sourceLanguageCode, String targetLanguageCode);
  
  /// Translates text from source language to target language
  Future<String> translateText(
    String text, 
    String sourceLanguageCode, 
    String targetLanguageCode
  );
  
  /// Disposes translation resources
  Future<void> dispose();
}
