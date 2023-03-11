import 'package:test/test.dart';

import '../lib/hash.dart';

void main() {
  group("Hash", () {
    test("static properties", () {
      expect(Hash.FIXED_ALGO_CODE_LENGTH, equals(1));
      expect(Hash.FIXED_HASH_VALUE_LENGTH, equals(0));
    });
  });

  group("NullHash", () {
    test("static properties", () {
      expect(NullHash.code.getInt8(0), equals(0x00));
      expect(NullHash.moniker, equals(#NULL));
      expect(
        NullHash.description, equals("A reserved value for special cases")
      );
    });

    test("isNull", () {
      var hash = new NullHash();

      expect(hash.isNull(), equals(true));
    });
  });

  group("UnitHash", () {
    test("static properties", () {
      expect(UnitHash.code.getUint8(0), equals(0xFF));
      expect(UnitHash.moniker, equals(#UNIT));
      expect(
        UnitHash.description, equals("A reserved value for special cases")
      );
    });

    test("isNull", () {
      var hash = new UnitHash();

      expect(hash.isNull(), equals(true));
    });
  });
}
