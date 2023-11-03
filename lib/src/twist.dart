import 'package:toda/toda.dart';

class Twist extends Atom {
  Hash identifier;
  Packet packet;

  Twist(this.identifier, this.packet): super(identifier, packet) {
    assert(packet is BasicTwistPacket);
  }
}

class TwistBody extends Atom {
  Hash identifier;
  Packet packet;

  TwistBody(this.identifier, this.packet): super(identifier, packet) {
    assert(packet is BasicBodyPacket);
  }
}
