import './hash.dart';


class Packet {
  List<int> _content;
  List<int> _serializedValue;

  static int MAX_CONTENT_SIZE = 1024 * 1024 * 1024 * 4;
 
  static int PACKET_LENGTH = 4;

  static int SHAPE_OFFSET = 0;
  static int PACKET_OFFSET = 1;
  static int CONTENT_OFFSET = PACKET_OFFSET + PACKET_LENGTH;

  Packet(List<int> content) {
    this._content = content;
  }

  serialize() {
    return this._serializedValue;
  }

  static parse(List<int> raw) {
    return this.createFromShapeCode(raw[0], raw.sublist(1));
  }

  static createFromShapeCode(int shapeCode, List<int> content) {
    const shape = this.implementFromShapeCode(shapeCode);
    if (!shape) {
      throw ArgumentError('Unknown shape code \'$shapeCode\'');
    }
    return new shape(content);
  }

  static List<Map> shapeByShapeCode = [];

  static registerShape(Shape shape) {
    this._shapeByShapeCode[shape.shapeCode] = shape;
  }

  static implementFromShapeCode(int shapeCode) {
    return this._shapeByShapeCode[shapeCode] || null;
  }

  getContent() {
    return this._content;
  }

  getSize() {
    return this._content.length;
  }
}

// Cargo packets
class ArbitraryPacket extends Packet with ArbitraryShape {
  static String moniker = 'ARB';
  static String description = 'Arbitrrary binary content';
}

class HashesPacket extends Packet with HashesShape {
  static String moniker = 'HASHES';
  static String description = 'A list of one or more hashes';
}

class PairTriePacket extends Packet with PairTrieShape {
  static String moniker = 'PAIRTRIE';
  static String description = 'A map of hashes, expressed as a list of key, value pairs of hashes';
}

// Rigging proof packets
class BasicTwistPacket extends Packet with BasicTwistShape {
  static String moniker = 'BASICTWIST';
  static String description = 'Two concatonated hashes';

  getBodyHash() {

  }

  getStatsHash() {

  }
}

class BasicBodyPacket extends Packet with BasicBodyShape {
  static String moniker = 'BASICBODY';
  static String description = 'Six concatenated hashes';

  getPrevHash() {

  }

  getTethHash() {

  }

  getShldHash() {

  }

  getRequirementsTrie() {

  }

  getRiggingTrie() {

  }

  getCargoTrie() {

  }
}

Packet.registerShape(ArbitraryPacket);
Packet.registerShape(HashesPacket);
Packet.registerShape(PairTriePacket);
Packet.registerShape(BasicTwistPacket);
Packet.registerShape(BasicBodyPacket);
