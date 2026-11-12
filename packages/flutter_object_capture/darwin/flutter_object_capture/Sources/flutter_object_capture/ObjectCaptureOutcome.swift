import Foundation

/// Final result of one guided capture: delivered to the caller exactly once.
enum ObjectCaptureOutcome {
  case completed(imageCount: Int)
  case failed(Error)
}
