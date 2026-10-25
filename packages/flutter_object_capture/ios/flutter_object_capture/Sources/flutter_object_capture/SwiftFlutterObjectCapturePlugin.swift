import Flutter
import UIKit

/// Registers the Object Capture channels and routes calls to `ObjectCaptureController`.
public class SwiftFlutterObjectCapturePlugin: NSObject, FlutterPlugin {
  private let controller = ObjectCaptureController()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "flutter_object_capture/method_channel", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterObjectCapturePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    let eventChannel = FlutterEventChannel(
      name: "flutter_object_capture/event_channel", binaryMessenger: registrar.messenger())
    eventChannel.setStreamHandler(instance.controller)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isSupported":
      result(controller.isSupported)
    case "getLimits":
      result(controller.getLimits() ?? FlutterError(
        code: "not_supported", message: "Object Capture is not supported on this device.", details: nil))
    case "startReconstruction":
      controller.startReconstruction(arguments: call.arguments, result: result)
    case "cancelReconstruction":
      controller.cancelReconstruction(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
