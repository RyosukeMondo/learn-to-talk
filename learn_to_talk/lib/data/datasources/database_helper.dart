import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  
  // Singleton pattern
  factory DatabaseHelper() => _instance;
  
  DatabaseHelper._internal();
  
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'learn_to_talk.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }
  
  Future<void> _createDatabase(Database db, int version) async {
    // Create languages table
    await db.execute('''
      CREATE TABLE languages(
        code TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        isOfflineAvailable INTEGER NOT NULL
      )
    ''');
    
    // Create practices table
    await db.execute('''
      CREATE TABLE practices(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sourceText TEXT NOT NULL,
        translatedText TEXT NOT NULL,
        sourceLanguageCode TEXT NOT NULL,
        targetLanguageCode TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        successCount INTEGER NOT NULL,
        attemptCount INTEGER NOT NULL,
        FOREIGN KEY (sourceLanguageCode) REFERENCES languages(code),
        FOREIGN KEY (targetLanguageCode) REFERENCES languages(code)
      )
    ''');
    
    // Create practice sessions table
    await db.execute('''
      CREATE TABLE practice_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sourceLanguageCode TEXT NOT NULL,
        targetLanguageCode TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        successCount INTEGER NOT NULL,
        failureCount INTEGER NOT NULL,
        FOREIGN KEY (sourceLanguageCode) REFERENCES languages(code),
        FOREIGN KEY (targetLanguageCode) REFERENCES languages(code)
      )
    ''');
    
    // Insert default languages
    await _insertDefaultLanguages(db);
  }
  
  Future<void> _insertDefaultLanguages(Database db) async {
    final languages = [
      {'code': 'en-US', 'name': 'English (US)', 'isOfflineAvailable': 0},
      {'code': 'ja-JP', 'name': 'Japanese', 'isOfflineAvailable': 0},
      {'code': 'fr-FR', 'name': 'French', 'isOfflineAvailable': 0},
      {'code': 'de-DE', 'name': 'German', 'isOfflineAvailable': 0},
      {'code': 'es-ES', 'name': 'Spanish', 'isOfflineAvailable': 0},
      {'code': 'zh-CN', 'name': 'Chinese (Simplified)', 'isOfflineAvailable': 0},
    ];
    
    for (final language in languages) {
      await db.insert('languages', language);
    }
  }
}
