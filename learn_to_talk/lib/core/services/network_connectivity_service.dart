import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logging/logging.dart';

/// Service for checking network connectivity status
class NetworkConnectivityService {
  final Logger _logger = Logger('NetworkConnectivityService');
  final Connectivity _connectivity = Connectivity();
  
  /// Check if device is connected to WiFi
  Future<bool> isWifiConnected() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final isWifi = connectivityResult == ConnectivityResult.wifi;
      _logger.info('WiFi connection check: $isWifi');
      return isWifi;
    } catch (e) {
      _logger.warning('Error checking connectivity: $e');
      return false;
    }
  }

  /// Check if device is connected to any network
  Future<bool> hasNetworkConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final hasConnection = connectivityResult != ConnectivityResult.none;
      _logger.info('Network connection check: $hasConnection');
      return hasConnection;
    } catch (e) {
      _logger.warning('Error checking connectivity: $e');
      return false;
    }
  }
  
  /// Stream of connectivity changes
  Stream<ConnectivityResult> get connectivityChanges => _connectivity.onConnectivityChanged;
}
