import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:learn_to_talk/domain/entities/language.dart';
import 'package:learn_to_talk/domain/services/model_download_service.dart';
import 'package:learn_to_talk/presentation/blocs/language/language_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/language/language_event.dart';
import 'package:learn_to_talk/presentation/blocs/language/language_state.dart';
import 'package:learn_to_talk/presentation/widgets/language_dropdown.dart';
import 'package:learn_to_talk/presentation/widgets/model_download_widget.dart';

class LanguageSelectionPage extends StatefulWidget {
  final VoidCallback? onLanguagePairSelected;
  final bool showBackButton;

  const LanguageSelectionPage({
    super.key,
    this.onLanguagePairSelected,
    this.showBackButton = true,
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
        leading: widget.showBackButton ? const BackButton() : null,
        automaticallyImplyLeading: widget.showBackButton,
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

    return _buildOfflineStatusCard(context, state);
  }

  Widget _buildOfflineStatusCard(BuildContext context, LanguageState state) {
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
        return Card(
          color: Colors.green,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    state.sourceLanguage != null && state.targetLanguage != null
                        ? 'Language models for ${state.sourceLanguage!.name} and ${state.targetLanguage!.name} are available offline'
                        : 'All required language models are available offline',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
        
      case OfflineStatus.downloading:
        return Card(
          color: Colors.blue,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    state.downloadProgress ?? 'Downloading language models...',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
        
      case OfflineStatus.unavailable:
        if (state.sourceLanguage != null && state.targetLanguage != null) {
          return ModelDownloadWidget(
            sourceLanguage: state.sourceLanguage,
            targetLanguage: state.targetLanguage,
            downloadService: GetIt.instance<ModelDownloadService>(),
          );
        } else {
          return Card(
            color: Colors.orange,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Please select both languages to check offline availability'),
            ),
          );
        }
        
      case OfflineStatus.unknown:
        return const SizedBox.shrink();
    }
  }

  Widget _buildContinueButton(BuildContext context, LanguageState state) {
    final isSelectionComplete = state.sourceLanguage != null && state.targetLanguage != null;
    final bool canProceed =
        isSelectionComplete && state.offlineStatus != OfflineStatus.downloading;

    return ElevatedButton(
      onPressed: !canProceed
          ? null
          : () {
              if (widget.onLanguagePairSelected != null) {
                widget.onLanguagePairSelected!();
              }

              // If this is the settings page (has back button), go back
              // otherwise, the onLanguagePairSelected callback will handle it
              if (widget.showBackButton && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
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
