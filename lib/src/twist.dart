import 'package:toda/toda.dart';

class Twist extends BaseAtom {
  Hash identifier;
  Packet packet;

  Map<String, Object?> toMap() {
    BasicTwistPacket twistPack = packet as BasicTwistPacket;

    return {
      "shape": BasicTwistPacket.shape.toNumber(),
      "hash": identifier.toHex(),
      "body": twistPack.getBodyHash().toHex() != ""
        ? twistPack.getBodyHash().toHex()
        : 0,
      "stats": twistPack.getStatsHash().toHex() != ""
        ? twistPack.getStatsHash().toHex()
        : 0,
    };
  }

  Twist(this.identifier, this.packet): super(identifier, packet) {
    assert(packet is BasicTwistPacket);
  }
}

class TwistBody extends BaseAtom {
  Hash identifier;
  Packet packet;

  Map<String, Object?> toMap() {
    BasicBodyPacket bodyPack = packet as BasicBodyPacket;

    return {
      "shape": BasicBodyPacket.shape.toNumber(),
      "hash": identifier.toHex(),
      "prev": bodyPack.getPrevHash().toHex() != ""
        ? bodyPack.getPrevHash().toHex()
        : 0,
      "teth": bodyPack.getTethHash().toHex() != ""
        ? bodyPack.getTethHash().toHex()
        : 0,
      "shld": bodyPack.getShldHash().toHex() != ""
        ? bodyPack.getShldHash().toHex()
        : 0,
      "reqs": bodyPack.getRequirementsHash().toHex() != ""
        ? bodyPack.getRequirementsHash().toHex()
        : 0,
      "rigs": bodyPack.getRiggingHash().toHex() != ""
        ? bodyPack.getRiggingHash().toHex()
        : 0,
      "carg": bodyPack.getCargoHash().toHex() != ""
        ? bodyPack.getCargoHash().toHex()
        : 0,
    };
  }

  TwistBody(this.identifier, this.packet): super(identifier, packet) {
    assert(packet is BasicBodyPacket);
  }
}
