import Foundation
import SwiftUI
import UIKit
import os.log
#if canImport(RealityKit)
import RealityKit
#endif

/// Owns a single `ObjectCaptureSession`, presents the guided capture UI, and
/// reports state transitions back to its caller.
///
/// All public methods must be invoked on the main thread; the SwiftUI host
/// runs there as well.
@available(iOS 17.0, *)
@MainActor
final class CaptureCoordinator {
  /// Outcome reported via `onCompletion`. Either the URL of the directory
  /// containing the captured images or the error that ended the session.
  enum Outcome {
    case success(imagesDirectory: URL)
    case failure(Error)
  }

  let imagesDirectory: URL
  let checkpointDirectory: URL
  let configuration: ObjectCaptureSession.Configuration

  private let log = Logger(
    subsystem: "com.paintpro.flutter_object_capture",
    category: "CaptureCoordinator")

  private(set) var session: ObjectCaptureSession?
  private var hostingController: UIHostingController<CaptureRootView>?
  private var stateObservationTask: Task<Void, Never>?

  private let onStateChange: (ObjectCaptureSession.CaptureState) -> Void
  private let onCompletion: (Outcome) -> Void

  init(
    imagesDirectory: URL,
    checkpointDirectory: URL,
    configuration: ObjectCaptureSession.Configuration,
    onStateChange: @escaping (ObjectCaptureSession.CaptureState) -> Void,
    onCompletion: @escaping (Outcome) -> Void
  ) {
    self.imagesDirectory = imagesDirectory
    self.checkpointDirectory = checkpointDirectory
    self.configuration = configuration
    self.onStateChange = onStateChange
    self.onCompletion = onCompletion
  }

  /// Creates the `ObjectCaptureSession`, mounts the SwiftUI capture view in a
  /// `UIHostingController`, and presents it modally from `presenter`.
  func start(presentingFrom presenter: UIViewController) throws {
    try FileManager.default.createDirectory(
      at: imagesDirectory, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(
      at: checkpointDirectory, withIntermediateDirectories: true)

    let session = ObjectCaptureSession()
    var config = configuration
    config.checkpointDirectory = checkpointDirectory

    session.start(imagesDirectory: imagesDirectory, configuration: config)
    self.session = session

    onStateChange(session.state)

    stateObservationTask = Task { [weak self] in
      guard let self else { return }
      for await state in session.stateUpdates {
        await self.handleStateUpdate(state)
      }
    }

    let rootView = CaptureRootView(
      session: session,
      onCancel: { [weak self] in self?.cancel() })
    let host = UIHostingController(rootView: rootView)
    host.modalPresentationStyle = .fullScreen
    host.isModalInPresentation = true
    self.hostingController = host

    presenter.present(host, animated: true)
  }

  /// Cancels an active session. Triggers a `failed` state transition that the
  /// observer translates into `Outcome.failure`.
  func cancel() {
    session?.cancel()
  }

  // MARK: - Private

  private func handleStateUpdate(_ state: ObjectCaptureSession.CaptureState) {
    onStateChange(state)

    switch state {
    case .completed:
      finish(with: .success(imagesDirectory: imagesDirectory))
    case .failed(let error):
      finish(with: .failure(error))
    default:
      break
    }
  }

  private func finish(with outcome: Outcome) {
    stateObservationTask?.cancel()
    stateObservationTask = nil

    let host = hostingController
    hostingController = nil
    session = nil

    if let host {
      host.dismiss(animated: true) { [onCompletion] in
        onCompletion(outcome)
      }
    } else {
      onCompletion(outcome)
    }
  }
}
