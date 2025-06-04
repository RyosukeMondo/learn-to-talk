import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_to_talk/domain/usecases/text_to_speech_usecase.dart';
import 'package:learn_to_talk/presentation/blocs/tts/tts_event.dart';
import 'package:learn_to_talk/presentation/blocs/tts/tts_state.dart';

class TTSBloc extends Bloc<TTSEvent, TTSState> {
  final TextToSpeechUseCase _ttsUseCase;
  StreamSubscription? _ttsCompletionSubscription;

  TTSBloc({required TextToSpeechUseCase ttsUseCase})
      : _ttsUseCase = ttsUseCase,
        super(const TTSState()) {
    on<InitializeTTS>(_onInitializeTTS);
    on<SpeakText>(_onSpeakText);
    on<StopSpeaking>(_onStopSpeaking);
    on<CheckLanguageAvailability>(_onCheckLanguageAvailability);
    on<PromptLanguageInstallation>(_onPromptLanguageInstallation);
    on<TTSCompletionReceived>(_onTTSCompletionReceived);
    
    // Listen to TTS completion events
    _setupTTSCompletionListener();
  }

  void _setupTTSCompletionListener() {
    _ttsCompletionSubscription = _ttsUseCase.onCompletedSpeech.listen(
      (_) => add(const TTSCompletionReceived()),
    );
  }

  Future<void> _onInitializeTTS(
    InitializeTTS event,
    Emitter<TTSState> emit,
  ) async {
    try {
      await _ttsUseCase.initialize();
      
      emit(state.copyWith(
        status: TTSStatus.available,
        clearErrorMessage: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TTSStatus.error,
        errorMessage: 'Failed to initialize TTS: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSpeakText(
    SpeakText event,
    Emitter<TTSState> emit,
  ) async {
    if (state.status != TTSStatus.available && 
        state.status != TTSStatus.completed && 
        state.status != TTSStatus.error) {
      // Initialize first if not already available
      await _onInitializeTTS(const InitializeTTS(), emit);
      
      if (state.status != TTSStatus.available) {
        // Cannot start speaking if TTS is not available
        return;
      }
    }
    
    try {
      // Stop current speech if any
      if (state.isSpeaking) {
        await _ttsUseCase.stop();
      }
      
      emit(state.copyWith(
        status: TTSStatus.speaking,
        isSpeaking: true,
        currentText: event.text,
        currentLanguageCode: event.languageCode,
        clearErrorMessage: true,
      ));
      
      await _ttsUseCase.speak(event.text, event.languageCode);
    } catch (e) {
      emit(state.copyWith(
        status: TTSStatus.error,
        isSpeaking: false,
        errorMessage: 'Failed to speak text: ${e.toString()}',
      ));
    }
  }

  Future<void> _onStopSpeaking(
    StopSpeaking event,
    Emitter<TTSState> emit,
  ) async {
    if (!state.isSpeaking) return;
    
    try {
      await _ttsUseCase.stop();
      
      emit(state.copyWith(
        status: TTSStatus.available,
        isSpeaking: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TTSStatus.error,
        isSpeaking: false,
        errorMessage: 'Failed to stop speaking: ${e.toString()}',
      ));
    }
  }

  Future<void> _onCheckLanguageAvailability(
    CheckLanguageAvailability event,
    Emitter<TTSState> emit,
  ) async {
    try {
      final isAvailable = await _ttsUseCase.isLanguageAvailableOffline(event.languageCode);
      
      emit(state.copyWith(
        isLanguageAvailableOffline: isAvailable,
        currentLanguageCode: event.languageCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TTSStatus.error,
        errorMessage: 'Failed to check language availability: ${e.toString()}',
      ));
    }
  }

  Future<void> _onPromptLanguageInstallation(
    PromptLanguageInstallation event,
    Emitter<TTSState> emit,
  ) async {
    try {
      final success = await _ttsUseCase.promptLanguageDownload(event.languageCode);
      
      if (success) {
        emit(state.copyWith(
          isLanguageAvailableOffline: true,
          currentLanguageCode: event.languageCode,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: TTSStatus.error,
        errorMessage: 'Failed to prompt language installation: ${e.toString()}',
      ));
    }
  }

  void _onTTSCompletionReceived(
    TTSCompletionReceived event,
    Emitter<TTSState> emit,
  ) {
    emit(state.copyWith(
      status: TTSStatus.completed,
      isSpeaking: false,
    ));
  }

  @override
  Future<void> close() {
    _ttsCompletionSubscription?.cancel();
    return super.close();
  }
}
