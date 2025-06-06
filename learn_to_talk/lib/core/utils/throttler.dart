import 'dart:async';

/// Utility class to prevent executing operations too frequently
/// Optimized for UI performance with microtasks and better scheduling
class Throttler {
  final Duration duration;
  Timer? _timer;
  bool _isExecuting = false;

  Throttler({required this.duration});

  /// Run the provided callback with throttling
  /// Returns a Future that completes with the result of the callback
  /// Designed to minimize impact on the UI thread
  Future<T> run<T>(Future<T> Function() callback) async {
    // If we're currently executing or have an active timer, throttle the request
    if (_isExecuting || (_timer?.isActive ?? false)) {
      // Create a completer that will be fulfilled later
      final completer = Completer<T>();
      
      // Cancel existing timer if any
      _timer?.cancel();
      
      // Schedule work using microtask to avoid blocking the UI thread
      _timer = Timer(duration, () {
        // Use a separate zone to isolate errors
        scheduleMicrotask(() async {
          try {
            _isExecuting = true;
            final result = await callback();
            _isExecuting = false;
            completer.complete(result);
          } catch (e) {
            _isExecuting = false;
            completer.completeError(e);
          }
        });
      });
      
      return completer.future;
    }

    // No active throttle or execution, run immediately but still track execution state
    _timer = Timer(duration, () {}); // Set cooldown timer
    
    try {
      _isExecuting = true;
      final result = await callback();
      _isExecuting = false;
      return result;
    } catch (e) {
      _isExecuting = false;
      rethrow;
    }
  }

  /// Cancel any pending throttled operations
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _isExecuting = false;
  }
}
