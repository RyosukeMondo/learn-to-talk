import 'dart:async';
import 'package:learn_to_talk/data/datasources/tts_data_source.dart';
import 'package:learn_to_talk/domain/entities/language.dart';
import 'package:learn_to_talk/domain/repositories/tts_repository.dart';

class TTSRepositoryImpl implements TTSRepository {
  final TTSDataSource _ttsDataSource;

  TTSRepositoryImpl(this._ttsDataSource);

  @override
  Future<void> initTTS() {
    return _ttsDataSource.initialize();
  }

  @override
  Future<List<Language>> getTTSLanguages() {
    return _ttsDataSource.getTTSLanguages();
  }

  @override
  Future<bool> isLanguageAvailableForOfflineTTS(String languageCode) {
    return _ttsDataSource.isLanguageAvailableForOfflineTTS(languageCode);
  }

  @override
  Future<bool> promptLanguageInstallation(String languageCode) {
    return _ttsDataSource.promptLanguageInstallation(languageCode);
  }

  @override
  Future<void> speak(String text, String languageCode) {
    return _ttsDataSource.speak(text, languageCode);
  }

  @override
  Future<void> stop() {
    return _ttsDataSource.stop();
  }

  @override
  Stream<void> get onCompletedSpeech => _ttsDataSource.onCompletedSpeech;
}
