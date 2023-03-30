import 'dart:typed_data';

/// A class that supports decoding from binary representation
///
/// Every implementation of the interface has *fromByteData* factory
abstract class BinaryDecodable {}

/// A class that supports encoding to binary representation
abstract class BinaryEncodable {
  /// Calculates and returns size of the object (in bytes)
  int get size;

  /// Encodes the object to binary data
  void encodeToBinary(ByteData byteData);
}

/// A class that supports both encoding and decoding to/from binary representation
abstract class BinaryCodable implements BinaryEncodable, BinaryDecodable {}
