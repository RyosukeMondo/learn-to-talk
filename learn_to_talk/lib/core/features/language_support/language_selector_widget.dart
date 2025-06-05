import 'package:flutter/material.dart';
import 'package:learn_to_talk/domain/entities/language.dart';

/// A reusable widget for selecting languages throughout the app
///
/// This widget provides a consistent interface for language selection
/// and can be configured with different appearances and behaviors.
class LanguageSelectorWidget extends StatelessWidget {
  /// The list of available languages to choose from
  final List<Language> availableLanguages;

  /// The currently selected language code
  final String selectedLanguageCode;

  /// Callback when a language is selected
  final Function(String) onLanguageSelected;

  /// Whether to show the language name, flag, or both
  final LanguageSelectorDisplayMode displayMode;

  /// Whether to use a compact dropdown or expanded selector
  final bool compact;

  /// Optional title to display above the selector
  final String? title;

  const LanguageSelectorWidget({
    super.key,
    required this.availableLanguages,
    required this.selectedLanguageCode,
    required this.onLanguageSelected,
    this.displayMode = LanguageSelectorDisplayMode.nameAndFlag,
    this.compact = true,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
        ],
        compact
            ? _buildCompactSelector(context)
            : _buildExpandedSelector(context),
      ],
    );
  }

  Widget _buildCompactSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedLanguageCode,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          items:
              availableLanguages.map((language) {
                return DropdownMenuItem<String>(
                  value: language.languageCode,
                  child: _buildLanguageItem(language),
                );
              }).toList(),
          onChanged: (value) {
            if (value != null) {
              onLanguageSelected(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildExpandedSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...availableLanguages.map((language) {
            final isSelected = language.languageCode == selectedLanguageCode;
            return InkWell(
              onTap: () {
                onLanguageSelected(language.languageCode);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildLanguageItem(language),
                    const Spacer(),
                    if (isSelected)
                      Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLanguageItem(Language language) {
    switch (displayMode) {
      case LanguageSelectorDisplayMode.nameOnly:
        return Text(language.name);
      case LanguageSelectorDisplayMode.flagOnly:
        return Text(language.flag);
      case LanguageSelectorDisplayMode.nameAndFlag:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(language.flag),
            const SizedBox(width: 8),
            Text(language.name),
          ],
        );
    }
  }
}

/// Display mode for language selector
enum LanguageSelectorDisplayMode {
  /// Show only language name
  nameOnly,

  /// Show only language flag
  flagOnly,

  /// Show both language name and flag
  nameAndFlag,
}
