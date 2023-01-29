import './hash.dart';
import './packet.dart';

class Atom {
  Hash _hash;
  Packet _packet;
  List<int> _serializedValue;

  Atom(Hash hash, Packet packet) {}

  Atom(List<int> hashRaw, List<int> packetRaw) {
    this._hash = Hash.parse(hashRaw);
    this._packet = Packet.parse(packetRaw);
  }

  serialize() {
    return this._serializedValue;
  }

  numBytes() {
    return this._serializedValue.length;
  }

  getHash() {
    return this._hash;
  }

  getPacket() {
    return this._packet;
  }

  static parse(List<int> raw) {
    const hash = Hash.parse(raw);
    const packet = Packet.parse(
      raw.sublist(
        hash.numBytes(),
        hash.numBytes() + Packet.CONTENT_OFFSET + Packet.MAX_CONTENT_SIZE,
      ),
    );

    return new Atom(hash, packet);
  }
}
