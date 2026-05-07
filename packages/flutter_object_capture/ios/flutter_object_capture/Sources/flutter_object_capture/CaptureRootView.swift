import SwiftUI
#if canImport(RealityKit)
import RealityKit
#endif

/// Root SwiftUI view shown inside the `UIHostingController` that the
/// coordinator presents. Hosts Apple's `ObjectCaptureView` and overlays a
/// minimal control surface that drives the session's state machine.
///
/// The overlay is intentionally bare-bones: a cancel button in the top
/// right and a single primary action button at the bottom whose label
/// follows the current `ObjectCaptureSession.CaptureState`. Apps that want
/// custom UI should fork this view in a future release.
@available(iOS 17.0, *)
struct CaptureRootView: View {
  /// `ObjectCaptureSession` is `@Observable`, so SwiftUI re-renders on its
  /// state changes when accessed via `@Bindable`.
  @Bindable var session: ObjectCaptureSession

  let onCancel: () -> Void

  var body: some View {
    ZStack {
      if shouldShowCaptureView {
        ObjectCaptureView(session: session)
          .ignoresSafeArea()
      } else {
        Color.black.ignoresSafeArea()
      }

      VStack {
        topBar
        Spacer()
        bottomActions
      }
      .padding()
    }
  }

  private var shouldShowCaptureView: Bool {
    switch session.state {
    case .ready, .detecting, .capturing:
      return true
    default:
      return false
    }
  }

  private var topBar: some View {
    HStack {
      Spacer()
      Button(action: onCancel) {
        Image(systemName: "xmark.circle.fill")
          .symbolRenderingMode(.palette)
          .foregroundStyle(.white, .black.opacity(0.6))
          .font(.system(size: 32))
      }
      .accessibilityLabel("Cancel capture")
    }
  }

  @ViewBuilder
  private var bottomActions: some View {
    switch session.state {
    case .initializing:
      progressBadge("Preparing capture\u{2026}")

    case .ready:
      primaryButton(title: "Start detection") {
        session.startDetecting()
      }

    case .detecting:
      VStack(spacing: 12) {
        instructionBadge(
          "Move the device until the box wraps the object, then tap Continue.")
        primaryButton(title: "Continue") {
          session.startCapturing()
        }
      }

    case .capturing:
      capturingControls

    case .finishing:
      progressBadge("Finishing capture\u{2026}")

    case .completed:
      progressBadge("Capture complete")

    case .failed:
      EmptyView()

    @unknown default:
      EmptyView()
    }
  }

  @ViewBuilder
  private var capturingControls: some View {
    if session.userCompletedScanPass {
      VStack(spacing: 12) {
        instructionBadge(
          "Pass complete. Start another pass or finish.")
        HStack(spacing: 12) {
          secondaryButton(title: "New pass") {
            session.beginNewScanPass()
          }
          primaryButton(title: "Finish") {
            session.finish()
          }
        }
      }
    } else {
      instructionBadge("Walk slowly around the object.")
    }
  }

  // MARK: - UI primitives

  private func primaryButton(title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(title)
        .font(.headline)
        .frame(maxWidth: .infinity, minHeight: 50)
    }
    .buttonStyle(.borderedProminent)
    .controlSize(.large)
  }

  private func secondaryButton(title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(title)
        .font(.headline)
        .frame(maxWidth: .infinity, minHeight: 50)
    }
    .buttonStyle(.bordered)
    .controlSize(.large)
    .tint(.white)
  }

  private func instructionBadge(_ text: String) -> some View {
    Text(text)
      .font(.subheadline.weight(.medium))
      .multilineTextAlignment(.center)
      .foregroundStyle(.white)
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .background(.black.opacity(0.55), in: Capsule())
  }

  private func progressBadge(_ text: String) -> some View {
    HStack(spacing: 8) {
      ProgressView()
        .progressViewStyle(.circular)
        .tint(.white)
      Text(text)
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.white)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .background(.black.opacity(0.55), in: Capsule())
  }
}
