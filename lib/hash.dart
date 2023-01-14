import 'dart:convert';
// import 'dart:typed_data'; 
import 'package:crypto/crypto.dart';


class Hash {
  List<int> _hashValue;
  List<int> _serializedValue;
  static String moniker;
  static String description;

  static int FIXED_ALGO_CODE_LENGTH = 1;
  static int FIXED_HASH_VALUE_LENGTH = 0; // Not implemented in base class.

  
  Hash(List<int> hashValue) {
    if (hashValue.length != Hash.getHashValueLength()) {
      throw ArgumentError('Cannot set hash value of wrong length');
    }
    this._hashValue = hashValue;
  }

  static hash(String value) {
    throw UnimplementedError('Not implemented');
  }

  serialize() {
    // 1 Byte, Algorithm Code.
    // n Bytes, Hash Value.
    return this._serializedValue;
  }

  numBytes() {
    return this._serializedValue.length;
  }

  getHashValue() {
    return this._hashValue;
  }

  static getHashValueLength() {
    throw UnimplementedError('Not implemented');
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

  isNull() {
    return false;
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
