import Foundation
import os.log
#if canImport(RealityKit)
import RealityKit
#endif

/// Drives a single `PhotogrammetrySession` reconstruction run.
///
/// The runner takes a folder of input images and writes a `.usdz` model to
/// `outputURL`. Progress is delivered through `progressHandler` and the final
/// outcome through `completion`. All callbacks are invoked on the main thread.
///
/// `PhotogrammetrySession` requires iOS 17+; the runner is annotated
/// accordingly.
@available(iOS 17.0, *)
final class PhotogrammetryRunner {
  enum RunnerError: Error {
    case cancelled
    case noOutput
  }

  private let log = Logger(
    subsystem: "com.paintpro.flutter_object_capture",
    category: "PhotogrammetryRunner")

  private var task: Task<Void, Never>?

  /// Cancels an in-flight reconstruction. Calls the original `completion`
  /// closure with `RunnerError.cancelled`.
  func cancel() {
    task?.cancel()
  }

  /// Maps Dart's `DetailLevel` enum names to `PhotogrammetrySession.Request.Detail`.
  static func detail(from name: String) -> PhotogrammetrySession.Request.Detail? {
    switch name {
    case "preview": return .preview
    case "reduced": return .reduced
    case "medium": return .medium
    case "full": return .full
    case "raw": return .raw
    default: return nil
    }
  }

  /// Starts a reconstruction. Returns immediately; results arrive via
  /// `progressHandler` and `completion` on the main thread.
  func run(
    inputURL: URL,
    outputURL: URL,
    detail: PhotogrammetrySession.Request.Detail,
    progressHandler: @escaping (Double) -> Void,
    completion: @escaping (Result<TimeInterval, Error>) -> Void
  ) {
    let started = Date()
    let log = self.log

    task = Task.detached { [weak self] in
      do {
        let session = try PhotogrammetrySession(input: inputURL)
        let request = PhotogrammetrySession.Request.modelFile(
          url: outputURL, detail: detail)

        let outputs = session.outputs

        try session.process(requests: [request])

        var completedSuccessfully = false

        for try await output in outputs {
          if Task.isCancelled {
            break
          }

          switch output {
          case .processingComplete:
            completedSuccessfully = true

          case .requestProgress(_, let fraction):
            await MainActor.run { progressHandler(fraction) }

          case .requestComplete:
            // Per-request completion; processing-wide signal arrives via
            // .processingComplete above.
            break

          case .requestError(_, let error):
            log.error("PhotogrammetrySession request error: \(String(describing: error), privacy: .public)")
            await MainActor.run { completion(.failure(error)) }
            return

          case .processingCancelled:
            await MainActor.run { completion(.failure(RunnerError.cancelled)) }
            return

          case .invalidSample(let id, let reason):
            log.warning("invalid sample \(id, privacy: .public): \(reason, privacy: .public)")

          case .skippedSample(let id):
            log.warning("skipped sample \(id, privacy: .public)")

          case .automaticDownsampling:
            log.info("automatic downsampling enabled")

          case .stitchingIncomplete:
            log.warning("stitching incomplete")

          case .inputComplete:
            break

          @unknown default:
            log.info("unhandled PhotogrammetrySession output")
          }
        }

        guard let _ = self else { return }

        if Task.isCancelled {
          await MainActor.run { completion(.failure(RunnerError.cancelled)) }
        } else if completedSuccessfully {
          let duration = Date().timeIntervalSince(started)
          await MainActor.run { completion(.success(duration)) }
        } else {
          await MainActor.run { completion(.failure(RunnerError.noOutput)) }
        }
      } catch {
        await MainActor.run { completion(.failure(error)) }
      }
    }
  }
}
