import Foundation
#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif

/// Registers the Object Capture channels and routes calls to `ObjectCaptureController`.
public class SwiftFlutterObjectCapturePlugin: NSObject, FlutterPlugin {
  private let controller = ObjectCaptureController()

  public static func register(with registrar: FlutterPluginRegistrar) {
    #if os(iOS)
    let messenger = registrar.messenger()
    #else
    let messenger = registrar.messenger
    #endif
    let channel = FlutterMethodChannel(
      name: "flutter_object_capture/method_channel", binaryMessenger: messenger)
    let instance = SwiftFlutterObjectCapturePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    let eventChannel = FlutterEventChannel(
      name: "flutter_object_capture/event_channel", binaryMessenger: messenger)
    eventChannel.setStreamHandler(instance.controller)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isSupported":
      result(controller.isSupported)
    case "getLimits":
      result(controller.getLimits() ?? FlutterError(
        code: "not_supported", message: "Object Capture is not supported on this device.", details: nil))
    case "isGuidedCaptureSupported":
      result(controller.isGuidedCaptureSupported)
    case "captureImages":
      MainActor.assumeIsolated {
        controller.captureImages(arguments: call.arguments, result: result)
      }
    case "startReconstruction":
      controller.startReconstruction(arguments: call.arguments, result: result)
    case "cancelReconstruction":
      controller.cancelReconstruction(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
