import Foundation
#if canImport(RealityKit)
import RealityKit

/// Converts `PhotogrammetrySession.Output` into the event payloads of the channel contract.
/// `processingComplete`, `processingCancelled` and `requestError` are handled by the controller.
enum ObjectCaptureOutputConverter {
  /// `lastFraction` is the latest `requestProgress` value, reused by `requestProgressInfo`
  /// (which carries the remaining-time estimate but no fraction).
  static func payload(for output: PhotogrammetrySession.Output, lastFraction: Double) throws
    -> [String: Any]?
  {
    if #available(macOS 14.0, *) {
      switch output {
      case .requestProgressInfo(_, let info):
        var payload: [String: Any] = ["type": "progress", "fraction": lastFraction]
        if let remaining = info.estimatedRemainingTime {
          payload["estimatedRemainingSeconds"] = remaining
        }
        return payload
      case .stitchingIncomplete:
        return ["type": "notice", "notice": "stitchingIncomplete"]
      default:
        break
      }
    }
    switch output {
    case .requestProgress(_, let fractionComplete):
      return ["type": "progress", "fraction": fractionComplete]
    case .invalidSample(let id, let reason):
      return ["type": "sampleIssue", "sampleId": id, "reason": reason, "skipped": false]
    case .skippedSample(let id):
      return ["type": "sampleIssue", "sampleId": id, "skipped": true]
    case .inputComplete:
      return ["type": "notice", "notice": "inputComplete"]
    case .automaticDownsampling:
      return ["type": "notice", "notice": "automaticDownsampling"]
    case .requestComplete(_, .modelFile(let url)):
      return [
        "type": "completed", "modelPath": url.path, "fileSizeBytes": try sizeInBytes(of: url),
      ]
    default:
      return nil
    }
  }

  /// File size, or the summed size of every file under a directory (macOS obj output).
  private static func sizeInBytes(of url: URL) throws -> Int {
    let manager = FileManager.default
    var isDirectory: ObjCBool = false
    manager.fileExists(atPath: url.path, isDirectory: &isDirectory)
    guard isDirectory.boolValue else {
      let size = try manager.attributesOfItem(atPath: url.path)[.size] as? NSNumber
      return size?.intValue ?? 0
    }
    var total = 0
    for case let file as URL in manager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey])
      ?? NSEnumerator()
    {
      total += try file.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
    }
    return total
  }
}
#endif
