import 'package:learn_to_talk/domain/entities/practice.dart';
import 'package:learn_to_talk/domain/entities/practice_session.dart';

abstract class PracticeRepository {
  /// Gets all practice items for a specific language pair
  Future<List<Practice>> getPractices(String sourceLanguageCode, String targetLanguageCode);
  
  /// Gets a single practice by ID
  Future<Practice?> getPracticeById(int id);
  
  /// Saves a new practice
  Future<int> savePractice(Practice practice);
  
  /// Updates an existing practice
  Future<void> updatePractice(Practice practice);
  
  /// Deletes a practice
  Future<void> deletePractice(int id);
  
  /// Gets all practice sessions
  Future<List<PracticeSession>> getPracticeSessions();
  
  /// Saves a new practice session
  Future<int> savePracticeSession(PracticeSession session);
  
  /// Updates an existing practice session
  Future<void> updatePracticeSession(PracticeSession session);
  
  /// Gets statistics for a specific language pair
  Future<Map<String, dynamic>> getStatistics(String sourceLanguageCode, String targetLanguageCode);
}
