import 'dart:typed_data';

import '../../common/codable/binary.dart';
import '../../utils/otf.dart';

const kLangSysRecordSize = 6;

class LanguageSystemRecord implements BinaryCodable {
  LanguageSystemRecord(this.langSysTag, this.langSysOffset);

  factory LanguageSystemRecord.fromByteData(ByteData byteData, int offset) {
    return LanguageSystemRecord(
      byteData.getTag(offset),
      byteData.getUint16(offset + 4),
    );
  }

  final String langSysTag;
  int langSysOffset;

  @override
  int get size => kLangSysRecordSize;

  @override
  void encodeToBinary(ByteData byteData) {
    byteData
      ..setTag(0, langSysTag)
      ..setUint16(4, langSysOffset);
  }
}

class LanguageSystemTable implements BinaryCodable {
  const LanguageSystemTable(
    this.lookupOrder,
    this.requiredFeatureIndex,
    this.featureIndexCount,
    this.featureIndices,
  );

  factory LanguageSystemTable.fromByteData(ByteData byteData, int offset) {
    final featureIndexCount = byteData.getUint16(offset + 4);
    final featureIndices = List.generate(
        featureIndexCount, (i) => byteData.getUint16(offset + 6 + 2 * i));

    return LanguageSystemTable(byteData.getUint16(offset),
        byteData.getUint16(offset + 2), featureIndexCount, featureIndices);
  }

  final int lookupOrder;
  final int requiredFeatureIndex;
  final int featureIndexCount;
  final List<int> featureIndices;

  @override
  int get size => 6 + 2 * featureIndexCount;

  @override
  void encodeToBinary(ByteData byteData) {
    byteData
      ..setUint16(0, lookupOrder)
      ..setUint16(2, requiredFeatureIndex)
      ..setUint16(4, featureIndexCount);

    for (var i = 0; i < featureIndexCount; i++) {
      byteData.setInt16(6 + 2 * i, featureIndices[i]);
    }
  }
}
