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

  Uint8List toUint8List() {
    Uint8List shape = Uint8List(Packet.CONTENT_LENGTH_OFFSET);
    shape.setRange(0, 1, [this.getUint8(0)]);
    return shape;
  }

  // @override
  noSuchMethod(Invocation invocation) =>
      throw UnsupportedError("Cannot use method on Shape");
      // 'Got the ${invocation.memberName} with arguments ${invocation.positionalArguments}';

  bool operator ==(other) {
    return other is Shape && getUint8(0) == other.getUint8(0);
  }
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
    BytesBuilder bytes = BytesBuilder();

    bytes.add(_shape);
    bytes.add(_contentLength);
    bytes.add(_content);

    return bytes.toBytes();
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

  static BasicTwistPacket fromHashes(Uint8List body, Uint8List stats) {
    Uint8List contentLength = Uint8List(Packet.CONTENT_LENGTH_BYTES);
    BytesBuilder bb = BytesBuilder();

    bb.add(body);
    bb.add(stats);

    contentLength.buffer.asUint32List(0, 1)[0] = body.length + stats.length;
    return BasicTwistPacket(
      Shape.BASIC_TWIST.toUint8List(),
      contentLength,
      bb.toBytes(),
    );
  }

  Hash getBodyHash() {
    // Body is always first, making retrieval easier.
    Uint8List algo = Uint8List.fromList(this._content.getRange(0, 1).toList());
    Code code = new Code(algo.first);

    if (code == Code.NULL) {
      return new NullHash(Uint8List(0));
    } else if (code == Code.UNIT) {
      return new UnitHash(Uint8List(0));
    } else if (code == Code.SHA_256) {
      Uint8List body = Uint8List.fromList(this._content.getRange(0, ShaHash256.FIXED_HASH_VALUE_LENGTH + Hash.FIXED_ALGO_CODE_LENGTH).toList());
      return new ShaHash256(body);
    } else if (code == Code.BLAKE3_256 || code == Code.BLAKE3_512) {
      throw UnimplementedError("Blake3 hashes unimplemented");
    } else {
      throw UnsupportedError("Unsupported hash algorithm");
    }
  }

  Hash getStatsHash() {
    Hash body = getBodyHash();
    Uint8List bodyData = body.toUint8List();
    Uint8List algo = Uint8List.fromList(this._content.getRange(bodyData.length, bodyData.length + Hash.FIXED_ALGO_CODE_LENGTH).toList());
    Code code = new Code(algo.first);

    if (code == Code.NULL) {
      return new NullHash(Uint8List(0));
    } else if (code == Code.UNIT) {
      return new UnitHash(Uint8List(0));
    } else if (code == Code.SHA_256) {
      Uint8List stats = Uint8List.fromList(this._content.getRange(bodyData.length + Hash.FIXED_ALGO_CODE_LENGTH, this._content.length).toList());
      return new ShaHash256(stats);
    } else if (code == Code.BLAKE3_256 || code == Code.BLAKE3_512) {
      throw UnimplementedError("Blake3 hashes unimplemented");
    } else {
      throw UnsupportedError("Unsupported hash algorithm");
    }
   
  }
  
  BasicTwistPacket(Uint8List shape, Uint8List contentLength, Uint8List content)
      : super(shape, contentLength, content);
}

class BasicBodyPacket extends BasePacket {
  static Shape moniker = Shape.BASIC_BODY;
  static String description = 'Six concatenated hashes';

  static BasicBodyPacket fromHashes(Uint8List prev, Uint8List teth, Uint8List shld, Uint8List reqs, Uint8List rigg, Uint8List cargo) {
    Uint8List contentLength = Uint8List(Packet.CONTENT_LENGTH_BYTES);
    BytesBuilder bb = BytesBuilder();

    bb.add(prev);
    bb.add(teth);
    bb.add(shld);
    bb.add(reqs);
    bb.add(rigg);
    bb.add(cargo);

    contentLength.buffer.asUint32List(0, 1)[0] = prev.length
        + teth.length
        + shld.length
        + reqs.length
        + rigg.length
        + cargo.length;

    return BasicBodyPacket(
      Shape.BASIC_BODY.toUint8List(),
      contentLength,
      bb.toBytes(),
    );
  }
  

  Hash getPrevHash() {
    // prev is always first.
    return Hash.fromUint8List(this._content);
  }

  // TODO: Make this not O(n^n)...
  Hash getTethHash() {
    Hash prev = getPrevHash();

    return Hash.fromUint8List(Uint8List.fromList(this._content.getRange(prev.length, this._content.length).toList()));
  }

  // TODO: Make this not O(n^n)...
  Hash getShldHash() {
    Hash prev = getPrevHash();
    Hash teth = getTethHash(); 
    
    return Hash.fromUint8List(
      Uint8List.fromList(
        this._content.getRange(prev.length + teth.length, this._content.length).toList()
      )
    );
  }

  Hash getRequirementsHash() {
    Hash prev = getPrevHash();
    Hash teth = getTethHash();
    Hash shld = getShldHash();
    
    return Hash.fromUint8List(
      Uint8List.fromList(
        this._content.getRange(prev.length + teth.length + shld.length, this._content.length).toList()
      )
    );
  }

  Hash getRiggingHash() {
    Hash prev = getPrevHash();
    Hash teth = getTethHash();
    Hash shld = getShldHash();
    Hash reqs = getRequirementsHash();
    
    return Hash.fromUint8List(
      Uint8List.fromList(
        this._content.getRange(prev.length + teth.length + shld.length + reqs.length, this._content.length).toList()
      )
    );
  }

  Hash getCargoHash() {
    Hash prev = getPrevHash();
    Hash teth = getTethHash();
    Hash shld = getShldHash();
    Hash reqs = getRequirementsHash();
    Hash rigg = getRiggingHash();
    
    return Hash.fromUint8List(
      Uint8List.fromList(
        this._content.getRange(prev.length + teth.length + shld.length + reqs.length + rigg.length, this._content.length).toList()
      )
    );
  }

  BasicBodyPacket(Uint8List shape, Uint8List contentLength, Uint8List content)
      : super(shape, contentLength, content) {
    this._shape = shape;
    this._contentLength = contentLength;
    this._content = content;
  }
}


// Cargo packets
class ArbitraryPacket extends BasePacket {
  static Shape moniker = Shape.ARB;
  static String description = 'Arbitrrary binary content';

  Uint8List getContents() {
    return this._content;
  }

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
