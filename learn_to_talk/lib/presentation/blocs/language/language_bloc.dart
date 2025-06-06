import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_to_talk/core/services/language_preferences_service.dart';
import 'package:learn_to_talk/domain/usecases/get_languages_usecase.dart';
import 'package:learn_to_talk/presentation/blocs/language/language_event.dart';
import 'package:learn_to_talk/presentation/blocs/language/language_state.dart';
import 'package:logging/logging.dart';

class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  final GetLanguagesUseCase _getLanguagesUseCase;
  final LanguagePreferencesService _languagePreferencesService;
  final Logger _logger = Logger('LanguageBloc');

  LanguageBloc({
    required GetLanguagesUseCase getLanguagesUseCase,
    required LanguagePreferencesService languagePreferencesService,
  })  : _getLanguagesUseCase = getLanguagesUseCase,
        _languagePreferencesService = languagePreferencesService,
        super(const LanguageState()) {
    // Register event handlers
    on<LoadLanguages>(_onLoadLanguages);
    on<SelectSourceLanguage>(_onSelectSourceLanguage);
    on<SelectTargetLanguage>(_onSelectTargetLanguage);
    on<CheckOfflineAvailability>(_onCheckOfflineAvailability);
    on<SwapLanguages>(_onSwapLanguages);
    
    // Register persistence event handlers
    on<SaveLanguagePreferences>(_onSaveLanguagePreferences);
    on<LoadLanguagePreferences>(_onLoadLanguagePreferences);
    
    // Load languages immediately when bloc is created
    add(LoadLanguages());
  }

  void _onLoadLanguages(
    LoadLanguages event,
    Emitter<LanguageState> emit,
  ) async {
    emit(state.copyWith(
      status: LanguageStatus.loading,
    ));

    try {
      final languages = await _getLanguagesUseCase.execute();
      emit(state.copyWith(
        availableLanguages: languages,
        status: LanguageStatus.loaded,
      ));
      
      // After languages are loaded, try to load language preferences
      add(LoadLanguagePreferences());
    } catch (e) {
      _logger.severe('Error loading languages: $e');
      emit(state.copyWith(
        status: LanguageStatus.error,
        errorMessage: 'Failed to load languages: $e',
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
    
    if (state.targetLanguage != null) {
      add(CheckOfflineAvailability(
        sourceLanguageCode: event.language.code,
        targetLanguageCode: state.targetLanguage!.code,
      ));
      
      add(SaveLanguagePreferences(
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
    
    if (state.sourceLanguage != null) {
      add(CheckOfflineAvailability(
        sourceLanguageCode: state.sourceLanguage!.code,
        targetLanguageCode: event.language.code,
      ));
      
      add(SaveLanguagePreferences(
        sourceLanguageCode: state.sourceLanguage!.code,
        targetLanguageCode: event.language.code,
      ));
    }
  }

  void _onCheckOfflineAvailability(
    CheckOfflineAvailability event,
    Emitter<LanguageState> emit,
  ) async {
    emit(state.copyWith(
      offlineStatus: OfflineStatus.checking,
    ));

    try {
      // Using the actual method name from GetLanguagesUseCase
      final isAvailableOffline = await _getLanguagesUseCase.areModelsAvailableOffline(
        event.sourceLanguageCode,
        event.targetLanguageCode,
      );

      emit(state.copyWith(
        offlineStatus: isAvailableOffline
            ? OfflineStatus.available
            : OfflineStatus.unavailable,
      ));
    } catch (e) {
      _logger.severe('Error checking offline availability: $e');
      _logger.info('Source: ${event.sourceLanguageCode}, Target: ${event.targetLanguageCode}');
      emit(state.copyWith(
        offlineStatus: OfflineStatus.unavailable,
        status: LanguageStatus.error,
        errorMessage: 'Failed to check offline availability: $e',
      ));
    }
  }

  // Download functionality is now handled by ModelDownloadWidget and ModelDownloadService

  void _onSwapLanguages(
    SwapLanguages event,
    Emitter<LanguageState> emit,
  ) {
    if (state.sourceLanguage == null || state.targetLanguage == null) {
      return;
    }

    final oldSource = state.sourceLanguage!;
    final oldTarget = state.targetLanguage!;

    emit(state.copyWith(
      sourceLanguage: oldTarget,
      targetLanguage: oldSource,
      offlineStatus: OfflineStatus.unknown,
    ));

    // Check offline availability after swapping
    add(CheckOfflineAvailability(
      sourceLanguageCode: oldTarget.code,
      targetLanguageCode: oldSource.code,
    ));
    
    // Save the swapped language preferences
    add(SaveLanguagePreferences(
      sourceLanguageCode: oldTarget.code,
      targetLanguageCode: oldSource.code,
    ));
  }

  void _onSaveLanguagePreferences(
    SaveLanguagePreferences event,
    Emitter<LanguageState> emit,
  ) async {
    try {
      // Using the correct method name from LanguagePreferencesService
      await _languagePreferencesService.saveLanguagePreferences(
        sourceLanguageCode: event.sourceLanguageCode,
        targetLanguageCode: event.targetLanguageCode,
      );
      _logger.info('Language preferences saved: ${event.sourceLanguageCode} -> ${event.targetLanguageCode}');
    } catch (e) {
      _logger.severe('Error saving language preferences: $e');
      // We don't update the state here as this is a background operation
    }
  }

  void _onLoadLanguagePreferences(
    LoadLanguagePreferences event,
    Emitter<LanguageState> emit,
  ) async {
    try {
      // Using the correct method name from LanguagePreferencesService
      final preferences = await _languagePreferencesService.getLanguagePreferences();
      
      // Check if preferences exist and if languages are loaded
      final sourceLanguageCode = preferences['sourceLanguageCode'];
      final targetLanguageCode = preferences['targetLanguageCode'];
      
      if (sourceLanguageCode == null || 
          targetLanguageCode == null ||
          state.availableLanguages.isEmpty) {
        _logger.info('No language preferences found or languages not loaded yet');
        return;
      }
      
      _logger.info('Language preferences loaded: $sourceLanguageCode -> $targetLanguageCode');
      
      // Find the language objects based on the codes stored in preferences
      final sourceLanguage = state.availableLanguages.firstWhere(
        (language) => language.code == sourceLanguageCode,
        orElse: () => state.availableLanguages.first,
      );
      
      final targetLanguage = state.availableLanguages.firstWhere(
        (language) => language.code == targetLanguageCode,
        orElse: () => state.availableLanguages.length > 1 ? state.availableLanguages[1] : state.availableLanguages.first,
      );
      
      // Update state with the loaded preferences
      emit(state.copyWith(
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        offlineStatus: OfflineStatus.unknown,
      ));
      
      // Check if the language pair is available offline
      add(CheckOfflineAvailability(
        sourceLanguageCode: sourceLanguage.code,
        targetLanguageCode: targetLanguage.code,
      ));
      
    } catch (e) {
      _logger.severe('Error loading language preferences: $e');
      // Don't update state with error as this is a background operation
    }
  }
}
