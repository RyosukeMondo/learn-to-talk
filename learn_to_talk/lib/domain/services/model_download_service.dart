import 'dart:async';
import 'package:logging/logging.dart';
// Using a different approach instead of unawaited
import 'package:learn_to_talk/domain/entities/language.dart';
import 'package:learn_to_talk/domain/repositories/translation_repository.dart';
import 'package:learn_to_talk/domain/repositories/speech_repository.dart';
import 'package:learn_to_talk/domain/repositories/tts_repository.dart';
import 'package:learn_to_talk/core/services/network_connectivity_service.dart';
import 'package:learn_to_talk/core/services/performance_monitoring_service.dart';
import 'package:learn_to_talk/core/utils/throttler.dart';

/// Service responsible for handling all model download operations
class ModelDownloadService {
  final TranslationRepository _translationRepository;
  final SpeechRepository _speechRepository;
  final TTSRepository _ttsRepository;
  final Logger _logger = Logger('ModelDownloadService');
  final NetworkConnectivityService _connectivityService;
  final PerformanceMonitoringService _performanceService;
  
  // Cache to avoid redundant model checks
  final Map<String, bool> _modelAvailabilityCache = {};
  
  // Throttle download operations to prevent overloading the main thread
  final Throttler _downloadThrottler = Throttler(duration: const Duration(milliseconds: 500));
  
  // Constants for performance trace names
  static const String _downloadTraceKey = 'model_download_operation';
  static const String _verifyTraceKey = 'model_verification';
  
  ModelDownloadService({
    required TranslationRepository translationRepository,
    required SpeechRepository speechRepository,
    required TTSRepository ttsRepository,
    NetworkConnectivityService? connectivityService,
    PerformanceMonitoringService? performanceService,
  }) : _translationRepository = translationRepository,
       _speechRepository = speechRepository,
       _ttsRepository = ttsRepository,
       _connectivityService = connectivityService ?? NetworkConnectivityService(),
       _performanceService = performanceService ?? PerformanceMonitoringService();

  /// Check if all required models are available for offline use
  Future<bool> areAllModelsAvailableOffline(
    String sourceLanguageCode, 
    String targetLanguageCode
  ) async {
    _logger.info('🔍 Checking all models availability: source=$sourceLanguageCode, target=$targetLanguageCode');

    final isTranslationAvailable = await _translationRepository.isModelDownloaded(
      sourceLanguageCode, 
      targetLanguageCode
    );
    
    final isSpeechAvailable = await _speechRepository.isLanguageAvailableForOfflineRecognition(
      sourceLanguageCode
    );
    
    final isSourceTtsAvailable = await _ttsRepository.isLanguageAvailableForOfflineTTS(
      sourceLanguageCode
    );
    
    final isTargetTtsAvailable = await _ttsRepository.isLanguageAvailableForOfflineTTS(
      targetLanguageCode
    );

    _logger.info('📊 Models availability: translation=$isTranslationAvailable, speech=$isSpeechAvailable, ' +
      'sourceTts=$isSourceTtsAvailable, targetTts=$isTargetTtsAvailable');

    return isTranslationAvailable && 
           isSpeechAvailable && 
           isSourceTtsAvailable && 
           isTargetTtsAvailable;
  }

  /// Check if translation models are available for offline use
  Future<bool> areTranslationModelsAvailable(
    String sourceLanguageCode, 
    String targetLanguageCode
  ) async {
    // Create a cache key for this language pair
    final cacheKey = '${sourceLanguageCode}_${targetLanguageCode}_translation';
    
    // Check cache first to avoid redundant repository calls
    if (_modelAvailabilityCache.containsKey(cacheKey)) {
      _logger.fine('Using cached translation model availability for $cacheKey: ${_modelAvailabilityCache[cacheKey]}');
      return _modelAvailabilityCache[cacheKey]!;
    }
    
    // Start performance trace
    await _performanceService.startTrace(_verifyTraceKey);
    
    try {
      // Check model availability
      final isAvailable = await _translationRepository.isModelDownloaded(
        sourceLanguageCode, 
        targetLanguageCode
      );
      
      // Cache the result
      _modelAvailabilityCache[cacheKey] = isAvailable;
      
      // Record metric and stop trace
      await _performanceService.addMetric(_verifyTraceKey, 'translation_check_ms', 0);
      try {
        await _performanceService.stopTrace(_verifyTraceKey);
      } catch (e) {
        // Silently continue if performance monitoring fails
        _logger.warning('Failed to stop performance trace: $e');
      }
      
      return isAvailable;
    } catch (e) {
      // Make sure to stop trace even on error
      try {
        await _performanceService.stopTrace(_verifyTraceKey);
      } catch (e) {
        // Silently continue if performance monitoring fails
        _logger.warning('Failed to stop performance trace: $e');
      }
      throw e;
    }
  }

  /// Download translation models for the specified languages
  /// This is a private implementation used by the public methods
  Future<bool> _downloadTranslationModelsImpl(
    String sourceLanguageCode, 
    String targetLanguageCode,
    void Function(String) onProgressUpdate,
  ) async {
    _logger.info('📥 Starting translation model download: source=$sourceLanguageCode, target=$targetLanguageCode');
    onProgressUpdate('Preparing to download translation models...');
    
    try {
      // Run connectivity check in a separate microtask to avoid blocking UI
      final hasNetwork = await Future(() async {
        return await _connectivityService.hasNetworkConnection();
      });
      
      if (!hasNetwork) {
        _logger.warning('❌ No network connection available for download');
        onProgressUpdate('No network connection available');
        return false;
      }
      
      // Warn if not on WiFi - run in separate microtask
      final isWifi = await Future(() async {
        return await _connectivityService.isWifiConnected();
      });
      
      if (!isWifi) {
        _logger.warning('⚠️ Not on WiFi, using cellular data for download');
        onProgressUpdate('Warning: Using cellular data for download');
      }
      
      // Start a performance trace (with error handling)
      Future<void> startPerformanceTracking() async {
        try {
          await _performanceService.startTrace(_downloadTraceKey);
          await _performanceService.addMetric(_downloadTraceKey, 'source_lang_code_length', sourceLanguageCode.length);
          await _performanceService.addMetric(_downloadTraceKey, 'target_lang_code_length', targetLanguageCode.length);
        } catch (e) {
          _logger.warning('Failed to start performance monitoring: $e');
        }
      }
      
      // Start performance tracking in a separate microtask without blocking
      startPerformanceTracking().then((_) {}).catchError((e) {
        _logger.warning('Error in performance tracking: $e');
      });
      
      // Set up a better progress reporting system that doesn't block the UI
      // This controller will push progress updates without blocking
      final progressController = StreamController<int>();
      
      // Listen to progress updates on a separate zone
      progressController.stream.listen((progress) {
        onProgressUpdate('Downloading translation models: $progress%');
      });
      
      // Run progress updates on a separate microtask without blocking
      Future(() async {
        for (int i = 0; i <= 90; i += 10) {
          progressController.add(i);
          await Future.delayed(const Duration(milliseconds: 150));
        }
      }).then((_) {}).catchError((e) {
        _logger.warning('Error during progress updates: $e');
      });
      
      // Use throttling to prevent UI jank
      final downloadResult = await _downloadThrottler.run(() async {
        // Actual download operation - this is the heavy lifting
        try {
          await _translationRepository.downloadModel(
            sourceLanguageCode,
            targetLanguageCode,
          );
          return true;
        } catch (e) {
          _logger.severe('Error during model download: $e');
          return false;
        }
      });
      
      // Final progress update
      progressController.add(100);
      onProgressUpdate('Download complete, verifying...');
      await progressController.close();

      if (!downloadResult) {
        _logger.warning('⚠️ Download operation failed');
        onProgressUpdate('Download failed. Please try again.');
        return false;
      }

      // Cache is no longer valid after a download
      final cacheKey = '${sourceLanguageCode}_${targetLanguageCode}_translation';
      _modelAvailabilityCache.remove(cacheKey);
      
      // Verify download success in a separate microtask
      final isAvailable = await Future(() async {
        return await _translationRepository.isModelDownloaded(
          sourceLanguageCode,
          targetLanguageCode,
        );
      });
      
      // Add metrics to the trace and stop the performance trace (with error handling)
      Future<void> stopPerformanceTracking(bool success) async {
        try {
          await _performanceService.addMetric(_downloadTraceKey, 'download_success', success ? 1 : 0);
          await _performanceService.stopTrace(_downloadTraceKey);
        } catch (e) {
          _logger.warning('Failed to record download metrics or stop trace: $e');
        }
      }
      
      // Stop performance tracking asynchronously without blocking
      stopPerformanceTracking(isAvailable).then((_) {}).catchError((e) {
        _logger.warning('Error stopping performance tracking: $e');
      });
      
      if (isAvailable) {
        onProgressUpdate('Translation models successfully downloaded!');
        return true;
      } else {
        _logger.warning('⚠️ Models not available after download attempt');
        onProgressUpdate('Download failed. Please try again.');
        return false;
      }
    } catch (e) {
      _logger.severe('❌ Error downloading translation models: $e');
      onProgressUpdate('Error: ${e.toString()}');
      
      // Stop performance trace in case of error
      try {
        await _performanceService.addMetric(_downloadTraceKey, 'download_error', 1);
        await _performanceService.stopTrace(_downloadTraceKey);
      } catch (ignored) {
        // Ignore errors stopping the trace
      }
      
      return false;
    }
  }

  /// Public method for downloading models with progress updates
  Future<bool> downloadTranslationModels(
    String sourceLanguageCode,
    String targetLanguageCode,
    Function(String) onProgressUpdate,
  ) async {
    try {
      await _downloadTranslationModelsImpl(sourceLanguageCode, targetLanguageCode, onProgressUpdate);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Download translation models using compute for background processing
  /// This method is called directly from the widget when needed
  Future<void> downloadModel(
    String sourceLanguageCode, 
    String targetLanguageCode,
    void Function(String)? onProgressUpdate,
  ) async {
    try {
      // Use a non-null progress function even when null is provided
      final progressFunction = onProgressUpdate ?? (_) {};
      
      // Call the implementation method
      await _downloadTranslationModelsImpl(sourceLanguageCode, targetLanguageCode, progressFunction);
    } catch (e) {
      _logger.severe('Error in downloadModel: $e');
      if (onProgressUpdate != null) {
        onProgressUpdate('Download failed: $e');
      }
      // Re-throw to allow caller to handle
      throw e;
    }
  }

  /// Get the human-readable components that need to be downloaded
  Future<ModelRequirements> getRequiredDownloads(
    Language sourceLanguage,
    Language targetLanguage
  ) async {
    final translationAvailable = await areTranslationModelsAvailable(
      sourceLanguage.code, 
      targetLanguage.code
    );
    
    final speechAvailable = await _speechRepository.isLanguageAvailableForOfflineRecognition(
      sourceLanguage.code
    );
    
    final sourceTtsAvailable = await _ttsRepository.isLanguageAvailableForOfflineTTS(
      sourceLanguage.code
    );
    
    final targetTtsAvailable = await _ttsRepository.isLanguageAvailableForOfflineTTS(
      targetLanguage.code
    );

    return ModelRequirements(
      needsTranslationModels: !translationAvailable,
      needsSpeechRecognition: !speechAvailable,
      needsSourceTts: !sourceTtsAvailable,
      needsTargetTts: !targetTtsAvailable,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage
    );
  }
}

/// Requirements for offline functionality
class ModelRequirements {
  final bool needsTranslationModels;
  final bool needsSpeechRecognition;
  final bool needsSourceTts;
  final bool needsTargetTts;
  final Language sourceLanguage;
  final Language targetLanguage;

  ModelRequirements({
    required this.needsTranslationModels,
    required this.needsSpeechRecognition,
    required this.needsSourceTts,
    required this.needsTargetTts,
    required this.sourceLanguage,
    required this.targetLanguage,
  });

  bool get hasRequirements => 
    needsTranslationModels || 
    needsSpeechRecognition || 
    needsSourceTts || 
    needsTargetTts;
}
