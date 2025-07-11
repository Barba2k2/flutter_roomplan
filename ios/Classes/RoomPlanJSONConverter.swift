import ARKit
import Foundation
import RoomPlan

/// A utility to convert `CapturedRoom` objects into a JSON format.
@available(iOS 16.0, *)
struct RoomPlanJSONConverter {
  /// Converts a `CapturedRoom` object into a JSON string.
  static func convertToJSON(capturedRoom: CapturedRoom, metadata: [String: Any]) throws -> String? {
    let serializableRoom = SerializableRoom(from: capturedRoom)

    var stringMetadata: [String: String] = [:]
    for (key, value) in metadata {
      stringMetadata[key] = String(describing: value)
    }

    let serializableResult = SerializableScanResult(
      room: serializableRoom, metadata: stringMetadata)
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try encoder.encode(serializableResult)
    return String(data: data, encoding: .utf8)
  }
}

struct SerializableScanResult: Encodable {
  let room: SerializableRoom
  let metadata: [String: String]
}

/// A serializable representation of a `CapturedRoom`.
struct SerializableRoom: Encodable {
  let walls: [SerializableSurface]
  let objects: [SerializableObject]
  let doors: [SerializableSurface]
  let windows: [SerializableSurface]
  let openings: [SerializableSurface]
  let floor: SerializableSurface?
  let ceiling: SerializableSurface?

  init(from room: CapturedRoom) {
    self.walls = room.walls.map { SerializableSurface(from: $0) }
    self.objects = room.objects.map { SerializableObject(from: $0) }
    self.doors = room.doors.map { SerializableSurface(from: $0) }
    self.windows = room.windows.map { SerializableSurface(from: $0) }
    self.openings = room.openings.map { SerializableSurface(from: $0) }

    let (floor, ceiling) = Self.findFloorAndCeiling(room: room)
    self.floor = floor
    self.ceiling = ceiling
  }

  private static func findFloorAndCeiling(room: CapturedRoom) -> (
    SerializableSurface?, SerializableSurface?
  ) {
    var floorSurface: CapturedRoom.Surface?
    var ceilingSurface: CapturedRoom.Surface?

    if #available(iOS 17.0, *) {
      floorSurface = room.floor
      ceilingSurface = room.ceiling
    } else {
      // Fallback for iOS 16: search for floor and ceiling in all surfaces.
      // Use rawValue to avoid compile-time errors on older SDKs.
      // On iOS 17+, floor's rawValue is 4 and ceiling's is 5.
      let allSurfaces = room.walls + room.doors + room.windows + room.openings
      floorSurface = allSurfaces.first { $0.category.rawValue == 4 }
      ceilingSurface = allSurfaces.first { $0.category.rawValue == 5 }
    }

    var serializableFloor: SerializableSurface?
    if let surface = floorSurface {
      serializableFloor = SerializableSurface(from: surface)
    }

    var serializableCeiling: SerializableSurface?
    if let surface = ceilingSurface {
      serializableCeiling = SerializableSurface(from: surface)
    }

    return (serializableFloor, serializableCeiling)
  }
}

/// A serializable representation of a `CapturedRoom.Surface`.
struct SerializableSurface: Encodable {
  let uuid: UUID
  let dimensions: SerializableVector
  let transform: [Float]
  let confidence: String

  init(from surface: CapturedRoom.Surface) {
    self.uuid = surface.identifier
    self.dimensions = SerializableVector(from: surface.dimensions)
    self.transform = surface.transform.toFloatArray()
    self.confidence = surface.confidence.description
  }
}

/// A serializable representation of a `CapturedRoom.Object`.
struct SerializableObject: Encodable {
  let uuid: UUID
  let category: String
  let dimensions: SerializableVector
  let transform: [Float]
  let confidence: String

  init(from object: CapturedRoom.Object) {
    self.uuid = object.identifier
    self.category = object.category.description
    self.dimensions = SerializableVector(from: object.dimensions)
    self.transform = object.transform.toFloatArray()
    self.confidence = object.confidence.description
  }
}

/// A serializable representation of a `simd_float3` vector.
struct SerializableVector: Encodable {
  let x: Float
  let y: Float
  let z: Float

  init(from vector: simd_float3) {
    self.x = vector.x
    self.y = vector.y
    self.z = vector.z
  }
}

// MARK: - Extensions for Serialization

extension simd_float4x4 {
  func toFloatArray() -> [Float] {
    return (0..<4).flatMap { col in (0..<4).map { row in self[col][row] } }
  }
}

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

extension CapturedRoom.Object.Category {
  var description: String {
    switch self {
    case .storage: return "storage"
    case .table: return "table"
    case .sofa: return "sofa"
    case .chair: return "chair"
    case .bed: return "bed"
    case .sink: return "sink"
    case .toilet: return "toilet"
    case .oven: return "oven"
    case .refrigerator: return "refrigerator"
    case .stove: return "stove"
    case .washerDryer: return "washerDryer"
    case .television: return "television"
    case .fireplace: return "fireplace"
    case .stairs: return "stairs"
    case .bathtub: return "bathtub"
    case .dishwasher: return "dishwasher"
    @unknown default: return "unknown"
    }
  }
}
