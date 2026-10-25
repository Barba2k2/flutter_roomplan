#if os(iOS) && canImport(RealityKit)
import RealityKit
import SwiftUI

/// Root of the modal guided capture screen: camera feed, point cloud review and controls.
struct ObjectCaptureScreenView: View {
  let session: ObjectCaptureSession
  let areaMode: Bool
  let onCancel: () -> Void

  var body: some View {
    ZStack(alignment: .bottom) {
      if session.state == .capturing && session.userCompletedScanPass {
        ObjectCapturePointCloudView(session: session)
      } else {
        ObjectCaptureView(session: session)
      }
      if session.state != .finishing && session.state != .completed {
        ObjectCaptureControlsView(session: session, areaMode: areaMode, onCancel: onCancel)
      }
    }
  }
}
#endif
