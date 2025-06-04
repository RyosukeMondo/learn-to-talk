import 'package:equatable/equatable.dart';

abstract class PracticeEvent extends Equatable {
  const PracticeEvent();

  @override
  List<Object?> get props => [];
}

class LoadPractices extends PracticeEvent {
  final String sourceLanguageCode;
  final String targetLanguageCode;

  const LoadPractices({
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
  });

  @override
  List<Object> get props => [sourceLanguageCode, targetLanguageCode];
}

class StartPracticeSession extends PracticeEvent {
  final String sourceLanguageCode;
  final String targetLanguageCode;

  const StartPracticeSession({
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
  });

  @override
  List<Object> get props => [sourceLanguageCode, targetLanguageCode];
}

class CreatePractice extends PracticeEvent {
  final String sourceText;
  final String translatedText;
  final String sourceLanguageCode;
  final String targetLanguageCode;

  const CreatePractice({
    required this.sourceText,
    required this.translatedText,
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
  });

  @override
  List<Object> get props => [
        sourceText,
        translatedText,
        sourceLanguageCode,
        targetLanguageCode,
      ];
}

class EvaluatePracticeAttempt extends PracticeEvent {
  final int practiceId;
  final String spokenText;
  final String expectedText;
  final int sessionId;

  const EvaluatePracticeAttempt({
    required this.practiceId,
    required this.spokenText,
    required this.expectedText,
    required this.sessionId,
  });

  @override
  List<Object> get props => [practiceId, spokenText, expectedText, sessionId];
}

class LoadPracticeStatistics extends PracticeEvent {
  final String sourceLanguageCode;
  final String targetLanguageCode;

  const LoadPracticeStatistics({
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
  });

  @override
  List<Object> get props => [sourceLanguageCode, targetLanguageCode];
}
