import 'package:learn_to_talk/domain/entities/practice_session.dart';

class PracticeSessionModel extends PracticeSession {
  const PracticeSessionModel({
    required super.id,
    required super.sourceLanguageCode,
    required super.targetLanguageCode,
    required super.timestamp,
    required super.successCount,
    required super.failureCount,
  });

  factory PracticeSessionModel.fromJson(Map<String, dynamic> json) {
    return PracticeSessionModel(
      id: json['id'],
      sourceLanguageCode: json['sourceLanguageCode'],
      targetLanguageCode: json['targetLanguageCode'],
      timestamp: DateTime.parse(json['timestamp']),
      successCount: json['successCount'],
      failureCount: json['failureCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceLanguageCode': sourceLanguageCode,
      'targetLanguageCode': targetLanguageCode,
      'timestamp': timestamp.toIso8601String(),
      'successCount': successCount,
      'failureCount': failureCount,
    };
  }

  factory PracticeSessionModel.fromEntity(PracticeSession session) {
    return PracticeSessionModel(
      id: session.id,
      sourceLanguageCode: session.sourceLanguageCode,
      targetLanguageCode: session.targetLanguageCode,
      timestamp: session.timestamp,
      successCount: session.successCount,
      failureCount: session.failureCount,
    );
  }
}
