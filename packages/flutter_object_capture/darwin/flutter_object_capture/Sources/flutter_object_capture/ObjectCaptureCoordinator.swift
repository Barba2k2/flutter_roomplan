import Foundation
#if os(iOS) && canImport(RealityKit)
import RealityKit
import UIKit
import SwiftUI

/// Hosts the guided capture UI modally and resolves the caller exactly once.
/// Main-thread confined: every entry point is `@MainActor`.
class ObjectCaptureCoordinator: NSObject, UIAdaptivePresentationControllerDelegate {
  private var session: ObjectCaptureSession?
  private var hosting: UIViewController?
  private var stateTask: Task<Void, Never>?
  private var completion: ((ObjectCaptureOutcome) -> Void)?
  private var busy = false

  var isActive: Bool { busy }

  @MainActor
  func begin(
    imagesDirectory: URL,
    checkpointDirectory: URL?,
    isOverCaptureEnabled: Bool,
    areaMode: Bool,
    presenter: UIViewController,
    completion: @escaping (ObjectCaptureOutcome) -> Void
  ) {
    busy = true
    self.completion = completion

    var configuration = ObjectCaptureSession.Configuration()
    configuration.checkpointDirectory = checkpointDirectory
    configuration.isOverCaptureEnabled = isOverCaptureEnabled

    let newSession = ObjectCaptureSession()
    session = newSession

    let screen = ObjectCaptureScreenView(
      session: newSession, areaMode: areaMode, onCancel: { [weak self] in self?.cancelByUser() })
    let host = UIHostingController(rootView: screen)
    host.presentationController?.delegate = self
    hosting = host

    stateTask = Task { @MainActor [weak self] in
      for await state in newSession.stateUpdates {
        guard let self, self.session === newSession else { return }
        switch state {
        case .completed:
          self.resolve(.completed(imageCount: newSession.numberOfShotsTaken))
        case .failed(let error):
          self.resolve(.failed(error))
        default:
          break
        }
      }
    }

    presenter.present(host, animated: true)
    // Errors such as a non-empty directory arrive through `.failed`, not as a throw.
    newSession.start(imagesDirectory: imagesDirectory, configuration: configuration)
  }

  // MARK: - UIAdaptivePresentationControllerDelegate

  /// Swipe-down dismiss: the Dart call must still complete (same bug class as roomplan 0.2.1).
  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    MainActor.assumeIsolated { cancelByUser() }
  }

  // MARK: - Resolution

  @MainActor
  private func cancelByUser() {
    session?.cancel()
    resolve(.failed(ObjectCaptureSession.Error.cancelled))
  }

  /// First call wins; later calls (state updates after a cancel) are ignored.
  @MainActor
  private func resolve(_ outcome: ObjectCaptureOutcome) {
    guard let completion else { return }
    self.completion = nil
    stateTask?.cancel()
    stateTask = nil
    session = nil
    let host = hosting
    hosting = nil
    let finish = { [weak self] in
      self?.busy = false
      completion(outcome)
    }
    if let host, host.presentingViewController != nil {
      host.dismiss(animated: true, completion: finish)
    } else {
      finish()
    }
  }
}
#endif
