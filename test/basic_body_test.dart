import 'dart:typed_data';

import 'package:test/test.dart';

import '../lib/packet.dart';
import '../lib/hash.dart';

void main() {
  group("BasicBodyPacket", () {
    group("create", () {
      test("fromHashes NullHash", () {
        NullHash prev = NullHash(Uint8List(0));
        NullHash teth = NullHash(Uint8List(0));
        NullHash shld = NullHash(Uint8List(0));
        NullHash reqs = NullHash(Uint8List(0));
        NullHash rigg = NullHash(Uint8List(0));
        NullHash cargo = NullHash(Uint8List(0));

        BasicBodyPacket packet = BasicBodyPacket.fromHashes(
          prev.toUint8List(),
          teth.toUint8List(),
          shld.toUint8List(),
          reqs.toUint8List(),
          rigg.toUint8List(),
          cargo.toUint8List()
        );

        expect(packet.getPrevHash() == prev, equals(true));
        expect(packet.getTethHash() == teth, equals(true));
        expect(packet.getShldHash() == shld, equals(true));
        expect(packet.getRequirementsHash() == reqs, equals(true));
        expect(packet.getRiggingHash() == rigg, equals(true));
        expect(packet.getCargoHash() == cargo, equals(true));
      });
    });
  });
}
