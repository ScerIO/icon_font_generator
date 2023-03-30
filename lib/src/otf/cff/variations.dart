import 'dart:typed_data';

import '../../common/codable/binary.dart';
import '../../utils/otf.dart';

const _kRegionAxisCoordinatesSize = 6;

class RegionAxisCoordinates extends BinaryCodable {
  RegionAxisCoordinates(this.startCoord, this.peakCoord, this.endCoord);

  factory RegionAxisCoordinates.fromByteData(ByteData byteData) {
    // NOTE: not converting F2DOT14, because variations are ignored anyway
    return RegionAxisCoordinates(
      byteData.getUint16(0),
      byteData.getUint16(2),
      byteData.getUint16(4),
    );
  }

  final int startCoord;
  final int peakCoord;
  final int endCoord;

  @override
  void encodeToBinary(ByteData byteData) {
    byteData
      ..setUint16(0, startCoord)
      ..setUint16(2, peakCoord)
      ..setUint16(4, endCoord);
  }

  @override
  int get size => _kRegionAxisCoordinatesSize;
}

class ItemVariationData extends BinaryCodable {
  ItemVariationData(this.itemCount, this.shortDeltaCount, this.regionIndexCount,
      this.regionIndexes);

  factory ItemVariationData.fromByteData(ByteData byteData) {
    final regionIndexCount = byteData.getUint16(4);

    return ItemVariationData(
        byteData.getUint16(0),
        byteData.getUint16(2),
        regionIndexCount,
        List.generate(regionIndexCount, (i) => byteData.getUint16(6 + 2 * i)));
  }

  final int itemCount;
  final int shortDeltaCount;
  final int regionIndexCount;
  final List<int> regionIndexes;

  @override
  void encodeToBinary(ByteData byteData) {
    byteData
      ..setUint16(0, itemCount)
      ..setUint16(2, shortDeltaCount)
      ..setUint16(4, regionIndexCount);

    for (var i = 0; i < regionIndexCount; i++) {
      byteData.setUint16(6 + 2 * i, regionIndexes[i]);
    }
  }

  @override
  int get size => 6 + 2 * regionIndexCount;
}

class VariationRegionList extends BinaryCodable {
  VariationRegionList(this.axisCount, this.regionCount, this.regions);

  factory VariationRegionList.fromByteData(ByteData byteData) {
    final axisCount = byteData.getUint16(0);
    final regionCount = byteData.getUint16(2);

    final regions = [
      for (var r = 0; r < regionCount; r++)
        for (var a = 0; a < axisCount; a++)
          RegionAxisCoordinates.fromByteData(byteData.sublistView(
            4 + (a + r * axisCount) * _kRegionAxisCoordinatesSize,
            _kRegionAxisCoordinatesSize,
          ))
    ];

    return VariationRegionList(
      axisCount,
      regionCount,
      regions,
    );
  }

  final int axisCount;
  final int regionCount;
  final List<RegionAxisCoordinates> regions;

  @override
  void encodeToBinary(ByteData byteData) {
    byteData..setUint16(0, axisCount)..setUint16(2, regionCount);

    for (var r = 0; r < regionCount; r++) {
      for (var a = 0; a < axisCount; a++) {
        final index = r * axisCount + a;
        final coords = regions[index];
        final coordsByteData = byteData.sublistView(
            4 + index * _kRegionAxisCoordinatesSize,
            _kRegionAxisCoordinatesSize);
        coords.encodeToBinary(coordsByteData);
      }
    }
  }

  @override
  int get size => 4 + regionCount * axisCount * _kRegionAxisCoordinatesSize;
}

class ItemVariationStore extends BinaryCodable {
  ItemVariationStore(
      this.format,
      this.variationRegionListOffset,
      this.itemVariationDataCount,
      this.itemVariationDataOffsets,
      this.variationRegionList,
      this.itemVariationDataList);

  factory ItemVariationStore.fromByteData(ByteData byteData) {
    final variationRegionListOffset = byteData.getUint32(2);
    final itemVariationDataCount = byteData.getUint16(6);
    final itemVariationDataOffsets = List.generate(
        itemVariationDataCount, (i) => byteData.getUint32(8 + 4 * i));

    final variationRegionList = VariationRegionList.fromByteData(
        byteData.sublistView(variationRegionListOffset));
    final itemVariationDataList = itemVariationDataOffsets
        .map((o) => ItemVariationData.fromByteData(byteData.sublistView(o)))
        .toList();

    return ItemVariationStore(
      byteData.getUint16(0),
      variationRegionListOffset,
      itemVariationDataCount,
      itemVariationDataOffsets,
      variationRegionList,
      itemVariationDataList,
    );
  }

  final int format;
  int variationRegionListOffset;
  int itemVariationDataCount;
  List<int> itemVariationDataOffsets;

  final VariationRegionList variationRegionList;
  final List<ItemVariationData> itemVariationDataList;

  @override
  void encodeToBinary(ByteData byteData) {
    final variationRegionListSize = variationRegionList.size;
    itemVariationDataCount = itemVariationDataList.length;
    variationRegionListOffset = 8 + 4 * itemVariationDataCount;
    itemVariationDataOffsets = [];

    var offset = variationRegionListOffset + variationRegionListSize;

    for (var i = 0; i < itemVariationDataCount; i++) {
      final itemVariationData = itemVariationDataList[i];
      final itemSize = itemVariationData.size;
      itemVariationDataOffsets.add(offset);

      byteData.setUint32(8 + 4 * i, offset);
      itemVariationData.encodeToBinary(byteData.sublistView(offset, itemSize));

      offset += itemSize;
    }

    byteData
      ..setUint16(0, format)
      ..setUint32(2, variationRegionListOffset)
      ..setUint16(6, itemVariationDataCount);

    variationRegionList.encodeToBinary(byteData.sublistView(
        variationRegionListOffset, variationRegionListSize));
  }

  int get _itemVariationSubtableListSize =>
      itemVariationDataList.fold<int>(0, (p, i) => p + i.size);

  @override
  int get size =>
      8 +
      4 * itemVariationDataCount +
      variationRegionList.size +
      _itemVariationSubtableListSize;
}

class VariationStoreData extends BinaryCodable {
  VariationStoreData(this.length, this.store);

  factory VariationStoreData.fromByteData(ByteData byteData) {
    return VariationStoreData(
      byteData.getUint16(0),
      ItemVariationStore.fromByteData(byteData.sublistView(2)),
    );
  }

  int length;
  final ItemVariationStore store;

  @override
  void encodeToBinary(ByteData byteData) {
    final storeSize = store.size;
    length = storeSize;
    byteData.setUint16(0, length);

    store.encodeToBinary(byteData.sublistView(2, storeSize));
  }

  @override
  int get size => 2 + store.size;
}
