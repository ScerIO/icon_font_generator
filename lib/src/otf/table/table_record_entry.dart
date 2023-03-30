import 'dart:typed_data';

import '../../common/codable/binary.dart';
import '../../utils/otf.dart';

const kTableRecordEntryLength = 16;

class TableRecordEntry implements BinaryCodable {
  TableRecordEntry(this.tag, this.checkSum, this.offset, this.length);

  factory TableRecordEntry.fromByteData(ByteData data, int entryOffset) =>
      TableRecordEntry(
          data.getTag(entryOffset),
          data.getUint32(entryOffset + 4),
          data.getUint32(entryOffset + 8),
          data.getUint32(entryOffset + 12));

  final String tag;
  final int checkSum;
  final int offset;
  final int length;

  @override
  int get size => kTableRecordEntryLength;

  @override
  void encodeToBinary(ByteData byteData) {
    byteData
      ..setTag(0, tag)
      ..setUint32(4, checkSum)
      ..setUint32(8, offset)
      ..setUint32(12, length);
  }
}
