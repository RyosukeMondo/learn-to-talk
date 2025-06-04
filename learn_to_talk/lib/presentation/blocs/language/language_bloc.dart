import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_to_talk/domain/usecases/get_languages_usecase.dart';
import 'package:learn_to_talk/domain/usecases/translation_usecase.dart';
import 'package:learn_to_talk/presentation/blocs/language/language_event.dart';
import 'package:learn_to_talk/presentation/blocs/language/language_state.dart';

class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  final GetLanguagesUseCase _getLanguagesUseCase;
  final TranslationUseCase _translationUseCase;

  LanguageBloc({
    required GetLanguagesUseCase getLanguagesUseCase,
    required TranslationUseCase translationUseCase,
  })  : _getLanguagesUseCase = getLanguagesUseCase,
        _translationUseCase = translationUseCase,
        super(const LanguageState()) {
    on<LoadLanguages>(_onLoadLanguages);
    on<SelectSourceLanguage>(_onSelectSourceLanguage);
    on<SelectTargetLanguage>(_onSelectTargetLanguage);
    on<CheckOfflineAvailability>(_onCheckOfflineAvailability);
    on<DownloadLanguageModels>(_onDownloadLanguageModels);
    on<SwapLanguages>(_onSwapLanguages);
  }

  Future<void> _onLoadLanguages(
    LoadLanguages event,
    Emitter<LanguageState> emit,
  ) async {
    try {
      print('LanguageBloc: Loading languages...');
      emit(state.copyWith(status: LanguageStatus.loading));
      
      final languages = await _getLanguagesUseCase.execute();
      print('LanguageBloc: Loaded languages count: ${languages.length}');
      if (languages.isNotEmpty) {
        languages.forEach((lang) => print('LanguageBloc: Language: ${lang.name} (${lang.code})'));
      } else {
        print('LanguageBloc: No languages were loaded!');
      }
      
      emit(state.copyWith(
        status: LanguageStatus.loaded,
        availableLanguages: languages,
      ));
    } catch (e) {
      print('LanguageBloc: Error loading languages: ${e.toString()}');
      emit(state.copyWith(
        status: LanguageStatus.error,
        errorMessage: 'Failed to load languages: ${e.toString()}',
      ));
    }
  }

  void _onSelectSourceLanguage(
    SelectSourceLanguage event,
    Emitter<LanguageState> emit,
  ) {
    emit(state.copyWith(
      sourceLanguage: event.language,
      offlineStatus: OfflineStatus.unknown,
    ));
    
    // If both languages are selected, check offline availability
    if (state.targetLanguage != null) {
      add(CheckOfflineAvailability(
        sourceLanguageCode: event.language.code,
        targetLanguageCode: state.targetLanguage!.code,
      ));
    }
  }

  void _onSelectTargetLanguage(
    SelectTargetLanguage event,
    Emitter<LanguageState> emit,
  ) {
    emit(state.copyWith(
      targetLanguage: event.language,
      offlineStatus: OfflineStatus.unknown,
    ));
    
    // If both languages are selected, check offline availability
    if (state.sourceLanguage != null) {
      add(CheckOfflineAvailability(
        sourceLanguageCode: state.sourceLanguage!.code,
        targetLanguageCode: event.language.code,
      ));
    }
  }

  Future<void> _onCheckOfflineAvailability(
    CheckOfflineAvailability event,
    Emitter<LanguageState> emit,
  ) async {
    try {
      emit(state.copyWith(offlineStatus: OfflineStatus.checking));
      
      final isAvailable = await _getLanguagesUseCase.areModelsAvailableOffline(
        event.sourceLanguageCode,
        event.targetLanguageCode,
      );
      
      emit(state.copyWith(
        offlineStatus: isAvailable ? OfflineStatus.available : OfflineStatus.unavailable,
      ));
    } catch (e) {
      emit(state.copyWith(
        offlineStatus: OfflineStatus.unavailable,
        errorMessage: 'Failed to check offline availability: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDownloadLanguageModels(
    DownloadLanguageModels event,
    Emitter<LanguageState> emit,
  ) async {
    try {
      emit(state.copyWith(offlineStatus: OfflineStatus.downloading));
      
      // Download translation model
      await _translationUseCase.downloadModel(
        event.sourceLanguageCode,
        event.targetLanguageCode,
      );
      
      // Check if all models are now available
      final isAvailable = await _getLanguagesUseCase.areModelsAvailableOffline(
        event.sourceLanguageCode,
        event.targetLanguageCode,
      );
      
      emit(state.copyWith(
        offlineStatus: isAvailable ? OfflineStatus.available : OfflineStatus.unavailable,
      ));
    } catch (e) {
      emit(state.copyWith(
        offlineStatus: OfflineStatus.unavailable,
        errorMessage: 'Failed to download language models: ${e.toString()}',
      ));
    }
  }
  
  void _onSwapLanguages(
    SwapLanguages event,
    Emitter<LanguageState> emit,
  ) {
    // Only swap if both languages are selected
    if (state.sourceLanguage != null && state.targetLanguage != null) {
      final sourceLanguage = state.sourceLanguage;
      final targetLanguage = state.targetLanguage;
      
      emit(state.copyWith(
        sourceLanguage: targetLanguage,
        targetLanguage: sourceLanguage,
        offlineStatus: OfflineStatus.unknown,
      ));
      
      // Check offline availability for the swapped language pair
      add(CheckOfflineAvailability(
        sourceLanguageCode: targetLanguage!.code,
        targetLanguageCode: sourceLanguage!.code,
      ));
    }
  }
}
