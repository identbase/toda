import 'package:toda/toda.dart';

class Twist extends Atom {
  Hash identifier;
  Packet packet;

  Map<String, Object?> toMap() {
    BasicTwistPacket twistPack = packet as BasicTwistPacket;

    return {
      "algorithm": "",
      "hash": identifier.toHex(),
      "body_hash": twistPack.getBodyHash().toHex(),
      "stats_hash": twistPack.getStatsHash().toHex(),
    };
  }

  Twist(this.identifier, this.packet): super(identifier, packet) {
    assert(packet is BasicTwistPacket);
  }
}

class TwistBody extends Atom {
  Hash identifier;
  Packet packet;

  Map<String, Object?> toMap() {
    BasicBodyPacket bodyPack = packet as BasicBodyPacket;

    return {
      "algorithm": "",
      "hash": identifier.toHex(),
      "prev_hash": bodyPack.getPrevHash().toHex(),
      "teth_hash": bodyPack.getTethHash().toHex(),
      "shield_hash": bodyPack.getShldHash().toHex(),
      "req_hash": bodyPack.getRequirementsHash().toHex(),
      "rigs_has": bodyPack.getRiggingHash().toHex(),
      "cargo_hash": bodyPack.getCargoHash().toHex(),
    };
  }

  TwistBody(this.identifier, this.packet): super(identifier, packet) {
    assert(packet is BasicBodyPacket);
  }
}
