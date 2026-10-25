import Foundation
#if canImport(RealityKit)
import RealityKit
#endif

/// Maps native errors to the channel error codes documented in the README.
/// Pure Foundation/RealityKit; the caller wraps the result in a `FlutterError`.
enum ObjectCaptureErrorMapper {
  typealias Mapped = (code: String, message: String, details: Any?)

  static let notSupported: Mapped = (
    "not_supported", "Object Capture is not supported on this device.", nil
  )
  static let sessionInProgress: Mapped = (
    "session_in_progress", "A reconstruction is already running.", nil
  )
  static let cancelled: Mapped = ("cancelled", "Reconstruction cancelled.", nil)

  static func map(_ error: Error) -> Mapped {
    #if canImport(RealityKit)
    if let sessionError = error as? PhotogrammetrySession.Error {
      switch sessionError {
      case .insufficientStorage(let requiredBytes):
        return (
          "insufficient_storage", error.localizedDescription, ["requiredBytes": requiredBytes]
        )
      case .invalidImages:
        return ("invalid_images", error.localizedDescription, nil)
      case .invalidOutput:
        return ("invalid_output", error.localizedDescription, nil)
      @unknown default:
        break
      }
    }
    #endif
    return ("reconstruction_failed", error.localizedDescription, nil)
  }
}
