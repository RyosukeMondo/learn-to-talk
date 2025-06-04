import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_to_talk/domain/entities/language.dart';
import 'package:learn_to_talk/presentation/blocs/language/language_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/language/language_event.dart';
import 'package:learn_to_talk/presentation/blocs/language/language_state.dart';
import 'package:learn_to_talk/presentation/widgets/language_dropdown.dart';

class LanguageSelectionPage extends StatefulWidget {
  final VoidCallback? onLanguagePairSelected;

  const LanguageSelectionPage({
    super.key,
    this.onLanguagePairSelected,
  });

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
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
        title: const Text('Select Languages'),
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
                _buildLanguageSelectionInfo(),
                const SizedBox(height: 32),
                _buildSourceLanguageDropdown(context, state),
                const SizedBox(height: 24),
                _buildTargetLanguageDropdown(context, state),
                const Spacer(),
                _buildOfflineAvailabilityInfo(state),
                const SizedBox(height: 16),
                _buildContinueButton(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLanguageSelectionInfo() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.info_outline, color: Colors.blue, size: 32),
            SizedBox(height: 8),
            Text(
              'Select your native language (source) and the language you want to learn (target).',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceLanguageDropdown(BuildContext context, LanguageState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Language (Source):',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        LanguageDropdown(
          languages: state.availableLanguages,
          selectedLanguage: state.sourceLanguage,
          onLanguageSelected: (Language language) {
            context.read<LanguageBloc>().add(SelectSourceLanguage(language));
          },
          hintText: 'Select your language',
          isLoading: state.status == LanguageStatus.loading,
        ),
      ],
    );
  }

  Widget _buildTargetLanguageDropdown(BuildContext context, LanguageState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Language to Learn (Target):',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        LanguageDropdown(
          languages: state.availableLanguages,
          selectedLanguage: state.targetLanguage,
          onLanguageSelected: (Language language) {
            context.read<LanguageBloc>().add(SelectTargetLanguage(language));
          },
          hintText: 'Select language to learn',
          isLoading: state.status == LanguageStatus.loading,
        ),
      ],
    );
  }

  Widget _buildOfflineAvailabilityInfo(LanguageState state) {
    if (!state.isLanguagePairSelected) {
      return const SizedBox.shrink();
    }

    switch (state.offlineStatus) {
      case OfflineStatus.checking:
        return const Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Checking offline availability...'),
            ],
          ),
        );
      case OfflineStatus.available:
        return const Card(
          color: Colors.green,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All language models are available for offline use',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      case OfflineStatus.unavailable:
        return Card(
          color: Colors.orange,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Some language models need to be downloaded for offline use',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    if (state.sourceLanguage != null && state.targetLanguage != null) {
                      context.read<LanguageBloc>().add(DownloadLanguageModels(
                        sourceLanguageCode: state.sourceLanguage!.code,
                        targetLanguageCode: state.targetLanguage!.code,
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange,
                  ),
                  child: const Text('Download Models'),
                ),
              ],
            ),
          ),
        );
      case OfflineStatus.downloading:
        return const Card(
          color: Colors.blue,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Downloading language models...',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildContinueButton(BuildContext context, LanguageState state) {
    return ElevatedButton(
      onPressed: state.isLanguagePairSelected ? () {
        // Trigger the callback to navigate to the next page
        if (widget.onLanguagePairSelected != null) {
          widget.onLanguagePairSelected!();
        }
      } : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        'Continue',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
