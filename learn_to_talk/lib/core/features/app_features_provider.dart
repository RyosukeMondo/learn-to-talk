import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_to_talk/core/features/language_support/language_service.dart';
import 'package:learn_to_talk/core/features/settings/feature_settings_controller.dart';
import 'package:provider/provider.dart';
import 'package:learn_to_talk/core/features/app_features.dart';
import 'package:learn_to_talk/domain/entities/language.dart';

/// A widget that provides all app features to its descendants.
///
/// Place this at the top of your widget tree to provide access to all
/// features throughout your app. It configures the necessary providers
/// and ensures dependencies are properly initialized.
class AppFeaturesProvider extends StatelessWidget {
  /// The child widget
  final Widget child;

  /// Available languages in the app
  final List<Language> availableLanguages;

  /// Initial source language code
  final String initialSourceLanguageCode;

  /// Initial target language code
  final String initialTargetLanguageCode;

  const AppFeaturesProvider({
    super.key,
    required this.child,
    required this.availableLanguages,
    required this.initialSourceLanguageCode,
    required this.initialTargetLanguageCode,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppFeatures.createProviders(
        availableLanguages: availableLanguages,
        initialSourceLanguageCode: initialSourceLanguageCode,
        initialTargetLanguageCode: initialTargetLanguageCode,
      ),
      child: Consumer2<LanguageService, FeatureSettingsController>(
        builder: (context, languageService, featuresController, child) {
          // Only create the bloc providers for enabled features
          return MultiBlocProvider(
            providers: AppFeatures.createBlocProviders(context),
            child: child!,
          );
        },
        child: child,
      ),
    );
  }
}
