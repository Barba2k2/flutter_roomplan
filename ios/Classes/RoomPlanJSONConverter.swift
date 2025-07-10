import ARKit
import Foundation
import RoomPlan

/// A utility to convert `CapturedRoom` objects into a JSON format.
@available(iOS 16.0, *)
struct RoomPlanJSONConverter {
  /// Converts a `CapturedRoom` object into a JSON string.
  static func convertToJSON(capturedRoom: CapturedRoom) throws -> String? {
    let serializableRoom = SerializableRoom(from: capturedRoom)
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try encoder.encode(serializableRoom)
    return String(data: data, encoding: .utf8)
  }
}

/// A serializable representation of a `CapturedRoom`.
struct SerializableRoom: Encodable {
  let walls: [SerializableSurface]
  let objects: [SerializableObject]
  let doors: [SerializableSurface]
  let windows: [SerializableSurface]
  let openings: [SerializableSurface]

  init(from room: CapturedRoom) {
    self.walls = room.walls.map { SerializableSurface(from: $0) }
    self.objects = room.objects.map { SerializableObject(from: $0) }
    self.doors = room.doors.map { SerializableSurface(from: $0) }
    self.windows = room.windows.map { SerializableSurface(from: $0) }
    self.openings = room.openings.map { SerializableSurface(from: $0) }
  }
}

/// A serializable representation of a `CapturedRoom.Surface`.
struct SerializableSurface: Encodable {
  let uuid: UUID
  let dimensions: simd_float3
  let confidence: String

  init(from surface: CapturedRoom.Surface) {
    self.uuid = surface.identifier
    self.dimensions = surface.dimensions
    self.confidence = surface.confidence.description
  }
}

/// A serializable representation of a `CapturedRoom.Object`.
struct SerializableObject: Encodable {
  let uuid: UUID
  let category: String
  let dimensions: simd_float3
  let confidence: String

  init(from object: CapturedRoom.Object) {
    self.uuid = object.identifier
    self.category = object.category.description
    self.dimensions = object.dimensions
    self.confidence = object.confidence.description
  }
}

// Add a description property to Confidence for easier serialization
extension CapturedRoom.Confidence {
  var description: String {
    switch self {
    case .high: return "high"
    case .medium: return "medium"
    case .low: return "low"
    @unknown default: return "unknown"
    }
  }
}

// Add a description property to Object.Category for easier serialization
extension CapturedRoom.Object.Category {
  var description: String {
    switch self {
    case .storage, .refrigerator, .stove, .bed, .sink, .washerDryer, .toilet, .bathtub, .oven,
      .dishwasher, .sofa, .chair, .fireplace, .television, .stairs, .table:
      return String(describing: self)
    @unknown default:
      return "unknown"
    }
  }
}
