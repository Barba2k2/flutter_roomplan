#if os(iOS) && canImport(RealityKit)
import RealityKit
import SwiftUI

/// Bottom buttons that follow the session state, as in Apple's guided capture sample.
struct ObjectCaptureControlsView: View {
  let session: ObjectCaptureSession
  let areaMode: Bool
  let onCancel: () -> Void

  var body: some View {
    HStack(spacing: 16) {
      Button("Cancel", role: .cancel, action: onCancel)
        .buttonStyle(.bordered)
      primaryButton
    }
    .padding()
  }

  @ViewBuilder
  private var primaryButton: some View {
    switch session.state {
    case .ready:
      Button("Continue") {
        // Area mode skips object detection and goes straight to capturing.
        if areaMode {
          session.startCapturing()
        } else {
          _ = session.startDetecting()
        }
      }
      .buttonStyle(.borderedProminent)
    case .detecting:
      Button("Start capture") { session.startCapturing() }
        .buttonStyle(.borderedProminent)
    case .capturing:
      Button("Finish") { session.finish() }
        .buttonStyle(.borderedProminent)
    default:
      EmptyView()
    }
  }
}
#endif
