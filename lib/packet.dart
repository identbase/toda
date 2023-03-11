import 'dart:ffi';
import 'dart:typed_data';

import './hash.dart';


// Helper class to make a single byte code more readable
class Shape /* implements ByteData */ {
  final ByteData _data = new ByteData(1);

  Shape(int value) {
    _data.setUint8(0, value);
  }

  int getInt8(int offset) => _data.getInt8(0);
  int getInt16(int offset, [Endian endian = Endian.big]) => getInt8(0);
  int getInt32(int offset, [Endian endian = Endian.big]) => getInt8(0);
  int getInt64(int offset, [Endian endian = Endian.big]) => getInt8(0);
  void setInt8(int offset, int value) => _data.setInt8(0, value);
  int getUint8(int offset) => _data.getUint8(0);
  int getUint16(int offset, [Endian endian = Endian.big]) => getUint8(0);
  int getUint32(int offset, [Endian endian = Endian.big]) => getUint8(0);
  int getUint64(int offset, [Endian endian = Endian.big]) => getUint8(0);
  void setUint8(int offset, int value) => _data.setUint8(0, value);

  static Shape BASIC_TWIST = new Shape(0x48);
  static Shape BASIC_BODY = new Shape(0x49);
  static Shape ARB = new Shape(0x60);
  static Shape HASHES = new Shape(0x61);
  static Shape PAIRTRIE = new Shape(0x62);

  // @override
  noSuchMethod(Invocation invocation) =>
      throw UnsupportedError("Cannot use method on Shape");
      // 'Got the ${invocation.memberName} with arguments ${invocation.positionalArguments}';
}

abstract class Packet {
  static int MAX_CONTENT_SIZE = 1024 * 1024 * 1024 * 4;

  static int SHAPE_OFFSET = 0;
  static int CONTENT_LENGTH_OFFSET = 1;
  static int CONTENT_LENGTH_BYTES = 4;
  static int CONTENT_OFFSET = SHAPE_OFFSET
      + CONTENT_LENGTH_OFFSET
      + CONTENT_LENGTH_BYTES;

  Uint8List _shape = Uint8List(SHAPE_OFFSET);
  Uint8List _contentLength = Uint8List(CONTENT_LENGTH_BYTES);
  late Uint8List _content;

  Uint8List toUint8List();
  int lengthInBytes();

  Shape getShape();
  int getContentLength();

  static Packet parse(Uint8List data) {
    Uint8List shapeData = Uint8List.fromList(data.getRange(0, Packet.CONTENT_LENGTH_OFFSET).toList());
    Shape shape = new Shape(shapeData.first);
    Uint8List contentLengthData = Uint8List.fromList(data.getRange(Packet.CONTENT_LENGTH_OFFSET, Packet.CONTENT_LENGTH_BYTES + Packet.CONTENT_LENGTH_OFFSET).toList());
    Uint8List contentData = Uint8List.fromList(data.getRange(Packet.SHAPE_OFFSET + Packet.CONTENT_LENGTH_OFFSET + Packet.CONTENT_LENGTH_BYTES, data.length).toList());

    if (shape == Shape.BASIC_TWIST) {
      return new BasicTwistPacket(shapeData, contentLengthData, contentData);
    } else if (shape == Shape.BASIC_BODY) {
      return new BasicBodyPacket(shapeData, contentLengthData, contentData);
    } else if (shape == Shape.ARB) {
      return new ArbitraryPacket(shapeData, contentLengthData, contentData);
    } else if (shape == Shape.HASHES) {
      return new HashesPacket(shapeData, contentLengthData, contentData);
    } else if (shape == Shape.PAIRTRIE) {
      return new PairTriePacket(shapeData, contentLengthData, contentData);
    } else {
      throw ArgumentError("Unknown shape of packet");
    }
  }

  Packet(this._shape, this._contentLength, this._content);
}

class BasePacket implements Packet {
  Uint8List _shape = Uint8List(Packet.SHAPE_OFFSET);
  Uint8List _contentLength = Uint8List(Packet.CONTENT_LENGTH_BYTES);
  Uint8List _content = Uint8List(0);

  Uint8List toUint8List() {
    return _content;
  }

  int lengthInBytes() {
    return _shape.lengthInBytes
        + _contentLength.lengthInBytes
        + _content.lengthInBytes;
  }

  Shape getShape() {
    return new Shape(this._shape.first);
  }

  int getContentLength() {
    return _contentLength.reduce((int value, int element) {
      return value + element;
    });
  }

  static BasePacket parse(Uint8List data) {
    throw UnimplementedError("Not implemented");
  }

  BasePacket(this._shape, this._contentLength, this._content) {
    if (this.lengthInBytes() < 5) {
      throw TypeError();
    } 
  }
}

// Rigging proof packets
class BasicTwistPacket extends BasePacket {
  static Shape moniker = Shape.BASIC_TWIST;
  static String description = 'Two concatonated hashes';

  // Hash getBodyHash() {
  // 
  // }

  // Hash getStatsHash() {
  // 
  // }
  
  BasicTwistPacket(Uint8List shape, Uint8List contentLength, Uint8List content)
      : super(shape, contentLength, content);
  /*
    {
      Uint8List shape = Uint8List(Packet.CONTENT_LENGTH_OFFSET);
      shape.setRange(0, 1, [Shape.BASIC_TWIST.getUint8(0)]);

      Uint8List length = Uint8List(Packet.CONTENT_LENGTH_BYTES);

      BasePacket(shape, length, content);
    }
  */
}

class BasicBodyPacket extends BasePacket {
  static Shape moniker = Shape.BASIC_BODY;
  static String description = 'Six concatenated hashes';

  // Hash getPrevHash() {
  // 
  // }

  // Hash getTethHash() {
  // 
  // }

  // Hash getShldHash() {
  // 
  // }

  // Hash getRequirementsTrie() {
  // 
  // }

  // Hash getRiggingTrie() {
  // 
  // }

  // Hash getCargoTrie() {
  // 
  // }

  BasicBodyPacket(Uint8List shape, Uint8List contentLength, Uint8List content)
      : super(shape, contentLength, content);
}


// Cargo packets
class ArbitraryPacket extends BasePacket {
  static Shape moniker = Shape.ARB;
  static String description = 'Arbitrrary binary content';

  ArbitraryPacket(Uint8List shape, Uint8List contentLength, Uint8List content)
      : super(shape, contentLength, content);
}

class HashesPacket extends BasePacket {
  static Shape moniker = Shape.HASHES;
  static String description = 'A list of one or more hashes';

  HashesPacket(Uint8List shape, Uint8List contentLength, Uint8List content)
      : super(shape, contentLength, content);
}

class PairTriePacket extends BasePacket {
  static Shape moniker = Shape.PAIRTRIE;
  static String description = 'A map of hashes, expressed as a list of key, value pairs of hashes';

  PairTriePacket(Uint8List shape, Uint8List contentLength, Uint8List content)
      : super(shape, contentLength, content);
}


/*
  Packet(Uint8 shape, Uint8List content) {
    _contentLength = Uint8List.fromList([content.length]);
    _content = Uint8List.fromList(content);
  }

  serialize() {

    // return this._serializedValue;
  }

  static parse(List<int> raw) {
    return this.createFromShapeShape(raw[0], raw.sublist(1));
  }

  static createFromShapeShape(int shapeShape, List<int> content) {
    const shape = this.implementFromShapeShape(shapeShape);
    if (!shape) {
      throw ArgumentError('Unknown shape code \'$shapeShape\'');
    }
    return new shape(content);
  }

  static List<Map> shapeByShapeShape = [];

  static registerShape(Shape shape) {
    this._shapeByShapeShape[shape.shapeShape] = shape;
  }

  static implementFromShapeShape(int shapeShape) {
    return this._shapeByShapeShape[shapeShape] || null;
  }

  getContent() {
    return this._content;
  }

  getSize() {
    return this._content.length;
  }
}
*/

// Packet.registerShape(ArbitraryPacket);
// Packet.registerShape(HashesPacket);
// Packet.registerShape(PairTriePacket);
// Packet.registerShape(BasicTwistPacket);
// Packet.registerShape(BasicBodyPacket);
