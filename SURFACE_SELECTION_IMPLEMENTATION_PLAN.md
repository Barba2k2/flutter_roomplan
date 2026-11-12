# Surface Selection — Implementation Plan

Status: **partially delivered** · Created: 2026-08-04 · Updated: 2026-10-24

| Phase | State | Evidence |
|-------|-------|----------|
| 1 Emit parent wall (Swift) | **DONE** (plugin 0.3.0) | `RoomPlanJSONConverter.swift:43-47` nests doors/windows/openings under their wall via `Surface.parentIdentifier`; `:192` |
| 2 Fix the parse (Dart) | **DONE** (plugin 0.3.0) | `optimized_mapper.dart:200` (surface axes x = width, y = height, z = thickness), `:248` (wall children parsed from nested keys); tests `test/mapper_test.dart`, `test/paintable_area_test.dart`, `test/room_footprint_test.dart` |
| Paintable area helper | **DONE** (public) | `lib/src/helpers/paintable_area_helper.dart`, exported in `lib/roomplan_flutter.dart:18` |
| Room footprint helper | **DONE** (internal) | `lib/src/performance/room_footprint_helper.dart`, used in `optimized_mapper.dart:142` |
| Final result via RoomBuilder | **DONE** | `RoomPlanController.swift:458` (`RoomBuilder(options: [.beautifyObjects])`) |
| 3 3D viewer PlatformView (Swift) | **PENDING** | grep: no `SCNView`, `FlutterPlatformViewFactory` or `registrar.register(` in `ios/` |
| 4 Dart viewer widget | **PENDING** | grep: no `UiKitView` / `RoomSurfaceViewer` in `lib/` or `example/` |
| 5-8 Selection, estimate wiring, persistence, rescan (Paint app) | **PENDING** | grep: no `selectedUuids` / viewer code in `Paint/lib` or `Paint/design_system/lib`; Paint still depends on `roomplan_flutter: ^0.2.1` (`Paint/pubspec.yaml:56`) |

Decided facts (2026-10-24): there is **no 3D result view today**. `RoomBuilder` is a processing
step, not a viewer. The only visual is the live capture preview (RoomPlan's own
`RoomCaptureView` during the scan). The example app shows the result as lists and a paintable
area breakdown, not as a model.

Minimum iOS is **17** since plugin `0.3.0`, so iOS 17 APIs (`parentIdentifier`,
`polygonCorners`, `floors`) are used without `#available` guards.

## Goal

After a RoomPlan scan, show the scanned room as an interactive 3D model and let the user tap
the surfaces (walls, ceiling, floor) that will actually be painted. The estimate is then built
on the selected surfaces only.

If three of four walls total 20 m² in a 30 m² room, the estimate uses 20 m². Skipping the
selection step selects everything, which reproduces today's behaviour.

## Scope decision: a layer here, not a new package

The work splits along a natural line:

| Where | What | Why |
|-------|------|-----|
| `roomplan_flutter` | real wall width, wall↔opening link (both done), 3D viewer PlatformView (pending) | RoomPlan facts and RoomPlan rendering. Nothing paint-specific. |
| Consumer app (Paint) | selection state, estimate wiring, persistence | Estimate semantics. Only the app knows them. The per-wall paintable area math now lives in the plugin (`PaintableAreaHelper`). |

A third package was considered and rejected: it would have exactly one consumer and would
depend on this plugin's models anyway. That buys a third `pubspec`, changelog, and release
cycle for no isolation. The monorepo already globs `packages/*`, so extracting later stays
cheap if a second consumer appears.

The plugin has **no PlatformView today** (confirmed 2026-10-24) — `SwiftFlutterRoomplanPlugin.register` wires a method
channel and an event channel only, with no `registrar.register(_:withId:)`. Phase 3 adds the
first embedded view to this plugin.

---

## Findings that shape the plan

The three calculation bugs found on 2026-08-04 (wall width read as ~0, no wall↔opening link,
empty `points`) are resolved or reframed in `0.3.0`. Current reality, verified 2026-10-24:

### Resolved in 0.3.0

- **Wall/opening dimensions**: walls, doors and windows map `dimensions` as Apple surfaces
  (x = width, y = height, z = thickness). `WallData.width` is the real width, so per-wall
  areas are real. Room, floor, ceiling and object mapping keep the room convention.
- **Wall↔opening link**: native nests each door/window/opening under its wall via
  `Surface.parentIdentifier` (top-level arrays unchanged); `WallData.openings` is filled,
  including `OpeningType.opening`.
- **Floor/ceiling**: synthetic surfaces send width in `z`; room and floor/ceiling length/width
  are measured from the wall endpoints in the room's own axes (`RoomFootprintHelper`).
- **Paintable area**: `PaintableAreaHelper` gives gross wall area, per-type opening area,
  built-in storage area per wall and paintable area clamped at 0.

### Still true

- `WallData.points` is empty: `optimized_mapper.dart` hardcodes `points: const []` and Swift
  never serializes a polygon. Geometry comes from `transform` + `dimensions` only.
- Geometry for the viewer is therefore a rectangle per wall, which is wrong for non-rectangular
  walls (under stairs, cut-outs).

### iOS 27 review conclusions (`docs/reports/2026-10-24-revisao-plano-surface-selection-ios27.md`)

- The RoomPlan API did **not** change in the iOS 27 SDK (Xcode 27.0): only `iOS 16.0` and
  `iOS 17.0` availability marks, nothing deprecated. The plan stays valid.
- `Surface.polygonCorners` (iOS 17, real outline), `Surface.curve` (curved walls) and
  `CapturedRoom.floors` (iOS 17, real floor) exist and are **not used yet** (grep of `ios/`
  confirms). Candidate improvements for the viewer and the synthetic floor; the ceiling stays
  synthetic (no RoomPlan API for it).
- SceneKit (`SCNView`, `SCNBox`, `allowsCameraControl`, `hitTest`) is not marked deprecated in
  the SDK 27 headers. Apple's long-term status for SceneKit is **unconfirmed** (recollection of
  maintenance-only since WWDC25, not verified online); keep SceneKit for the first cut.
- Surface identifiers are **not stable between scans** and no stable-identity API exists, so
  the selection must be cleared on rescan (Phase 8).
- `CapturedRoom.sections`/`story` and `CapturedStructure` (iOS 17) are possible future paths
  for multi-room, not part of this plan.

### Adjacent breakage (Paint app side, unverified here)

`ZoneDataBuilder` (`Paint/lib/utils/roomplan/zone_data_builder.dart`) was reported on
2026-08-04 to read a `ceiling.area` and to compute `trimLength` as an area divided by two.
Not re-checked in this update; check when Phase 6 touches the file.

---

## Architecture

The 3D view is a native `SCNView` hosted in the Flutter tree via `UiKitView`. Flutter never
renders 3D; it sends geometry down and receives selection events back.

```
Flutter (Dart)                            iOS (Swift)
──────────────                            ───────────
RoomSurfaceViewer widget
  creationParams: [surfaces] ───────────► RoomSurfaceViewFactory
                                            builds SCNNode per surface
                                            node.name = surface uuid
                                            allowsCameraControl = true

  onSurfaceTapped(uuid) ◄── channel ────── UITapGestureRecognizer
                                            scnView.hitTest → node.name
  setSelected([uuids])  ──── channel ────► swap node material
        │
        ▼
SurfaceSelectionViewModel
  Set<String> _selected
        │
        ▼
ZoneDataBuilder(selectedUuids: …)
```

**Geometry is passed down from Dart, not retained natively.** The controller currently holds
`finalResults: CapturedRoom?` and nils it on the next `startSession`, so it cannot be relied on
after a scan ends, an app restart, or reopening a saved estimate. Since every surface already
carries `transform` and `dimensions` in the JSON the app persists, the viewer rebuilds its
nodes from those. The viewer is therefore stateless, works on scans loaded from SQLite, and
needs no `CapturedRoom` lifetime management.

---

## Phases

### Phase 1 — Emit the opening's parent wall (Swift) — DONE

Delivered differently from the sketch below: children are nested under their wall in the
converter (`RoomPlanJSONConverter.swift:43-47`) and `parentIdentifier` is read without
`#available` (iOS 17 minimum). Sketch kept for reference:

`packages/roomplan_flutter/ios/roomplan_flutter/Sources/roomplan_flutter/RoomPlanJSONConverter.swift`

```swift
struct SerializableSurface: Encodable {
  let uuid: UUID
  let parentIdentifier: UUID?
  let category: String
  let dimensions: SerializableVector
  let transform: [Float]
  let confidence: String

  init(from surface: CapturedRoom.Surface) {
    self.uuid = surface.identifier
    self.parentIdentifier = surface.parentIdentifier
    self.category = surface.category.description
    self.dimensions = SerializableVector(from: surface.dimensions)
    self.transform = surface.transform.toFloatArray()
    self.confidence = surface.confidence.description
  }
}
```

The synthetic-surface initializer (floor/ceiling) passes `parentIdentifier: nil`.

Expected payload:

```json
{ "uuid": "C3", "category": "wall",   "dimensions": { "x": 3.0, "y": 2.5, "z": 0.0 } }
{ "uuid": "W1", "category": "window", "parentIdentifier": "C3",
  "dimensions": { "x": 1.2, "y": 1.0, "z": 0.0 } }
```

### Phase 2 — Fix the parse (Dart) — DONE

Delivered as `_toSurfaceDimensionsOptimized` (x = width, y = height, z = thickness) and nested
openings parsed in `_toWallDataOptimized`, not as the `.length` workaround and
`openingsByWall` grouping sketched below. Sketch kept for history; do not apply it.

`packages/roomplan_flutter/lib/src/performance/optimized_mapper.dart`

Wall width comes from the `x` component, which `_toRoomDimensionsOptimized` exposes as `length`:

```dart
return WallData(
  uuid: data['uuid'] as String? ?? '',
  width: dimensions?.length ?? 0,   // was dimensions?.width — always 0
  height: dimensions?.height ?? 0,
  // ...
);
```

Openings are grouped by owner in `_toRoomData`, where the sibling lists are in scope — not
inside `_toWallData`, which never sees them:

```dart
final openingsByWall = <String, List<OpeningData>>{};
for (final opening in [...doors, ...windows]) {
  final parent = opening.parentUuid;
  if (parent == null) continue;
  openingsByWall.putIfAbsent(parent, () => []).add(opening);
}
```

Each wall then receives `openingsByWall[wall.uuid] ?? const []`.

`OpeningData` gains a `parentUuid` field, parsed from `parentIdentifier`.

**Regression tests** (none exist for either behaviour today):

```dart
test('wall width comes from dimensions.x, not dimensions.z', () {
  // fixture: dimensions {x: 3.0, y: 2.5, z: 0.0}
  expect(result.room.walls.first.width, 3.0);   // currently 0.0
});

test('an opening is attached to its parent wall', () {
  expect(result.room.walls.single.openings.single.uuid, 'W1');
});

test('an opening with no parent is dropped, not misattributed', () {
  expect(result.room.walls.single.openings, isEmpty);
});
```

### Phase 3 — 3D viewer PlatformView (Swift) — PENDING

Three new files under `packages/roomplan_flutter/ios/roomplan_flutter/Sources/roomplan_flutter/`. Register the factory in `SwiftFlutterRoomplanPlugin.swift`.

**`RoomSurfaceViewFactory.swift`** — registers the view type:

```swift
public class RoomSurfaceViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  public func create(
    withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?
  ) -> FlutterPlatformView {
    RoomSurfaceView(frame: frame, viewId: viewId, args: args, messenger: messenger)
  }
}
```

Registered in `SwiftFlutterRoomplanPlugin.register`:

```swift
registrar.register(
  RoomSurfaceViewFactory(messenger: registrar.messenger()),
  withId: "roomplan_flutter/surface_view")
```

**`RoomSurfaceGeometry.swift`** — surfaces to SceneKit nodes. A RoomPlan surface is a plane;
`SCNBox` with a small depth reads better than `SCNPlane` because it stays visible edge-on and
does not need double-sided materials.

```swift
enum RoomSurfaceGeometry {
  static func node(for surface: SurfaceDescriptor) -> SCNNode {
    let box = SCNBox(
      width: CGFloat(surface.width),
      height: CGFloat(surface.height),
      length: 0.04,
      chamferRadius: 0)
    let node = SCNNode(geometry: box)
    node.name = surface.uuid            // the selection key
    node.simdTransform = surface.transform
    node.geometry?.firstMaterial = Materials.idle
    return node
  }
}
```

`SurfaceDescriptor` is decoded from the creation params: `uuid`, `category`, `width`,
`height`, `transform` (16 floats, column-major).

**`RoomSurfaceView.swift`** — the view itself:

```swift
class RoomSurfaceView: NSObject, FlutterPlatformView {
  private let scnView = SCNView()
  private let channel: FlutterMethodChannel
  private var selected: Set<String> = []

  init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "roomplan_flutter/surface_view_\(viewId)", binaryMessenger: messenger)
    super.init()

    let scene = SCNScene()
    for descriptor in SurfaceDescriptor.list(from: args) {
      scene.rootNode.addChildNode(RoomSurfaceGeometry.node(for: descriptor))
    }
    scnView.scene = scene
    scnView.allowsCameraControl = true      // orbit, pinch-zoom, pan — free
    scnView.autoenablesDefaultLighting = true

    scnView.addGestureRecognizer(
      UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))

    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "setSelected", let uuids = call.arguments as? [String] {
        self?.applySelection(Set(uuids))
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func view() -> UIView { scnView }

  @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
    let point = recognizer.location(in: scnView)
    guard let uuid = scnView.hitTest(point, options: nil).first?.node.name else { return }
    channel.invokeMethod("surfaceTapped", arguments: uuid)
  }

  private func applySelection(_ uuids: Set<String>) {
    selected = uuids
    scnView.scene?.rootNode.childNodes.forEach { node in
      guard let name = node.name else { return }
      node.geometry?.firstMaterial =
        selected.contains(name) ? Materials.selected : Materials.idle
    }
  }
}
```

Notes on this phase:

- `allowsCameraControl = true` gives orbit, pinch-zoom, and pan with no camera code. That is
  the single biggest saving in the native work — the "will it have zoom?" question is answered
  by one line.
- The tap recognizer coexists with the built-in camera gestures; SceneKit's own recognizers
  handle pan/pinch, a single tap falls through.
- **Flutter is the source of truth for selection.** The tap handler only reports; it does not
  toggle the material itself. The ViewModel decides and calls `setSelected` back down. This
  keeps state in one place and makes "restore a saved selection" the same code path as
  "user tapped".
- Openings (doors/windows) are rendered as nodes but must be **non-selectable** — give them a
  distinct material and skip them in `handleTap`, or they will be tapped instead of the wall
  behind them. They are visual context, plus the geometry the area deduction already accounts
  for.
- No iOS gate needed (minimum is iOS 17). Geometry arrives as plain floats, so the viewer
  itself has no RoomPlan dependency. Worth keeping it that way.
- Optional, from the iOS 27 review: serialize `polygonCorners` (and `curve`) and draw a wall by
  its real outline when present, instead of a `SCNBox` rectangle. Not a new requirement; decide
  when Phase 3 starts.

### Phase 4 — Dart-side viewer widget — PENDING

`packages/roomplan_flutter/lib/api/room_surface_viewer.dart` (export from `lib/roomplan_flutter.dart`)

```dart
class RoomSurfaceViewer extends StatefulWidget {
  const RoomSurfaceViewer({
    super.key,
    required this.surfaces,
    required this.selectedUuids,
    required this.onSurfaceTapped,
  });

  final List<WallData> surfaces;
  final Set<String> selectedUuids;
  final ValueChanged<String> onSurfaceTapped;
  // ...
}
```

The `State` creates a `UiKitView` with `viewType: 'roomplan_flutter/surface_view'` and
`creationParams` built from `surfaces`. On `onPlatformViewCreated` it opens
`roomplan_flutter/surface_view_$id`, handles `surfaceTapped`, and pushes `setSelected` whenever
`widget.selectedUuids` changes in `didUpdateWidget`.

Non-iOS and non-LiDAR builds get a plain placeholder rather than a crash — the plugin already
declares `platforms: ios:`, but `UiKitView` on Android throws at build time, not compile time.

### Phase 5 — Selection model (consumer app) — PENDING

`grossArea`/`openingsArea` per wall can reuse `PaintableAreaHelper` from the plugin instead of
reimplementing it.

```dart
class PaintableSurface {
  final String uuid;
  final SurfaceKind kind;        // wall | ceiling | floor
  final double grossArea;        // width * height
  final double openingsArea;     // openings belonging to THIS surface

  double get netArea => grossArea - openingsArea;
}
```

Selection state lives in a `ChangeNotifier` ViewModel:

```dart
final Set<String> _selected = {};

void toggle(String uuid) { /* add or remove, then notifyListeners() */ }
void selectAll() { /* the "skip" action */ }

double get selectedArea => surfaces
    .where((s) => _selected.contains(s.uuid))
    .fold(0.0, (sum, s) => sum + s.netArea);
```

Skip is `selectAll()`, not a separate branch. One calculation path, not two.

### Phase 6 — Wire into the estimate (consumer app) — PENDING

`ZoneDataBuilder.build` takes the selection and filters before summing:

```dart
required Set<String> selectedUuids,
// ...
final walls = _filterByUuid(roomData['walls'] as List?, selectedUuids);
final totalWallArea = _sumAreas(walls);
```

Openings are deducted **only when their parent wall is selected**. Otherwise the estimate
subtracts a window from a wall that is not being painted.

Worked example:

```
Room: 4 walls, 27.0 m² net (openings already deducted)
Selected: A1, B2, C3

  A1  5.7   (has a door)
  B2  7.5
  C3  4.8   (has a window)
  ───────
      18.0 m²   ← estimate basis

Ceiling (12.0 m²) not selected → excluded
Floor not selected → excluded

Skip instead: 27.0 + 12.0 = 39.0 m²
```

### Phase 7 — Persistence — PENDING

Store `selected_surface_uuids` alongside `roomPlanData` on the zone. Without it, reopening an
estimate silently recalculates against the whole room. Because the viewer rebuilds from
persisted transforms, a reopened estimate shows the same 3D model with the same walls
highlighted.

### Phase 8 — Rescan — PENDING

A scan can come out bad — poor lighting, a missed wall, a room the LiDAR merged wrong. The
selection screen needs a **Rescan** action that throws the current scan away and makes the new
one the basis for everything downstream.

The consumer already has the machinery: `RoomPlanViewModel.runScan(photos, projectData)` is
re-callable and takes photos and project data as arguments rather than reading them from the
previous result. Rescan calls it again with the same photos and project data, and the new
`ScanResult` replaces `roomData` wholesale.

Three things make this more than "call `runScan` twice".

**1. The selection must be cleared. This is mandatory, not cosmetic.**

RoomPlan assigns surface identifiers per capture session. A new scan of the same physical room
produces entirely new UUIDs — there is no stable identity across scans. Carrying
`selectedUuids` over therefore selects nothing at best, and if an identifier happens to collide
it selects an unrelated surface.

```dart
Future<void> rescan(List<String> photos, Map<String, dynamic>? projectData) async {
  _selected.clear();          // old UUIDs are meaningless against the new scan
  await runScan(photos, projectData);
}
```

Deliberately **not** attempted: matching old selections to new surfaces by position or
orientation. Two scans of the same room differ in origin and drift, so any such matching is a
heuristic that silently produces a wrong estimate when it misfires. Making the user re-tap
three walls is the cheaper failure mode.

**2. Cancelling a rescan must not destroy the existing scan.**

Today `runScan` emits `RoomPlanScanCancelled`, and `RoomPlanOutcomeDispatcher` responds with
`context.pop()`. That is correct for the first scan — the user backed out before there was
anything to keep. On a rescan it would pop the selection screen and discard a scan the user
still had.

Rescan needs its own outcome so the dispatcher can distinguish them:

```dart
case RoomPlanRescanCancelled():
  // stay on the selection screen; previous scan and selection are untouched
  break;
```

Which means the selection must be cleared **after** a new result arrives, not before the
native sheet opens. Reorder accordingly:

```dart
final result = await _runScan.runRoomPlanScan();
if (result == null) {
  _outcome.value = const RoomPlanRescanCancelled();
  return;                     // _selected still intact
}
_selected.clear();
// … map, rebuild extra, emit success
```

The same applies to a failed rescan (permission, world tracking): keep the old scan, surface
the error, let the user retry or continue with what they have.

**3. Confirm before discarding.**

The scan is the user's work — they walked the room with the phone. Use the existing
`ConfirmationDialogDs` rather than acting on the first tap.

```
title:       Rescan room?
message:     The current scan and your surface selection will be discarded.
confirmText: Rescan
cancelText:  Keep current
```

**Photos survive a rescan.** They are captured on a separate step and passed into `runScan` as
an argument, so they are unaffected — only `roomData` and the selection are replaced. Worth
stating in the dialog copy so the user does not think they are losing photos too.

---

## Cost and constraints of the native path

| Item | Reality |
|------|---------|
| New Swift | ~250-350 lines across three files. `allowsCameraControl` removes the camera work; passing geometry from Dart removes the `CapturedRoom` lifetime work |
| Iteration loop | No hot reload for the Swift side. Every viewer change is a full rebuild and reinstall |
| Testing | `UiKitView` cannot be covered by widget tests. Phases 1-2 and 5-7 are fully testable; Phase 3-4 is device-only |
| Release cycle | The app consumes this plugin from pub.dev. Use a temporary `dependency_overrides` path during development rather than publishing per iteration |
| Platform | iOS-only, as the plugin already is. If Android ever enters scope, it needs its own selection UI |

## Breaking change

`WallData.width` changes meaning in Phase 2 — from a constant zero to the wall's real width.
Anything currently reading `.length` as the width will break.

Shipped in `0.3.0` (CHANGELOG entry present, together with the iOS 17 minimum and other
breaking removals). Paint still pins `^0.2.1` from pub.dev (`Paint/pubspec.yaml:56`) and must
bump to `0.3.0` before Phases 5-8.

## Sequencing

| Phase | Repo | Ships as |
|-------|------|----------|
| 1-2 | `flutter_roomplan` | `0.3.0` (done, in the branch ahead of `origin/master`; publish state not verified) |
| 3-4 | `flutter_roomplan` | next plugin release (pending) |
| 5-8 | consumer app | no publish |

Phases 1-2 landed on their own merit and are the prerequisite for the viewer: per-wall areas
and wall↔opening links are now real.

## Known gaps, deliberately deferred

- A wall shared between two rooms is reported once per scan, with no cross-scan identity
  (`sections`/`story`/`CapturedStructure` do not provide it).
- RoomPlan sometimes splits one physical wall into two surfaces at a corner. The user sees two
  selectable faces where they expect one.
- Floor/ceiling axis mismatch is fixed in `0.3.0`. The floor is still synthetic; swapping it for
  `CapturedRoom.floors` (iOS 17) is a possible improvement, not planned. The ceiling stays
  synthetic.
- Tapping a wall from outside the room selects its back face. Either cull back faces or accept
  it — the camera starts inside the room, so it only shows up after the user orbits out.
