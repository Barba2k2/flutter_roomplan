import Flutter
import UIKit
#if canImport(RealityKit)
import RealityKit
#endif

/// Registers the Object Capture channels. Scaffold: every call is not implemented yet.
public class SwiftFlutterObjectCapturePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "flutter_object_capture/method_channel", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterObjectCapturePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    let eventChannel = FlutterEventChannel(
      name: "flutter_object_capture/event_channel", binaryMessenger: registrar.messenger())
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterMethodNotImplemented)
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    return FlutterError(code: "not_implemented", message: "Not implemented yet", details: nil)
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    return nil
  }
}
