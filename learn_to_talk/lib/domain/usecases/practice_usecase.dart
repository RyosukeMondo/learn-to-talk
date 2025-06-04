import 'package:learn_to_talk/domain/entities/practice.dart';
import 'package:learn_to_talk/domain/entities/practice_session.dart';
import 'package:learn_to_talk/domain/repositories/practice_repository.dart';

class PracticeUseCase {
  final PracticeRepository _practiceRepository;

  PracticeUseCase({required PracticeRepository practiceRepository})
      : _practiceRepository = practiceRepository;

  /// Get all practice items for a specific language pair
  Future<List<Practice>> getPractices(String sourceLanguageCode, String targetLanguageCode) async {
    return await _practiceRepository.getPractices(sourceLanguageCode, targetLanguageCode);
  }

  /// Get a single practice by ID
  Future<Practice?> getPracticeById(int id) async {
    return await _practiceRepository.getPracticeById(id);
  }

  /// Save a new practice item
  Future<int> savePractice({
    required String sourceText,
    required String translatedText,
    required String sourceLanguageCode,
    required String targetLanguageCode,
  }) async {
    final practice = Practice(
      id: 0, // Will be replaced by the database
      sourceText: sourceText,
      translatedText: translatedText,
      sourceLanguageCode: sourceLanguageCode,
      targetLanguageCode: targetLanguageCode,
      createdAt: DateTime.now(),
    );
    
    return await _practiceRepository.savePractice(practice);
  }

  /// Update practice statistics after an attempt
  Future<void> updatePracticeStatistics(int practiceId, bool isSuccess) async {
    final practice = await _practiceRepository.getPracticeById(practiceId);
    
    if (practice != null) {
      final updatedPractice = practice.copyWith(
        successCount: isSuccess ? practice.successCount + 1 : practice.successCount,
        attemptCount: practice.attemptCount + 1,
      );
      
      await _practiceRepository.updatePractice(updatedPractice);
    }
  }

  /// Delete a practice
  Future<void> deletePractice(int id) async {
    await _practiceRepository.deletePractice(id);
  }

  /// Start a new practice session
  Future<int> startPracticeSession(String sourceLanguageCode, String targetLanguageCode) async {
    final session = PracticeSession(
      id: 0, // Will be replaced by the database
      sourceLanguageCode: sourceLanguageCode,
      targetLanguageCode: targetLanguageCode,
      timestamp: DateTime.now(),
      successCount: 0,
      failureCount: 0,
    );
    
    return await _practiceRepository.savePracticeSession(session);
  }

  /// Update session statistics
  Future<void> updateSessionStatistics(int sessionId, bool isSuccess) async {
    final sessions = await _practiceRepository.getPracticeSessions();
    final session = sessions.firstWhere((s) => s.id == sessionId);
    
    final updatedSession = session.copyWith(
      successCount: isSuccess ? session.successCount + 1 : session.successCount,
      failureCount: isSuccess ? session.failureCount : session.failureCount + 1,
    );
    
    await _practiceRepository.updatePracticeSession(updatedSession);
  }

  /// Get statistics for a specific language pair
  Future<Map<String, dynamic>> getStatistics(String sourceLanguageCode, String targetLanguageCode) async {
    return await _practiceRepository.getStatistics(sourceLanguageCode, targetLanguageCode);
  }
}
