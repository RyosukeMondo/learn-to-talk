import 'package:equatable/equatable.dart';

class Practice extends Equatable {
  final int id;
  final String sourceText;
  final String translatedText;
  final String sourceLanguageCode;
  final String targetLanguageCode;
  final DateTime createdAt;
  final int successCount;
  final int attemptCount;

  const Practice({
    required this.id,
    required this.sourceText,
    required this.translatedText,
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
    required this.createdAt,
    this.successCount = 0,
    this.attemptCount = 0,
  });

  Practice copyWith({
    int? id,
    String? sourceText,
    String? translatedText,
    String? sourceLanguageCode,
    String? targetLanguageCode,
    DateTime? createdAt,
    int? successCount,
    int? attemptCount,
  }) {
    return Practice(
      id: id ?? this.id,
      sourceText: sourceText ?? this.sourceText,
      translatedText: translatedText ?? this.translatedText,
      sourceLanguageCode: sourceLanguageCode ?? this.sourceLanguageCode,
      targetLanguageCode: targetLanguageCode ?? this.targetLanguageCode,
      createdAt: createdAt ?? this.createdAt,
      successCount: successCount ?? this.successCount,
      attemptCount: attemptCount ?? this.attemptCount,
    );
  }

  @override
  List<Object> get props => [
        id,
        sourceText,
        translatedText,
        sourceLanguageCode,
        targetLanguageCode,
        createdAt,
        successCount,
        attemptCount,
      ];
}
