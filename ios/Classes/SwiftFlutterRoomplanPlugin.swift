import Flutter
import UIKit

/// The main plugin class for the roomplan_flutter package.
///
/// This class handles the registration of the plugin and the routing of method calls
/// to the appropriate handlers.
public class SwiftFlutterRoomplanPlugin: NSObject, FlutterPlugin {
  /// Registers the plugin with the Flutter engine.
  ///
  /// This method sets up the method and event channels that are used to communicate
  /// between the Flutter app and the native iOS code.
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "roomplan_flutter/method_channel", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterRoomplanPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    let eventChannel = FlutterEventChannel(
      name: "roomplan_flutter/event_channel", binaryMessenger: registrar.messenger())
    eventChannel.setStreamHandler(RoomPlanController.shared)
    RoomPlanController.shared.channel = channel
  }

  /// Handles incoming method calls from Flutter.
  ///
  /// This method delegates the calls to the `RoomPlanController` singleton.
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startRoomCapture":
      RoomPlanController.shared.startSession(result: result)
    case "stopRoomCapture":
      RoomPlanController.shared.stopSession(result: result)
    case "isRoomPlanSupported":
      if #available(iOS 16.0, *) {
        result(true)
      } else {
        result(false)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

/// A fallback handler for devices where RoomPlan is not available (iOS < 16.0).
///
/// This handler ensures that the app does not crash and provides a consistent
/// API surface, returning 'isSupported = false'.
class RoomPlanFallbackHandler: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // This handler is registered by the main plugin class, so this method is empty.
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isRoomPlanSupported":
      result(false)
    case "startRoomCapture", "stopRoomCapture":
      result(
        FlutterError(
          code: "UNSUPPORTED",
          message: "RoomPlan is only available on iOS 16.0 and later.",
          details: nil))
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
