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

        BasicBodyPacket bodyPacket = BasicBodyPacket.fromHashes(
          prev, teth, shld, reqs, rigg, cargo,
        );

        Hash bodyHash = ShaHash256.hash(bodyPacket.toUint8List());
        NullHash statsHash = NullHash();

        BasicTwistPacket packet = BasicTwistPacket.fromHashes(bodyHash, statsHash);

        Twist twist = Twist(ShaHash256.hash(packet.toUint8List()), packet);

        print(twist.toMap());

        expect(packet.toUint8List().length, equals(39));
        expect(packet.getBodyHash() == bodyHash, equals(true));
        expect(packet.getStatsHash() == statsHash, equals(true));
      });
    });
  });
}
