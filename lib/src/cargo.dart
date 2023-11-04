import 'dart:convert';

import 'package:toda/toda.dart';

class Arbitrary extends Atom {
  Hash identifier;
  Packet packet;

  Map<String, Object?> toMap() {
    ArbitraryPacket arbPack = packet as ArbitraryPacket;

    return {
      "algorithm": utf8.encode(
        String.fromCharCodes(identifier.toUint8List().getRange(0, 1)))
          .map((c) => c.toRadixString(16))
          .join(),
      "hash": identifier.toHex(),
      "content:": utf8.encode(String.fromCharCodes(arbPack.getContents()))
          .map((c) => c.toRadixString(16))
          .join(),
    };
  }

  Arbitrary(this.identifier, this.packet): super(identifier, packet) {
    assert(packet is ArbitraryPacket);
  }
}

class Hashes extends Atom {
  Hash identifier;
  Packet packet;

  Map<String, Object?> toMap() {
    HashesPacket hashesPack = packet as HashesPacket;

    return {
      "algorithm": utf8.encode(
        String.fromCharCodes(identifier.toUint8List().getRange(0, 1)))
          .map((c) => c.toRadixString(16))
          .join(),
      "hash": identifier.toHex(),
      "content": hashesPack.getHashes().map((hash) => hash.toString()),
    };
  }

  Hashes(this.identifier, this.packet): super(identifier, packet) {
    assert(packet is HashesPacket);
  }
}

class PairTrie extends Atom {
  Hash identifier;
  Packet packet;

  Map<String, Object?> toMap() {
    PairTriePacket pairPack = packet as PairTriePacket;

    return {
      "algorithm": utf8.encode(
        String.fromCharCodes(identifier.toUint8List().getRange(0, 1)))
          .map((c) => c.toRadixString(16))
          .join(),
      "hash": identifier.toHex(),
      "pairs": pairPack.getPairTrie(),
    };
  }

  PairTrie(this.identifier, this.packet): super(identifier, packet) {
    assert(packet is PairTriePacket);
  }
}
