import 'dart:async';
import 'package:learn_to_talk/data/datasources/speech_data_source.dart';
import 'package:learn_to_talk/domain/entities/language.dart';
import 'package:learn_to_talk/domain/repositories/speech_repository.dart';

class SpeechRepositoryImpl implements SpeechRepository {
  final SpeechDataSource _speechDataSource;

  SpeechRepositoryImpl(this._speechDataSource);

  @override
  Future<bool> isRecognitionAvailable() {
    return _speechDataSource.isRecognitionAvailable();
  }

  @override
  Future<List<Language>> getSpeechRecognitionLanguages() {
    return _speechDataSource.getSpeechRecognitionLanguages();
  }

  @override
  Future<bool> isLanguageAvailableForOfflineRecognition(String languageCode) {
    return _speechDataSource.isLanguageAvailableForOfflineRecognition(languageCode);
  }

  @override
  Future<void> startRecognition(String languageCode) {
    return _speechDataSource.startRecognition(languageCode);
  }

  @override
  Future<void> stopRecognition() {
    return _speechDataSource.stopRecognition();
  }

  @override
  Stream<String> get recognitionResults => _speechDataSource.recognitionResults;

  @override
  Stream<String> get recognitionErrors => _speechDataSource.recognitionErrors;
}
