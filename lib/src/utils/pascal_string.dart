import 'dart:typed_data';

import '../common/codable/binary.dart';

class PascalString implements BinaryCodable {
  PascalString(this.string, this.length);

  factory PascalString.fromByteData(ByteData byteData, int offset) {
    final length = byteData.getUint8(offset++);
    final bytes = List.generate(length, (i) => byteData.getUint8(offset + i));
    return PascalString(String.fromCharCodes(bytes), length);
  }

  factory PascalString.fromString(String string) =>
      PascalString(string, string.length);

  final String string;
  final int length;

  @override
  int get size => length + 1;

  @override
  String toString() => string;

  @override
  void encodeToBinary(ByteData byteData) {
    byteData.setUint8(0, length);

    var offset = 1;

    for (final charCode in string.codeUnits) {
      byteData.setUint8(offset++, charCode);
    }
  }
}
