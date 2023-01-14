import './packet.dart';

class Shape {
  static int _shapeCode;

  getShapeCode() {
    return this._shapeCode;
  }
}

// Twist Shapes (rigging proof structures)
class BasicTwistShape extends Shape {
  static int _shapeCode = 0x48;
}

class BasicBodyShape extends Shape {
  static int _shapeCode = 0x49;
}

// Cargo Shapes (data structures)
class ArbitraryShape extends Shape {
  static int _shapeCode = 0x60;
}

class HashesShape extends Shape {
  static int _shapeCode = 0x61;
}

class PairTrieShape extends Shape {
  static int _shapeCode = 0x62;
}
