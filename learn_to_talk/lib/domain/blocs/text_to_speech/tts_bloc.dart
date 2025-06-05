import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:learn_to_talk/domain/usecases/text_to_speech_usecase.dart';

part 'tts_event.dart';
part 'tts_state.dart';

/// BLoC for managing text-to-speech functionality
class TTSBloc extends Bloc<TTSEvent, TTSState> {
  final TextToSpeechUseCase _ttsUseCase;

  TTSBloc({required TextToSpeechUseCase ttsUseCase})
    : _ttsUseCase = ttsUseCase,
      super(TTSInitial()) {
    on<SpeakText>(_onSpeakText);
    on<StopSpeaking>(_onStopSpeaking);
    on<CheckVoiceData>(_onCheckVoiceData);
    on<DownloadVoiceData>(_onDownloadVoiceData);
  }

  /// Handles the SpeakText event
  Future<void> _onSpeakText(SpeakText event, Emitter<TTSState> emit) async {
    emit(TTSSpeaking(text: event.text));

    try {
      await _ttsUseCase.speak(event.text, event.languageCode);
      emit(TTSCompleted(text: event.text));
    } catch (e) {
      emit(TTSFailure(error: e.toString()));
    }
  }

  /// Handles the StopSpeaking event
  Future<void> _onStopSpeaking(
    StopSpeaking event,
    Emitter<TTSState> emit,
  ) async {
    try {
      await _ttsUseCase.stop();
      emit(TTSStopped());
    } catch (e) {
      emit(TTSFailure(error: e.toString()));
    }
  }

  /// Handles the CheckVoiceData event
  Future<void> _onCheckVoiceData(
    CheckVoiceData event,
    Emitter<TTSState> emit,
  ) async {
    emit(TTSChecking());

    try {
      final isAvailable = await _ttsUseCase.isLanguageAvailableOffline(
        event.languageCode,
      );

      if (isAvailable) {
        emit(TTSVoiceDataAvailable(languageCode: event.languageCode));
      } else {
        emit(TTSVoiceDataMissing(languageCode: event.languageCode));
      }
    } catch (e) {
      emit(TTSFailure(error: e.toString()));
    }
  }

  /// Handles the DownloadVoiceData event
  Future<void> _onDownloadVoiceData(
    DownloadVoiceData event,
    Emitter<TTSState> emit,
  ) async {
    emit(TTSDownloading(languageCode: event.languageCode));

    try {
      final downloaded = await _ttsUseCase.promptLanguageDownload(
        event.languageCode,
      );

      if (downloaded) {
        emit(TTSVoiceDataAvailable(languageCode: event.languageCode));
      } else {
        emit(TTSDownloadFailed(languageCode: event.languageCode));
      }
    } catch (e) {
      emit(TTSDownloadFailed(languageCode: event.languageCode));
    }
  }
}
