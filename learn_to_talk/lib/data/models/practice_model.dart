import 'package:learn_to_talk/domain/entities/practice.dart';

class PracticeModel extends Practice {
  const PracticeModel({
    required super.id,
    required super.sourceText,
    required super.translatedText,
    required super.sourceLanguageCode,
    required super.targetLanguageCode,
    required super.createdAt,
    super.successCount,
    super.attemptCount,
  });

  factory PracticeModel.fromJson(Map<String, dynamic> json) {
    return PracticeModel(
      id: json['id'],
      sourceText: json['sourceText'],
      translatedText: json['translatedText'],
      sourceLanguageCode: json['sourceLanguageCode'],
      targetLanguageCode: json['targetLanguageCode'],
      createdAt: DateTime.parse(json['createdAt']),
      successCount: json['successCount'],
      attemptCount: json['attemptCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceText': sourceText,
      'translatedText': translatedText,
      'sourceLanguageCode': sourceLanguageCode,
      'targetLanguageCode': targetLanguageCode,
      'createdAt': createdAt.toIso8601String(),
      'successCount': successCount,
      'attemptCount': attemptCount,
    };
  }

  factory PracticeModel.fromEntity(Practice practice) {
    return PracticeModel(
      id: practice.id,
      sourceText: practice.sourceText,
      translatedText: practice.translatedText,
      sourceLanguageCode: practice.sourceLanguageCode,
      targetLanguageCode: practice.targetLanguageCode,
      createdAt: practice.createdAt,
      successCount: practice.successCount,
      attemptCount: practice.attemptCount,
    );
  }
}
