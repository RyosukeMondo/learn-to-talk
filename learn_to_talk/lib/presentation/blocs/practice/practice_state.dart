import 'package:equatable/equatable.dart';
import 'package:learn_to_talk/domain/entities/practice.dart';

enum PracticeStatus { initial, loading, loaded, evaluating, success, failure, error }

class PracticeState extends Equatable {
  final PracticeStatus status;
  final List<Practice> practices;
  final int? currentSessionId;
  final int? currentPracticeId;
  final Map<String, dynamic>? feedbackDetails;
  final double? similarityScore;
  final Map<String, dynamic>? statistics;
  final String? errorMessage;

  const PracticeState({
    this.status = PracticeStatus.initial,
    this.practices = const [],
    this.currentSessionId,
    this.currentPracticeId,
    this.feedbackDetails,
    this.similarityScore,
    this.statistics,
    this.errorMessage,
  });

  PracticeState copyWith({
    PracticeStatus? status,
    List<Practice>? practices,
    int? currentSessionId,
    bool clearCurrentSessionId = false,
    int? currentPracticeId,
    bool clearCurrentPracticeId = false,
    Map<String, dynamic>? feedbackDetails,
    bool clearFeedbackDetails = false,
    double? similarityScore,
    bool clearSimilarityScore = false,
    Map<String, dynamic>? statistics,
    bool clearStatistics = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return PracticeState(
      status: status ?? this.status,
      practices: practices ?? this.practices,
      currentSessionId: clearCurrentSessionId ? null : currentSessionId ?? this.currentSessionId,
      currentPracticeId: clearCurrentPracticeId ? null : currentPracticeId ?? this.currentPracticeId,
      feedbackDetails: clearFeedbackDetails ? null : feedbackDetails ?? this.feedbackDetails,
      similarityScore: clearSimilarityScore ? null : similarityScore ?? this.similarityScore,
      statistics: clearStatistics ? null : statistics ?? this.statistics,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        practices,
        currentSessionId,
        currentPracticeId,
        feedbackDetails,
        similarityScore,
        statistics,
        errorMessage,
      ];
}
