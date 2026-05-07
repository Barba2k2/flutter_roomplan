# Packages

This document tracks every package planned for or shipped from this monorepo, along with its scope, the Apple framework(s) it wraps, and its current status.

## Status legend

- **Stable** — published on pub.dev, public API considered stable.
- **Beta** — published, public API may still change.
- **In progress** — actively being implemented in this repo, not yet published.
- **Planned** — agreed scope, not started.
- **Considering** — under evaluation, may not ship.

## Current and planned packages

### `roomplan_flutter`

- **Status:** Stable
- **Apple framework:** [RoomPlan](https://developer.apple.com/documentation/roomplan)
- **Platforms:** iOS 16+
- **Scope:** 3D parametric room scanning using LiDAR. Captures walls, doors, windows, openings, and bounding boxes for furniture / appliances. Exports USDZ.
- **Why it exists:** Apple's first-party room-scanning framework has no Flutter binding; this plugin provides a typed Dart API plus dual unit support (metric / imperial) and performance helpers.
- **Source:** [`packages/roomplan_flutter`](../packages/roomplan_flutter)

### `flutter_object_capture`

- **Status:** Alpha (`0.0.2` — both `ObjectCaptureSession` and `PhotogrammetrySession` wired through; not yet validated on a real device)
- **Apple framework:** [RealityKit Object Capture](https://developer.apple.com/documentation/realitykit/photogrammetrysession) (`ObjectCaptureSession` + `PhotogrammetrySession`)
- **Platforms:** iOS 17+ (on-device); macOS 12+ (desktop pipeline) is a future target.
- **Scope:** Guided photo capture and on-device photogrammetry. Takes a set of photos and produces a textured `USDZ` model.
- **Synergy with RoomPlan:** RoomPlan returns furniture as bounding boxes only; Object Capture lets the consumer turn those boxes into photorealistic meshes.
- **Source:** [`packages/flutter_object_capture`](../packages/flutter_object_capture)

### `flutter_realitykit`

- **Status:** Planned
- **Apple framework:** [RealityKit](https://developer.apple.com/documentation/realitykit)
- **Platforms:** iOS 13+, macOS 10.15+
- **Scope:** Render and interact with 3D scenes / USDZ assets in a Flutter widget. Anchors, entities, lighting, animation hooks.
- **Why it exists:** Most consumers of `roomplan_flutter` and `flutter_object_capture` need to display the resulting 3D model.

### `flutter_apple_vision`

- **Status:** Planned
- **Apple framework:** [Vision](https://developer.apple.com/documentation/vision)
- **Platforms:** iOS 13+, macOS 10.15+
- **Scope:** Object detection / classification, OCR, rectangle detection, face landmarks, image segmentation. Operates on `UIImage`, `CVPixelBuffer`, or file URLs.

### `flutter_visionkit`

- **Status:** Planned
- **Apple framework:** [VisionKit](https://developer.apple.com/documentation/visionkit)
- **Platforms:** iOS 13+ (`VNDocumentCameraViewController`); iOS 16+ (`DataScannerViewController`); iOS 16+ (Live Text).
- **Scope:** UI-driven document scanning, real-time text + barcode capture, Live Text. Distinct from `flutter_apple_vision` (which is the lower-level CV engine).

### `flutter_avfoundation_camera`

- **Status:** Planned
- **Apple framework:** [AVFoundation Capture](https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture) (`AVCaptureSession`, `AVCaptureDevice`, `AVCapturePhotoOutput`, `AVCaptureVideoPreviewLayer`, `AVCaptureDevice.DiscoverySession`, `AVCapturePhoto`, `AVCaptureOutput`)
- **Platforms:** iOS 13+, macOS 10.15+
- **Scope:** Full camera capture pipeline with access to advanced features the official `camera` plugin does not surface (ProRAW, multi-cam sessions, depth data, custom photo settings).
- **Note:** The full `AVFoundation` capture stack ships in **one** package — splitting it would force consumers to reassemble the pipeline by hand.

### `flutter_photokit`

- **Status:** Planned
- **Apple framework:** [Photos / PhotoKit](https://developer.apple.com/documentation/photokit) + [PhotosUI](https://developer.apple.com/documentation/photosui)
- **Platforms:** iOS 14+, macOS 11+
- **Scope:** Read / write the user's photo library, save assets, fetch albums, request `PHPickerViewController` for selection. Photos and PhotosUI ship together because the picker depends on the library types.

### `flutter_core_image`

- **Status:** Planned
- **Apple framework:** [Core Image](https://developer.apple.com/documentation/coreimage) + [Image I/O](https://developer.apple.com/documentation/imageio)
- **Platforms:** iOS 13+, macOS 10.15+
- **Scope:** Apply CIFilters, color management, HEIC ↔ JPEG conversion, EXIF metadata read / write. Image I/O bundled because it is the substrate for Core Image's I/O on Apple platforms.

### `apple_camera_kit` (umbrella)

- **Status:** Planned
- **Apple framework:** none directly
- **Platforms:** iOS / macOS (inherited from children)
- **Scope:** Pure-Dart meta-package that re-exports every plugin in this repo. See [`ARCHITECTURE.md`](ARCHITECTURE.md#the-umbrella-package-apple_camera_kit) for design notes and trade-offs.

## Packages explicitly NOT planned

The following Apple frameworks were considered and excluded from the roadmap:

| Framework | Reason for exclusion |
| --- | --- |
| Core Media (`CMSampleBuffer`, `CMTime`) | Low-level types do not survive Flutter's platform channel boundary cleanly. Will be exposed implicitly through `flutter_avfoundation_camera`. |
| Core Video (`CVPixelBuffer`, `CVMetalTextureCache`) | Same reason as Core Media. |
| Core Media I/O | Niche (external cameras on macOS), no clear Flutter use case. |
| ImageCaptureCore | Legacy framework for USB scanners / cameras on macOS. |
| Video Toolbox | Codec-level encode / decode; almost no Flutter use case. Reconsider on demand. |
| Metal Performance Shaders Graph | GPU compute graph; better consumed indirectly via Vision / Object Capture than as a raw Flutter API. |
| ScreenCaptureKit | macOS-only screen capture; out of scope for an Apple-camera-focused family. May ship later if there is demand. |

These can be revisited if a concrete consumer use case appears.

## Roadmap (suggested order)

1. **`flutter_object_capture`** — highest synergy with the existing `roomplan_flutter`, no good alternative on pub.dev.
2. **`flutter_apple_vision` + `flutter_visionkit`** — broad applicability beyond room scanning.
3. **`flutter_realitykit`** — high implementation complexity, but unblocks rich visualization for the rest of the family.
4. **`flutter_avfoundation_camera`** — only if there is demand for features beyond what the official `camera` plugin offers.
5. **`flutter_photokit`**.
6. **`flutter_core_image`**.
7. **`apple_camera_kit`** — ships last, once the children have stabilized enough public APIs to be worth re-exporting.
