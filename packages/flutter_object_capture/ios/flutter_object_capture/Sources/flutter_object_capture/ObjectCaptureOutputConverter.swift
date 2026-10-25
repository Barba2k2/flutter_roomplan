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
    switch output {
    case .requestProgress(_, let fractionComplete):
      return ["type": "progress", "fraction": fractionComplete]
    case .requestProgressInfo(_, let info):
      var payload: [String: Any] = ["type": "progress", "fraction": lastFraction]
      if let remaining = info.estimatedRemainingTime {
        payload["estimatedRemainingSeconds"] = remaining
      }
      return payload
    case .invalidSample(let id, let reason):
      return ["type": "sampleIssue", "sampleId": id, "reason": reason, "skipped": false]
    case .skippedSample(let id):
      return ["type": "sampleIssue", "sampleId": id, "skipped": true]
    case .inputComplete:
      return ["type": "notice", "notice": "inputComplete"]
    case .automaticDownsampling:
      return ["type": "notice", "notice": "automaticDownsampling"]
    case .stitchingIncomplete:
      return ["type": "notice", "notice": "stitchingIncomplete"]
    case .requestComplete(_, .modelFile(let url)):
      let size = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber
      return [
        "type": "completed", "modelPath": url.path, "fileSizeBytes": size?.intValue ?? 0,
      ]
    default:
      return nil
    }
  }
}
#endif
