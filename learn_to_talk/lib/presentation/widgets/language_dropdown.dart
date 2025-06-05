import 'package:flutter/material.dart';
import 'package:learn_to_talk/core/utils/language_display_util.dart';
import 'package:learn_to_talk/domain/entities/language.dart';

class LanguageDropdown extends StatelessWidget {
  final List<Language> languages;
  final Language? selectedLanguage;
  final Function(Language) onLanguageSelected;
  final String hintText;
  final bool isLoading;

  const LanguageDropdown({
    super.key,
    required this.languages,
    this.selectedLanguage,
    required this.onLanguageSelected,
    required this.hintText,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Theme.of(context).primaryColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Language>(
          isExpanded: true,
          value: selectedLanguage,
          hint: Text(hintText),
          items: languages.map((Language language) {
            return DropdownMenuItem<Language>(
              value: language,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      // Use the user-friendly name from our utility class
                      LanguageDisplayUtil.getDisplayName(language),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (language.isOfflineAvailable)
                    const Icon(
                      Icons.offline_pin,
                      color: Colors.green,
                      size: 16.0,
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: (Language? newValue) {
            if (newValue != null) {
              onLanguageSelected(newValue);
            }
          },
        ),
      ),
    );
  }
}
