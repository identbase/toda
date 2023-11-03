import 'package:toda/toda.dart';

class Arbitrary extends Atom {
  Hash identifier;
  Packet packet;

  Arbitrary(this.identifier, this.packet): super(identifier, packet) {
    assert(packet is ArbitraryPacket);
  }
}

class Hashes extends Atom {
  Hash identifier;
  Packet packet;

  Hashes(this.identifier, this.packet): super(identifier, packet) {
    assert(packet is HashesPacket);
  }
}

class PairTrie extends Atom {
  Hash identifier;
  Packet packet;

  PairTrie(this.identifier, this.packet): super(identifier, packet) {
    assert(packet is PairTriePacket);
  }
}
