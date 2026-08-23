import 'package:file_explorer/features/nearby_sharing/data/protocol/nearby_crc.dart';
import 'package:file_explorer/features/nearby_sharing/data/protocol/nearby_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('crc32', () {
    test('known check value for "123456789"', () {
      expect(crc32('123456789'.codeUnits), 0xCBF43926);
    });

    test('incremental equals bulk', () {
      final data = List<int>.generate(256, (i) => i % 251);
      expect(crc32Update(0xFFFFFFFF, data) ^ 0xFFFFFFFF, crc32(data));

      var c = crc32Update(0xFFFFFFFF, data.sublist(0, 100));
      c = crc32Update(c, data.sublist(100));
      expect(c ^ 0xFFFFFFFF, crc32(data));
    });

    test('empty input', () {
      expect(crc32(const []), 0);
    });
  });

  group('NearbyProtocol constants', () {
    test('ports and scheme', () {
      expect(NearbyProtocol.udpPort, 45321);
      expect(NearbyProtocol.tcpPort, 45322);
      expect(NearbyProtocol.schemeVersion, 1);
      expect(NearbyProtocol.beaconMagic, 'fe-filex');
    });
  });

  group('message round trip', () {
    test('beacon', () {
      final m = NearbyBeaconMessage(
        id: 'a',
        name: 'Phone',
        tcpPort: 1234,
        code: '9',
      );
      final line = m.toLine();
      expect(line.endsWith('\n'), isTrue);
      final parsed = NearbyMessage.tryParse(line);
      expect(parsed, isA<NearbyBeaconMessage>());
      final b = parsed as NearbyBeaconMessage;
      expect(b.id, 'a');
      expect(b.name, 'Phone');
      expect(b.tcpPort, 1234);
      expect(b.code, '9');
    });

    test('hello', () {
      final m = NearbyHelloMessage(
        deviceId: 'g',
        name: 'Guest',
        code: '1234',
      );
      final parsed = NearbyMessage.tryParse(m.toLine()) as NearbyHelloMessage;
      expect(parsed.deviceId, 'g');
      expect(parsed.name, 'Guest');
      expect(parsed.code, '1234');
    });

    test('manifest and accept', () {
      final m = NearbyManifestMessage(
        files: [NearbyFileMeta(id: 'f1', name: 'a.txt', size: 10)],
      );
      final parsed = NearbyMessage.tryParse(m.toLine()) as NearbyManifestMessage;
      expect(parsed.files.single.id, 'f1');
      expect(parsed.files.single.size, 10);

      final a = NearbyAcceptMessage(ids: const ['f1']);
      final pa = NearbyMessage.tryParse(a.toLine()) as NearbyAcceptMessage;
      expect(pa.ids, const ['f1']);
    });

    test('file header', () {
      final m = NearbyFileHeaderMessage(
        meta: NearbyFileMeta(id: 'f1', name: 'a.txt', size: 10),
      );
      final parsed = NearbyMessage.tryParse(m.toLine()) as NearbyFileHeaderMessage;
      expect(parsed.meta.id, 'f1');
      expect(parsed.meta.name, 'a.txt');
      expect(parsed.meta.size, 10);
    });

    test('simple messages', () {
      expect(
        NearbyMessage.tryParse(const NearbyOkMessage().toLine()),
        isA<NearbyOkMessage>(),
      );
      expect(
        NearbyMessage.tryParse(const NearbyDoneMessage().toLine()),
        isA<NearbyDoneMessage>(),
      );
      expect(
        NearbyMessage.tryParse(const NearbyCompleteMessage().toLine()),
        isA<NearbyCompleteMessage>(),
      );
      final deny = NearbyMessage.tryParse(
            NearbyDenyMessage(reason: 'bad code').toLine(),
          )
          as NearbyDenyMessage;
      expect(deny.reason, 'bad code');
    });

    test('tryParse rejects garbage', () {
      expect(NearbyMessage.tryParse('not json\n'), isNull);
      expect(NearbyMessage.tryParse('{}\n'), isNull);
      expect(NearbyMessage.tryParse('{"t":99}\n'), isNull);
      expect(NearbyMessage.tryParse('{"t":"beacon","name":"x"}\n'), isNull);
    });
  });
}
