import 'package:learn_to_talk/domain/entities/language.dart';

/// Utility class for displaying language names in a user-friendly format
class LanguageDisplayUtil {
  /// Maps a language code to a user-friendly display name
  static String getUserFriendlyName(String languageCode) {
    // Remove any underscores in the code and convert to lowercase for consistency
    final normalizedCode = languageCode.replaceAll('_', '-').toLowerCase();
    
    // Map of language codes to user-friendly names
    const Map<String, String> languageNameMap = {
      'en-us': 'English (US)',
      'en-gb': 'English (UK)',
      'fr-fr': 'French',
      'fr-ca': 'French (Canada)',
      'de-de': 'German',
      'es-es': 'Spanish (Spain)',
      'es-mx': 'Spanish (Mexico)',
      'it-it': 'Italian',
      'pt-br': 'Portuguese (Brazil)',
      'pt-pt': 'Portuguese (Portugal)',
      'ja-jp': 'Japanese',
      'ko-kr': 'Korean',
      'zh-cn': 'Chinese (Simplified)',
      'zh-tw': 'Chinese (Traditional)',
      'ru-ru': 'Russian',
      'ar-sa': 'Arabic',
      'nl-nl': 'Dutch',
      'pl-pl': 'Polish',
      'sv-se': 'Swedish',
      'tr-tr': 'Turkish',
      'hi-in': 'Hindi',
      'th-th': 'Thai',
      'vi-vn': 'Vietnamese',
    };
    
    // Get the user-friendly name or return the original code if not found
    return languageNameMap[normalizedCode] ?? 
           // If the full code is not found, try with just the language part (before the hyphen)
           languageNameMap[normalizedCode.split('-')[0]] ?? 
           // If still not found, use the original name but format it nicely
           _formatLanguageCode(languageCode);
  }
  
  /// Format a language code to look nicer when no mapping is found
  static String _formatLanguageCode(String code) {
    // If the code contains an underscore or hyphen, split and format
    if (code.contains('_') || code.contains('-')) {
      final parts = code.split(RegExp(r'[_-]'));
      if (parts.length >= 2) {
        // Format as "Language (Country)" if we have both parts
        try {
          final language = parts[0];
          final country = parts[1];
          
          // Capitalize the first letter of the language
          final formattedLanguage = language[0].toUpperCase() + language.substring(1).toLowerCase();
          
          return '$formattedLanguage ($country)';
        } catch (e) {
          return code; // Return original if formatting fails
        }
      }
    }
    
    // If no special formatting, just return the original
    return code;
  }
  
  /// Get a user-friendly display name for a Language object
  static String getDisplayName(Language language) {
    return getUserFriendlyName(language.code);
  }
}
