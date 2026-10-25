import Foundation
#if canImport(RealityKit)
import RealityKit
import SwiftUI
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
  static let unsupportedOutputFormat: Mapped = (
    "invalid_output", "The obj directory output is only supported on macOS.", nil
  )

  static func unsupportedDetail(_ detail: String) -> Mapped {
    ("unsupported_detail", "Detail '\(detail)' is not supported on this platform.", nil)
  }

  static let captureInProgress: Mapped = (
    "session_in_progress", "A guided capture is already running.", nil
  )
  static let captureCancelled: Mapped = ("cancelled", "Capture cancelled.", nil)

  /// Maps a guided capture error (`ObjectCaptureSession.Error` or anything else).
  static func mapCapture(_ error: Error) -> Mapped {
    #if os(iOS) && canImport(RealityKit)
    if let captureError = error as? ObjectCaptureSession.Error {
      switch captureError {
      case .cancelled:
        return captureCancelled
      case .directoryNotEmpty:
        return ("directory_not_empty", error.localizedDescription, nil)
      case .insufficientStorage(let requiredBytes):
        return (
          "insufficient_storage", error.localizedDescription, ["requiredBytes": requiredBytes]
        )
      case .sensorFailed:
        return ("sensor_failed", error.localizedDescription, nil)
      case .trackingFailed:
        return ("tracking_failed", error.localizedDescription, nil)
      @unknown default:
        break
      }
    }
    #endif
    return ("capture_failed", error.localizedDescription, nil)
  }

  static func map(_ error: Error) -> Mapped {
    #if canImport(RealityKit)
    if #available(macOS 14.0, *), let sessionError = error as? PhotogrammetrySession.Error {
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
