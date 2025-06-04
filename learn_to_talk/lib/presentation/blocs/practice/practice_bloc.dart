import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_to_talk/domain/usecases/practice_usecase.dart';
import 'package:learn_to_talk/domain/usecases/speech_recognition_usecase.dart';
import 'package:learn_to_talk/presentation/blocs/practice/practice_event.dart';
import 'package:learn_to_talk/presentation/blocs/practice/practice_state.dart';

class PracticeBloc extends Bloc<PracticeEvent, PracticeState> {
  final PracticeUseCase _practiceUseCase;
  final SpeechRecognitionUseCase _speechRecognitionUseCase;

  PracticeBloc({
    required PracticeUseCase practiceUseCase,
    required SpeechRecognitionUseCase speechRecognitionUseCase,
  })  : _practiceUseCase = practiceUseCase,
        _speechRecognitionUseCase = speechRecognitionUseCase,
        super(const PracticeState()) {
    on<LoadPractices>(_onLoadPractices);
    on<StartPracticeSession>(_onStartPracticeSession);
    on<CreatePractice>(_onCreatePractice);
    on<EvaluatePracticeAttempt>(_onEvaluatePracticeAttempt);
    on<LoadPracticeStatistics>(_onLoadPracticeStatistics);
  }

  Future<void> _onLoadPractices(
    LoadPractices event,
    Emitter<PracticeState> emit,
  ) async {
    try {
      emit(state.copyWith(status: PracticeStatus.loading));
      
      final practices = await _practiceUseCase.getPractices(
        event.sourceLanguageCode,
        event.targetLanguageCode,
      );
      
      emit(state.copyWith(
        status: PracticeStatus.loaded,
        practices: practices,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PracticeStatus.error,
        errorMessage: 'Failed to load practices: ${e.toString()}',
      ));
    }
  }

  Future<void> _onStartPracticeSession(
    StartPracticeSession event,
    Emitter<PracticeState> emit,
  ) async {
    try {
      final sessionId = await _practiceUseCase.startPracticeSession(
        event.sourceLanguageCode,
        event.targetLanguageCode,
      );
      
      emit(state.copyWith(
        currentSessionId: sessionId,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PracticeStatus.error,
        errorMessage: 'Failed to start practice session: ${e.toString()}',
      ));
    }
  }

  Future<void> _onCreatePractice(
    CreatePractice event,
    Emitter<PracticeState> emit,
  ) async {
    try {
      emit(state.copyWith(status: PracticeStatus.loading));
      
      final practiceId = await _practiceUseCase.savePractice(
        sourceText: event.sourceText,
        translatedText: event.translatedText,
        sourceLanguageCode: event.sourceLanguageCode,
        targetLanguageCode: event.targetLanguageCode,
      );
      
      // Reload practices to include the new one
      final practices = await _practiceUseCase.getPractices(
        event.sourceLanguageCode,
        event.targetLanguageCode,
      );
      
      emit(state.copyWith(
        status: PracticeStatus.loaded,
        practices: practices,
        currentPracticeId: practiceId,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PracticeStatus.error,
        errorMessage: 'Failed to create practice: ${e.toString()}',
      ));
    }
  }

  Future<void> _onEvaluatePracticeAttempt(
    EvaluatePracticeAttempt event,
    Emitter<PracticeState> emit,
  ) async {
    try {
      emit(state.copyWith(status: PracticeStatus.evaluating));
      
      // Calculate similarity score
      final similarityScore = _speechRecognitionUseCase.validateSpeech(
        event.spokenText,
        event.expectedText,
      );
      
      // Get detailed feedback
      final feedbackDetails = _speechRecognitionUseCase.getDetailedFeedback(
        event.spokenText,
        event.expectedText,
      );
      
      // Determine if the attempt was successful (e.g., score > 0.7)
      final isSuccess = similarityScore >= 0.7;
      
      // Update practice statistics
      await _practiceUseCase.updatePracticeStatistics(
        event.practiceId,
        isSuccess,
      );
      
      // Update session statistics
      await _practiceUseCase.updateSessionStatistics(
        event.sessionId,
        isSuccess,
      );
      
      emit(state.copyWith(
        status: isSuccess ? PracticeStatus.success : PracticeStatus.failure,
        similarityScore: similarityScore,
        feedbackDetails: feedbackDetails,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PracticeStatus.error,
        errorMessage: 'Failed to evaluate practice attempt: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLoadPracticeStatistics(
    LoadPracticeStatistics event,
    Emitter<PracticeState> emit,
  ) async {
    try {
      emit(state.copyWith(status: PracticeStatus.loading));
      
      final statistics = await _practiceUseCase.getStatistics(
        event.sourceLanguageCode,
        event.targetLanguageCode,
      );
      
      emit(state.copyWith(
        status: PracticeStatus.loaded,
        statistics: statistics,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PracticeStatus.error,
        errorMessage: 'Failed to load statistics: ${e.toString()}',
      ));
    }
  }
}
