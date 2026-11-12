# flutter_object_capture

Flutter plugin that wraps Apple's RealityKit Object Capture (`PhotogrammetrySession`) to turn a folder of photos into a textured 3D model (USDZ, or an OBJ directory on macOS).

**Status:** in progress (Dart API and native layers done, guided capture and macOS added; not yet run on a device). See the [plan](../../docs/plans/object-capture-package-plan.md).

## Requirements

- iOS 17.0+ on a device with LiDAR (iPhone 12 Pro or later, LiDAR iPad Pro), or
- macOS 12.0+ on a Mac with a GPU that supports Object Capture (4 GB, ray tracing; Apple silicon recommended). `PhotogrammetrySession.isSupported` is the authoritative runtime check; it exists from macOS 13, so macOS 12 reports unsupported, and `getLimits` needs macOS 14.

The iOS and macOS code share one `darwin/` source folder (`sharedDarwinSource`), guarded with `#if os(iOS)` / `#if os(macOS)`.

| Feature | iOS 17+ | macOS 12+ |
|---------|---------|-----------|
| `isSupported`, `getLimits`, `reconstruct`, `cancel` | yes | yes (`getLimits` macOS 14+) |
| Detail `reduced` | yes | yes |
| Detail `preview`, `medium`, `full`, `raw` | no (`UnsupportedDetailException`) | yes |
| Output `ObjectOutputFormat.usdz` | yes | yes |
| Output `ObjectOutputFormat.objDirectory` (USDA + OBJ + textures) | no (`InvalidOutputPathException`) | yes |
| Guided capture (`captureImages`) | yes | no (`isGuidedCaptureSupported` is false, `captureImages` throws `ObjectCaptureNotSupportedException`) |

Not wired yet (optional extras in the plan): poses request, custom detail, mesh primitive, object masking, `ignoreBoundingBox`.

## Usage

```dart
if (await ObjectCaptureProcessor.isSupported()) {
  final processor = ObjectCaptureProcessor();
  final subscription = processor
      .reconstruct(imagesDirectory: photos, outputPath: '$dir/model.usdz')
      .listen(
        (event) => switch (event) {
          ReconstructionProgress() => {},
          ReconstructionSampleIssue() => {},
          ReconstructionNotice() => {},
          ReconstructionCompleted() => {},
        },
        onError: (Object e) {}, // ObjectCaptureException subtypes
      );
  // subscription.cancel() or processor.cancel() stops the job.
}
```

Guided capture (iOS 17+, device with LiDAR) shoots the photos for you and returns a folder that feeds `reconstruct`:

```dart
if (await ObjectCaptureProcessor.isGuidedCaptureSupported()) {
  final captured = await processor.captureImages(imagesDirectory: emptyFolder);
  // captured.imagesDirectory, captured.imageCount
}
```

`captureImages` opens a full-screen capture UI (cancel, continue, start capture, finish). A user cancel or swipe-down throws `ReconstructionCancelledException` (the same type as a cancelled reconstruction). `areaMode: true` skips object detection and goes straight to capturing (UNVERIFIED on a device). `isOverCaptureEnabled` and `checkpointDirectory` map to `ObjectCaptureSession.Configuration`.

## Info.plist requirements

Guided capture uses the camera, so the host app must declare it (reconstruction alone needs no keys):

```xml
<key>NSCameraUsageDescription</key>
<string>This app uses the camera to capture photos of an object and build a 3D model.</string>
```

`reconstruct` throws synchronously for an empty images directory, an output path that does not fit the output format (`.usdz` file for `usdz`, extension-less directory path for `objDirectory`), or a second job on the same processor.

### Detail levels and output format (macOS)

```dart
processor.reconstruct(
  imagesDirectory: photos,
  outputPath: '$dir/chair', // no extension: a directory with USDA + OBJ + textures
  configuration: const ObjectCaptureConfiguration(
    detail: ObjectDetail.full, // preview, reduced (default), medium, full, raw
    outputFormat: ObjectOutputFormat.objDirectory,
  ),
);
```

On iOS any detail other than `reduced` fails the stream with `UnsupportedDetailException`, and `objDirectory` with `InvalidOutputPathException`. For `objDirectory` the completed `fileSizeBytes` is the summed size of the files in the directory.

## Example app

`example/` (iOS and macOS runners) is a small MVC app (`models`, `views`, `controllers`, `widgets`, `helpers`, `strings`) with three screens: device support (`isSupported` + `getLimits`), reconstruct (pick a photos folder, name the output, detail selector on macOS only, Capture photos button only where guided capture is supported, Start/Cancel, progress, sample issues and notices, one clear message per exception type) and result (path, size, share sheet).

What you need to run it for real:
- An iPhone or iPad with LiDAR on iOS 17+, plugged in (the Simulator builds but shows "not supported"), or a supported Mac (`flutter run -d macos`; the example enables the App Sandbox with user-selected read/write access so the folder picker can read your photos).
- A folder of your own photos of one object (HEIC with depth gives a real-world scale). The repo ships no sample photos.

```bash
cd packages/flutter_object_capture/example
flutter run -d <device-id>
```

Dependencies added only for the example: `file_picker` (folder picker), `path_provider` (documents folder where the `.usdz` is saved) and `share_plus` (share sheet). No `Info.plist` keys are needed for them or for reconstruction; guided capture needs `NSCameraUsageDescription` (already set in the example).

iOS notes from the packages' docs and source (not yet checked on a device):
- `file_picker`: `getDirectoryPath()` is supported on iOS (requires iOS 14+) and opens the system document picker in place, without copying. I found no `startAccessingSecurityScopedResource` call in `file_picker_darwin` 2.3.4, so a folder outside the app sandbox (iCloud Drive, other apps) may not be readable by the plugin. If reconstruction reports an invalid images folder, copy the photos to "On My iPhone" and pick that folder. Confirm on the device.
- `share_plus`: opens the iOS share sheet (AirDrop, Save to Files). It is not a Quick Look preview. On iPad a popover origin is passed from the page.
- The `.usdz` is written to the app documents directory and never deleted by the plugin or the example.

## Channel contract

Native implements exactly this (Dart side: `lib/src/services/object_capture_channel.dart` and `lib/src/helpers/reconstruction_event_helper.dart`).

Channels: `MethodChannel('flutter_object_capture/method_channel')`, `EventChannel('flutter_object_capture/event_channel')`.

Dart subscribes to the event channel first, then calls `startReconstruction`.

| Method | Arguments | Result |
|--------|-----------|--------|
| `isSupported` | none | `bool` |
| `getLimits` | none | `{maxImages: int, maxImageDimension: int}` |
| `isGuidedCaptureSupported` | none | `bool` (`ObjectCaptureSession.isSupported`) |
| `captureImages` | `{imagesDirectory: String (empty folder, created natively when missing), checkpointDirectory: String?, isOverCaptureEnabled: bool, areaMode: bool}` | `{imagesDirectory: String, checkpointDirectory: String?, imageCount: int}` once the user finishes; user cancel, swipe-down and failures resolve the call once with an error |
| `startReconstruction` | `{imagesDirectory: String, outputPath: String (.usdz file, or extension-less directory for objDirectory), featureSensitivity: "normal"\|"high", sampleOrdering: "unordered"\|"sequential", detail: "preview"\|"reduced"\|"medium"\|"full"\|"raw", outputFormat: "usdz"\|"objDirectory"}` | returns (null) once the job is accepted; progress and the result arrive on the event channel |
| `cancelReconstruction` | none | returns; native then emits the `cancelled` error event |

Events (maps with a `type` key):

| `type` | Keys |
|--------|------|
| `progress` | `fraction: double` (clamped to 0..1 in Dart), `estimatedRemainingSeconds: double?` |
| `sampleIssue` | `sampleId: int`, `reason: String?`, `skipped: bool?` (default false) |
| `notice` | `notice: "inputComplete"\|"automaticDownsampling"\|"stitchingIncomplete"` |
| `completed` | `modelPath: String`, `fileSizeBytes: int` (terminal; Dart closes the stream) |

A malformed event fails the stream with `PayloadParsingException`.

Errors (`FlutterError` on either channel, `code` to Dart exception):

| Code | Exception |
|------|-----------|
| `invalid_images` | `InvalidImagesDirectoryException` |
| `invalid_output` | `InvalidOutputPathException` |
| `unsupported_detail` | `UnsupportedDetailException` |
| `insufficient_storage` (details `{requiredBytes: int}`) | `InsufficientStorageException` |
| `session_in_progress` | `ReconstructionInProgressException` |
| `cancelled` | `ReconstructionCancelledException` |
| `reconstruction_failed` (message = `localizedDescription`) | `ReconstructionFailedException` |
| `not_supported` | `ObjectCaptureNotSupportedException` |
| `directory_not_empty` | `DirectoryNotEmptyException` |
| `sensor_failed` | `CaptureSensorFailedException` |
| `tracking_failed` | `CaptureTrackingFailedException` |
| `capture_failed` (any other capture error) | `CaptureFailedException` |
| anything else | `NativeChannelException` |

## License

See [LICENSE](LICENSE).
