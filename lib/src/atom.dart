import 'dart:typed_data';

import './hash.dart';
import './packet.dart';

class Atom {
  Hash identifier;
  Packet packet;

  Atom(this.identifier, this.packet);

  static Atom fromAlgoAndPacket(Code algo, Uint8List packet) {
    Hash hash;

    if (algo == Code.NULL) {
      hash = NullHash();  
    } else if (algo == Code.SHA_256) {
      hash = ShaHash256.hash(packet);
    } else if (algo == Code.BLAKE3_256 || algo == Code.BLAKE3_512) {
      throw UnimplementedError("Blake3 is unimplemented");
    } else {
      throw ArgumentError("Unsupported algorithm");
    }

    return new Atom(hash, Packet.parse(packet));
  }

  Uint8List toUint8List() {
    BytesBuilder bb = BytesBuilder();

    bb.add(identifier.toUint8List());
    bb.add(packet.toUint8List());

    return bb.takeBytes();
  }

  String toString() {
    return identifier.toString();
  }
}

class Lat {
  List<Atom> atoms = [];

  Lat();

  factory Lat.fromEntries(Iterable<Atom> entries) {
    Lat lat = Lat();

    for(Atom entry in entries) {
      lat.atoms.add(entry);
    }

    return lat;
  }

  void withFocus(String hash) {

  }

  Atom focus() {
    return atoms.last;
  }
}
