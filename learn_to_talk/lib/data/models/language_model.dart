import 'package:learn_to_talk/domain/entities/language.dart';

class LanguageModel extends Language {
  const LanguageModel({
    required super.code,
    required super.name,
    required super.isOfflineAvailable,
  });

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
      code: json['code'],
      name: json['name'],
      isOfflineAvailable: json['isOfflineAvailable'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'isOfflineAvailable': isOfflineAvailable ? 1 : 0,
    };
  }

  factory LanguageModel.fromEntity(Language language) {
    return LanguageModel(
      code: language.code,
      name: language.name,
      isOfflineAvailable: language.isOfflineAvailable,
    );
  }
}
