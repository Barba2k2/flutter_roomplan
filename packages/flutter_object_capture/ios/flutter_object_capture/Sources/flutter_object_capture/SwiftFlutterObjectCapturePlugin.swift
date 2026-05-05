import Flutter
import UIKit
#if canImport(RealityKit)
import RealityKit
#endif

/// Entry point for the `flutter_object_capture` plugin.
///
/// Registers the method and event channels and dispatches incoming calls to
/// `ObjectCaptureController`. The controller currently returns
/// `FlutterError(code: "not_implemented")` for capture / reconstruction calls
/// while the native pipeline is being built out.
public class SwiftFlutterObjectCapturePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(
      name: "flutter_object_capture/method_channel",
      binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterObjectCapturePlugin()
    registrar.addMethodCallDelegate(instance, channel: methodChannel)

    let eventChannel = FlutterEventChannel(
      name: "flutter_object_capture/event_channel",
      binaryMessenger: registrar.messenger())
    eventChannel.setStreamHandler(ObjectCaptureController.shared)
    ObjectCaptureController.shared.methodChannel = methodChannel
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isSupported":
      checkSupport(result: result)
    case "captureObject":
      ObjectCaptureController.shared.startCapture(
        arguments: call.arguments as? [String: Any],
        result: result)
    case "reconstruct":
      ObjectCaptureController.shared.reconstruct(
        arguments: call.arguments as? [String: Any],
        result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Reports whether the device meets the runtime requirements for Object
  /// Capture: iOS 17+ and an A14 Bionic chip or newer.
  private func checkSupport(result: @escaping FlutterResult) {
    guard #available(iOS 17.0, *) else {
      result(false)
      return
    }

    #if canImport(RealityKit)
    if #available(iOS 17.0, *) {
      result(ObjectCaptureSession.isSupported)
    } else {
      result(false)
    }
    #else
    result(false)
    #endif
  }
}
