# Nearby Sharing (Xender / ShareIt style) — Design

Status: draft for review (not yet approved).

## Goal / scope

Add **device-to-device file sharing over the local network** (ShareIt / Xender
style): send and receive files between two phones running this app while both
are on the same Wi-Fi (or one phone's hotspot).

MVP scope:

- **Discovery** — find nearby devices on the LAN without leaving the app.
- **Send** — pick files (from Explorer multi-select or in the Share screen) and
  push them to a chosen peer.
- **Receive** — host a session, accept/reject incoming transfers, save received
  files to a destination folder, and make them appear in MediaStore.
- **Progress + history** — reuse the existing Transfer Station so transfers show
  live progress and persist in history.

Out of scope for MVP:

- Wi-Fi Direct / automatic hotspot creation (auto-tethering). Phase 2 only.
- Encrypted/relayed transfer over the internet.
- Chat / multiple simultaneous peer sessions (MVP is a 1:1 session).
- Resume of interrupted transfers (MVP restarts a failed file).

## Architecture

New feature-first module:

```
lib/features/nearby_sharing/
  domain/
    entities/
      nearby_peer.dart            // id, name, host, tcpPort, schemeVersion
      nearby_session.dart         // role (host/guest), peer, state machine
      nearby_file_offer.dart      // id, name, size, mime, relativePath, status
    repositories/
      nearby_sharing_repository.dart   // interface: discover/send/receive
  data/
    repositories/
      nearby_sharing_repository_io.dart    // dart:io UDP + TCP implementation
      nearby_sharing_repository_stub.dart  // InMemoryFake for tests
    protocol/
      nearby_protocol.dart        // control-message framing + parsing
      nearby_crc.dart             // CRC32 helper for integrity
  presentation/
    controllers/
      nearby_sharing_controller.dart   // Riverpod Notifier: scan, connect, send
    nearby_share_screen.dart
    widgets/
      peer_list_tile.dart
      incoming_file_tile.dart
```

Two clear layers:

1. **Protocol layer** (`data/protocol`) — pure, framework-free Dart. UDP beacon
   for discovery, TCP stream for file transfer. Fully unit-testable on loopback.
2. **Repository layer** — wraps the protocol behind an interface so tests use a
   fake; the IO implementation uses `dart:io` (`ServerSocket`, `Socket`,
   `RawDatagramSocket`, `NetworkInterface`, `File`).
3. **Presentation layer** — Riverpod `Notifier` + screen, reusing existing
   widgets/`NeumorphicCard` styling.

No external networking plugin is required for the MVP: discovery uses a UDP
broadcast and transfer uses raw TCP sockets, consistent with the app's existing
`dart:io` storage approach. (A later phase may adopt `nsd`/`wifi_info_flutter`
for cleaner discovery, but the protocol stays the same.)

## Connection model

A session has two roles:

- **Host (receiver):** opens a `ServerSocket` (TCP) + a `RawDatagramSocket`
  (UDP) and advertises itself on the LAN. Waits for a guest to connect.
- **Guest (sender):** scans the LAN via UDP, discovers hosts, connects to the
  chosen host's TCP port, and pushes files.

After the TCP connection is established the channel is bidirectional, so either
side can send; MVP keeps the simple "guest sends → host receives" flow, plus an
optional "host requests a file back" phase-2 hook.

A short **pairing code** (4–6 digits) is exchanged automatically during LAN
discovery (carried in the host's beacon / guest's hello) and prevents accidental
connections without any manual entry. This keeps a UX parallel to ShareIt.

## Protocol (text framing + binary)

All control messages are **newline-delimited JSON** on the TCP socket. Binary
file data follows a `FILE` header line and is read by the exact `size` bytes
from the header (so no embedding/escaping is needed).

Ports (configurable constants):

- UDP discovery: `45321`
- TCP transfer: `45322`

### Discovery (UDP)

Host periodically sends a beacon datagram to the subnet broadcast address
(`255.255.255.255` or the interface broadcast) on `45321`:

```json
{ "t": "fe-beacon", "v": 1,
  "id": "<hostDeviceId>", "name": "Ajay's Phone",
  "tcp": 45322, "code": "4281" }
```

Guests listen on `45321`; on receiving a beacon they surface the peer (dedup by
`id`, refresh last-seen, drop after ~5s of silence). The host also answers a
direct UDP "probe" so a guest can refresh instantly after tapping Scan.

### Transfer (TCP)

Handshake:

```
GUEST -> HOST:  {"t":"hello","v":1,"id":"<guestId>","name":"...","code":"4281"}
HOST -> GUEST:  {"t":"ok","accepted":true}        // or {"t":"deny","reason":"code"}
GUEST -> HOST:  {"t":"manifest","files":[
                  {"id":"f1","name":"photo.jpg","size":123456,
                   "mime":"image/jpeg","rel":"Pictures"}
                ]}
HOST -> GUEST:  {"t":"accept","ids":["f1"]}       // or {"t":"reject","ids":[...]}
```

Per accepted file:

```
GUEST -> HOST:  {"t":"file","id":"f1","size":123456,"name":"photo.jpg",
                  "mime":"image/jpeg","rel":"Pictures"}
                <size bytes of raw file content>
                <4-byte big-endian CRC32 of the content>
HOST -> GUEST:  {"t":"ack","id":"f1","ok":true}    // or {"t":"nak","id":"f1"}
```

Close:

```
GUEST -> HOST:  {"t":"done"}
HOST -> GUEST:  {"t":"complete"}
```

Files are streamed in **fixed chunks (e.g. 64 KB)** via
`File.openRead().pipe(...)` / `await socket.addStream(...)` so large files never
load fully into memory. The CRC32 trailer lets the host verify integrity and
reply `nak` on mismatch (guest retries the single file once, then marks failed).

## Integration with the Transfer Station

Reuse `TransferController` / `TransferTaskStore` (Drift) so nearby transfers get
free live progress + history in the existing **Transfer Manager** screen.

- Add two enum values to `TransferOperation`: `receive` and `send`.
- Add a small public surface on `TransferController` so the nearby service can
  drive an in-flight task without reimplementing the executor:
  - `queueNearby({required TransferOperation op, required String displayName,
     String? sourcePath, required String destinationPath, int? totalBytes})`
     → returns the `taskId` (creates a `running`/`queued` task like
     `queueOperation` does).
  - `reportNearbyProgress(taskId, transferredBytes, totalBytes)` → updates
     `TransferProgress` (mirrors the internal `_replaceTask` progress path).
  - `finishNearby(taskId, {required bool success, String? failureMessage})`
     → sets `completed` / `failed`.
- **Received files** become `TransferOperation.receive` tasks writing to the
  chosen destination (default `File Explorer/Share`, user-selectable). After a
  successful write, trigger the same **MediaStore rescan** the Transfer Station
  already does for moved/copied files so the new file appears in Explorer /
  Media libraries.
- **Sent files** become `TransferOperation.send` tasks for history (source =
  local path, destination = peer name).

This keeps a single source of truth for history/progress and avoids a second
queue UI. Fallback (lower-risk) option if the controller extension proves
  intrusive: the Share screen keeps its own progress and only inserts a
*completed* `TransferTask` at the end. Recommend the controller-extension
approach.

## Navigation + entry points

- New route `AppRoutes.nearbyShare = '/nearby'` + a `GoRoute` in
  `buildAppRoutes()` rendering `NearbyShareScreen`.
- New `NavigationRail` + `NavigationBar`   destination **Share** in `AppShell` (reached from the Home shortcut and Core
  Features), with `_selectedIndex` + `_go` cases (insert as
  index 2, shifting Transfers→3, Settings→4, Windows→5; or append after
  Windows — decide during implementation to keep the Windows index logic intact).
- **Send from Explorer:** add a "Send nearby" action to the Explorer
  multi-select action sheet (`SelectionBottomBar` / its action sheet). Selecting
  it opens `NearbyShareScreen` pre-seeded in Send mode with the chosen paths.
- **Core Features screen:** add a "Nearby sharing" card (currently listed under
  🚧 Upcoming) flipping `comingSoon` off once landed.

> Audit files (CHANGELOG.md / ROADMAP.md / README.md) get the matching updates
> when implementation starts — not in this design doc.

## Permissions / manifest

`INTERNET` is already declared. Add (in `android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
<!-- Android 10–12 need location to read the Wi-Fi info used for discovery -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"
                 android:maxSdkVersion="32" />
<!-- Android 13+ replaces location with NEARBY_WIFI_DEVICES -->
<uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES" />
```

Runtime handling:

- `NEARBY_WIFI_DEVICES` (API 33+) must be requested at runtime (use the existing
  `permission_handler` path in `storage_permissions` or add a small nearby
  permission check).
- On API 21–32, discovery that reads local IP / scans the subnet typically
  requires `ACCESS_FINE_LOCATION` at runtime; the app already depends on
  `permission_handler`, so add a `NearbySharing` permission gate reusing that
  flow.
- `MANAGE_EXTERNAL_STORAGE` is already requested, so writing received files to
  arbitrary destinations works.

Note: discovery uses subnet UDP broadcast + `NetworkInterface.list()` to learn
the device's own IP; this is why the location/nearby permission is needed on
older Android. Phase 2 may switch to NSD (`NsdManager`) which only needs
`NEARBY_WIFI_DEVICES` on 13+.

## Testing

- **Protocol unit tests** (`test/features/nearby_sharing/`):
  - `nearby_protocol_test.dart` — encode/decode every control message; reject
    malformed `hello`/`manifest`/`file` frames.
  - `nearby_crc_test.dart` — CRC32 known vectors.
  - `nearby_transfer_test.dart` — spin up a real `ServerSocket` + `Socket` on
    `localhost` (loopback, no network needed), send a few in-memory / temp files
    through the full handshake, assert received bytes equal sent bytes and
    `ack`/`nak` paths fire; simulate a CRC mismatch → `nak` + retry.
  - `nearby_discovery_test.dart` — two `RawDatagramSocket`s on loopback exchange
    beacon/response; assert peer surfaces and times out.
- **Controller / repository tests** with `NearbySharingRepository` fake
  (in-memory): scanning yields peers, connect→send drives progress callbacks,
  failure path marks the task failed.
- **Widget test** `nearby_share_screen_test.dart`: pump `NearbyShareScreen` with
  fakes; assert states (idle → scanning → peers → sending → progress → done)
  and that a `TransferTask` of `TransferOperation.send`/`receive` is queued via
  the (fake) `TransferController`.
- **Regression:** adding `receive`/`send` to `TransferOperation` must not break
  existing `transfer_controller_test.dart`; add a tiny test covering the new ops.

## Build phases

1. Protocol layer: `nearby_protocol.dart` + `nearby_crc.dart` + unit tests
   (loopback TCP/UDP). **Gate: protocol tests green.**
2. Repository IO: `ServerSocket`/`RawDatagramSocket` impl + fake; discovery +
   transfer happy path. **Gate: repository tests green.**
3. `TransferOperation.receive`/`send` + `TransferController` progress surface;
   MediaStore rescan on receive.
4. `NearbySharingController` (Riverpod) wiring discovery → connect → send.
5. `NearbyShareScreen` UI (Receive/Scan modes, peer list, incoming tiles,
   progress) reusing `NeumorphicCard` styling; permission gate.
6. Navigation: route + `AppShell` destination + Explorer "Send nearby" action +
   Core Features card.
7. `flutter analyze` + on-device verification (two phones: send a mix of image /
   apk / large file; confirm progress, integrity, and that received files appear
   in MediaStore).
8. Update audit files (CHANGELOG / ROADMAP / README) when merged.

## Risks / notes

- **Same-subnet requirement:** MVP assumes both phones are on the same Wi-Fi or
  one opens a hotspot. If they aren't, discovery silently finds nothing — the UI
  must show a clear "connect both phones to the same Wi-Fi" hint. Wi-Fi Direct /
  auto-hotspot is phase 2.
- **Android permission split:** location (≤32) vs `NEARBY_WIFI_DEVICES` (≥33)
  needs careful runtime gating; test on both an Android 13 device and an
  Android 11/12 device.
- **Large files:** always stream in chunks; never buffer a whole file in memory.
- **Mid-transfer disruption** (Wi-Fi drop, app backgrounding): wrap socket I/O
  in try/catch, mark the task `failed` with `TransferFailureCode.unknown`, and
  let the user retry the file. Consider a `WakeLock`/foreground service for
  large sends in phase 2.
- **Security:** MVP trusts any peer that knows the pairing code; transfers are
  unencrypted LAN traffic. Acceptable for MVP; note it. Phase 2 can add a
  per-session TLS or a noise-based handshake.
- **Host blocking UI:** discovery beacon + server socket run off the UI thread
  (async I/O is fine; keep any parsing off `build`). Cap concurrent incoming
  files to bound resources.
- **File collisions on receive:** reuse the existing `ConflictPolicy`
  (overwrite / skip / rename) when the destination already has a same-named file.
