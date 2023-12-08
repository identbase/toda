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
  
  String toString() {
    return _data.toString();
  }

  int toNumber() {
    return _data.getUint8(0);
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
  static Shape shape = Shape.BASIC_TWIST;
  static String description = 'Two concatonated hashes';

  static BasicTwistPacket fromHashes(Hash body, Hash stats) {
    Uint8List contentLength = Uint8List(Packet.CONTENT_LENGTH_BYTES);
    BytesBuilder bb = BytesBuilder();

    bb.add(body.toUint8List());
    bb.add(stats.toUint8List());

    contentLength.buffer.asUint32List(0, 1)[0] = body.length + stats.length;
    return BasicTwistPacket(
      Shape.BASIC_TWIST.toUint8List(),
      contentLength,
      bb.toBytes(),
    );
  }

  Hash getBodyHash() {
    Uint8List algoData = Uint8List.fromList(_content.getRange(0, 1).toList());
    Code algo = new Code(algoData.first);
    Uint8List data = Uint8List(0);

    if (algo == Code.NULL) {
      data = Uint8List.fromList(_content.getRange(1, NullHash.FIXED_HASH_VALUE_LENGTH + 1).toList());
    } else if (algo == Code.UNIT) {
      data = Uint8List.fromList(_content.getRange(1, UnitHash.FIXED_HASH_VALUE_LENGTH + 1).toList());
    } else if (algo == Code.SHA_256) {
      data = Uint8List.fromList(_content.getRange(1, ShaHash256.FIXED_HASH_VALUE_LENGTH + 1).toList());
    } else if (algo == Code.BLAKE3_256 || algo == Code.BLAKE3_512) {
      throw UnimplementedError("Blake3 hashes unimplemented");
    } else {
      throw UnsupportedError("Unsupported hash algorithm");
    }
  
    BytesBuilder builder = BytesBuilder();

    builder.add(algoData);
    builder.add(data);

    return Hash.parse(builder.toBytes());
  }

  Hash getStatsHash() {
    Uint8List bodyAlgoData = Uint8List.fromList(_content.getRange(0, 1).toList());
    Code bodyAlgo = new Code(bodyAlgoData.first);
   
    Uint8List algoData = Uint8List(1);
    Uint8List data = Uint8List(0); 

    if (bodyAlgo == Code.NULL || bodyAlgo == Code.UNIT) {
      algoData = Uint8List.fromList(_content.getRange(NullHash.FIXED_HASH_VALUE_LENGTH + 1, NullHash.FIXED_HASH_VALUE_LENGTH + 2).toList());
      data = Uint8List.fromList(_content.getRange(NullHash.FIXED_HASH_VALUE_LENGTH + 2, _content.lengthInBytes).toList());
    } else if (bodyAlgo == Code.SHA_256) {
      algoData = Uint8List.fromList(_content.getRange(ShaHash256.FIXED_HASH_VALUE_LENGTH + 1, ShaHash256.FIXED_HASH_VALUE_LENGTH + 2).toList());

      data = Uint8List.fromList(_content.getRange(ShaHash256.FIXED_HASH_VALUE_LENGTH + 2, _content.lengthInBytes).toList());
    } else if (bodyAlgo == Code.BLAKE3_256 || bodyAlgo == Code.BLAKE3_512) {
      throw UnimplementedError("Blake3 hashes unimplemented");
    } else {
      throw UnsupportedError("Unsupported hash algorithm");
    }

    BytesBuilder builder = BytesBuilder();

    builder.add(algoData);
    builder.add(data);

    return Hash.parse(builder.toBytes());
  }
  
  BasicTwistPacket(Uint8List shape, Uint8List contentLength, Uint8List content)
      : super(shape, contentLength, content);
}

class BasicBodyPacket extends BasePacket {
  static Shape shape = Shape.BASIC_BODY;
  static String description = 'Six concatenated hashes';

  static BasicBodyPacket fromHashes(Hash prev, Hash teth, Hash shld, Hash reqs, Hash rigg, Hash cargo) {
    Uint8List contentLength = Uint8List(Packet.CONTENT_LENGTH_BYTES);
    BytesBuilder bb = BytesBuilder();

    bb.add(prev.toUint8List());
    bb.add(teth.toUint8List());
    bb.add(shld.toUint8List());
    bb.add(reqs.toUint8List());
    bb.add(rigg.toUint8List());
    bb.add(cargo.toUint8List());

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
  static Shape shape = Shape.ARB;
  static String description = 'Arbitrrary binary content';

  Uint8List getContents() {
    return this._content;
  }

  ArbitraryPacket(Uint8List shape, Uint8List contentLength, Uint8List content)
      : super(shape, contentLength, content);
}

class HashesPacket extends BasePacket {
  static Shape shape = Shape.HASHES;
  static String description = 'A list of one or more hashes concatonated';

  List<Hash> getHashes() {
    List<Hash> list = []; 
    Uint8List content = _content;

    while(content.lengthInBytes > 0) {
      int range = 0;

      Uint8List algoData = Uint8List.fromList(content.getRange(0, Hash.FIXED_ALGO_CODE_LENGTH).toList());
      Code algo = Code(algoData.first);
   
      if (algo == Code.NULL || algo == Code.UNIT) {
        range = 1;
      } else if (algo == Code.SHA_256) {
        range = 33;
      } else if (algo == Code.BLAKE3_256 || algo == Code.BLAKE3_512) {
        throw UnimplementedError("Blake3 hashes unimplemented");
      } else {
        throw UnsupportedError("Unsupported hash algorithm");
      }

      Uint8List data = Uint8List.fromList(content.getRange(0, range).toList());

      list.add(Hash.parse(data));

      content.removeRange(0, range);
    }

    return list;
  }

  HashesPacket(Uint8List shape, Uint8List contentLength, Uint8List content)
      : super(shape, contentLength, content);
}

class PairTriePacket extends BasePacket {
  static Shape shape = Shape.PAIRTRIE;
  static String description = 'A map of hashes, expressed as a list of key, value pairs of hashes';

  Map<Hash, Hash> getPairTrie() {
    List<Hash> list = getHashes();
    Map<Hash, Hash> map = Map<Hash, Hash>();

    // TODO: Add checks to ensure pairtrie has even number of hashes
    // TODO: Add checks that the pairtrie is sorted AND does not have duplicate keys
    for (var i = 0; i < list.length / 2; i ++) {
      // If we are even index, skip
      if (i % 2 == 0) {
        continue;
      }

      map.addEntries([
        MapEntry(list[i - 1], list[i]),
      ]);
    }

    return map;
  }

  List<Hash> getHashes() {
    List<Hash> list = []; 
    Uint8List content = _content;

    while(content.lengthInBytes > 0) {
      int range = 0;

      Uint8List algoData = Uint8List.fromList(content.getRange(0, Hash.FIXED_ALGO_CODE_LENGTH).toList());
      Code algo = Code(algoData.first);
   
      if (algo == Code.NULL || algo == Code.UNIT) {
        range = 1;
      } else if (algo == Code.SHA_256) {
        range = 33;
      } else if (algo == Code.BLAKE3_256 || algo == Code.BLAKE3_512) {
        throw UnimplementedError("Blake3 hashes unimplemented");
      } else {
        throw UnsupportedError("Unsupported hash algorithm");
      }

      Uint8List data = Uint8List.fromList(content.getRange(0, range).toList());

      list.add(Hash.parse(data));

      content.removeRange(0, range);
    }

    return list;
  }

  PairTriePacket(Uint8List shape, Uint8List contentLength, Uint8List content)
      : super(shape, contentLength, content);
}
