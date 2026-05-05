import 'package:vector_math/vector_math_64.dart';

/// Performance optimization: Object pool for expensive objects like Matrix4
/// to reduce garbage collection pressure during real-time scanning.
class ObjectPool<T> {
  final List<T> _pool = [];
  final T Function() _factory;
  final void Function(T)? _reset;
  final int _maxSize;

  ObjectPool(this._factory, {void Function(T)? reset, int maxSize = 10})
      : _reset = reset,
        _maxSize = maxSize;

  T acquire() {
    if (_pool.isNotEmpty) {
      return _pool.removeLast();
    }
    return _factory();
  }

  void release(T object) {
    if (_pool.length < _maxSize) {
      _reset?.call(object);
      _pool.add(object);
    }
  }

  void clear() {
    _pool.clear();
  }

  int get poolSize => _pool.length;
}

/// Performance optimization: Specialized pools for common objects
class ObjectPools {
  static final _matrixPool = ObjectPool<Matrix4>(
    () => Matrix4.zero(),
    reset: (matrix) => matrix.setZero(),
    maxSize: 20,
  );

  static final _vector3Pool = ObjectPool<Vector3>(
    () => Vector3.zero(),
    reset: (vector) => vector.setZero(),
    maxSize: 50,
  );

  static final _listPool = ObjectPool<List<dynamic>>(
    () => <dynamic>[],
    reset: (list) => list.clear(),
    maxSize: 10,
  );

  /// Acquire a Matrix4 from the pool
  static Matrix4 acquireMatrix4() => _matrixPool.acquire();

  /// Release a Matrix4 back to the pool
  static void releaseMatrix4(Matrix4 matrix) => _matrixPool.release(matrix);

  /// Acquire a Vector3 from the pool
  static Vector3 acquireVector3() => _vector3Pool.acquire();

  /// Release a Vector3 back to the pool
  static void releaseVector3(Vector3 vector) => _vector3Pool.release(vector);

  /// Acquire a List from the pool
  static List<dynamic> acquireList() => _listPool.acquire();

  /// Release a List back to the pool
  static void releaseList(List<dynamic> list) => _listPool.release(list);

  /// Clear all pools (useful for testing or memory pressure)
  static void clearAll() {
    _matrixPool.clear();
    _vector3Pool.clear();
    _listPool.clear();
  }

  /// Get pool statistics for monitoring
  static Map<String, int> getPoolStats() {
    return {
      'matrix4_pool_size': _matrixPool.poolSize,
      'vector3_pool_size': _vector3Pool.poolSize,
      'list_pool_size': _listPool.poolSize,
    };
  }
}