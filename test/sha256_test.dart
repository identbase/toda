import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

import '../lib/hash.dart';

void main() {
  group("ShaHash256", () {
    test("static properties", () {
      expect(ShaHash256.code.getUint8(0), equals(0x41));
      expect(ShaHash256.moniker, equals(#SHA_256));
      expect(
        ShaHash256.description, equals("The 256 bit SHA-2 digest in FIPS PUB ISO-4")
      );
    });

    test("hashing", () {
      // Actual
      List<int> test = "test".codeUnits;
      Uint8List bytes = Uint8List.fromList(test);
      ShaHash256 hash = ShaHash256.hash(bytes);

      // Expected
      Digest digest = sha256.convert(bytes);

      expect(
        String.fromCharCodes(hash.toUint8List()),
        equals(String.fromCharCodes(digest.bytes))
      ); 
    });
  });
}
