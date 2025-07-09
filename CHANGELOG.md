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
