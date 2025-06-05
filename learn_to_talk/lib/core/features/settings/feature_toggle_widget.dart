import 'package:flutter/material.dart';
import 'package:learn_to_talk/core/features/settings/feature_settings_controller.dart';
import 'package:provider/provider.dart';

/// A widget for toggling app features on and off
///
/// This widget provides UI controls for enabling/disabling various app features
/// like translation, speech recognition, and text-to-speech.
class FeatureToggleWidget extends StatelessWidget {
  /// The specific feature to toggle
  final FeatureType featureType;
  
  /// Optional custom icon for the feature
  final IconData? icon;
  
  /// Optional custom label for the feature
  final String? label;
  
  /// Whether to show a label next to the switch
  final bool showLabel;
  
  /// Callback when the feature is toggled
  final Function(bool)? onToggle;

  const FeatureToggleWidget({
    super.key, 
    required this.featureType,
    this.icon,
    this.label,
    this.showLabel = true,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FeatureSettingsController>(
      builder: (context, settings, _) {
        final isEnabled = _isFeatureEnabled(settings);
        
        return Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isEnabled ? Theme.of(context).primaryColor : Colors.grey,
              ),
              const SizedBox(width: 8),
            ],
            if (showLabel) ...[
              Expanded(
                child: Text(
                  label ?? _getDefaultLabel(),
                  style: TextStyle(
                    color: isEnabled ? null : Colors.grey,
                  ),
                ),
              ),
            ],
            Switch(
              value: isEnabled,
              onChanged: (value) {
                _toggleFeature(settings, value);
                if (onToggle != null) {
                  onToggle!(value);
                }
              },
            ),
          ],
        );
      },
    );
  }
  
  
  /// Gets the default label for the feature
  String _getDefaultLabel() {
    switch (featureType) {
      case FeatureType.translation:
        return 'Translation';
      case FeatureType.speechToText:
        return 'Speech Recognition';
      case FeatureType.textToSpeech:
        return 'Text-to-Speech';
      case FeatureType.languageSwitcher:
        return 'Language Selection';
    }
  }
  
  /// Checks if the specific feature is enabled
  bool _isFeatureEnabled(FeatureSettingsController settings) {
    switch (featureType) {
      case FeatureType.translation:
        return settings.isTranslationEnabled;
      case FeatureType.speechToText:
        return settings.isSTTEnabled;
      case FeatureType.textToSpeech:
        return settings.isTTSEnabled;
      case FeatureType.languageSwitcher:
        return settings.isLanguageSwitcherEnabled;
    }
  }
  
  /// Toggles the specific feature
  void _toggleFeature(FeatureSettingsController settings, bool value) {
    switch (featureType) {
      case FeatureType.translation:
        settings.setTranslationEnabled(value);
        break;
      case FeatureType.speechToText:
        settings.setSTTEnabled(value);
        break;
      case FeatureType.textToSpeech:
        settings.setTTSEnabled(value);
        break;
      case FeatureType.languageSwitcher:
        settings.setLanguageSwitcherEnabled(value);
        break;
    }
  }
}

/// Available feature types in the app
enum FeatureType {
  /// Translation feature
  translation,
  
  /// Speech-to-Text feature
  speechToText,
  
  /// Text-to-Speech feature
  textToSpeech,
  
  /// Language Switcher UI
  languageSwitcher,
}
