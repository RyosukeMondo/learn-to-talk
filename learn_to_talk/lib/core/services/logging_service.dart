import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// A centralized logging service for the application that:
/// - Logs all levels to a file
/// - Only prints warnings and errors to the console
class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  static LoggingService get instance => _instance;

  final Logger _rootLogger = Logger.root;
  bool _isInitialized = false;
  File? _logFile;

  LoggingService._internal();

  /// Initialize logging service with proper configuration
  Future<void> init() async {
    if (_isInitialized) return;

    // Format messages with timestamp, level, and origin
    Logger.root.onRecord.listen((record) async {
      final logMessage = _formatLogMessage(record);

      // Write to file (all levels)
      if (_logFile != null) {
        await _logFile!.writeAsString('$logMessage\n', mode: FileMode.append);
      }

      // Only print warnings and errors to console
      if (record.level >= Level.WARNING) {
        _rootLogger.warning(logMessage);
      }
    });

    // Create log file
    await _setupLogFile();

    // Set root level to ALL to capture everything
    _rootLogger.level = Level.ALL;

    _isInitialized = true;

    // Log startup message
    Logger('LoggingService').info('Logging service initialized');
  }

  /// Creates and prepares the log file
  Future<void> _setupLogFile() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final now = DateTime.now();
      final formatter = DateFormat('yyyy-MM-dd');
      final fileName = 'learn_to_talk_${formatter.format(now)}.log';
      _logFile = File('${directory.path}/$fileName');

      // Create the file if it doesn't exist
      if (!await _logFile!.exists()) {
        await _logFile!.create(recursive: true);
      }

      // Log rotation logic could be added here
    } catch (e) {
      _rootLogger.warning('Failed to setup log file: $e');
      _logFile = null;
    }
  }

  /// Format log messages with timestamp, level, and logger name
  String _formatLogMessage(LogRecord record) {
    final time = DateFormat('HH:mm:ss.SSS').format(record.time);
    final level = record.level.name.padRight(7);
    return '[$time] $level [${record.loggerName}] ${record.message}${record.error != null ? ' ERROR: ${record.error}' : ''}${record.stackTrace != null ? '\n${record.stackTrace}' : ''}';
  }

  /// Get a named logger for a specific class or component
  Logger getLogger(String name) {
    if (!_isInitialized) {
      init();
    }
    return Logger(name);
  }
}
