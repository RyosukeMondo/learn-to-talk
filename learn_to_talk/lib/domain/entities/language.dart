import 'package:equatable/equatable.dart';

/// Represents a language in the application
class Language extends Equatable {
  /// The language code (e.g., 'en-US', 'fr-FR')
  final String code;
  
  /// The display name of the language
  final String name;
  
  /// Whether the language is available offline
  final bool isOfflineAvailable;
  
  /// The flag emoji for the language
  final String flag;

  const Language({
    required this.code,
    required this.name,
    required this.isOfflineAvailable,
    this.flag = '',
  });

  /// Getter for languageCode to maintain compatibility with existing code
  String get languageCode => code;

  @override
  List<Object> get props => [code, name, isOfflineAvailable, flag];
}
