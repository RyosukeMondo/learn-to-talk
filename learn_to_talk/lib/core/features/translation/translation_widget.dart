import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/translation/translation_bloc.dart';
import 'package:learn_to_talk/presentation/blocs/translation/translation_event.dart';
import 'package:learn_to_talk/presentation/blocs/translation/translation_state.dart';
import 'package:learn_to_talk/core/features/tts/text_to_speech_widget.dart';

/// A reusable Translation widget that handles text translation between languages
///
/// This widget provides translation functionality with customizable UI options
/// and can be integrated into any screen requiring translation capabilities.
class TranslationWidget extends StatefulWidget {
  /// Source language code for translation
  final String sourceLanguageCode;
  
  /// Target language code for translation
  final String targetLanguageCode;
  
  /// Whether to autofocus the text input field
  final bool autoFocus;
  
  /// Callback when translation is completed
  final Function(String, String)? onTranslationComplete;
  
  /// Initial text to translate (optional)
  final String? initialText;
  
  /// Whether to use a compact layout
  final bool compact;
  
  /// Whether to show TTS controls for the translated text
  final bool showTTS;
  
  /// Custom style for the input text field
  final InputDecoration? inputDecoration;
  
  /// Label for the translation action button
  final String? actionButtonLabel;

  const TranslationWidget({
    super.key,
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
    this.autoFocus = false,
    this.onTranslationComplete,
    this.initialText,
    this.compact = false,
    this.showTTS = true,
    this.inputDecoration,
    this.actionButtonLabel,
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
    if (widget.initialText != null) {
      _textController.text = widget.initialText!;
    }
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
    
    if (oldWidget.initialText != widget.initialText && widget.initialText != null) {
      _textController.text = widget.initialText!;
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
        return widget.compact 
          ? _buildCompactLayout(context, state) 
          : _buildFullLayout(context, state);
      },
    );
  }
  
  /// Builds a compact translation layout with minimal UI
  Widget _buildCompactLayout(BuildContext context, TranslationState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: _textController,
            autofocus: widget.autoFocus,
            decoration: widget.inputDecoration ?? InputDecoration(
              hintText: 'Translate...',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onSubmitted: (_) => _translateText(context),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.translate),
          onPressed: _textController.text.isNotEmpty
              ? () => _translateText(context)
              : null,
        ),
        if (state.status == TranslationStatus.translating)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  /// Builds the full translation layout with all UI elements
  Widget _buildFullLayout(BuildContext context, TranslationState state) {
    return SingleChildScrollView(
      child: Column(
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSourceTextInput(BuildContext context, TranslationState state) {
    return TextField(
      controller: _textController,
      autofocus: widget.autoFocus,
      decoration: widget.inputDecoration ?? InputDecoration(
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
                  setState(() {});
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
              if (widget.showTTS)
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
      width: double.infinity,
      child: Text(
        state.errorMessage!,
        style: const TextStyle(color: Colors.red),
        textAlign: TextAlign.center,
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
