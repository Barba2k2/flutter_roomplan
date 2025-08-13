import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'optimized_mapper.dart';

/// Performance monitoring utility for tracking memory usage and processing times
class PerformanceMonitor {
  static final Map<String, DateTime> _operationStartTimes = {};
  static final Map<String, List<int>> _operationDurations = {};
  static final List<String> _memoryWarnings = [];
  static Timer? _memoryMonitorTimer;
  
  /// Start timing an operation
  static void startOperation(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
  }
  
  /// End timing an operation and record the duration
  static void endOperation(String operationName) {
    final startTime = _operationStartTimes.remove(operationName);
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime).inMicroseconds;
      _operationDurations.putIfAbsent(operationName, () => []).add(duration);
      
      // Keep only recent measurements to prevent memory growth
      final measurements = _operationDurations[operationName]!;
      if (measurements.length > 100) {
        measurements.removeRange(0, measurements.length - 100);
      }
    }
  }
  
  /// Get average duration for an operation in microseconds
  static double? getAverageDuration(String operationName) {
    final durations = _operationDurations[operationName];
    if (durations == null || durations.isEmpty) return null;
    
    final sum = durations.reduce((a, b) => a + b);
    return sum / durations.length;
  }
  
  /// Get all performance statistics
  static Map<String, dynamic> getPerformanceStats() {
    final stats = <String, dynamic>{
      'operation_averages': {},
      'memory_warnings': List.from(_memoryWarnings),
      'mapper_stats': OptimizedMapper.getPerformanceStats(),
    };
    
    for (final entry in _operationDurations.entries) {
      if (entry.value.isNotEmpty) {
        final sum = entry.value.reduce((a, b) => a + b);
        stats['operation_averages'][entry.key] = {
          'average_microseconds': sum / entry.value.length,
          'measurement_count': entry.value.length,
          'last_duration_microseconds': entry.value.last,
        };
      }
    }
    
    return stats;
  }
  
  /// Start monitoring memory usage (if available)
  static void startMemoryMonitoring() {
    if (kDebugMode && Platform.isIOS) {
      _memoryMonitorTimer?.cancel();
      _memoryMonitorTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _checkMemoryPressure();
      });
    }
  }
  
  /// Stop memory monitoring
  static void stopMemoryMonitoring() {
    _memoryMonitorTimer?.cancel();
  }
  
  /// Check for memory pressure and log warnings
  static void _checkMemoryPressure() {
    // Note: In a real implementation, you would use native platform channels
    // to get actual memory statistics. This is a placeholder.
    final mapperStats = OptimizedMapper.getPerformanceStats();
    final totalCacheSize = mapperStats['category_cache_size'] as int;
    
    if (totalCacheSize > 1000) {
      final warning = 'High cache usage detected: $totalCacheSize items at ${DateTime.now()}';
      _memoryWarnings.add(warning);
      
      // Keep only recent warnings
      if (_memoryWarnings.length > 10) {
        _memoryWarnings.removeRange(0, _memoryWarnings.length - 10);
      }
      
      // Clear caches if they get too large
      if (totalCacheSize > 5000) {
        OptimizedMapper.clearCaches();
        debugPrint('Performance: Cleared caches due to high memory usage');
      }
    }
  }
  
  /// Clear all performance data
  static void clearStats() {
    _operationStartTimes.clear();
    _operationDurations.clear();
    _memoryWarnings.clear();
    OptimizedMapper.clearCaches();
  }
  
  /// Helper method to time a function execution
  static T timeOperation<T>(String operationName, T Function() operation) {
    startOperation(operationName);
    try {
      return operation();
    } finally {
      endOperation(operationName);
    }
  }
  
  /// Helper method to time an async function execution
  static Future<T> timeOperationAsync<T>(String operationName, Future<T> Function() operation) async {
    startOperation(operationName);
    try {
      return await operation();
    } finally {
      endOperation(operationName);
    }
  }
}

/// Extension to easily time operations
extension PerformanceTimingExtension<T> on T Function() {
  T timed(String operationName) {
    return PerformanceMonitor.timeOperation(operationName, this);
  }
}

/// Extension to easily time async operations
extension PerformanceTimingAsyncExtension<T> on Future<T> Function() {
  Future<T> timed(String operationName) {
    return PerformanceMonitor.timeOperationAsync(operationName, this);
  }
}