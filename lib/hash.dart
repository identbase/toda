// import 'dart:convert';
// import 'dart:ffi';
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

  static Code NULL = new Code(0x00);
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
  bool isNull() => true;

  // `parse` assumes that `hash` is exact size, and no larger/smaller.
  static Hash parse(Uint8List hash) {
    Uint8List algoData = Uint8List.fromList(hash.getRange(0, FIXED_ALGO_CODE_LENGTH).toList());
    Code algo = new Code(algoData.first);
    Uint8List data = Uint8List.fromList(hash.getRange(FIXED_ALGO_CODE_LENGTH, hash.length).toList());

    if (algo == Code.NULL) {
      return new NullHash(hash);
    } else if (algo == Code.UNIT) {
      return new UnitHash(hash);
    } else if (algo == Code.SHA_256) {
      return new ShaHash256(hash);
    } else if (algo == Code.BLAKE3_256 || algo == Code.BLAKE3_512) {
      throw UnimplementedError("Blake3 hashes unimplemented");
    } else {
      throw UnsupportedError("Unsupported hash algorithm");
    }
  }

  // `fromUint8List` may not use all of `data`, but we assume the first byte
  // is the algorithm, and take only whats needed after that.
  static Hash fromUint8List(Uint8List data) {
    Uint8List algoData = Uint8List.fromList(data.getRange(0, FIXED_ALGO_CODE_LENGTH).toList());
    Code algo = new Code(algoData.first);

    if (algo == Code.NULL) {
      Uint8List hash = Uint8List.fromList(data.getRange(FIXED_ALGO_CODE_LENGTH, FIXED_ALGO_CODE_LENGTH).toList());
      return new NullHash(hash);
    } else if (algo == Code.UNIT) {
      Uint8List hash = Uint8List.fromList(data.getRange(FIXED_ALGO_CODE_LENGTH, FIXED_ALGO_CODE_LENGTH).toList());
      
      return new UnitHash(hash);
    } else if (algo == Code.SHA_256) {
      Uint8List hash = Uint8List.fromList(data.getRange(FIXED_ALGO_CODE_LENGTH, FIXED_ALGO_CODE_LENGTH + ShaHash256.FIXED_HASH_VALUE_LENGTH).toList());
      return new ShaHash256(hash);
    } else if (algo == Code.BLAKE3_256 || algo == Code.BLAKE3_512) {
      throw UnimplementedError("Blake3 hashes unimplemented");
    } else {
      throw UnsupportedError("Unsupported hash algorithm");
    }
  }

  Hash(this._value);
}

class BaseHash implements Hash {
  int length = 0;
  // Uint8List _hash = Uint8List(0);
  Uint8List _value = Uint8List(0);

  Uint8List toUint8List() {
    return _value;
  }

  bool compare(Hash other) {
    var list = toUint8List().toList();
    var otherList = other.toUint8List().toList();

    if (list.length == otherList.length) {
      return list.every((value) {
        return otherList.contains(value);
      });
    } else {
      return false;
    }
  }

  static hash(Uint8List value) {
    throw UnimplementedError("Not implemented");
  }

  static BaseHash parse(Uint8List hash) {
    throw UnimplementedError("Not implemented");
  }

  bool isNull() => true;

  BaseHash(this._value);
}

class NullHash extends BaseHash {
  static Code code = Code.NULL;
  static Symbol moniker = Symbol("NULL");
  static String description = "A reserved value for special cases";

  Uint8List toUint8List() {
    BytesBuilder bytes = BytesBuilder();
    Uint8List algo = Uint8List(1);
    algo.setRange(0, 1, [NullHash.code.getUint8(0)]);

    bytes.add(algo.toList());
    bytes.add(_value.toList());

    return bytes.toBytes();
  }

  static NullHash hash(Uint8List value) {
    throw UnsupportedError("Cannot hash data with NULL algorithm");
  }

  static NullHash parse(Uint8List hash) {
    return new NullHash(hash);
  }

  @override
  bool operator ==(other) {
    Uint8List codeData = Uint8List(1);
    codeData.setRange(0, 1, toUint8List().getRange(0, 1));
    Code code = new Code(codeData.getRange(0, 1).first);

    // print(toUint8List().toList());
    // print((other as NullHash).toUint8List().toList());
    Uint8List otherCodeData = Uint8List(1);
    otherCodeData.setRange(0, 1, (other as NullHash).toUint8List().getRange(0, 1));
    Code otherCode = new Code(otherCodeData.getRange(0, 1).first);

    // print(code == otherCode);
    // print(compare(other));

    return code == otherCode && compare(other);

  }

  NullHash(Uint8List value) : super(value);
}

class UnitHash extends NullHash {
  static Code code = Code.UNIT;
  static Symbol moniker = Symbol("UNIT");
  static String description = "A reserved value for special cases";

  Uint8List toUint8List() {
    BytesBuilder bytes = BytesBuilder();
    Uint8List algo = Uint8List(1);
    algo.setRange(0, 1, [UnitHash.code.getUint8(0)]);

    bytes.add(algo.toList());
    bytes.add(_value.toList());

    return bytes.toBytes();
  }

  static UnitHash hash(Uint8List value) {
    throw UnsupportedError("Cannot hash data with NULL algorithm");
  }

  static UnitHash parse(Uint8List hash) {
    return new UnitHash(hash);
  }

  UnitHash(Uint8List value) : super(value);
}


class ShaHash256 extends BaseHash {
  static int FIXED_HASH_VALUE_LENGTH = 32;

  static Code code = Code.SHA_256;
  static Symbol moniker = Symbol("SHA_256");
  static String description = "The 256 bit SHA-2 digest in FIPS PUB ISO-4";

  @override
  Uint8List _value = Uint8List(ShaHash256.FIXED_HASH_VALUE_LENGTH);

  Uint8List toUint8List() {
    BytesBuilder bytes = BytesBuilder();
    Uint8List algo = Uint8List(1);
    algo.setRange(0, 1, [ShaHash256.code.getUint8(0)]);

    bytes.add(algo.toList());
    bytes.add(_value.toList());

    return bytes.toBytes();
  }

  String toString() {
    return String.fromCharCodes(_value);
  }

  static ShaHash256 hash(Uint8List value) {
    Digest digest = sha256.convert(value.toList());

    Uint8List hash = Uint8List.fromList(digest.bytes);

    return new ShaHash256(hash);
  }

  static ShaHash256 parse(Uint8List hash) {
    return new ShaHash256(hash);
  }

  ShaHash256(Uint8List value) : super(value) {
    this._value = value;
  }
}


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


/*
class BaseHash implements Hash {
  List<Uint8> _hash;

  static String moniker = "";
  static String description = "";

  static hash(String value) {
    throw UnimplementedError('Not implemented');
  }

  List<Uint8> toUint8List() {
    // 1 Byte, Algorithm Code.
    // n Bytes, Hash Value.
    return this._hash;
  }

  numBytes() {
    return this._value.length;
  }

  getHashValue() {
    return this._hashValue;
  }


  static parse(List<int> raw) {
    return this.createFromAlgoCode(raw[0], raw.sublist(1));
  }

  static createFromAlgoCode(int algoCode, List<int> hashValue) {
    const hash = this.implementFromAlgorithmCode(algoCode);
    if (!hash) {
      throw ArgumentError('Unknown hash algorithm code \'$algoCode\'');
    }
    return new hash(hashValue);
  }

  static List<Map> _hashByAlgoCode = [];

  static getAlgorithm(int algoCode) {
    return this._hashByAlgoCode[algoCode);
  }

  static registerAlgorithm(Hash subclass) {
    this._hashByAlgoCode[subclass.algoCode] = subclass;
  }

  static implementFromAlgorithmCode(int algoCode) {
    return this._hashByAlgoCode[algoCode] || null;
  }

}

class NullHash extends Hash {
  static int algoCode = 0x00;
  static int length = 0;
  static String moniker = 'NULL';
  static String description = 'An empty hash'; 

  NullHash() {
    return super([]);
  }

  static hash(String value) {
    throw UnsupportedError('Cannot hash data with a NullHash');
  }

  static getHashValueLength() {
    return 0;
  }

  static parse(List<int> raw) {
    return new this();
  }

  isNull() {
    return true;
  }
}

class ShaHash extends Hash {
  static getHashValueLength() {
    return this.FIXED_HASH_VALUE_LENGTH;
  }
}

class Sha256Hash extends ShaHash {
  static int algoCode = 0x41;
  static String moniker = 'SHA256';
  static String description = 'A 32-bit SHA hash';

  static int FIXED_HASH_VALUE_LENGTH = 32;

  static hash(List<int> value) {
    return sha256.convert(value).bytes;
  }

  static parse(List<int> raw) {
    return new Sha512Hash(raw.sublist(
        this.FIXED_ALGO_CODE_LENGTH,
        this.FIXED_ALGO_CODE_LENGTH + this.FIXED_HASH_VALUE_LENGTH,
    ));
  }
}

class Sha512Hash extends ShaHash {
  static int algoCode = 0x44';
  static String monkier = 'SHA512';
  static String description = 'A 64-bit SHA hash';

  static int FIXED_HASH_VALUE_LENGTH = 64;

  static hash(List<int> value) {
    return sha512.convert(value).bytes;
  }

  static parse(List<int> raw) {
    return new Sha512Hash(raw.sublist(
        this.FIXED_ALGO_CODE_LENGTH,
        this.FIXED_ALGO_CODE_LENGTH + this.FIXED_HASH_VALUE_LENGTH,
    ));
  }
}

Hash.registerType(NullHash);
Hash.registerType(Sha256Hash);
Hash.registerType(Sha512Hash);

*/
