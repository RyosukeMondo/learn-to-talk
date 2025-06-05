import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:learn_to_talk/domain/usecases/speech_recognition_usecase.dart';

part 'speech_event.dart';
part 'speech_state.dart';

/// BLoC for managing speech recognition state and events
class SpeechBloc extends Bloc<SpeechEvent, SpeechState> {
  final SpeechRecognitionUseCase speechRecognitionUseCase;
  StreamSubscription? _resultSubscription;
  StreamSubscription? _errorSubscription;

  SpeechBloc({required this.speechRecognitionUseCase})
      : super(const SpeechInitial()) {
    on<StartListening>(_onStartListening);
    on<StopListening>(_onStopListening);
    on<RecognizedSpeech>(_onRecognizedSpeech);
    on<SpeechError>(_onSpeechError);
    
    // Listen to the recognition results stream
    _resultSubscription = speechRecognitionUseCase.recognitionResults.listen(
      (result) => add(RecognizedSpeech(result)),
    );
    
    // Listen to the recognition errors stream
    _errorSubscription = speechRecognitionUseCase.recognitionErrors.listen(
      (error) => add(SpeechError(error)),
    );
  }

  /// Handles the StartListening event
  Future<void> _onStartListening(StartListening event, Emitter<SpeechState> emit) async {
    emit(const SpeechListening());
    
    try {
      await speechRecognitionUseCase.startListening(event.languageCode);
    } catch (e) {
      add(SpeechError(e.toString()));
    }
  }

  /// Handles the StopListening event
  Future<void> _onStopListening(StopListening event, Emitter<SpeechState> emit) async {
    await speechRecognitionUseCase.stopListening();
    emit(SpeechNotListening(finalText: state is SpeechRecognized ? (state as SpeechRecognized).text : ''));
  }

  /// Handles the RecognizedSpeech event
  void _onRecognizedSpeech(RecognizedSpeech event, Emitter<SpeechState> emit) {
    emit(SpeechRecognized(text: event.text));
  }

  /// Handles the SpeechError event
  void _onSpeechError(SpeechError event, Emitter<SpeechState> emit) {
    emit(SpeechFailure(error: event.error));
  }
  
  @override
  Future<void> close() async {
    await _resultSubscription?.cancel();
    await _errorSubscription?.cancel();
    return super.close();
  }
}
