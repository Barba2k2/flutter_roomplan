# flutter_object_capture

Flutter plugin that wraps Apple's RealityKit Object Capture (`PhotogrammetrySession`) to turn a folder of photos into a textured 3D model (USDZ).

**Status:** in progress (scaffold only, no public API yet). See the [plan](../../docs/plans/object-capture-package-plan.md).

## Requirements

- iOS 17.0+
- A device with LiDAR (iPhone 12 Pro or later, LiDAR iPad Pro). `PhotogrammetrySession.isSupported` is the authoritative runtime check.

## License

See [LICENSE](LICENSE).
