import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

// Import blocs with aliases to avoid conflicts
import 'package:learn_to_talk/presentation/blocs/speech/speech_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/translation/translation_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/tts/tts_bloc.dart';

// Import usecase interfaces
import 'package:learn_to_talk/domain/usecases/speech_recognition_usecase.dart';
import 'package:learn_to_talk/domain/usecases/text_to_speech_usecase.dart';
import 'package:learn_to_talk/domain/usecases/translation_usecase.dart';

// Import feature modules
import 'package:learn_to_talk/core/features/language_support/language_service.dart';
import 'package:learn_to_talk/core/features/settings/feature_settings_controller.dart';
import 'package:learn_to_talk/domain/entities/language.dart';
import 'package:learn_to_talk/main.dart';

/// A facade class that provides easy access to all app features
///
/// This class follows the Facade design pattern to simplify access to the
/// various features of the app and their dependencies.
class AppFeatures {
  /// Access to language management functionality
  final LanguageService languageService;

  /// Access to feature settings management
  final FeatureSettingsController featuresController;

  /// Constructor for AppFeatures
  const AppFeatures({
    required this.languageService,
    required this.featuresController,
  });

  /// Creates all the necessary providers for app features
  ///
  /// This static method provides a central place to configure all feature providers
  /// and ensures they're properly initialized with the correct dependencies.
  static List<ChangeNotifierProvider> createProviders({
    required List<Language> availableLanguages,
    required String initialSourceLanguageCode,
    required String initialTargetLanguageCode,
  }) {
    return [
      ChangeNotifierProvider<LanguageService>(
        create:
            (_) => LanguageService(
              availableLanguages: availableLanguages,
              initialSourceLanguageCode: initialSourceLanguageCode,
              initialTargetLanguageCode: initialTargetLanguageCode,
            ),
      ),
      ChangeNotifierProvider<FeatureSettingsController>(
        create: (_) => FeatureSettingsController(),
      ),
    ];
  }

  /// Get an instance of AppFeatures from the BuildContext
  static AppFeatures of(BuildContext context) {
    return AppFeatures(
      languageService: Provider.of<LanguageService>(context, listen: false),
      featuresController: Provider.of<FeatureSettingsController>(
        context,
        listen: false,
      ),
    );
  }

  /// Conditionally create a bloc based on whether its feature is enabled
  ///
  /// This is useful for conditionally providing blocs only when their
  /// corresponding features are enabled.
  static T? createBlocIfEnabled<T>(
    BuildContext context,
    T Function() createBloc,
    bool isEnabled,
  ) {
    return isEnabled ? createBloc() : null;
  }

  /// Setup all required bloc providers for app features
  ///
  /// This method creates all the necessary bloc providers, taking into
  /// account which features are enabled based on user preferences.
  static List<BlocProvider> createBlocProviders(BuildContext context) {
    final features = AppFeatures.of(context);

    return [
      // Only create the TranslationBloc if translation is enabled
      if (features.featuresController.isTranslationEnabled)
        BlocProvider<TranslationBloc>(
          create:
              (context) => TranslationBloc(
                translationUseCase: getIt<TranslationUseCase>(),
              ),
        ),

      // Only create the SpeechBloc if speech-to-text is enabled
      if (features.featuresController.isSTTEnabled)
        BlocProvider<SpeechBloc>(
          create:
              (context) => SpeechBloc(
                speechRecognitionUseCase: getIt<SpeechRecognitionUseCase>(),
              ),
        ),

      // Only create the TTSBloc if text-to-speech is enabled
      if (features.featuresController.isTTSEnabled)
        BlocProvider<TTSBloc>(
          create: (context) => TTSBloc(ttsUseCase: getIt<TextToSpeechUseCase>()),
        ),
    ];
  }
}
