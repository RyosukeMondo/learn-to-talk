/// This file exports all the modular features for easy import throughout the app
///
/// Import this file to access all feature components in one import statement:
/// ```dart
/// import 'package:learn_to_talk/core/features/index.dart';
/// ```
library;

// App Features (Main facade and provider)
export 'app_features.dart';
export 'app_features_provider.dart';

// Language Support Features
export 'language_support/language_selector_widget.dart';
export 'language_support/language_service.dart';

// Settings Features
export 'settings/feature_settings_controller.dart';
export 'settings/feature_toggle_widget.dart';

// Translation Features
export 'translation/translation_widget.dart';

// Text-to-Speech Features
export 'tts/text_to_speech_widget.dart';

// Speech-to-Text Features
export 'stt/speech_recognition_widget.dart';
