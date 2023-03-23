import 'dart:typed_data';

import 'package:test/test.dart';

import '../lib/toda.dart';

void main() {
  group("BasicTwistPacket", () {
    group("create", () {
      test("fromHashes", () {
        NullHash prev = NullHash(Uint8List(0));
        NullHash teth = NullHash(Uint8List(0));
        NullHash shld = NullHash(Uint8List(0));
        NullHash reqs = NullHash(Uint8List(0));
        NullHash rigg = NullHash(Uint8List(0));
        NullHash cargo = NullHash(Uint8List(0));

        BasicBodyPacket body = BasicBodyPacket.fromHashes(
          prev.toUint8List(),
          teth.toUint8List(),
          shld.toUint8List(),
          reqs.toUint8List(),
          rigg.toUint8List(),
          cargo.toUint8List(),
        );

        NullHash stats = NullHash(Uint8List(0));

        Atom atom = Atom.fromAlgoAndPacket(Code.SHA_256, body.toUint8List());

        BasicTwistPacket packet = BasicTwistPacket.fromHashes(atom.hash.toUint8List(), stats.toUint8List());

        // TODO: May want to add other checks than length here.
        expect(packet.toUint8List().length, equals(39));
      });
    });
  });
}
