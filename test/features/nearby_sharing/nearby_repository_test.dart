import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_explorer/features/nearby_sharing/data/protocol/nearby_protocol.dart';
import 'package:file_explorer/features/nearby_sharing/data/repositories/nearby_sharing_repository_io.dart';
import 'package:file_explorer/features/nearby_sharing/domain/entities/nearby_events.dart';
import 'package:file_explorer/features/nearby_sharing/domain/entities/nearby_peer.dart';
import 'package:file_explorer/features/nearby_sharing/domain/entities/nearby_transfer_file.dart';
import 'package:file_explorer/features/nearby_sharing/domain/repositories/nearby_sharing_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NearbySharingRepositoryIo loopback', () {
    test('host receives a file sent by guest over loopback', () async {
      final repo = NearbySharingRepositoryIo();
      final tmp = await Directory.systemTemp.createTemp('nb_');
      final src = File('${tmp.path}/src.bin');
      final payload = List<int>.generate(2048, (i) => i % 256);
      await src.writeAsBytes(payload);
      final destDir = '${tmp.path}/dest';

      final host = await repo.startHost(
        NearbyHostConfig(
          deviceId: 'host1',
          deviceName: 'Host',
          code: '1234',
          destinationDir: destDir,
          bindAddress: InternetAddress.loopbackIPv4,
          tcpPort: 0,
          udpPort: 45399,
        ),
      );

      final peer = NearbyPeer(
        id: 'host1',
        name: 'Host',
        host: '127.0.0.1',
        tcpPort: host.port,
        code: '1234',
      );

      final events = <NearbyTransferEvent>[];
      final sub = host.events.listen(events.add);

      final session = await repo.sendFiles(
        peer: peer,
        code: '1234',
        files: [
          NearbyOutgoingFile(
            id: 'f1',
            path: src.path,
            name: 'src.bin',
            size: payload.length,
          ),
        ],
        deviceId: 'guest1',
        deviceName: 'Guest',
      );

      await session.events.firstWhere((e) => e is NearbySessionFinished);
      await sub.cancel();
      await host.stop();

      final saved = File('$destDir/src.bin');
      expect(saved.existsSync(), isTrue);
      expect(await saved.readAsBytes(), payload);

      final completed = events.whereType<NearbyFileCompleted>().single;
      expect(completed.ok, isTrue);
      expect(completed.id, 'f1');

      await tmp.delete(recursive: true);
    });

    test('discover picks up a UDP beacon', () async {
      final repo = NearbySharingRepositoryIo();
      final completer = Completer<NearbyPeer>();
      final sub = repo
          .discover(
            config: NearbyDiscoveryConfig(
              bindAddress: InternetAddress.loopbackIPv4,
              udpPort: 45401,
              scanTimeout: const Duration(seconds: 5),
            ),
          )
          .listen((p) => completer.complete(p));

      await Future.delayed(const Duration(milliseconds: 150));
      final sock = await RawDatagramSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      sock.send(
        utf8.encode(
          NearbyBeaconMessage(
            id: 'x',
            name: 'Phone',
            tcpPort: 1234,
            code: '9',
          ).toLine(),
        ),
        InternetAddress.loopbackIPv4,
        45401,
      );

      final peer = await completer.future.timeout(const Duration(seconds: 5));
      expect(peer.id, 'x');
      expect(peer.name, 'Phone');
      expect(peer.tcpPort, 1234);

      sub.cancel();
      sock.close();
    });
  });
}
