import Flutter
import UIKit
#if canImport(RoomPlan)
import RoomPlan
#endif

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
    case "isSupported":
      checkRoomPlanSupport(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  /// Checks if RoomPlan is supported on the current device.
  ///
  /// This method checks for iOS version compatibility and LiDAR sensor availability.
  private func checkRoomPlanSupport(result: @escaping FlutterResult) {
    guard #available(iOS 16.0, *) else {
      result(false)
      return
    }
    
    // Check if device has LiDAR sensor and RoomPlan is available
    #if canImport(RoomPlan)
    // Check if RoomCaptureSession is available (requires LiDAR)
    if RoomCaptureSession.isSupported {
      result(true)
    } else {
      result(false)
    }
    #else
    result(false)
    #endif
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
    case "isSupported":
      result(false)
    case "startRoomCapture", "stopRoomCapture":
      result(
        FlutterError(
          code: "not_available",
          message: "RoomPlan is only available on iOS 16.0 and later with LiDAR sensor.",
          details: nil))
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
