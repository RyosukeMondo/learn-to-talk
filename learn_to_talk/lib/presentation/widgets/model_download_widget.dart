import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_to_talk/domain/entities/language.dart';
import 'package:learn_to_talk/domain/services/model_download_service.dart';
import 'package:learn_to_talk/presentation/blocs/language/language_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/language/language_event.dart';

/// A dedicated widget for handling model downloads
/// This widget encapsulates all the UI and logic related to downloading language models
class ModelDownloadWidget extends StatefulWidget {
  final Language? sourceLanguage;
  final Language? targetLanguage;
  final ModelDownloadService downloadService;

  const ModelDownloadWidget({
    super.key,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.downloadService,
  });

  @override
  State<ModelDownloadWidget> createState() => _ModelDownloadWidgetState();
}

class _ModelDownloadWidgetState extends State<ModelDownloadWidget> {
  bool _isLoading = false;
  String _statusMessage = '';
  ModelRequirements? _requirements;

  @override
  void initState() {
    super.initState();
    _checkModelRequirements();
  }

  @override
  void didUpdateWidget(ModelDownloadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check for language changes
    if (oldWidget.sourceLanguage?.code != widget.sourceLanguage?.code ||
        oldWidget.targetLanguage?.code != widget.targetLanguage?.code) {
      _checkModelRequirements();
    }
  }

  Future<void> _checkModelRequirements() async {
    if (widget.sourceLanguage == null || widget.targetLanguage == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking model requirements...';
    });

    try {
      final requirements = await widget.downloadService.getRequiredDownloads(
        widget.sourceLanguage!,
        widget.targetLanguage!,
      );

      setState(() {
        _requirements = requirements;
        _isLoading = false;
        _statusMessage = requirements.hasRequirements
            ? 'Some components need to be downloaded'
            : 'All models are available for offline use';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error checking model availability: $e';
      });
    }
  }

  Future<void> _downloadTranslationModels() async {
    if (widget.sourceLanguage == null || widget.targetLanguage == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await widget.downloadService.downloadTranslationModels(
      widget.sourceLanguage!.code,
      widget.targetLanguage!.code,
      (message) {
        setState(() {
          _statusMessage = message;
        });
      },
    );

    if (success) {
      // Refresh the requirements
      await _checkModelRequirements();
      
      // Update the language bloc state
      if (mounted) {
        context.read<LanguageBloc>().add(
              CheckOfflineAvailability(
                sourceLanguageCode: widget.sourceLanguage!.code,
                targetLanguageCode: widget.targetLanguage!.code,
              ),
            );
      }
    } else {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Failed to download models. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_requirements == null || !_requirements!.hasRequirements) {
      return const SizedBox.shrink(); // Don't show anything if no models are needed
    }

    return Card(
      color: Colors.orange,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_download, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (_requirements != null && _requirements!.hasRequirements) ...[
              const SizedBox(height: 8),
              Text(
                'For complete offline use, you need:',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              if (_requirements!.needsTranslationModels)
                _RequirementItem(
                  text: 'Translation models for ${_requirements!.sourceLanguage.name} ↔ ${_requirements!.targetLanguage.name}',
                ),
              if (_requirements!.needsSpeechRecognition)
                _RequirementItem(
                  text: 'Speech recognition for ${_requirements!.sourceLanguage.name}',
                ),
              if (_requirements!.needsSourceTts)
                _RequirementItem(
                  text: 'Text-to-speech for ${_requirements!.sourceLanguage.name}',
                ),
              if (_requirements!.needsTargetTts)
                _RequirementItem(
                  text: 'Text-to-speech for ${_requirements!.targetLanguage.name}',
                ),
            ],
            const SizedBox(height: 16),
            if (_requirements?.needsTranslationModels == true) ...[
              ElevatedButton(
                onPressed: _isLoading ? null : _downloadTranslationModels,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.orange,
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(Colors.orange),
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Downloading...'),
                        ],
                      )
                    : const Text('Download Translation Models'),
              ),
            ],
            if (_requirements?.needsSpeechRecognition == true ||
                _requirements?.needsSourceTts == true ||
                _requirements?.needsTargetTts == true) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  // Show instructions for downloading other models through device settings
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Download Other Models'),
                      content: const Text(
                        'Speech recognition and text-to-speech models need to be downloaded '
                        'through your device settings. Go to Settings > System > Languages & input > '
                        'Text-to-speech output and Speech recognition to download additional language models.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'How to download speech and TTS models?',
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RequirementItem extends StatelessWidget {
  final String text;

  const _RequirementItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.white70, fontSize: 12)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
