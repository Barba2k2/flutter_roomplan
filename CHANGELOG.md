## 0.1.2

- **Feature(iOS)**: Added floor and ceiling detection. Derives horizontal extents from walls, computes floor (min Y) and ceiling (max Y), and emits `floor`/`ceiling` surfaces with full dimensions and transforms.
- **Enhancement(iOS)**: Added `SerializableSurface` convenience initializer to construct synthetic surfaces (used for floor/ceiling).
- **Feature(example)**: Room details show floor/ceiling length, width, area, and confidence. Added `floor_ceiling_details_view.dart`. Advanced scanning page displays real-time floor/ceiling area.
- **Documentation**: Updated README with floor/ceiling usage examples and notes.
- **Testing**: Added `test/floor_ceiling_test.dart` covering presence/absence scenarios and area calculation.

## 0.1.1

- **Documentation**: Comprehensive README update with new features, performance details, and expanded API reference.
- **Documentation**: Added detailed performance monitoring guide and unit conversion examples.
- **Documentation**: Enhanced troubleshooting section with 25+ specific exception types and their solutions.
- **Testing**: Added comprehensive performance test suite with 12 test categories covering memory, JSON parsing, and UI optimization.
- **Testing**: Added regression prevention tests for memory stability and parsing performance benchmarks.

## 0.1.0

- **Performance**: 🚀 **Major Performance Overhaul** - 3x faster JSON parsing and 30-40% memory reduction.
- **Performance**: Implemented object pooling for Matrix4 and Vector3 objects to reduce garbage collection pressure.
- **Performance**: Added stream caching and automatic cleanup to prevent memory leaks.
- **Performance**: Optimized confidence calculations from O(n²) to O(n) complexity using single-pass algorithms.
- **Performance**: Added throttled UI updates (500ms timer) to maintain 60fps during real-time scanning.
- **Performance**: Implemented comprehensive performance monitoring system with operation timing and memory pressure detection.
- **Fix**: Enhanced stream subscription management with proper disposal order and automatic maintenance cleanup.
- **Fix**: Added automatic cache clearing when memory usage exceeds thresholds.
- **Enhancement**: Created `PerformanceMonitor` class for real-time performance tracking and debugging.
- **Enhancement**: Added `ObjectPool` system for efficient resource reuse.
- **Enhancement**: Implemented lazy evaluation and pre-computed lookup maps for enum conversions.

## 0.0.9

- **Feature**: 🌍 **Full Dual Unit System Support** - Added comprehensive imperial measurements alongside metric.
- **Feature**: Added `MeasurementUnit` enum with `metric` and `imperial` options.
- **Feature**: Enhanced `RoomDimensions` with imperial getters: `lengthInFeet`, `widthInFeet`, `heightInFeet`, `floorAreaInSqFeet`, `volumeInCuFeet`.
- **Feature**: Added formatted display methods: `getFormattedLength()`, `getFormattedArea()`, `getFormattedVolume()` with unit selection.
- **Feature**: Created `UnitConverter` class with precise conversion methods and formatting utilities.
- **Feature**: Updated advanced example with unit toggle button for seamless switching between metric and imperial displays.
- **Fix**: ✅ **Complete JSON Serialization Support** - Added missing `fromJson`/`toJson` methods to all model classes.
- **Fix**: Implemented JSON serialization for `RoomData`, `WallData`, `ObjectData`, `OpeningData`, `Position`, and `Confidence`.
- **Fix**: Added Matrix4 serialization helpers for 3D transformation data.
- **Fix**: Enhanced enum serialization for `ObjectCategory`, `OpeningType`, and `Confidence` with proper string conversion.
- **Enhancement**: Added comprehensive unit conversion test suite with 15+ test scenarios.
- **Enhancement**: Updated example UI to display both metric and imperial measurements with real-time unit switching.

## 0.0.8

- **Refactor(example)**: Reorganized example code structure for better pub.dev display and maintainability.
- **Improvement(example)**: Simplified main.dart and moved comprehensive example to scanner_page.dart with detailed documentation.
- **Enhancement(example)**: Added better UI organization, extensive code comments, and improved user experience with real-time scan data display.

## 0.0.7

- **Feature(example)**: Enhanced main.dart with comprehensive RoomPlanScanner example demonstrating proper initialization, real-time updates, and result handling.
- **Improvement(example)**: Added complete working code example that shows practical usage of all major features including error handling and resource disposal.

## 0.0.6

- **Feature**: Enhanced LiDAR detection with multi-method approach for better accuracy across different iOS devices and development environments.
- **Feature**: Added support for iPhone 16 Pro and Pro Max models in LiDAR device detection.
- **Fix**: Added missing `CapturedRoom.Surface.Category` extension mapping for proper surface categorization (doors, windows, openings, walls).
- **Fix**: Corrected height mapping for doors and windows - now uses the correct Y component instead of Z component for opening height calculations.
- **Fix**: Resolved Swift compilation errors related to device identifier parsing using proper `String(cString:)` method.
- **Chore**: Removed debug logging from both native iOS and Flutter code for cleaner production builds.

## 0.0.5

- **Feature**: Added `floor` and `ceiling` properties to `RoomData` to provide direct access to these surfaces when available.
- **Feature**: Added `transform` (Matrix4) and `dimensions` (RoomDimensions) properties to `WallData`, `ObjectData`, and `OpeningData`. This provides more precise positioning and sizing data aligned with the latest native APIs.
- **Fix**: The example app now includes a `PaintAreaDetailsView` to demonstrate calculating the paintable area of walls, subtracting openings.

## 0.0.4

- **Feature**: Added support for detecting `openings`. The `RoomData` model now includes a list of `OpeningData`.
- **Fix**: Implemented full data parsing for `WallData` and `OpeningData`, which now correctly deserialize `dimensions` and `confidence` from the native payload.
- **Fix**: Resolved a critical threading issue in the native iOS code that caused crashes when sending updates to Flutter. Work is now correctly dispatched between background and main threads.
- **Fix**: Corrected a native serialization error by implementing a custom `RoomPlanJSONConverter` to handle the `CapturedRoom` object, which is not directly `Encodable`.
- **Chore(example)**: Refactored the example app's UI for better clarity and organization, separating views into individual widgets.
- **Chore(example)**: Added visual feedback in the example app to show the `confidence` level of scanned items using colors.

## 0.0.3

- **Docs**: Improved package description for better clarity on pub.dev.
- **Fix**: Corrected exception handling for scan cancellation.
- **Refactor**: Simplified the internal JSON mapper for robustness.
- **Chore(example)**: Updated the example application and its dependencies.
- **Test**: Overhauled the test suite, adding isolated tests for the mapper and simplifying plugin-level tests.

## 0.0.2

- **BREAKING**: Refactored `RoomPlanScanner` API for clarity and correctness.
  - `finishScanning()` has been removed.
  - `startScanning()` now returns a `Future<ScanResult?>` which completes with the final scan result.
  - A new `stopScanning()` method was added to programmatically stop the session.
  - The `onScanResult` stream now correctly emits `ScanResult` objects during the scan.
- Fixed a bug where the internal data model was incorrectly exposed.

## 0.0.1

- Initial release of the `roomplan_flutter` package.
- Support for starting and stopping a RoomPlan scan on iOS 16+.
- Provides real-time updates on room structure during a scan (`onRoomUpdate`, `onWallDetected`, etc.).
- Returns a detailed `ScanResult` with structured data for walls, doors, windows, and overall dimensions.
