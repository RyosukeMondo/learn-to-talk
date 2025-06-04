import 'package:equatable/equatable.dart';

class PracticeSession extends Equatable {
  final int id;
  final String sourceLanguageCode;
  final String targetLanguageCode;
  final DateTime timestamp;
  final int successCount;
  final int failureCount;

  const PracticeSession({
    required this.id,
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
    required this.timestamp,
    required this.successCount,
    required this.failureCount,
  });

  PracticeSession copyWith({
    int? id,
    String? sourceLanguageCode,
    String? targetLanguageCode,
    DateTime? timestamp,
    int? successCount,
    int? failureCount,
  }) {
    return PracticeSession(
      id: id ?? this.id,
      sourceLanguageCode: sourceLanguageCode ?? this.sourceLanguageCode,
      targetLanguageCode: targetLanguageCode ?? this.targetLanguageCode,
      timestamp: timestamp ?? this.timestamp,
      successCount: successCount ?? this.successCount,
      failureCount: failureCount ?? this.failureCount,
    );
  }

  @override
  List<Object> get props => [
        id,
        sourceLanguageCode,
        targetLanguageCode,
        timestamp,
        successCount,
        failureCount,
      ];
}
