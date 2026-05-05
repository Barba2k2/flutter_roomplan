import ARKit
import Foundation
import RoomPlan
import os

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
  let dimensions: SerializableVector?

  init(from room: CapturedRoom) {
    self.walls = room.walls.map { SerializableSurface(from: $0) }
    self.objects = room.objects.map { SerializableObject(from: $0) }
    self.doors = room.doors.map { SerializableSurface(from: $0) }
    self.windows = room.windows.map { SerializableSurface(from: $0) }
    self.openings = room.openings.map { SerializableSurface(from: $0) }

    let (floor, ceiling, dimensions) = Self.findFloorAndCeiling(room: room)
    self.floor = floor
    self.ceiling = ceiling
    self.dimensions = dimensions
  }

  private static func findFloorAndCeiling(room: CapturedRoom) -> (
    SerializableSurface?, SerializableSurface?, SerializableVector?
  ) {
    // Derive floor and ceiling from wall geometry by projecting to XZ and using Y extents
    let walls = room.walls
    guard !walls.isEmpty else { return (nil, nil, nil) }

    var minFloorY: Float = .greatestFiniteMagnitude
    var maxCeilingY: Float = -.greatestFiniteMagnitude

    var minX: Float = .greatestFiniteMagnitude
    var maxX: Float = -.greatestFiniteMagnitude
    var minZ: Float = .greatestFiniteMagnitude
    var maxZ: Float = -.greatestFiniteMagnitude

    var confidences: [CapturedRoom.Confidence] = []

    for wall in walls {
      let t = wall.transform
      let translation = simd_float3(t.columns.3.x, t.columns.3.y, t.columns.3.z)
      let wallHeight = wall.dimensions.y

      // Update floor and ceiling Y using wall bottom/top
      let bottomY = translation.y - (wallHeight / 2.0)
      let topY = translation.y + (wallHeight / 2.0)
      if bottomY < minFloorY { minFloorY = bottomY }
      if topY > maxCeilingY { maxCeilingY = topY }

      // Estimate room XZ extents using wall endpoints along local X axis
      let localXAxis = simd_normalize(simd_float3(t.columns.0.x, t.columns.0.y, t.columns.0.z))
      let halfLength = wall.dimensions.x / 2.0
      let p1 = translation + (localXAxis * halfLength)
      let p2 = translation - (localXAxis * halfLength)

      // Project to XZ plane
      minX = Swift.min(minX, p1.x)
      minX = Swift.min(minX, p2.x)
      maxX = Swift.max(maxX, p1.x)
      maxX = Swift.max(maxX, p2.x)

      minZ = Swift.min(minZ, p1.z)
      minZ = Swift.min(minZ, p2.z)
      maxZ = Swift.max(maxZ, p1.z)
      maxZ = Swift.max(maxZ, p2.z)

      confidences.append(wall.confidence)
    }

    // Compute planar dimensions (length along X, width along Z)
    let length = max(0.0, maxX - minX)
    let width = max(0.0, maxZ - minZ)

    // Guard against degenerate rooms
    if !length.isFinite || !width.isFinite || length == 0 || width == 0 {
      return (nil, nil, nil)
    }

    // Build transforms centered in XZ bounds at floor/ceiling heights
    let centerX = (minX + maxX) / 2.0
    let centerZ = (minZ + maxZ) / 2.0

    var floorTransform = matrix_identity_float4x4
    floorTransform.columns.3 = simd_float4(centerX, minFloorY, centerZ, 1.0)

    var ceilingTransform = matrix_identity_float4x4
    ceilingTransform.columns.3 = simd_float4(centerX, maxCeilingY, centerZ, 1.0)

    // Determine conservative confidence (minimum across walls)
    func confidenceString(from list: [CapturedRoom.Confidence]) -> String {
      guard !list.isEmpty else { return CapturedRoom.Confidence.medium.description }
      var minLevel = 2
      for c in list {
        let level: Int
        switch c {
        case .high: level = 2
        case .medium: level = 1
        case .low: level = 0
        @unknown default: level = 0
        }
        minLevel = Swift.min(minLevel, level)
      }
      switch minLevel {
      case 2: return CapturedRoom.Confidence.high.description
      case 1: return CapturedRoom.Confidence.medium.description
      default: return CapturedRoom.Confidence.low.description
      }
    }

    let conf = confidenceString(from: confidences)

    // Calculate room height from floor to ceiling
    let height = max(0.0, maxCeilingY - minFloorY)

    // Create room dimensions vector (x=length, y=height, z=width)
    let roomDimensions = SerializableVector(
      from: simd_float3(length, height, width)
    )

    // Construct serializable surfaces for floor and ceiling
    let floorSurface = SerializableSurface(
      category: "floor",
      dimensions: simd_float3(length, width, 0.0),
      transform: floorTransform,
      confidence: conf
    )

    let ceilingSurface = SerializableSurface(
      category: "ceiling",
      dimensions: simd_float3(length, width, 0.0),
      transform: ceilingTransform,
      confidence: conf
    )

    return (floorSurface, ceilingSurface, roomDimensions)
  }
}

/// A serializable representation of a `CapturedRoom.Surface`.
struct SerializableSurface: Encodable {
  let uuid: UUID
  let category: String
  let dimensions: SerializableVector
  let transform: [Float]
  let confidence: String

  init(from surface: CapturedRoom.Surface) {
    self.uuid = surface.identifier
    self.category = surface.category.description
    self.dimensions = SerializableVector(from: surface.dimensions)
    self.transform = surface.transform.toFloatArray()
    self.confidence = surface.confidence.description
  }

  /// Convenience initializer to create synthetic surfaces (e.g., floor/ceiling)
  init(
    uuid: UUID = UUID(),
    category: String,
    dimensions: simd_float3,
    transform: simd_float4x4,
    confidence: String
  ) {
    self.uuid = uuid
    self.category = category
    self.dimensions = SerializableVector(from: dimensions)
    self.transform = transform.toFloatArray()
    self.confidence = confidence
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

extension CapturedRoom.Surface.Category {
  var description: String {
    switch self {
    case .wall: return "wall"
    case .door: return "door"
    case .window: return "window"
    case .opening: return "opening"
    @unknown default: return "unknown"
    }
  }
}
