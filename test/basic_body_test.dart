import 'package:test/test.dart';

import 'package:toda/toda.dart';

void main() {
  group("BasicBodyPacket", () {
    group("create", () {
      test("fromHashes NullHash", () {
        NullHash prev = NullHash();
        NullHash teth = NullHash();
        NullHash shld = NullHash();
        NullHash reqs = NullHash();
        NullHash rigg = NullHash();
        NullHash cargo = NullHash();

        BasicBodyPacket packet = BasicBodyPacket.fromHashes(
          prev, teth, shld, reqs, rigg, cargo,
        );

        TwistBody body = TwistBody(ShaHash256.hash(packet.toUint8List()), packet);

        print(body.toMap());

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
