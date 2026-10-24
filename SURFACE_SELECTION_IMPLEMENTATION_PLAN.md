# Surface Selection — Implementation Plan

Status: **proposed** · Created: 2026-08-04

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
| `roomplan_flutter` | real wall width, wall↔opening link, 3D viewer PlatformView | RoomPlan facts and RoomPlan rendering. Nothing paint-specific. |
| Consumer app (Paint) | selection state, paintable area, opening deduction | Estimate semantics. Only the app knows them. |

A third package was considered and rejected: it would have exactly one consumer and would
depend on this plugin's models anyway. That buys a third `pubspec`, changelog, and release
cycle for no isolation. The monorepo already globs `packages/*`, so extracting later stays
cheap if a second consumer appears.

The plugin has **no PlatformView today** — `SwiftFlutterRoomplanPlugin.register` wires a method
channel and an event channel only, with no `registrar.register(_:withId:)`. Phase 3 adds the
first embedded view to this plugin.

---

## Findings that shape the plan

All three were confirmed by reading the current source. Each one blocks the feature, and none
of them is fixed by choosing 3D over 2D — they are calculation bugs, not rendering bugs.

### 1. `WallData.width` is always ~0 — this alone invalidates per-wall areas

Swift sends `surface.dimensions` as `simd_float3`. For a planar wall surface that is
`(width, height, 0)` — depth is zero because the surface has no thickness.

`_toRoomDimensions` maps the axes for the *room* convention:

```dart
length: data['x'],   // actually the wall's width
height: data['y'],   // correct
width:  data['z'],   // 0
```

So `WallData.width` reads the zero component. The wall's real width sits in `.length`.

The corroborating evidence is in the consumer. `RoomPlanResultMapper` carries a fallback that
must be firing on every single wall:

```dart
final w = wall.width > 0 ? wall.width : averageWallWidth;
```

where `averageWallWidth = (roomWidth + roomLength) * 2 / walls.length`.

**Consequence:** today every wall is assigned the same averaged width. Selecting three walls
would sum three identical averages, not three real areas. The feature is meaningless until
this is fixed.

No test covers it — the suite only asserts `room.dimensions`, never a wall's own width.

### 2. There is no wall↔opening association

`_toWallData` looks for `data['doors']` and `data['windows']` nested inside each wall map. The
Swift converter emits doors and windows as **sibling top-level lists**. The nested keys never
exist, so `wall.openings` is always `[]`.

RoomPlan itself has the answer — `CapturedRoom.Surface.parentIdentifier` links an opening to
its wall — but the plugin does not serialize it.

**Consequence:** deducting a window from the specific wall it belongs to is impossible today.

### 3. `WallData.points` is always empty

`lib/src/mapper.dart` hardcodes `points: const []`, and the Swift side never serializes a
`points` key. Geometry can only come from `transform` + `dimensions`.

This matters for the 3D viewer too: node placement is driven by the 4×4 transform, not by a
polygon outline.

### Adjacent breakage (not blocking, worth fixing while in here)

- `ZoneDataBuilder` reads `roomData['ceiling']['area']`, but `RoomPlanResultMapper` never emits
  a `ceiling` key. Ceiling area is therefore always `0.0`.
- `ZoneDataBuilder` computes `trimLength: totalWallArea / 2` — an area divided by two,
  formatted as a linear measurement.

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

### Phase 1 — Emit the opening's parent wall (Swift)

`ios/roomplan_flutter/Sources/roomplan_flutter/RoomPlanJSONConverter.swift`

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

### Phase 2 — Fix the parse (Dart)

`lib/src/mapper.dart`

Wall width comes from the `x` component, which `_toRoomDimensions` exposes as `length`:

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

### Phase 3 — 3D viewer PlatformView (Swift)

Three new files under `ios/roomplan_flutter/Sources/roomplan_flutter/`.

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
- iOS gate: the file needs `@available(iOS 16.0, *)` only where RoomPlan types appear. Since
  geometry arrives as plain floats, the viewer itself has no RoomPlan dependency and can build
  on any iOS version the plugin supports. Worth keeping it that way.

### Phase 4 — Dart-side viewer widget

`lib/api/room_surface_viewer.dart`

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

### Phase 5 — Selection model (consumer app)

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

### Phase 6 — Wire into the estimate (consumer app)

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

### Phase 7 — Persistence

Store `selected_surface_uuids` alongside `roomPlanData` on the zone. Without it, reopening an
estimate silently recalculates against the whole room. Because the viewer rebuilds from
persisted transforms, a reopened estimate shows the same 3D model with the same walls
highlighted.

### Phase 8 — Rescan

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

Release as `0.3.0` with an explicit CHANGELOG entry.

## Sequencing

| Phase | Repo | Ships as |
|-------|------|----------|
| 1-4 | `flutter_roomplan` | `0.3.0` on pub.dev |
| 5-8 | consumer app | no publish |

Phases 1-2 are worth landing on their own merit — they fix per-wall areas that are wrong today,
selection feature or not. They are also a prerequisite: a 3D viewer built on the current parse
would render every wall at the same averaged width.

## Known gaps, deliberately deferred

- A wall shared between two rooms is reported once per scan, with no cross-scan identity.
- RoomPlan sometimes splits one physical wall into two surfaces at a corner. The user sees two
  selectable faces where they expect one.
- Floor and ceiling synthetic surfaces are built from `simd_float3(length, width, 0.0)` and land
  in the same axis mismatch as walls. Fix alongside Phase 2 if ceiling selection ships in the
  first cut.
- Tapping a wall from outside the room selects its back face. Either cull back faces or accept
  it — the camera starts inside the room, so it only shows up after the user orbits out.
