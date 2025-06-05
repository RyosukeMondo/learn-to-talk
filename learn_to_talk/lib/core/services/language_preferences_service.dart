import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

class LanguagePreferencesService {
  static const String _sourceLanguageCodeKey = 'source_language_code';
  static const String _targetLanguageCodeKey = 'target_language_code';
  final Logger _logger = Logger('LanguagePreferencesService');

  // Save selected language codes
  Future<bool> saveLanguagePreferences({
    required String sourceLanguageCode,
    required String targetLanguageCode,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString(_sourceLanguageCodeKey, sourceLanguageCode);
      await prefs.setString(_targetLanguageCodeKey, targetLanguageCode);
      
      _logger.info('Saved language preferences: $sourceLanguageCode -> $targetLanguageCode');
      return true;
    } catch (e) {
      _logger.severe('Error saving language preferences: $e');
      return false;
    }
  }

  // Load saved language codes
  Future<Map<String, String?>> getLanguagePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final sourceLanguageCode = prefs.getString(_sourceLanguageCodeKey);
      final targetLanguageCode = prefs.getString(_targetLanguageCodeKey);
      
      _logger.info('Retrieved language preferences - source: $sourceLanguageCode, target: $targetLanguageCode');
      
      return {
        'sourceLanguageCode': sourceLanguageCode,
        'targetLanguageCode': targetLanguageCode,
      };
    } catch (e) {
      _logger.severe('Error retrieving language preferences: $e');
      return {
        'sourceLanguageCode': null,
        'targetLanguageCode': null,
      };
    }
  }

  // Check if language preferences are saved
  Future<bool> hasLanguagePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final hasSource = prefs.containsKey(_sourceLanguageCodeKey);
      final hasTarget = prefs.containsKey(_targetLanguageCodeKey);
      
      return hasSource && hasTarget;
    } catch (e) {
      _logger.severe('Error checking if language preferences exist: $e');
      return false;
    }
  }

  // Clear saved language preferences
  Future<bool> clearLanguagePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove(_sourceLanguageCodeKey);
      await prefs.remove(_targetLanguageCodeKey);
      
      _logger.info('Cleared language preferences');
      return true;
    } catch (e) {
      _logger.severe('Error clearing language preferences: $e');
      return false;
    }
  }
}
