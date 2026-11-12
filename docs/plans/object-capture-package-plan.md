# Plan: `flutter_object_capture`

Date: 2026-10-24. Status: approved by the owner on 2026-10-24 with one change (example app uses MVC, section 7); nothing implemented. Convention note: `docs/` had only `reports/` (dated files); this file lives in `docs/plans/` as requested.

## 1. What Apple actually provides (verified 2026-10-24 against Apple's live doc JSON)

Sources are the `developer.apple.com/documentation/...` pages (fetched via their `tutorials/data/...json` mirror). Items marked **UNVERIFIED** were not found in docs.

Reconstruction (`PhotogrammetrySession`, iOS 17+, iPadOS 17+, macOS 12+):
- `init(input: URL, configuration:) throws` (folder of images) and `init<S: Sequence>(input:, configuration:)` (sequence of `PhotogrammetrySample`).
- `static var isSupported: Bool` ("hardware supports Object Capture"). Docs: check it before any use. [photogrammetrysession](https://developer.apple.com/documentation/realitykit/photogrammetrysession), [creating-3d-objects-from-photographs](https://developer.apple.com/documentation/realitykit/creating-3d-objects-from-photographs)
- `static let limits` -> `Limits.maximumNumberOfInputImages`, `maximumInputImageDimension` (device specific). Excess or oversized inputs are ignored and reported as `.invalidSample`. [limits](https://developer.apple.com/documentation/realitykit/photogrammetrysession/limits-swift.struct)
- `process(requests:) throws` (returns immediately; results arrive on `outputs`), `cancel()`, `isProcessing`, `activeRequests`, `outputs` (AsyncSequence).
- `Request`: `.modelFile(url:detail:geometry:)`, `.modelEntity`, `.bounds`, `.pointCloud`, `.poses`. A `.usdz` file URL gives one USDZ; a directory URL gives USDA + OBJ plus referenced assets (stated in WWDC21, a macOS session; **UNVERIFIED on iOS**). [request](https://developer.apple.com/documentation/realitykit/photogrammetrysession/request), [WWDC21 10076](https://developer.apple.com/videos/play/wwdc2021/10076)
- `Request.Detail`: `.preview .reduced .medium .full .raw .custom`. **On iOS only `.reduced` is supported** ("currently supported"; ~2048x2048 texture, diffuse + normal + AO maps). `.poses` and custom detail are Mac-only per WWDC23 10191. [detail](https://developer.apple.com/documentation/realitykit/photogrammetrysession/request/detail), [WWDC23 10191](https://developer.apple.com/videos/play/wwdc2023/10191)
- `Output` cases: `processingComplete`, `processingCancelled`, `inputComplete`, `requestProgress(_, fractionComplete)`, `requestProgressInfo(_, ProgressInfo)` (estimated remaining time + `ProcessingStage`), `requestComplete(_, Result)`, `requestError(_, Error)`, `invalidSample(id, reason)`, `skippedSample(id)`, `automaticDownsampling`, `stitchingIncomplete`. There is no `inputSkipped`. Apple's own page example omits `stitchingIncomplete`. [output](https://developer.apple.com/documentation/realitykit/photogrammetrysession/output)
- `PhotogrammetrySession.Error` (only 3 cases): `insufficientStorage(requiredBytes:)`, `invalidImages(URL)`, `invalidOutput(URL)`. Everything else surfaces as an untyped `any Error` in `requestError`. [error](https://developer.apple.com/documentation/realitykit/photogrammetrysession/error)
- `Configuration`: `featureSensitivity` (`.high` for low-landmark / low-contrast sets), `sampleOrdering` (`unordered` / `sequential`), `isObjectMaskingEnabled`, `ignoreBoundingBox`, `checkpointDirectory`, `meshPrimitive` (macOS only), `customDetailSpecification`. Defaults other than `meshPrimitive` (triangles) are not documented (**UNVERIFIED**). [configuration](https://developer.apple.com/documentation/realitykit/photogrammetrysession/configuration-swift.struct)

Device requirements:
- Docs: iOS "select devices with LiDAR"; Mac needs a GPU with 4 GB and ray tracing. WWDC23 10191: iPhone 12 Pro, iPad Pro 2021 and later; LiDAR "improves low-texture objects" (not stated as hard requirement for reconstruction). The WWDC24 sample README requires LiDAR + A14 or later + iOS 18 for the guided-capture sample. The only authoritative runtime gate is `PhotogrammetrySession.isSupported`. RAM / thermal limits and behavior on non-LiDAR iPhones: **UNVERIFIED -> device spike (phase 0)**.

Input:
- Folder of images; any camera works (iPhone, DSLR, drone); no naming or order needed. HEIC with embedded depth gives real-world scale; gravity metadata orients the model upright; no depth means the model may need scaling. 70%+ overlap between neighbors, <50% may fail; 20-200 close-ups suggested. JPEG/PNG acceptance is not stated in Apple docs (**UNVERIFIED**; the docs only demonstrate HEIC). [capturing-photographs](https://developer.apple.com/documentation/realitykit/capturing-photographs-for-realitykit-object-capture)
- `PhotogrammetrySample` can carry image + depth map + gravity + object mask (WWDC24 10107). Not needed for a folder-based v1.

Guided capture (`ObjectCaptureSession` + `ObjectCaptureView` + `ObjectCapturePointCloudView`): iOS/iPadOS 17+ only (no macOS). `ObjectCaptureSession.isSupported` must be checked or session creation is a runtime error. State machine `initializing -> ready -> detecting -> capturing -> finishing -> completed | failed`. `start(imagesDirectory:configuration:)` requires an empty writable directory. Errors: `cancelled`, `directoryNotEmpty`, `insufficientStorage`, `sensorFailed`, `trackingFailed`. `Configuration.isOverCaptureEnabled` keeps extra shots for Mac processing; `checkpointDirectory` speeds up later reconstruction. WWDC24 added area mode (skip `startDetecting`, `hideObjectReticle`). [objectcapturesession](https://developer.apple.com/documentation/realitykit/objectcapturesession), [WWDC24 10107](https://developer.apple.com/videos/play/wwdc2024/10107). It is a SwiftUI view: hosting it needs a `UIHostingController` presented from native (same pattern as RoomPlan's modal) or a platform view.

iOS 26 / iOS 27 changes: **none found.** Searches for WWDC25/26 Object Capture changes returned nothing relevant; the current doc pages list `iOS 17.0` as the introduction version and I found no deprecation flag on the pages above. Treat "no changes" as unproven; re-check Xcode release notes during phase 0.

Doc oddities to code around: `requestComplete` abstract wrongly says "finished handling all pending requests" (that is `processingComplete`); `Error`, `Limits`, `ProgressInfo` are macOS 14+ (iOS 17 is fine).

## 2. Scope

In (v1, 0.1.0):
- iOS 17+ only, on-device reconstruction from a folder of images to one USDZ at `.reduced` detail.
- `isSupported`, `getLimits`, `reconstruct` (events: progress, sample issues, notices, completed), `cancel`.
- Typed exceptions, example app, tests, docs.

Out of v1 (each is a later, separate decision):
- `ObjectCaptureSession` / `ObjectCaptureView` guided capture (see Decision 1: it is what makes iOS useful).
- macOS (PACKAGES.md lists macOS 12+; adds detail levels, poses, point cloud, custom detail, OBJ directory output).
- `.modelEntity`, `.bounds`, `.pointCloud`, `.poses`, `PhotogrammetrySample` input, object masks, `meshPrimitive`, `customDetailSpecification`, `ignoreBoundingBox`.
- Rendering/previewing the model (belongs to planned `flutter_realitykit`).
- Combining with RoomPlan (ARCHITECTURE.md: workflows belong in apps).

Why not expose `detail` in v1: iOS accepts only `.reduced`, so a single-value parameter is dead API. Hardcode it natively; add `ObjectDetail` when macOS lands (additive, non-breaking).

## 3. Public Dart API sketch

Mirrors roomplan_flutter: `lib/api` public, `lib/src` internal, one class per file, `*_helper` = private ctor + static methods, `log()` from `dart:developer`, trailing commas, no re-exports beyond the library entry file (same as `roomplan_flutter.dart`).

```
class ObjectCaptureProcessor {                       // lib/api/object_capture_processor.dart
  ObjectCaptureProcessor();                           // owns channel; call dispose()
  static Future<bool> isSupported();                  // PhotogrammetrySession.isSupported; false off iOS
  Future<ObjectCaptureLimits> getLimits();            // maxImages, maxImageDimension
  Stream<ReconstructionEvent> reconstruct({
    required String imagesDirectory,
    required String outputPath,                       // must end in .usdz (validated in Dart)
    ObjectCaptureConfiguration configuration = const ObjectCaptureConfiguration(),
  });                                                 // single-subscription; cancel subscription == cancel()
  Future<void> cancel();
  void dispose();
}

class ObjectCaptureConfiguration { FeatureSensitivity featureSensitivity; SampleOrdering sampleOrdering; }
enum FeatureSensitivity { normal, high }
enum SampleOrdering { unordered, sequential }
class ObjectCaptureLimits { int maxImages; int maxImageDimension; }

sealed class ReconstructionEvent
  ReconstructionProgress { double fraction; Duration? estimatedRemaining; }   // stage field only if spike shows value
  ReconstructionSampleIssue { int sampleId; String? reason; bool skipped; }   // invalidSample / skippedSample
  ReconstructionNotice { ReconstructionNoticeType type; }                    // inputComplete, automaticDownsampling, stitchingIncomplete
  ReconstructionCompleted { String modelPath; int fileSizeBytes; }           // terminal; stream closes after

exceptions (lib/api/exceptions.dart): abstract ObjectCaptureException
  ObjectCaptureNotSupportedException, InvalidImagesDirectoryException, InvalidOutputPathException,
  InsufficientStorageException(requiredBytes), ReconstructionInProgressException,
  ReconstructionCancelledException, ReconstructionFailedException(message), NativeChannelException
```

Design calls (my recommendation, product-neutral):
- Stream of sealed events instead of RoomPlan's Future + two controllers: one session = one stream, less state, no cleanup timer, no broadcast caching. Terminal events: `ReconstructionCompleted` then stream closes; failures are stream errors.
- One active job per processor; second call throws `ReconstructionInProgressException` (native side creates a fresh `PhotogrammetrySession` per job; reuse after `process` is **UNVERIFIED**, so never reuse).
- `Duration? estimatedRemaining` only if `ProgressInfo` proves reliable on device (spike). `ProcessingStage` case list not read yet.
- Channel names: `flutter_object_capture/method_channel` (`isSupported`, `getLimits`, `startReconstruction`, `cancelReconstruction`) and `flutter_object_capture/event_channel`. Event payload: `{ "type": "progress" | "sampleIssue" | "notice" | "completed", ... }`; error codes snake_case like roomplan (`invalid_images`, `invalid_output`, `insufficient_storage`, `session_in_progress`, `cancelled`, `reconstruction_failed`, `not_supported`).
- Mapping of untyped `requestError` to `reconstruction_failed` with `localizedDescription`.

## 4. Native layer (Swift, SPM + CocoaPods, iOS 17)

```
ios/flutter_object_capture/Package.swift          // .iOS("17.0"), FlutterFramework dep, like roomplan
ios/flutter_object_capture.podspec                // s.frameworks/weak_frameworks = ['RealityKit']
ios/flutter_object_capture/Sources/flutter_object_capture/
  SwiftFlutterObjectCapturePlugin.swift           // register channels, route calls
  ObjectCaptureController.swift                   // owns session + Task; EventChannel stream handler
  ObjectCaptureOutputConverter.swift              // PhotogrammetrySession.Output -> [String: Any]
  ObjectCaptureErrorMapper.swift                  // Error -> FlutterError code
```
Flow: `startReconstruction` -> guard `isSupported` -> validate not already running -> build `Configuration` -> `PhotogrammetrySession(input:configuration:)` (throws -> `invalid_images`) -> `Task { for try await output in session.outputs { convert and send on main } }` -> `session.process(requests: [.modelFile(url:, detail: .reduced)])` (throws -> `invalid_output`) -> method call returns when job accepted; events carry the rest. `requestComplete(.modelFile(url))` -> `completed`; `requestError` -> mapped error then end stream; `processingCancelled` -> `cancelled`. Events must be dispatched on the main thread (FlutterEventSink). Keep strong ref to session until terminal output. Guard `#if canImport(RealityKit)` like roomplan's `canImport(RoomPlan)`; simulator behavior of `isSupported` is **UNVERIFIED** (the WWDC24 capture sample does not compile for Simulator; that concerns `ObjectCaptureSession`, matters in phase 5). Consider `isIdleTimerDisabled = true` during a job (long GPU work; **UNVERIFIED** need, spike).

Not needed in the plugin: camera permission (reconstruction reads files; no `NSCameraUsageDescription` until guided capture exists).

## 5. File layout

```
packages/flutter_object_capture/
  pubspec.yaml            version 0.0.1 (CONTRIBUTING), platforms: ios, resolution: workspace, plugin pluginClass: SwiftFlutterObjectCapturePlugin
  CHANGELOG.md  LICENSE  README.md  analysis_options.yaml
  lib/flutter_object_capture.dart                 // public exports (same precedent as roomplan_flutter.dart)
  lib/api/object_capture_processor.dart  exceptions.dart
  lib/api/models/{object_capture_configuration, feature_sensitivity, sample_ordering, object_capture_limits,
                  reconstruction_event, reconstruction_progress, reconstruction_sample_issue,
                  reconstruction_notice, reconstruction_notice_type, reconstruction_completed}.dart
  lib/src/services/object_capture_channel.dart    // MethodChannel + EventChannel, PlatformException -> exception
  lib/src/helpers/reconstruction_event_helper.dart // map payload -> sealed event (static)
  lib/src/helpers/output_path_helper.dart          // .usdz validation (static)
  ios/ ...as in section 4
  test/{models,event_helper,output_path_helper,channel_mapping,processor}_test.dart
  example/ (section 7)
```
Workspace wiring: add `packages/flutter_object_capture` and `/example` to root `pubspec.yaml` `workspace:`; update `docs/PACKAGES.md` (Planned -> In progress) and the README table row; CONTRIBUTING step list. Naming already fixed by CONTRIBUTING (`flutter_<framework>`). No `ScanConfiguration`-style fields that never reach native (lesson from roomplan 0.3.0 changelog): every Dart config field must be wired in the same commit.

## 6. Test strategy

Unit-testable (CI, `flutter test`, no device):
- Model value semantics / equality; sealed-event exhaustiveness.
- `ReconstructionEventHelper`: every payload shape incl. malformed (missing keys -> `DataParsingException`-style error), fraction clamping 0..1.
- `OutputPathHelper`: `.usdz` accepted, directory/other extension rejected.
- `ObjectCaptureChannel` with mocked `MethodChannel`/`EventChannel` (as `roomplan_flutter_test.dart` does): each native error code -> right exception; `isSupported` false when channel throws or off iOS; single-job guard; subscription cancel calls `cancelReconstruction`; stream closes after `completed`.
- Optional Swift XCTest of `ObjectCaptureOutputConverter` (Output/Result cases are constructible without hardware); skip in v1 unless converter logic grows (roomplan has no Swift tests).

Device-only (checklist in README/CLAUDE.md like roomplan):
- Real reconstruction, progress cadence, cancel mid-run, `isSupported` on LiDAR and non-LiDAR phones, limits values, `invalidSample` for >max images / oversized images, `insufficientStorage`, `automaticDownsampling` under memory pressure, backgrounding mid-job, thermal throttling, output file opens in Quick Look / RealityKit, repeated runs (memory), HEIC with and without depth (scale) and JPEG acceptance.
Gate per CONTRIBUTING: `melos run test`, `analyze`, `format-check`; iOS changes require a real-device run.

## 7. Example app

MVC, well organized (owner change, 2026-10-24). Rules: one class per file, no widget functions, even sizes, no UPPER_CASE, strings in a strings file. Layout:
```
example/lib/
  models/        // M: plain immutable data classes (e.g. reconstruct_form.dart, result_info.dart)
  views/         // V: pages; only initState/dispose/build, listen via ListenableBuilder
    support_page.dart  reconstruct_page.dart  result_page.dart
  controllers/   // C: ChangeNotifier classes
    support_controller.dart  reconstruct_controller.dart  result_controller.dart
  widgets/       // one folder per component allowed (e.g. progress_card/)
    progress_card  event_log_tile  limits_card  result_card  unsupported_card
  helpers/       // *_actions_helper: private ctor + static; flows needing context/navigation
  strings/       // all UI text
```
1. `SupportPage` + `SupportController`: `isSupported`, `getLimits`, device note.
2. `ReconstructPage` + `ReconstructController`: choose images folder (needs a picker dependency, e.g. `file_picker` `getDirectoryPath`; **UNVERIFIED** iOS behavior), choose output name, Start/Cancel, progress bar + estimated time, live list of sample issues and notices.
3. `ResultPage` + `ResultController`: output path, file size, open/share the USDZ (Quick Look via an `open_filex`-style package, **UNVERIFIED**; fallback: share sheet).
Widgets (in `widgets/`): `progress_card`, `event_log_tile`, `limits_card`, `result_card`, `unsupported_card`. Sample photo set must come from the owner or a real capture; none invented. Without guided capture, test photos come from the Camera app (HEIC; depth is only present for depth-capable modes such as Portrait, **UNVERIFIED** for this use) or from the Mac.

## 8. Phases

0. Device spike (Swift-only throwaway app, <=1 day, needs a LiDAR iPhone and ideally a non-LiDAR one): confirm `.reduced` USDZ output, `isSupported` per device and on Simulator, `Limits` values, Output cases seen, ProgressInfo/`ProcessingStage` cases, JPEG vs HEIC, OBJ-directory on iOS, peak memory and time for ~40/100/200 images, session reuse, background behavior. Exit: edit this plan's UNVERIFIED items.
1. Scaffold: package, workspace wiring, podspec/Package.swift, docs rows. `melos bootstrap` green.
2. Dart API + tests (TDD: test first per repo rule), analyzer/format clean.
3. Native layer, wired to the contract tested in phase 2.
4. Example app + device checklist run + README (install, Info.plist note: none needed for v1, error handling table) + CHANGELOG 0.0.1 -> 0.1.0 on the first real-device pass.
5. (Only if Decision 1 = yes) Guided capture: `ObjectCaptureCoordinator` presenting `UIHostingController(ObjectCaptureView)` modally, `captureImages()` returns `{imagesDirectory, checkpointDirectory}` that feed `reconstruct`; adds `NSCameraUsageDescription`, simulator compile guards, `isOverCaptureEnabled`, area mode flag, cancel/swipe-dismiss handling (same bug class as roomplan 0.2.1).
6. (Only if Decision 2 = yes) macOS target, detail levels, poses, custom detail.

## 9. Risks

- iOS yields only `.reduced`: quality ceiling is fixed by Apple; photoreal furniture (the PACKAGES.md "synergy with RoomPlan" story) may not hold. Mitigation: show phase 0 sample outputs to the owner before building the Dart API.
- Without phase 5 the iOS package needs photos with depth/gravity that Flutter camera/picker plugins usually do not produce (they strip or never capture depth) -> scale errors, weaker results. Biggest product risk; see Decision 1.
- Hardware gating is vague (LiDAR vs A-series vs RAM) and only `isSupported` is authoritative; Apple's own docs disagree on wording ("select devices with LiDAR" vs iPhone 12 Pro list). Expose `isSupported` and show its result, do not hardcode a device list (roomplan's LiDAR device list needed manual upkeep every release, see CHANGELOG 0.3.0).
- Memory pressure / thermal / backgrounding can kill a long GPU job; only `automaticDownsampling` is signalled. Needs device measurements.
- Untyped `requestError`: only three typed Apple errors; others are opaque strings, so `ReconstructionFailedException` is a catch-all.
- API-surface drift: no iOS 26/27 notes found; re-verify against Xcode release notes before 0.1.0.
- Repo doc conflict (not this package's problem, flagging): ARCHITECTURE.md plans an umbrella `apple_camera_kit` that re-exports siblings, which conflicts with the owner's no-re-export rule (design-system barrels are the only exception). Resolve before the umbrella is built.
- Large outputs (~tens of MB USDZ) and disk use: checkpoints and images live in app sandbox; document cleanup responsibility (the package never deletes caller files).

## 10. Decisions that belong to the owner (product only)

The owner approved the plan as written (with the section 7 MVC change). Decisions 3, 4 and 5 were not answered individually and stay open (recommendations unchanged).

1. Is guided capture (`ObjectCaptureView`) part of this package's 1.0? My recommendation: yes as phase 5, v1 ships reconstruction first. Without it, the iOS use case depends on the app supplying depth-bearing photos.
2. Is macOS / desktop pipeline (higher detail levels, poses) wanted, or iOS only? PACKAGES.md currently promises both.
3. Which concrete workflow does the Paint app need from this (furniture models per RoomPlan box, or product/sample objects)? It sets the acceptable quality bar and whether `.reduced` is enough.
4. Should non-LiDAR iPhones be offered anything (the docs imply they may be unsupported), or just show "not supported"?
5. Publish as `0.1.0` to pub.dev after the device pass, or keep it private until phase 5?
