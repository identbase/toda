import 'package:test/test.dart';

import 'package:toda/toda.dart';

void main() {
  group("BasicTwistPacket", () {
    group("create", () {
      test("fromHashes", () {
        NullHash prev = NullHash();
        NullHash teth = NullHash();
        NullHash shld = NullHash();
        NullHash reqs = NullHash();
        NullHash rigg = NullHash();
        NullHash cargo = NullHash();

        BasicBodyPacket body = BasicBodyPacket.fromHashes(
          prev, teth, shld, reqs, rigg, cargo,
        );

        Hash bodyHash = ShaHash256.hash(body.toUint8List());
        NullHash statsHash = NullHash();

        BasicTwistPacket packet = BasicTwistPacket.fromHashes(bodyHash, statsHash);

        print(packet.toMap());

        expect(packet.toUint8List().length, equals(39));
        expect(packet.getBodyHash() == bodyHash, equals(true));
        expect(packet.getStatsHash() == statsHash, equals(true));
      });
    });
  });
}
