import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_to_talk/domain/usecases/translation_usecase.dart';
import 'package:learn_to_talk/presentation/blocs/translation/translation_event.dart';
import 'package:learn_to_talk/presentation/blocs/translation/translation_state.dart';

class TranslationBloc extends Bloc<TranslationEvent, TranslationState> {
  final TranslationUseCase _translationUseCase;

  TranslationBloc({required TranslationUseCase translationUseCase})
      : _translationUseCase = translationUseCase,
        super(const TranslationState()) {
    on<InitializeTranslation>(_onInitializeTranslation);
    on<TranslateText>(_onTranslateText);
    on<CheckModelAvailability>(_onCheckModelAvailability);
    on<DownloadTranslationModel>(_onDownloadTranslationModel);
    on<DeleteTranslationModel>(_onDeleteTranslationModel);
  }

  Future<void> _onInitializeTranslation(
    InitializeTranslation event,
    Emitter<TranslationState> emit,
  ) async {
    try {
      emit(state.copyWith(status: TranslationStatus.loading));
      
      await _translationUseCase.initialize();
      
      emit(state.copyWith(
        status: TranslationStatus.available,
        clearErrorMessage: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TranslationStatus.error,
        errorMessage: 'Failed to initialize translation: ${e.toString()}',
      ));
    }
  }

  Future<void> _onTranslateText(
    TranslateText event,
    Emitter<TranslationState> emit,
  ) async {
    if (state.status != TranslationStatus.available && 
        state.status != TranslationStatus.completed && 
        state.status != TranslationStatus.error) {
      // Initialize first if not already available
      await _onInitializeTranslation(const InitializeTranslation(), emit);
      
      if (state.status != TranslationStatus.available) {
        // Cannot translate if translation is not available
        return;
      }
    }
    
    try {
      emit(state.copyWith(
        status: TranslationStatus.translating,
        sourceText: event.text,
        sourceLanguageCode: event.sourceLanguageCode,
        targetLanguageCode: event.targetLanguageCode,
        clearTranslatedText: true,
        clearErrorMessage: true,
      ));
      
      final translatedText = await _translationUseCase.translateText(
        event.text,
        event.sourceLanguageCode,
        event.targetLanguageCode,
      );
      
      emit(state.copyWith(
        status: TranslationStatus.completed,
        translatedText: translatedText,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TranslationStatus.error,
        errorMessage: 'Failed to translate text: ${e.toString()}',
      ));
    }
  }

  Future<void> _onCheckModelAvailability(
    CheckModelAvailability event,
    Emitter<TranslationState> emit,
  ) async {
    try {
      emit(state.copyWith(
        modelAvailability: ModelAvailability.checking,
        sourceLanguageCode: event.sourceLanguageCode,
        targetLanguageCode: event.targetLanguageCode,
      ));
      
      final isAvailable = await _translationUseCase.isModelAvailableOffline(
        event.sourceLanguageCode,
        event.targetLanguageCode,
      );
      
      emit(state.copyWith(
        modelAvailability: isAvailable 
            ? ModelAvailability.available 
            : ModelAvailability.unavailable,
      ));
    } catch (e) {
      emit(state.copyWith(
        modelAvailability: ModelAvailability.unavailable,
        errorMessage: 'Failed to check model availability: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDownloadTranslationModel(
    DownloadTranslationModel event,
    Emitter<TranslationState> emit,
  ) async {
    try {
      emit(state.copyWith(
        status: TranslationStatus.downloading,
        modelAvailability: ModelAvailability.downloading,
        sourceLanguageCode: event.sourceLanguageCode,
        targetLanguageCode: event.targetLanguageCode,
        clearErrorMessage: true,
      ));
      
      await _translationUseCase.downloadModel(
        event.sourceLanguageCode,
        event.targetLanguageCode,
      );
      
      // Check if model is now available
      final isAvailable = await _translationUseCase.isModelAvailableOffline(
        event.sourceLanguageCode,
        event.targetLanguageCode,
      );
      
      emit(state.copyWith(
        status: TranslationStatus.available,
        modelAvailability: isAvailable 
            ? ModelAvailability.available 
            : ModelAvailability.unavailable,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TranslationStatus.error,
        modelAvailability: ModelAvailability.unavailable,
        errorMessage: 'Failed to download translation model: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDeleteTranslationModel(
    DeleteTranslationModel event,
    Emitter<TranslationState> emit,
  ) async {
    try {
      emit(state.copyWith(
        modelAvailability: ModelAvailability.checking,
        sourceLanguageCode: event.sourceLanguageCode,
        targetLanguageCode: event.targetLanguageCode,
      ));
      
      await _translationUseCase.deleteModel(
        event.sourceLanguageCode,
        event.targetLanguageCode,
      );
      
      emit(state.copyWith(
        modelAvailability: ModelAvailability.unavailable,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to delete translation model: ${e.toString()}',
      ));
    }
  }

  @override
  Future<void> close() async {
    await _translationUseCase.dispose();
    return super.close();
  }
}
