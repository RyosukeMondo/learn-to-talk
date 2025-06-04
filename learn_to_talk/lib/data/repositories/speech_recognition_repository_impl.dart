import 'dart:async';

import 'package:learn_to_talk/data/datasources/speech_recognition_data_source.dart' as data_source;
import 'package:learn_to_talk/domain/repositories/speech_recognition_repository.dart';

class SpeechRecognitionRepositoryImpl implements SpeechRecognitionRepository {
  final data_source.SpeechRecognitionDataSource _dataSource;

  SpeechRecognitionRepositoryImpl(this._dataSource);

  @override
  Future<void> initialize() {
    return _dataSource.initialize();
  }

  @override
  Future<List<String>> getAvailableLanguages() {
    return _dataSource.getAvailableLanguages();
  }

  @override
  Future<bool> startListening(String languageCode) {
    return _dataSource.startListening(languageCode);
  }

  @override
  Future<void> stopListening() {
    return _dataSource.stopListening();
  }

  @override
  bool isListening() {
    return _dataSource.isListening();
  }

  @override
  Stream<RecognitionResult> get recognitionResults => _dataSource.recognitionResults
      .map((data_source.RecognitionResult result) => RecognitionResult(
            recognizedWords: result.recognizedWords,
            finalResult: result.finalResult,
            confidence: result.confidence,
          ));

  @override
  Stream<String> get recognitionErrors => _dataSource.recognitionErrors;

  @override
  Stream<bool> get listeningStatus => _dataSource.listeningStatus;

  @override
  Future<void> dispose() {
    return _dataSource.dispose();
  }
}
