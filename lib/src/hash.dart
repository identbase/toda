import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

// Helper class to make a single byte code more readable
class Code /* implements ByteData */ {
  final ByteData _data = new ByteData(1);

  Code(int value) {
    _data.setUint8(0, value);
  }

  int getInt8(int offset) => _data.getInt8(0);
  int getInt16(int offset, [Endian endian = Endian.big]) => getInt8(0);
  int getInt32(int offset, [Endian endian = Endian.big]) => getInt8(0);
  int getInt64(int offset, [Endian endian = Endian.big]) => getInt8(0);
  void setInt8(int offset, int value) => _data.setInt8(0, value);
  int getUint8(int offset) => _data.getUint8(0);
  int getUint16(int offset, [Endian endian = Endian.big]) => getUint8(0);
  int getUint32(int offset, [Endian endian = Endian.big]) => getUint8(0);
  int getUint64(int offset, [Endian endian = Endian.big]) => getUint8(0);
  void setUint8(int offset, int value) => _data.setUint8(0, value);

  Uint8List toUint8List() {
    BytesBuilder builder = BytesBuilder();

    builder.add([ _data.getUint8(0) ]);

    return builder.toBytes();
  }

  static Code NULL = new Code(0x00);
  static Code SYMBOL = new Code(0x22);
  static Code UNIT = new Code(0xFF);
  static Code SHA_256 = new Code(0x41);
  static Code BLAKE3_256 = new Code(0x42);
  static Code BLAKE3_512 = new Code(0x43);

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnsupportedError("Cannot use method on Code");
      // 'Got the ${invocation.memberName} with arguments ${invocation.positionalArguments}';

  @override
  bool operator ==(other) {
    return other is Code && getUint8(0) == other.getUint8(0);
  }
}

abstract class Hash {
  static int FIXED_ALGO_CODE_LENGTH = 1;
  static int FIXED_HASH_VALUE_LENGTH = 0;

  // late Uint8List _hash;
  Uint8List _value;
  int get length;

  Uint8List toUint8List();
  String toString();
  String toHex();
  bool isNull() => true;

  // `parse` assumes that `hash` is exact size, and no larger/smaller.
  static Hash parse(Uint8List hash) {
    Uint8List algoData = Uint8List.fromList(hash.getRange(0, FIXED_ALGO_CODE_LENGTH).toList());
    Code algo = new Code(algoData.first);

    Uint8List content = Uint8List.fromList(hash.getRange(FIXED_ALGO_CODE_LENGTH, hash.length).toList());

    if (algo == Code.NULL) {
      return NullHash();
    } else if (algo == Code.UNIT) {
      return UnitHash();
    } else if (algo == Code.SHA_256) {
      return ShaHash256(content);
    } else if (algo == Code.BLAKE3_256 || algo == Code.BLAKE3_512) {
      throw UnimplementedError("Blake3 hashes unimplemented");
    } else {
      throw UnsupportedError("Unsupported hash algorithm");
    }
  }

  // `fromUint8List` may not use all of `data`, but we assume the first byte
  // is the algorithm, and take only whats needed after that.
  static Hash fromUint8List(Uint8List data) {
    return Hash.parse(data);
  }

  Hash(this._value);
}

class BaseHash implements Hash {
  int length = 0;
  Uint8List _algo = Uint8List(1);
  Uint8List _value = Uint8List(0);

  Uint8List toUint8List() {
    BytesBuilder builder = BytesBuilder();
    
    builder.add(_algo);
    builder.add(_value);

    return builder.toBytes();
  }

  String toString() {
    Uint8List content = toUint8List();

    return String.fromCharCodes(
      Uint8List.fromList(content.getRange(1, content.length).toList()),
    );
  }

  String toHex() {
    String content = toString();

    return utf8.encode(content).map((c) => c.toRadixString(16)).join();
  }

  @override
  bool operator ==(other) {
    String hex = toHex();
    String otherHex = (other as BaseHash).toHex();

    return hex == otherHex;
  }

  static hash(Uint8List value) {
    throw UnimplementedError("Not implemented");
  }

  static BaseHash parse(Uint8List hash) {
    throw UnimplementedError("Not implemented");
  }

  bool isNull() => true;

  BaseHash(this._algo, this._value);
}

class SymbolHash extends BaseHash {
  static int FIXED_HASH_VALUE_LENGTH = 32;

  static Code code = Code.SYMBOL; 
  static Symbol moniker = Symbol("SYMBOL");
  static String description = "Arbtrary bytes use for introducing a new name";
  @override
  Uint8List _value = Uint8List(SymbolHash.FIXED_HASH_VALUE_LENGTH);

  SymbolHash(Uint8List algo, Uint8List value): super(algo, value);
}

class NullHash extends BaseHash {
  static int FIXED_HASH_VALUE_LENGTH = 0;

  static Code code = Code.NULL;
  static Symbol moniker = Symbol("NULL");
  static String description = "A reserved value for special cases";

  NullHash() : super(
    code.toUint8List(),
    Uint8List(0),
  );
}

class UnitHash extends SymbolHash {
  static int FIXED_HASH_VALUE_LENGTH = 0;

  static Code code = Code.UNIT;
  static Symbol moniker = Symbol("UNIT");
  static String description = "A reserved value for special cases";

  UnitHash() : super(
    code.toUint8List(),
    Uint8List(0),
  );
}

class ShaHash256 extends BaseHash {
  static int FIXED_HASH_VALUE_LENGTH = 32;

  static Code code = Code.SHA_256;
  static Symbol moniker = Symbol("SHA_256");
  static String description = "The 256 bit SHA-2 digest in FIPS PUB ISO-4";

  @override
  Uint8List _value = Uint8List(ShaHash256.FIXED_HASH_VALUE_LENGTH);

  static ShaHash256 hash(Uint8List value) {
    Digest digest = sha256.convert(value.toList());

    Uint8List hash = Uint8List.fromList(digest.bytes);

    return ShaHash256(hash);
  }

  static ShaHash256 parse(Uint8List hash) {
    // Assume this is a proper hash otherwise they would use hash()
    Uint8List data = Uint8List.fromList(hash.getRange(Hash.FIXED_ALGO_CODE_LENGTH, hash.lengthInBytes).toList());

    return ShaHash256(data);
  }

  ShaHash256(Uint8List value) : super(code.toUint8List(), value) {
    this._algo = code.toUint8List();
    this._value = value;
  }
}

/*
// class Blake3Hash extends BaseHash {
//   static Code code = Code.BLAKE3_256;
//   static Symbol moniker = Symbol("BLAKE3_256");
//   static String description = "The 256 bit Blake3 digest in";
// }

// class Blake3Hash256 extends Blake3Hash implements Hash {
//   static Code code = Code.BLAKE3_256;
//   static Symbol moniker = Symbol("BLAKE3_256");
//   static String description = "The 256 bit Blake3 digest in";
// }

// class Blake3Hash512 extends Blake3Hash {
//   static Code code = Code.BLAKE3_512;
//   static Symbol moniker = Symbol("BLAKE3_512");
//   static String description = "The 512 bit Blak3 digest in";
// 
//   static Blake3Hash512 hash(Uint8List value) {
// 
//   }
// 
//   static Blake3Hash512 parse(Uint8List hash) {
// 
//   }
// 
// }
*/
