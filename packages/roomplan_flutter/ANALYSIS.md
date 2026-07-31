# roomplan_flutter — Analysis & Improvement Plan

> v0.2.0 · iOS-only · Apple RoomPlan wrapper · LiDAR room scanning

## Package Summary

Flutter plugin wrapping Apple RoomPlan API (iOS 16+). Captures 3D room scans via LiDAR,
detecting walls, doors, windows, openings, furniture objects, floor, and ceiling — all
with dimensions, 3D positions, transforms, and confidence levels.

**Architecture:** MethodChannel + EventChannel → Swift `RoomPlanController` (singleton)
→ `RoomCaptureSession` + `RoomCaptureView` → `RoomPlanJSONConverter` → JSON → Dart models.

## Findings

### Bugs

1. **✅ FIXED — `ObjectCategory` missing 5 categories**  
   Swift maps `television`, `fireplace`, `stairs`, `bathtub`, `dishwasher`. Dart enum
   didn't include them — any scan detecting these objects would return `unknown`.

2. **`flutterResult` leak on manual dismiss**  
   If the user swipe-dismisses the presented `UINavigationController`, neither
   `doneScanning` nor `cancelScanning` fire → the Dart `Future` from `startScanning()`
   hangs forever. No timeout, no recovery. **Critical for UX.**

3. **`UIApplication.shared.windows` deprecated since iOS 15**  
   `RoomPlanController.startSession()` uses the deprecated `windows` property. Should
   use `UIWindowScene.windows` via `connectedScenes`.

### Dead / Unused Code

4. **`lib/src/models/` — obsolete internal models** (~250 lines)  
   `RoomPlanResult`, `WallMeasurement`, `ObjectMeasurement`, `DoorWindowMeasurement`,
   and internal `RoomDimensions`. Not exported, not used by `RoomPlanScanner`. Parse a
   different JSON format than what the Swift side actually sends. Contain Portuguese
   strings (`'Alta'`, `'Média'`) inconsistent with the rest of the English codebase.

5. **`ObjectPool` never called by production code**  
   `ObjectPools.acquireMatrix4()` etc. are defined but `OptimizedMapper` allocates
   objects directly. The pool is dead code.

### Silent Failures

6. **`ScanConfiguration` fields ignored on native side**  
   `detectFurniture`, `detectDoors`, `detectWindows`, `minimumConfidence`,
   `enableAdvancedSurfaceDetection`, `timeoutSeconds`, `enableRealtimeUpdates` — ALL
   silently ignored. `createConfiguration()` returns a default config with a comment
   acknowledging iOS 16 has limited options. Client expects them to work.

### Thread Safety

7. **`PerformanceMonitor` static maps — no synchronization**  
   `_operationStartTimes`, `_operationDurations` mutated from both main thread and
   event channel background thread. Race condition on map operations.

### Code Quality

8. **`_listEquals` duplicated in 3 model files**  
   `RoomData`, `WallData`, `ScanConfidence` each define their own copy.

## Missing Features (vs Apple RoomPlan API)

| Feature | iOS Version | Status |
|---------|------------|--------|
| USDZ export (`captureSession.export()`) | 17.0 | ❌ Not exposed |
| `StructureBuilder` (`.porcelain`, etc.) | 17.0 | ❌ Not exposed |
| `pause()` / `resume()` | 17.0 | ❌ Not exposed |
| `visualizationMode` customization | 17.0 | ❌ Not exposed |
| `didProvide:command:` delegate | 17.0 | ❌ Not exposed |
| Thermal state monitoring | 16.0 | ❌ Not exposed |
| Session state query (isRunning, isPaused) | 16.0 | ❌ Not exposed |

## Dependency

- `vector_math: ^2.1.4` — used for `Matrix4` and `Vector3`. Could be replaced with
  `dart:typed_data` + manual math to remove the external dependency, but gains are
  marginal for a package that already depends on Flutter SDK.

## Improvement Plan

### Phase 1 — Critical fixes (PaintPro impact)
- [x] Add missing `ObjectCategory` values (television, fireplace, stairs, bathtub, dishwasher)
- [x] Fix `flutterResult` leak on dismiss (add `UIAdaptivePresentationControllerDelegate`)
- [x] Fix deprecated `UIApplication.shared.windows` → `UIWindowScene`
- [x] Document `ScanConfiguration` limitations clearly in Dartdoc

### Phase 2 — Cleanup
- [x] Remove `lib/src/models/` dead code (5 files, ~250 lines)
- [x] Replace 3 duplicate `_listEquals` with `package:flutter/foundation.dart` `listEquals`
- [ ] Remove unused `ObjectPool` / `ObjectPools` or wire it into `OptimizedMapper`

### Phase 3 — Features
- [ ] Expose USDZ export (`captureSession.export()`)
- [ ] Expose `pause`/`resume` session control
- [ ] Expose `StructureBuilder` customization
