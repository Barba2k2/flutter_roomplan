import 'package:flutter_test/flutter_test.dart';
import 'package:roomplan_flutter/src/performance/object_pool.dart';
import 'package:roomplan_flutter/src/performance/optimized_mapper.dart';
import 'package:roomplan_flutter/src/performance/performance_monitor.dart';
import 'package:roomplan_flutter/src/mapper.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('Performance Tests', () {
    setUp(() {
      // Clear performance data before each test
      PerformanceMonitor.clearStats();
      ObjectPools.clearAll();
      OptimizedMapper.clearCaches();
    });

    group('ObjectPool', () {
      test('pool reuses objects efficiently', () {
        final pool = ObjectPool<List<int>>(
          () => <int>[],
          reset: (list) => list.clear(),
          maxSize: 3,
        );

        // Acquire and release objects
        final obj1 = pool.acquire();
        final obj2 = pool.acquire();
        
        pool.release(obj1);
        pool.release(obj2);
        
        expect(pool.poolSize, equals(2));
        
        // Reuse should return the same objects
        final reused1 = pool.acquire();
        final reused2 = pool.acquire();
        
        expect(identical(reused1, obj2), isTrue); // LIFO order
        expect(identical(reused2, obj1), isTrue);
        expect(pool.poolSize, equals(0));
      });

      test('ObjectPools provides Matrix4 and Vector3 pooling', () {
        final matrix1 = ObjectPools.acquireMatrix4();
        final matrix2 = ObjectPools.acquireMatrix4();
        final vector1 = ObjectPools.acquireVector3();
        
        expect(matrix1, isA<Matrix4>());
        expect(vector1, isA<Vector3>());
        
        ObjectPools.releaseMatrix4(matrix1);
        ObjectPools.releaseMatrix4(matrix2);
        ObjectPools.releaseVector3(vector1);
        
        final stats = ObjectPools.getPoolStats();
        expect(stats['matrix4_pool_size'], greaterThanOrEqualTo(2));
        expect(stats['vector3_pool_size'], greaterThanOrEqualTo(1));
      });

      test('pool respects max size', () {
        final pool = ObjectPool<String>(
          () => 'new',
          maxSize: 2,
        );

        pool.release('obj1');
        pool.release('obj2');
        pool.release('obj3'); // Should not be added due to max size
        
        expect(pool.poolSize, equals(2));
      });
    });

    group('PerformanceMonitor', () {
      test('tracks operation timing', () {
        PerformanceMonitor.startOperation('test_op');
        
        // Simulate some work
        for (int i = 0; i < 1000; i++) {
          // Simple computation
        }
        
        PerformanceMonitor.endOperation('test_op');
        
        final duration = PerformanceMonitor.getAverageDuration('test_op');
        expect(duration, isNotNull);
        expect(duration!, greaterThan(0));
      });

      test('timeOperation helper works correctly', () {
        final result = PerformanceMonitor.timeOperation('helper_test', () {
          return 42;
        });
        
        expect(result, equals(42));
        
        final duration = PerformanceMonitor.getAverageDuration('helper_test');
        expect(duration, isNotNull);
        expect(duration!, greaterThan(0));
      });

      test('provides comprehensive stats', () {
        PerformanceMonitor.timeOperation('op1', () => 'result1');
        PerformanceMonitor.timeOperation('op2', () => 'result2');
        
        final stats = PerformanceMonitor.getPerformanceStats();
        
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['operation_averages'], isA<Map>());
        expect(stats['operation_averages']['op1'], isNotNull);
        expect(stats['operation_averages']['op2'], isNotNull);
        expect(stats['mapper_stats'], isNotNull);
      });

      test('limits operation history to prevent memory growth', () {
        // Simulate many operations
        for (int i = 0; i < 150; i++) {
          PerformanceMonitor.timeOperation('memory_test', () => i);
        }
        
        final stats = PerformanceMonitor.getPerformanceStats();
        final opStats = stats['operation_averages']['memory_test'];
        
        // Should be limited to 100 measurements
        expect(opStats['measurement_count'], lessThanOrEqualTo(100));
      });
    });

    group('OptimizedMapper', () {
      test('provides performance statistics', () {
        // Use the mapper to populate some caches
        OptimizedMapper.parseScanResult('{"walls": [], "objects": []}');
        
        final stats = OptimizedMapper.getPerformanceStats();
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('category_cache_size'), isTrue);
      });

      test('clears caches properly', () {
        // Populate caches
        OptimizedMapper.parseScanResult('''
        {
          "objects": [
            {"category": "table", "confidence": "high", "dimensions": {"x": 1, "y": 1, "z": 1}}
          ]
        }
        ''');
        
        final statsBefore = OptimizedMapper.getPerformanceStats();
        expect(statsBefore['category_cache_size'], greaterThan(0));
        
        OptimizedMapper.clearCaches();
        
        final statsAfter = OptimizedMapper.getPerformanceStats();
        expect(statsAfter['category_cache_size'], equals(0));
      });

      test('performance optimizations maintain correctness', () {
        const testJson = '''
        {
          "walls": [
            {
              "uuid": "wall1", 
              "confidence": "high", 
              "dimensions": {"x": 3, "y": 2, "z": 0.2},
              "doors": [],
              "windows": []
            }
          ],
          "objects": [
            {
              "uuid": "obj1",
              "category": "table",
              "confidence": "medium",
              "dimensions": {"x": 1.5, "y": 0.8, "z": 0.7}
            }
          ],
          "doors": [],
          "windows": [],
          "openings": []
        }
        ''';
        
        // Parse with optimized mapper
        final optimizedResult = OptimizedMapper.parseScanResult(testJson);
        
        // Parse with legacy mapper  
        final legacyResult = parseScanResultLegacy(testJson);
        
        // Results should be equivalent
        expect(optimizedResult, isNotNull);
        expect(legacyResult, isNotNull);
        expect(optimizedResult!.room.walls.length, equals(legacyResult!.room.walls.length));
        expect(optimizedResult.room.objects.length, equals(legacyResult.room.objects.length));
        expect(optimizedResult.room.walls.first.uuid, equals(legacyResult.room.walls.first.uuid));
        expect(optimizedResult.room.objects.first.category, equals(legacyResult.room.objects.first.category));
      });
    });

    group('Performance Regression Prevention', () {
      test('JSON parsing performance is reasonable', () {
        const complexJson = '''
        {
          "walls": [
            {"uuid": "w1", "confidence": "high", "dimensions": {"x": 3, "y": 2.5, "z": 0.2}, "doors": [], "windows": []},
            {"uuid": "w2", "confidence": "high", "dimensions": {"x": 4, "y": 2.5, "z": 0.2}, "doors": [], "windows": []},
            {"uuid": "w3", "confidence": "medium", "dimensions": {"x": 3, "y": 2.5, "z": 0.2}, "doors": [], "windows": []}
          ],
          "objects": [
            {"uuid": "o1", "category": "table", "confidence": "high", "dimensions": {"x": 1.5, "y": 0.8, "z": 0.7}},
            {"uuid": "o2", "category": "chair", "confidence": "medium", "dimensions": {"x": 0.6, "y": 0.6, "z": 0.9}},
            {"uuid": "o3", "category": "sofa", "confidence": "high", "dimensions": {"x": 2.0, "y": 0.9, "z": 0.8}}
          ],
          "doors": [
            {"uuid": "d1", "confidence": "high", "dimensions": {"x": 0.9, "y": 2.1, "z": 0.05}}
          ],
          "windows": [
            {"uuid": "win1", "confidence": "medium", "dimensions": {"x": 1.2, "y": 1.0, "z": 0.05}}
          ],
          "openings": []
        }
        ''';
        
        // Warm up
        for (int i = 0; i < 5; i++) {
          parseScanResult(complexJson);
        }
        
        // Time multiple parses
        final stopwatch = Stopwatch()..start();
        const iterations = 100;
        
        for (int i = 0; i < iterations; i++) {
          final result = parseScanResult(complexJson);
          expect(result, isNotNull);
        }
        
        stopwatch.stop();
        
        final avgTimePerParse = stopwatch.elapsedMicroseconds / iterations;
        
        // Should parse in reasonable time (less than 10ms per parse on average)
        expect(avgTimePerParse, lessThan(10000)); // 10ms = 10,000 microseconds
        
        // Verify performance monitoring captured the data
        final stats = PerformanceMonitor.getPerformanceStats();
        expect(stats['operation_averages'], isNotNull);
      });

      test('memory usage remains stable during repeated parsing', () {
        const testJson = '''
        {
          "objects": [
            {"uuid": "obj", "category": "table", "confidence": "high", "dimensions": {"x": 1, "y": 1, "z": 1}}
          ]
        }
        ''';
        
        // Parse many times to test for memory leaks
        for (int i = 0; i < 1000; i++) {
          final result = parseScanResult(testJson);
          expect(result, isNotNull);
        }
        
        final stats = OptimizedMapper.getPerformanceStats();
        
        // Cache sizes should be reasonable
        expect(stats['category_cache_size'], lessThan(100));
        
        final poolStats = ObjectPools.getPoolStats();
        expect(poolStats['matrix4_pool_size'], lessThan(50));
        expect(poolStats['vector3_pool_size'], lessThan(50));
      });
    });
  });
}