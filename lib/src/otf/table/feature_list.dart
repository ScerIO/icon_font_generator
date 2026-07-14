import 'dart:typed_data';

import '../../common/codable/binary.dart';
import '../../utils/otf.dart';

const kFeatureRecordSize = 6;

const _kDefaultFeatureTableList = [
  FeatureTable(0, 1, [0]),
];

List<FeatureRecord> _createDefaultFeatureRecordList() => [
      FeatureRecord('liga', null),
    ];

class FeatureRecord implements BinaryCodable {
  FeatureRecord(this.featureTag, this.featureOffset);

  factory FeatureRecord.fromByteData(ByteData byteData, int offset) {
    return FeatureRecord(
      byteData.getTag(offset),
      byteData.getUint16(offset + 4),
    );
  }

  final String featureTag;
  int? featureOffset;

  @override
  int get size => kFeatureRecordSize;

  @override
  void encodeToBinary(ByteData byteData) {
    byteData
      ..setTag(0, featureTag)
      ..setUint16(4, featureOffset!);
  }
}

class FeatureTable implements BinaryCodable {
  const FeatureTable(
      this.featureParams, this.lookupIndexCount, this.lookupListIndices);

  factory FeatureTable.fromByteData(
      ByteData byteData, int offset, FeatureRecord record) {
    offset += record.featureOffset!;

    final lookupIndexCount = byteData.getUint16(offset + 2);
    final lookupListIndices = List.generate(
        lookupIndexCount, (i) => byteData.getUint16(offset + 4 + i * 2));

    return FeatureTable(
        byteData.getUint16(offset), lookupIndexCount, lookupListIndices);
  }

  final int featureParams;
  final int lookupIndexCount;
  final List<int> lookupListIndices;

  @override
  int get size => 4 + 2 * lookupIndexCount;

  @override
  void encodeToBinary(ByteData byteData) {
    byteData
      ..setUint16(0, featureParams)
      ..setUint16(2, lookupIndexCount);

    for (var i = 0; i < lookupIndexCount; i++) {
      byteData.setInt16(4 + 2 * i, lookupListIndices[i]);
    }
  }
}

class FeatureListTable implements BinaryCodable {
  FeatureListTable(this.featureCount, this.featureRecords, this.featureTables);

  factory FeatureListTable.fromByteData(ByteData byteData, int offset) {
    final featureCount = byteData.getUint16(offset);
    final featureRecords = List.generate(
        featureCount,
        (i) => FeatureRecord.fromByteData(
            byteData, offset + 2 + kFeatureRecordSize * i));
    final featureTables = List.generate(featureCount,
        (i) => FeatureTable.fromByteData(byteData, offset, featureRecords[i]));

    return FeatureListTable(featureCount, featureRecords, featureTables);
  }

  factory FeatureListTable.create() {
    final featureRecordList = _createDefaultFeatureRecordList();

    return FeatureListTable(
        featureRecordList.length, featureRecordList, _kDefaultFeatureTableList);
  }

  final int featureCount;
  final List<FeatureRecord> featureRecords;

  final List<FeatureTable> featureTables;

  @override
  int get size {
    final recordListSize = featureRecords.fold<int>(0, (p, r) => p + r.size);
    final tableListSize = featureTables.fold<int>(0, (p, t) => p + t.size);

    return 2 + recordListSize + tableListSize;
  }

  @override
  void encodeToBinary(ByteData byteData) {
    byteData.setUint16(0, featureCount);

    var recordOffset = 2;
    var tableRelativeOffset = 2 + kFeatureRecordSize * featureCount;

    for (var i = 0; i < featureCount; i++) {
      final record = featureRecords[i]
        ..featureOffset = tableRelativeOffset
        ..encodeToBinary(
            byteData.sublistView(recordOffset, kFeatureRecordSize));

      final table = featureTables[i];
      final tableSize = table.size;
      table
          .encodeToBinary(byteData.sublistView(tableRelativeOffset, tableSize));

      recordOffset += record.size;
      tableRelativeOffset += table.size;
    }
  }
}
