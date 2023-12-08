import 'package:toda/toda.dart';

class Twist extends BaseAtom {
  Hash identifier;
  Packet packet;

  Map<String, Object?> toMap() {
    BasicTwistPacket twistPack = packet as BasicTwistPacket;

    return {
      "shape": BasicTwistPacket.shape.toNumber(),
      "hash": identifier.toHex(),
      "body": twistPack.getBodyHash().toHex(),
      "stats": twistPack.getStatsHash().toHex(),
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
      "prev": bodyPack.getPrevHash().toHex(),
      "teth": bodyPack.getTethHash().toHex(),
      "shld": bodyPack.getShldHash().toHex(),
      "reqs": bodyPack.getRequirementsHash().toHex(),
      "rigs": bodyPack.getRiggingHash().toHex(),
      "carg": bodyPack.getCargoHash().toHex(),
    };
  }

  TwistBody(this.identifier, this.packet): super(identifier, packet) {
    assert(packet is BasicBodyPacket);
  }
}
