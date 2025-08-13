/// A Flutter plugin for using Apple's RoomPlan API.
///
/// This library provides a high-level API to interact with the RoomPlan
/// framework on iOS, allowing you to easily initiate room scanning sessions
/// and receive structured data about the scanned environment.
library roomplan_flutter;

// Main scanner class
export 'api/room_plan_scanner.dart';

// Public data models
export 'api/models/confidence.dart';
export 'api/models/object_data.dart';
export 'api/models/opening_data.dart';
export 'api/models/position.dart';
export 'api/models/room_data.dart';
export 'api/models/room_dimensions.dart';
export 'api/models/scan_confidence.dart';
export 'api/models/scan_configuration.dart';
export 'api/models/scan_metadata.dart';
export 'api/models/scan_result.dart';
export 'api/models/wall_data.dart';

// Public exceptions
export 'api/exceptions.dart';
