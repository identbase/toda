import 'dart:typed_data';

import './hash.dart';
import './packet.dart';

class Atom {
  Hash hash;
  Packet packet;

  Atom(this.hash, this.packet);

  static Atom fromAlgoAndPacket(Code algo, Uint8List packet) {
    Hash hash;

    if (algo == Code.NULL) {
      hash = NullHash.hash(packet);  
    } else if (algo == Code.SHA_256) {
      hash = ShaHash256.hash(packet);
    } else if (algo == Code.BLAKE3_256 || algo == Code.BLAKE3_512) {
      throw UnimplementedError("Blake3 is unimplemented");
    } else {
      throw ArgumentError("Unsupported algorithm");
    }

    return new Atom(hash, Packet.parse(packet));
  }
}
