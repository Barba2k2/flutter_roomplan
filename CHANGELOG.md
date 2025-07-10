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
