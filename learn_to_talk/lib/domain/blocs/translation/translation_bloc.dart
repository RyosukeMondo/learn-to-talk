import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:learn_to_talk/domain/usecases/translation_usecase.dart';

part 'translation_event.dart';
part 'translation_state.dart';

/// BLoC for managing translation functionality
class TranslationBloc extends Bloc<TranslationEvent, TranslationState> {
  final TranslationUseCase translationUseCase;

  TranslationBloc({required this.translationUseCase}) 
      : super(const TranslationInitial()) {
    on<TranslateText>(_onTranslateText);
    on<CheckTranslationModel>(_onCheckTranslationModel);
    on<DownloadTranslationModel>(_onDownloadTranslationModel);
    on<ClearTranslation>(_onClearTranslation);
  }

  /// Handles the TranslateText event
  Future<void> _onTranslateText(TranslateText event, Emitter<TranslationState> emit) async {
    emit(TranslationLoading(sourceText: event.text));
    
    try {
      final translatedText = await translationUseCase.translateText(
        event.text, 
        event.sourceLanguageCode, 
        event.targetLanguageCode
      );
      
      emit(TranslationSuccess(
        sourceText: event.text, 
        translatedText: translatedText,
        sourceLanguageCode: event.sourceLanguageCode,
        targetLanguageCode: event.targetLanguageCode,
      ));
    } catch (e) {
      emit(TranslationFailure(error: e.toString()));
    }
  }

  /// Handles the CheckTranslationModel event
  Future<void> _onCheckTranslationModel(CheckTranslationModel event, Emitter<TranslationState> emit) async {
    emit(TranslationModelChecking(
      sourceLanguageCode: event.sourceLanguageCode, 
      targetLanguageCode: event.targetLanguageCode
    ));
    
    try {
      final isAvailable = await translationUseCase.isModelAvailableOffline(
        event.sourceLanguageCode, 
        event.targetLanguageCode
      );
      
      if (isAvailable) {
        emit(TranslationModelAvailable(
          sourceLanguageCode: event.sourceLanguageCode, 
          targetLanguageCode: event.targetLanguageCode
        ));
      } else {
        emit(TranslationModelMissing(
          sourceLanguageCode: event.sourceLanguageCode, 
          targetLanguageCode: event.targetLanguageCode
        ));
      }
    } catch (e) {
      emit(TranslationFailure(error: e.toString()));
    }
  }

  /// Handles the DownloadTranslationModel event
  Future<void> _onDownloadTranslationModel(DownloadTranslationModel event, Emitter<TranslationState> emit) async {
    emit(TranslationModelDownloading(
      sourceLanguageCode: event.sourceLanguageCode, 
      targetLanguageCode: event.targetLanguageCode
    ));
    
    try {
      await translationUseCase.downloadModel(
        event.sourceLanguageCode, 
        event.targetLanguageCode
      );

      final result = await translationUseCase.isModelAvailableOffline(
        event.sourceLanguageCode, 
        event.targetLanguageCode
      );

      if (result) {
        emit(TranslationModelAvailable(
          sourceLanguageCode: event.sourceLanguageCode, 
          targetLanguageCode: event.targetLanguageCode
        ));
      } else {
        emit(TranslationModelDownloadFailed(
          sourceLanguageCode: event.sourceLanguageCode, 
          targetLanguageCode: event.targetLanguageCode,
          error: 'Failed to download model'
        ));
      }
    } catch (e) {
      emit(TranslationModelDownloadFailed(
        sourceLanguageCode: event.sourceLanguageCode, 
        targetLanguageCode: event.targetLanguageCode,
        error: e.toString()
      ));
    }
  }

  /// Handles the ClearTranslation event
  void _onClearTranslation(ClearTranslation event, Emitter<TranslationState> emit) {
    emit(const TranslationInitial());
  }
}
