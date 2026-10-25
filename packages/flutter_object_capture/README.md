# flutter_object_capture

Flutter plugin that wraps Apple's RealityKit Object Capture (`PhotogrammetrySession`) to turn a folder of photos into a textured 3D model (USDZ).

**Status:** in progress (Dart API done, native reconstruction not implemented yet). See the [plan](../../docs/plans/object-capture-package-plan.md).

## Requirements

- iOS 17.0+
- A device with LiDAR (iPhone 12 Pro or later, LiDAR iPad Pro). `PhotogrammetrySession.isSupported` is the authoritative runtime check.

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

`reconstruct` throws synchronously for an empty images directory, a non-`.usdz` output path, or a second job on the same processor.

## Channel contract

Native implements exactly this (Dart side: `lib/src/services/object_capture_channel.dart` and `lib/src/helpers/reconstruction_event_helper.dart`).

Channels: `MethodChannel('flutter_object_capture/method_channel')`, `EventChannel('flutter_object_capture/event_channel')`.

Dart subscribes to the event channel first, then calls `startReconstruction`.

| Method | Arguments | Result |
|--------|-----------|--------|
| `isSupported` | none | `bool` |
| `getLimits` | none | `{maxImages: int, maxImageDimension: int}` |
| `startReconstruction` | `{imagesDirectory: String, outputPath: String (.usdz), featureSensitivity: "normal"\|"high", sampleOrdering: "unordered"\|"sequential"}` | returns (null) once the job is accepted; progress and the result arrive on the event channel |
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
| `insufficient_storage` (details `{requiredBytes: int}`) | `InsufficientStorageException` |
| `session_in_progress` | `ReconstructionInProgressException` |
| `cancelled` | `ReconstructionCancelledException` |
| `reconstruction_failed` (message = `localizedDescription`) | `ReconstructionFailedException` |
| `not_supported` | `ObjectCaptureNotSupportedException` |
| anything else | `NativeChannelException` |

## License

See [LICENSE](LICENSE).
