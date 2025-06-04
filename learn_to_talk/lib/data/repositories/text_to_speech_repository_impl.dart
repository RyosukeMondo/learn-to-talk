import 'dart:async';

import 'package:learn_to_talk/data/datasources/text_to_speech_data_source.dart';
import 'package:learn_to_talk/domain/repositories/text_to_speech_repository.dart';

class TextToSpeechRepositoryImpl implements TextToSpeechRepository {
  final TextToSpeechDataSource _dataSource;

  TextToSpeechRepositoryImpl(this._dataSource);

  @override
  Future<void> initialize() {
    return _dataSource.initialize();
  }

  @override
  Future<List<String>> getAvailableLanguages() {
    return _dataSource.getAvailableLanguages();
  }

  @override
  Future<List<String>> getAvailableVoices(String languageCode) async {
    // Convert the List<dynamic> to List<String>
    final voices = await _dataSource.getAvailableVoices(languageCode);
    return voices.map((voice) => voice['name'].toString()).toList();
  }

  @override
  Future<void> setLanguage(String languageCode) {
    return _dataSource.setLanguage(languageCode);
  }

  @override
  Future<void> setSpeechRate(double rate) {
    return _dataSource.setSpeechRate(rate);
  }

  @override
  Future<void> setPitch(double pitch) {
    return _dataSource.setPitch(pitch);
  }

  @override
  Future<void> setVolume(double volume) {
    return _dataSource.setVolume(volume);
  }

  @override
  Future<void> speak(String text, {String? languageCode, String? voiceName}) {
    return _dataSource.speak(text, languageCode: languageCode, voiceName: voiceName);
  }

  @override
  Future<void> pause() {
    return _dataSource.pause();
  }

  @override
  Future<void> stop() {
    return _dataSource.stop();
  }

  @override
  TtsState get state => _dataSource.state;

  @override
  Stream<void> get onTtsCompletion => _dataSource.onTtsCompletion;

  @override
  Stream<String> get onTtsError => _dataSource.onTtsError;

  @override
  Stream<void> get onTtsStart => _dataSource.onTtsStart;
  
  @override
  Stream<Map<String, dynamic>> get onTtsProgress => _dataSource.onTtsProgress;

  @override
  Future<void> dispose() async {
    _dataSource.dispose();
  }
}
