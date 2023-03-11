import 'dart:typed_data';

import 'package:test/test.dart';

import '../lib/packet.dart';

void main() {
  group("BasePacket", () {
    group("packet must be at least 5 bytes", () {
      test("should throw error when it doesn't", () {
        Uint8List shape = Uint8List(0);
        Uint8List contentLength = Uint8List(0);
        Uint8List content = Uint8List(0);

        try {
          new BasePacket(shape, contentLength, content);
        } catch(e) {
          expect(e, isA<TypeError>());
        }
      });

      test("lengthInBytes() should return 5 or more bytes", () {
        Uint8List shape = Uint8List(1);
        Uint8List contentLength = Uint8List(4);
        Uint8List content = Uint8List(0);

        BasePacket packet = new BasePacket(shape, contentLength, content);

        expect(packet.lengthInBytes(), greaterThanOrEqualTo(5));
      });
    });
  });
}
