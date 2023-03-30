import 'dart:typed_data';

import '../../../common/codable/binary.dart';

const _kGlyphHeaderSize = 10;

class GlyphHeader implements BinaryCodable {
  GlyphHeader(
      this.numberOfContours, this.xMin, this.yMin, this.xMax, this.yMax);

  factory GlyphHeader.fromByteData(ByteData byteData, int offset) {
    return GlyphHeader(
      byteData.getInt16(offset),
      byteData.getInt16(offset + 2),
      byteData.getInt16(offset + 4),
      byteData.getInt16(offset + 6),
      byteData.getInt16(offset + 8),
    );
  }

  final int numberOfContours;
  final int xMin;
  final int yMin;
  final int xMax;
  final int yMax;

  bool get isComposite => numberOfContours.isNegative;

  @override
  int get size => _kGlyphHeaderSize;

  @override
  void encodeToBinary(ByteData byteData) {
    byteData
      ..setInt16(0, numberOfContours)
      ..setInt16(2, xMin)
      ..setInt16(4, yMin)
      ..setInt16(6, xMax)
      ..setInt16(8, yMax);
  }
}
