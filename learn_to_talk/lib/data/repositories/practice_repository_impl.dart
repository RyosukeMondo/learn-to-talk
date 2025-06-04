import 'package:learn_to_talk/data/datasources/practice_data_source.dart';
import 'package:learn_to_talk/data/models/practice_model.dart';
import 'package:learn_to_talk/data/models/practice_session_model.dart';
import 'package:learn_to_talk/domain/entities/practice.dart';
import 'package:learn_to_talk/domain/entities/practice_session.dart';
import 'package:learn_to_talk/domain/repositories/practice_repository.dart';

class PracticeRepositoryImpl implements PracticeRepository {
  final PracticeDataSource _practiceDataSource;

  PracticeRepositoryImpl(this._practiceDataSource);

  @override
  Future<List<Practice>> getPractices(String sourceLanguageCode, String targetLanguageCode) async {
    final practiceModels = await _practiceDataSource.getPractices(sourceLanguageCode, targetLanguageCode);
    return practiceModels;
  }

  @override
  Future<Practice?> getPracticeById(int id) async {
    return await _practiceDataSource.getPracticeById(id);
  }

  @override
  Future<int> savePractice(Practice practice) async {
    final practiceModel = PracticeModel.fromEntity(practice);
    return await _practiceDataSource.insertPractice(practiceModel);
  }

  @override
  Future<void> updatePractice(Practice practice) async {
    final practiceModel = PracticeModel.fromEntity(practice);
    await _practiceDataSource.updatePractice(practiceModel);
  }

  @override
  Future<void> deletePractice(int id) async {
    await _practiceDataSource.deletePractice(id);
  }

  @override
  Future<List<PracticeSession>> getPracticeSessions() async {
    final sessionModels = await _practiceDataSource.getPracticeSessions();
    return sessionModels;
  }

  @override
  Future<int> savePracticeSession(PracticeSession session) async {
    final sessionModel = PracticeSessionModel.fromEntity(session);
    return await _practiceDataSource.insertPracticeSession(sessionModel);
  }

  @override
  Future<void> updatePracticeSession(PracticeSession session) async {
    final sessionModel = PracticeSessionModel.fromEntity(session);
    await _practiceDataSource.updatePracticeSession(sessionModel);
  }

  @override
  Future<Map<String, dynamic>> getStatistics(String sourceLanguageCode, String targetLanguageCode) async {
    return await _practiceDataSource.getStatistics(sourceLanguageCode, targetLanguageCode);
  }
}
