import Foundation
import RoomPlan

/// A utility struct to convert `CapturedRoom` objects to a JSON string.
@available(iOS 16.0, *)
struct RoomPlanJSONConverter {
  /// Converts a `CapturedRoom` object into a JSON string.
  ///
  /// - Parameter capturedRoom: The `CapturedRoom` object to encode.
  /// - Returns: A JSON string representing the room, or `nil` if encoding fails.
  /// - Throws: An error if the `JSONEncoder` fails to encode the object.
  static func convertToJSON(capturedRoom: CapturedRoom) throws -> String? {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try encoder.encode(capturedRoom)
    return String(data: data, encoding: .utf8)
  }
}
