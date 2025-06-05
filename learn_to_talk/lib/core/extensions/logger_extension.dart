import 'package:logging/logging.dart';

/// Extension on Type to get a named logger for any class
extension LoggerExtension on Object {
  /// Gets a logger named after the class
  Logger get log => Logger(runtimeType.toString());
}
