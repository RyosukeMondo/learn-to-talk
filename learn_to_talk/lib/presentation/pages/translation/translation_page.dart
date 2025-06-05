import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_to_talk/domain/entities/language.dart';
import 'package:learn_to_talk/presentation/blocs/language/language_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/language/language_event.dart';
import 'package:learn_to_talk/presentation/blocs/language/language_state.dart';
import 'package:learn_to_talk/presentation/blocs/practice/practice_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/practice/practice_event.dart';
import 'package:learn_to_talk/presentation/widgets/language_dropdown.dart';
import 'package:learn_to_talk/core/features/translation/translation_widget.dart';

class TranslationPage extends StatefulWidget {
  const TranslationPage({super.key});

  @override
  State<TranslationPage> createState() => _TranslationPageState();
}

class _TranslationPageState extends State<TranslationPage> {
  bool _showSaveAsPracticeButton = false;
  String? _sourceText;
  String? _translatedText;

  @override
  void initState() {
    super.initState();
    // Load languages when the page is created
    context.read<LanguageBloc>().add(const LoadLanguages());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Translation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: _swapLanguages,
            tooltip: 'Swap languages',
          ),
        ],
      ),
      body: BlocBuilder<LanguageBloc, LanguageState>(
        builder: (context, state) {
          if (state.status == LanguageStatus.initial || 
              state.status == LanguageStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.status == LanguageStatus.error) {
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
                    state.errorMessage ?? 'An error occurred loading languages',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<LanguageBloc>().add(const LoadLanguages());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLanguageSelectors(context, state),
                const SizedBox(height: 24),
                Expanded(
                  child: _buildTranslationWidget(context, state),
                ),
                if (_showSaveAsPracticeButton) ...[
                  const SizedBox(height: 16),
                  _buildSaveAsPracticeButton(context, state),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLanguageSelectors(BuildContext context, LanguageState state) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: LanguageDropdown(
                languages: state.availableLanguages,
                selectedLanguage: state.sourceLanguage,
                onLanguageSelected: (Language language) {
                  context.read<LanguageBloc>().add(SelectSourceLanguage(language));
                },
                hintText: 'From',
                isLoading: state.status == LanguageStatus.loading,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: IconButton(
                icon: const Icon(Icons.swap_horiz),
                onPressed: _swapLanguages,
                tooltip: 'Swap languages',
              ),
            ),
            Expanded(
              child: LanguageDropdown(
                languages: state.availableLanguages,
                selectedLanguage: state.targetLanguage,
                onLanguageSelected: (Language language) {
                  context.read<LanguageBloc>().add(SelectTargetLanguage(language));
                },
                hintText: 'To',
                isLoading: state.status == LanguageStatus.loading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationWidget(BuildContext context, LanguageState state) {
    if (state.sourceLanguage == null || state.targetLanguage == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.translate,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Select source and target languages to start translating',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return TranslationWidget(
      sourceLanguageCode: state.sourceLanguage!.code,
      targetLanguageCode: state.targetLanguage!.code,
      autoFocus: true,
      onTranslationComplete: (sourceText, translatedText) {
        setState(() {
          _showSaveAsPracticeButton = true;
          _sourceText = sourceText;
          _translatedText = translatedText;
        });
      },
    );
  }

  Widget _buildSaveAsPracticeButton(BuildContext context, LanguageState state) {
    return ElevatedButton.icon(
      onPressed: () => _saveAsPractice(context, state),
      icon: const Icon(Icons.save),
      label: const Text('Save as Practice Item'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _swapLanguages() {
    final languageBloc = context.read<LanguageBloc>();
    final state = languageBloc.state;
    
    if (state.sourceLanguage != null && state.targetLanguage != null) {
      languageBloc.add(SwapLanguages());
      
      // Clear saved text when swapping languages
      setState(() {
        _showSaveAsPracticeButton = false;
        _sourceText = null;
        _translatedText = null;
      });
    }
  }

  void _saveAsPractice(BuildContext context, LanguageState state) {
    if (_sourceText != null && 
        _translatedText != null && 
        state.sourceLanguage != null && 
        state.targetLanguage != null) {
      
      context.read<PracticeBloc>().add(CreatePractice(
        sourceText: _sourceText!,
        translatedText: _translatedText!,
        sourceLanguageCode: state.sourceLanguage!.code,
        targetLanguageCode: state.targetLanguage!.code,
      ));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Practice item saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      setState(() {
        _showSaveAsPracticeButton = false;
      });
    }
  }
}
