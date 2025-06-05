import 'package:learn_to_talk/core/services/logging_service.dart';

/// Class responsible for initializing all app services
class AppInitializer {
  /// Initialize all app services
  static Future<void> init() async {
    // Initialize logging first so all other services can use it
    await LoggingService.instance.init();
  }
}
