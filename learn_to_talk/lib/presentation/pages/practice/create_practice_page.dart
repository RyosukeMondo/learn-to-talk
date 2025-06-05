import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_to_talk/domain/entities/language.dart';
import 'package:learn_to_talk/presentation/blocs/language/language_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/language/language_event.dart';
import 'package:learn_to_talk/presentation/blocs/language/language_state.dart';
import 'package:learn_to_talk/presentation/blocs/practice/practice_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/practice/practice_event.dart';
import 'package:learn_to_talk/presentation/blocs/practice/practice_state.dart';
import 'package:learn_to_talk/presentation/widgets/language_dropdown.dart';
import 'package:learn_to_talk/core/features/tts/text_to_speech_widget.dart';

class CreatePracticePage extends StatefulWidget {
  final String? initialSourceLanguageCode;
  final String? initialTargetLanguageCode;

  const CreatePracticePage({
    super.key,
    this.initialSourceLanguageCode,
    this.initialTargetLanguageCode,
  });

  @override
  State<CreatePracticePage> createState() => _CreatePracticePageState();
}

class _CreatePracticePageState extends State<CreatePracticePage> {
  final TextEditingController _sourceTextController = TextEditingController();
  final TextEditingController _translatedTextController =
      TextEditingController();
  bool _isTranslationUsed = false;

  @override
  void initState() {
    super.initState();
    // Load languages when the page is created
    context.read<LanguageBloc>().add(const LoadLanguages());

    // If initial languages are provided, set them
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final languageBloc = context.read<LanguageBloc>();
      if (widget.initialSourceLanguageCode != null &&
          widget.initialTargetLanguageCode != null) {
        // Find the languages by code
        final languages = languageBloc.state.availableLanguages;
        final sourceLanguage = languages.firstWhere(
          (lang) => lang.code == widget.initialSourceLanguageCode,
          orElse: () => languages.first,
        );
        final targetLanguage = languages.firstWhere(
          (lang) => lang.code == widget.initialTargetLanguageCode,
          orElse: () => languages.first,
        );

        // Select the languages
        languageBloc.add(SelectSourceLanguage(sourceLanguage));
        languageBloc.add(SelectTargetLanguage(targetLanguage));
      }
    });
  }

  @override
  void dispose() {
    _sourceTextController.dispose();
    _translatedTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Practice Item')),
      body: BlocConsumer<PracticeBloc, PracticeState>(
        listenWhen:
            (previous, current) =>
                previous.status != current.status &&
                current.status == PracticeStatus.success,
        listener: (context, state) {
          // If practice creation was successful, navigate back
          if (state.status == PracticeStatus.success) {
            Navigator.of(context).pop();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Practice item created successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, practiceState) {
          return BlocBuilder<LanguageBloc, LanguageState>(
            builder: (context, languageState) {
              if (languageState.status == LanguageStatus.initial ||
                  languageState.status == LanguageStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (languageState.status == LanguageStatus.error) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        languageState.errorMessage ??
                            'An error occurred loading languages',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<LanguageBloc>().add(
                            const LoadLanguages(),
                          );
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildLanguageSelectors(context, languageState),
                      const SizedBox(height: 24),
                      _buildSourceTextInput(context, languageState),
                      const SizedBox(height: 24),
                      _buildTranslatedTextInput(context, languageState),
                      const SizedBox(height: 24),
                      _buildOrDivider(),
                      const SizedBox(height: 24),
                      _buildUseTranslationButton(context, languageState),
                      const SizedBox(height: 32),
                      _buildSaveButton(context, languageState, practiceState),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLanguageSelectors(BuildContext context, LanguageState state) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Languages',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your Language:'),
                      const SizedBox(height: 8),
                      LanguageDropdown(
                        languages: state.availableLanguages,
                        selectedLanguage: state.sourceLanguage,
                        onLanguageSelected: (Language language) {
                          context.read<LanguageBloc>().add(
                            SelectSourceLanguage(language),
                          );
                        },
                        hintText: 'From',
                        isLoading: state.status == LanguageStatus.loading,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.swap_horiz),
                    onPressed: () {
                      final languageBloc = context.read<LanguageBloc>();
                      languageBloc.add(SwapLanguages());
                    },
                    tooltip: 'Swap languages',
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Learning:'),
                      const SizedBox(height: 8),
                      LanguageDropdown(
                        languages: state.availableLanguages,
                        selectedLanguage: state.targetLanguage,
                        onLanguageSelected: (Language language) {
                          context.read<LanguageBloc>().add(
                            SelectTargetLanguage(language),
                          );
                        },
                        hintText: 'To',
                        isLoading: state.status == LanguageStatus.loading,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceTextInput(BuildContext context, LanguageState state) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Text in ${state.sourceLanguage?.name ?? "your language"}:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sourceTextController,
              decoration: InputDecoration(
                hintText:
                    'Enter text in ${state.sourceLanguage?.name ?? "your language"}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon:
                    _sourceTextController.text.isNotEmpty &&
                            state.sourceLanguage != null
                        ? IconButton(
                          icon: const Icon(Icons.volume_up),
                          onPressed: () {
                            // We will implement this with TTS widget
                          },
                        )
                        : null,
              ),
              maxLines: 3,
              onChanged: (text) {
                // Update text in controller (already happening via the TextField)
              },
            ),
            if (state.sourceLanguage != null &&
                _sourceTextController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextToSpeechWidget(
                  text: _sourceTextController.text,
                  languageCode: state.sourceLanguage!.code,
                  compact: true,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTranslatedTextInput(BuildContext context, LanguageState state) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Text in ${state.targetLanguage?.name ?? "target language"}:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _translatedTextController,
              decoration: InputDecoration(
                hintText:
                    'Enter text in ${state.targetLanguage?.name ?? "target language"}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon:
                    _translatedTextController.text.isNotEmpty &&
                            state.targetLanguage != null
                        ? IconButton(
                          icon: const Icon(Icons.volume_up),
                          onPressed: () {
                            // We will implement this with TTS widget
                          },
                        )
                        : null,
              ),
              maxLines: 3,
              onChanged: (text) {
                // Update text in controller (already happening via the TextField)
              },
            ),
            if (state.targetLanguage != null &&
                _translatedTextController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextToSpeechWidget(
                  text: _translatedTextController.text,
                  languageCode: state.targetLanguage!.code,
                  compact: true,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
      ],
    );
  }

  Widget _buildUseTranslationButton(BuildContext context, LanguageState state) {
    if (state.sourceLanguage == null || state.targetLanguage == null) {
      return const SizedBox.shrink();
    }

    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          _isTranslationUsed = !_isTranslationUsed;
        });
      },
      icon: const Icon(Icons.translate),
      label: Text(
        _isTranslationUsed ? 'Hide Translation Tool' : 'Use Translation Tool',
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildSaveButton(
    BuildContext context,
    LanguageState languageState,
    PracticeState practiceState,
  ) {
    final bool canSave =
        languageState.sourceLanguage != null &&
        languageState.targetLanguage != null &&
        _sourceTextController.text.isNotEmpty &&
        _translatedTextController.text.isNotEmpty;

    return ElevatedButton.icon(
      onPressed:
          canSave
              ? () => _savePractice(context, languageState, practiceState)
              : null,
      icon: const Icon(Icons.save),
      label: Text(
        practiceState.status == PracticeStatus.loading
            ? 'Saving...'
            : 'Save Practice Item',
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _savePractice(
    BuildContext context,
    LanguageState languageState,
    PracticeState practiceState,
  ) {
    if (languageState.sourceLanguage != null &&
        languageState.targetLanguage != null &&
        _sourceTextController.text.isNotEmpty &&
        _translatedTextController.text.isNotEmpty) {
      context.read<PracticeBloc>().add(
        CreatePractice(
          sourceText: _sourceTextController.text,
          translatedText: _translatedTextController.text,
          sourceLanguageCode: languageState.sourceLanguage!.code,
          targetLanguageCode: languageState.targetLanguage!.code,
        ),
      );
    }
  }
}
