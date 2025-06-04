import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/translation/translation_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/translation/translation_event.dart';
import 'package:learn_to_talk/presentation/blocs/translation/translation_state.dart';
import 'package:learn_to_talk/presentation/widgets/text_to_speech_widget.dart';

class TranslationWidget extends StatefulWidget {
  final String sourceLanguageCode;
  final String targetLanguageCode;
  final bool autoFocus;
  final Function(String, String)? onTranslationComplete;

  const TranslationWidget({
    super.key,
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
    this.autoFocus = false,
    this.onTranslationComplete,
  });

  @override
  State<TranslationWidget> createState() => _TranslationWidgetState();
}

class _TranslationWidgetState extends State<TranslationWidget> {
  final TextEditingController _textController = TextEditingController();
  bool _hasInitiallyCheckedModel = false;

  @override
  void initState() {
    super.initState();
    // Delay to ensure bloc is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkModelAvailability();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TranslationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sourceLanguageCode != widget.sourceLanguageCode ||
        oldWidget.targetLanguageCode != widget.targetLanguageCode) {
      _checkModelAvailability();
    }
  }

  void _checkModelAvailability() {
    final translationBloc = context.read<TranslationBloc>();
    translationBloc.add(CheckModelAvailability(
      sourceLanguageCode: widget.sourceLanguageCode,
      targetLanguageCode: widget.targetLanguageCode,
    ));
    _hasInitiallyCheckedModel = true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TranslationBloc, TranslationState>(
      listenWhen: (previous, current) =>
          previous.translatedText != current.translatedText &&
          current.translatedText != null,
      listener: (context, state) {
        if (state.translatedText != null &&
            state.sourceText != null &&
            widget.onTranslationComplete != null) {
          widget.onTranslationComplete!(state.sourceText!, state.translatedText!);
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSourceTextInput(context, state),
            const SizedBox(height: 16),
            _buildTranslationArea(context, state),
            const SizedBox(height: 16),
            _buildActionButtons(context, state),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 8),
              _buildErrorMessage(state),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSourceTextInput(BuildContext context, TranslationState state) {
    return TextField(
      controller: _textController,
      autofocus: widget.autoFocus,
      decoration: InputDecoration(
        labelText: 'Enter text to translate',
        hintText: 'Type something to translate...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_textController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _textController.clear();
                },
              ),
            IconButton(
              icon: const Icon(Icons.translate),
              onPressed: _textController.text.isNotEmpty
                  ? () => _translateText(context)
                  : null,
            ),
          ],
        ),
      ),
      maxLines: 3,
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _translateText(context),
    );
  }

  Widget _buildTranslationArea(BuildContext context, TranslationState state) {
    if (state.status == TranslationStatus.translating) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.translatedText == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        width: double.infinity,
        child: Text(
          'Translation will appear here...',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  state.translatedText!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextToSpeechWidget(
                text: state.translatedText!,
                languageCode: widget.targetLanguageCode,
                compact: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, TranslationState state) {
    // Only show download button if model is not available and we've checked
    if (state.modelAvailability == ModelAvailability.unavailable && _hasInitiallyCheckedModel) {
      return ElevatedButton.icon(
        onPressed: state.modelAvailability == ModelAvailability.downloading
            ? null
            : () => _downloadModel(context),
        icon: const Icon(Icons.download),
        label: const Text('Download Translation Model for Offline Use'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildErrorMessage(TranslationState state) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        state.errorMessage!,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  void _translateText(BuildContext context) {
    if (_textController.text.isNotEmpty) {
      final translationBloc = context.read<TranslationBloc>();
      translationBloc.add(TranslateText(
        text: _textController.text,
        sourceLanguageCode: widget.sourceLanguageCode,
        targetLanguageCode: widget.targetLanguageCode,
      ));
    }
  }

  void _downloadModel(BuildContext context) {
    final translationBloc = context.read<TranslationBloc>();
    translationBloc.add(DownloadTranslationModel(
      sourceLanguageCode: widget.sourceLanguageCode,
      targetLanguageCode: widget.targetLanguageCode,
    ));
  }
}
