import 'package:learn_to_talk/data/datasources/database_helper.dart';
import 'package:learn_to_talk/data/models/practice_model.dart';
import 'package:learn_to_talk/data/models/practice_session_model.dart';
import 'package:sqflite/sqflite.dart';

class PracticeDataSource {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Practices CRUD operations
  Future<List<PracticeModel>> getPractices(
    String sourceLanguageCode,
    String targetLanguageCode,
  ) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'practices',
      where: 'sourceLanguageCode = ? AND targetLanguageCode = ?',
      whereArgs: [sourceLanguageCode, targetLanguageCode],
    );

    return List.generate(maps.length, (i) => PracticeModel.fromJson(maps[i]));
  }

  Future<PracticeModel?> getPracticeById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'practices',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return PracticeModel.fromJson(maps.first);
  }

  Future<int> insertPractice(PracticeModel practice) async {
    final db = await _databaseHelper.database;
    return await db.insert(
      'practices',
      practice.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updatePractice(PracticeModel practice) async {
    final db = await _databaseHelper.database;
    await db.update(
      'practices',
      practice.toJson(),
      where: 'id = ?',
      whereArgs: [practice.id],
    );
  }

  Future<void> deletePractice(int id) async {
    final db = await _databaseHelper.database;
    await db.delete('practices', where: 'id = ?', whereArgs: [id]);
  }

  // Practice Sessions CRUD operations
  Future<List<PracticeSessionModel>> getPracticeSessions() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('practice_sessions');

    return List.generate(
      maps.length,
      (i) => PracticeSessionModel.fromJson(maps[i]),
    );
  }

  Future<int> insertPracticeSession(PracticeSessionModel session) async {
    final db = await _databaseHelper.database;
    return await db.insert(
      'practice_sessions',
      session.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updatePracticeSession(PracticeSessionModel session) async {
    final db = await _databaseHelper.database;
    await db.update(
      'practice_sessions',
      session.toJson(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<Map<String, dynamic>> getStatistics(
    String sourceLanguageCode,
    String targetLanguageCode,
  ) async {
    final db = await _databaseHelper.database;

    // Get total practices
    final practicesCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM practices WHERE sourceLanguageCode = ? AND targetLanguageCode = ?',
            [sourceLanguageCode, targetLanguageCode],
          ),
        ) ??
        0;

    // Get total successful attempts
    final successCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT SUM(successCount) FROM practices WHERE sourceLanguageCode = ? AND targetLanguageCode = ?',
            [sourceLanguageCode, targetLanguageCode],
          ),
        ) ??
        0;

    // Get total attempts
    final attemptCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT SUM(attemptCount) FROM practices WHERE sourceLanguageCode = ? AND targetLanguageCode = ?',
            [sourceLanguageCode, targetLanguageCode],
          ),
        ) ??
        0;

    return {
      'practicesCount': practicesCount,
      'successCount': successCount,
      'attemptCount': attemptCount,
      'successRate': attemptCount > 0 ? successCount / attemptCount : 0,
    };
  }
}
