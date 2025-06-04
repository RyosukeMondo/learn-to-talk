import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_to_talk/domain/usecases/speech_recognition_usecase.dart';
import 'package:learn_to_talk/presentation/blocs/speech/speech_event.dart';
import 'package:learn_to_talk/presentation/blocs/speech/speech_state.dart';

class SpeechBloc extends Bloc<SpeechEvent, SpeechState> {
  final SpeechRecognitionUseCase _speechRecognitionUseCase;
  StreamSubscription? _recognitionResultsSubscription;
  StreamSubscription? _recognitionErrorsSubscription;

  SpeechBloc({required SpeechRecognitionUseCase speechRecognitionUseCase})
      : _speechRecognitionUseCase = speechRecognitionUseCase,
        super(const SpeechState()) {
    on<InitializeSpeech>(_onInitializeSpeech);
    on<StartListening>(_onStartListening);
    on<StopListening>(_onStopListening);
    on<SpeechResultReceived>(_onSpeechResultReceived);
    on<SpeechErrorReceived>(_onSpeechErrorReceived);
    
    // Listen to speech recognition streams
    _setupSpeechRecognitionListeners();
  }

  void _setupSpeechRecognitionListeners() {
    _recognitionResultsSubscription = _speechRecognitionUseCase.recognitionResults.listen(
      (result) => add(SpeechResultReceived(text: result)),
      onError: (error) => add(SpeechErrorReceived(error: error.toString())),
    );
    
    _recognitionErrorsSubscription = _speechRecognitionUseCase.recognitionErrors.listen(
      (error) => add(SpeechErrorReceived(error: error)),
    );
  }

  Future<void> _onInitializeSpeech(
    InitializeSpeech event,
    Emitter<SpeechState> emit,
  ) async {
    try {
      final isAvailable = await _speechRecognitionUseCase.isAvailable();
      
      emit(state.copyWith(
        status: isAvailable ? SpeechStatus.available : SpeechStatus.unavailable,
        errorMessage: isAvailable ? null : 'Speech recognition is not available on this device',
        clearErrorMessage: isAvailable,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SpeechStatus.error,
        errorMessage: 'Failed to initialize speech recognition: ${e.toString()}',
      ));
    }
  }

  Future<void> _onStartListening(
    StartListening event,
    Emitter<SpeechState> emit,
  ) async {
    if (state.status != SpeechStatus.available && state.status != SpeechStatus.error) {
      // Initialize first if not already available
      await _onInitializeSpeech(const InitializeSpeech(), emit);
      
      if (state.status != SpeechStatus.available) {
        // Cannot start listening if speech recognition is not available
        return;
      }
    }
    
    try {
      emit(state.copyWith(
        status: SpeechStatus.listening,
        isListening: true,
        languageCode: event.languageCode,
        clearRecognizedText: true,
        clearErrorMessage: true,
      ));
      
      await _speechRecognitionUseCase.startListening(event.languageCode);
    } catch (e) {
      emit(state.copyWith(
        status: SpeechStatus.error,
        isListening: false,
        errorMessage: 'Failed to start listening: ${e.toString()}',
      ));
    }
  }

  Future<void> _onStopListening(
    StopListening event,
    Emitter<SpeechState> emit,
  ) async {
    if (!state.isListening) return;
    
    try {
      await _speechRecognitionUseCase.stopListening();
      
      emit(state.copyWith(
        status: SpeechStatus.processing,
        isListening: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SpeechStatus.error,
        isListening: false,
        errorMessage: 'Failed to stop listening: ${e.toString()}',
      ));
    }
  }

  void _onSpeechResultReceived(
    SpeechResultReceived event,
    Emitter<SpeechState> emit,
  ) {
    emit(state.copyWith(
      status: state.isListening ? SpeechStatus.listening : SpeechStatus.available,
      recognizedText: event.text,
    ));
  }

  void _onSpeechErrorReceived(
    SpeechErrorReceived event,
    Emitter<SpeechState> emit,
  ) {
    emit(state.copyWith(
      status: SpeechStatus.error,
      errorMessage: event.error,
      isListening: false,
    ));
  }

  @override
  Future<void> close() {
    _recognitionResultsSubscription?.cancel();
    _recognitionErrorsSubscription?.cancel();
    return super.close();
  }
}
