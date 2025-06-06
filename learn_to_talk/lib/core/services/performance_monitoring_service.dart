import 'package:firebase_performance/firebase_performance.dart';
import 'package:logging/logging.dart';

/// Service for monitoring application performance
class PerformanceMonitoringService {
  final Logger _logger = Logger('PerformanceMonitoringService');
  FirebasePerformance? _performance;
  final Map<String, Trace> _activeTraces = {};
  bool _isAvailable = false;
  
  PerformanceMonitoringService() {
    _tryInitialize();
  }
  
  void _tryInitialize() {
    try {
      _performance = FirebasePerformance.instance;
      _isAvailable = true;
      _logger.info('Firebase Performance Monitoring initialized successfully');
    } catch (e) {
      _isAvailable = false;
      _logger.warning('Firebase Performance Monitoring not available: $e');
    }
  }

  /// Start a performance trace with the given name
  /// Returns true if the trace was started successfully
  Future<bool> startTrace(String traceName) async {
    try {
      if (!_isAvailable) {
        _logger.fine('Performance monitoring not available, ignoring trace: $traceName');
        return true; // Return success but do nothing
      }
      
      if (_activeTraces.containsKey(traceName)) {
        _logger.warning('A trace with name $traceName is already active');
        return false;
      }
      
      final trace = _performance?.newTrace(traceName);
      if (trace == null) {
        _logger.warning('Failed to create trace: $traceName');
        return false;
      }
      
      await trace.start();
      _activeTraces[traceName] = trace;
      _logger.info('Started performance trace: $traceName');
      return true;
    } catch (e) {
      _logger.severe('Error starting performance trace: $e');
      return false;
    }
  }

  /// Stop a performance trace with the given name
  /// Returns true if the trace was stopped successfully
  Future<bool> stopTrace(String traceName) async {
    try {
      if (!_isAvailable) {
        _logger.fine('Performance monitoring not available, ignoring stopTrace: $traceName');
        return true; // Return success but do nothing
      }
      
      final trace = _activeTraces[traceName];
      if (trace == null) {
        _logger.warning('No active trace found with name: $traceName');
        return false;
      }
      
      await trace.stop();
      _activeTraces.remove(traceName);
      _logger.info('Stopped performance trace: $traceName');
      return true;
    } catch (e) {
      _logger.severe('Error stopping performance trace: $e');
      return false;
    }
  }

  /// Add a metric to an active trace
  /// Returns true if the metric was added successfully
  Future<bool> addMetric(String traceName, String metricName, int value) async {
    try {
      if (!_isAvailable) {
        _logger.fine('Performance monitoring not available, ignoring addMetric: $traceName/$metricName');
        return true; // Return success but do nothing
      }
      
      final trace = _activeTraces[traceName];
      if (trace == null) {
        _logger.warning('No active trace found with name: $traceName');
        return false;
      }
      
      trace.setMetric(metricName, value);
      _logger.info('Added metric: $metricName = $value to trace: $traceName');
      return true;
    } catch (e) {
      _logger.severe('Error adding metric: $e');
      return false;
    }
  }
}
