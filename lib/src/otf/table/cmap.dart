import 'dart:math' as math;
import 'dart:typed_data';

import '../../common.dart';
import '../../common/codable/binary.dart';
import '../../utils/otf.dart';
import '../debugger.dart';
import 'abstract.dart';
import 'table_record_entry.dart';

const _kFormat0 = 0;
const _kFormat4 = 4;
const _kFormat12 = 12;

const _kEncodingRecordSize = 8;
const _kSequentialMapGroupSize = 12;
const _kByteEncodingTableSize = 256 + 6;

/// Ordered list of encoding record templates, sorted by platform and encoding ID
List<EncodingRecord> _getDefaultEncodingRecordList() => [
      /// Unicode (2.0 or later semantics BMP only), format 4
      EncodingRecord.create(kPlatformUnicode, 3),

      /// Unicode (Unicode 2.0 or later semantics non-BMP characters allowed), format 12
      EncodingRecord.create(kPlatformUnicode, 4),

      /// Macintosh, format 0
      EncodingRecord.create(kPlatformMacintosh, 0),

      /// Windows (Unicode BMP-only UCS-2), format 4
      EncodingRecord.create(kPlatformWindows, 1),

      /// Windows (Unicode UCS-4), format 12
      EncodingRecord.create(kPlatformWindows, 10),
    ];

/// Ordered list of encoding record format for each template
const _kDefaultEncodingRecordFormatList = [
  _kFormat4,
  _kFormat12,
  _kFormat0,
  _kFormat4,
  _kFormat12
];

class Segment {
  Segment(this.startCode, this.endCode, this.startGlyphID);

  final int startCode;
  final int endCode;
  final int startGlyphID;

  int get idDelta => startGlyphID - startCode;
}

class EncodingRecord implements BinaryCodable {
  EncodingRecord(this.platformID, this.encodingID, this.offset);

  EncodingRecord.create(
    this.platformID,
    this.encodingID,
  ) : offset = null;

  factory EncodingRecord.fromByteData(ByteData byteData, int offset) {
    return EncodingRecord(
      byteData.getUint16(offset),
      byteData.getUint16(offset + 2),
      byteData.getUint32(offset + 4),
    );
  }

  final int platformID;
  final int encodingID;
  int? offset;

  @override
  int get size => _kEncodingRecordSize;

  @override
  void encodeToBinary(ByteData byteData) {
    byteData
      ..setUint16(0, platformID)
      ..setUint16(2, encodingID)
      ..setUint32(4, offset!);
  }
}

class SequentialMapGroup implements BinaryCodable {
  SequentialMapGroup(this.startCharCode, this.endCharCode, this.startGlyphID);

  factory SequentialMapGroup.fromByteData(ByteData byteData, int offset) {
    return SequentialMapGroup(
      byteData.getUint32(offset),
      byteData.getUint32(offset + 4),
      byteData.getUint32(offset + 8),
    );
  }

  final int startCharCode;
  final int endCharCode;
  final int startGlyphID;

  @override
  int get size => _kSequentialMapGroupSize;

  @override
  void encodeToBinary(ByteData byteData) {
    byteData
      ..setUint32(0, startCharCode)
      ..setUint32(4, endCharCode)
      ..setUint32(8, startGlyphID);
  }
}

class CharacterToGlyphTableHeader implements BinaryCodable {
  CharacterToGlyphTableHeader(
    this.version,
    this.numTables,
    this.encodingRecords,
  );

  factory CharacterToGlyphTableHeader.fromByteData(
      ByteData byteData, TableRecordEntry entry) {
    final version = byteData.getUint16(entry.offset);
    final numTables = byteData.getUint16(entry.offset + 2);
    final encodingRecords = List.generate(
        numTables,
        (i) => EncodingRecord.fromByteData(
            byteData, entry.offset + 4 + _kEncodingRecordSize * i));

    return CharacterToGlyphTableHeader(version, numTables, encodingRecords);
  }

  final int version;
  final int numTables;
  final List<EncodingRecord> encodingRecords;

  @override
  int get size => 4 + _kEncodingRecordSize * encodingRecords.length;

  @override
  void encodeToBinary(ByteData byteData) {
    byteData..setUint16(0, version)..setUint16(2, numTables);

    for (var i = 0; i < encodingRecords.length; i++) {
      final r = encodingRecords[i];
      r.encodeToBinary(
          byteData.sublistView(4 + _kEncodingRecordSize * i, r.size));
    }
  }
}

abstract class CmapData implements BinaryCodable {
  CmapData(this.format);

  static CmapData? fromByteData(ByteData byteData, int offset) {
    final format = byteData.getUint16(offset);

    switch (format) {
      case _kFormat0:
        return CmapByteEncodingTable.fromByteData(byteData, offset);
      case _kFormat4:
        return CmapSegmentMappingToDeltaValuesTable.fromByteData(
            byteData, offset);
      case _kFormat12:
        return CmapSegmentedCoverageTable.fromByteData(byteData, offset);
      default:
        debugUnsupportedTableFormat(kCmapTag, format);
        return null;
    }
  }

  static CmapData? create(List<Segment> segmentList, int format) {
    switch (format) {
      case _kFormat0:
        return CmapByteEncodingTable.create();
      case _kFormat4:
        return CmapSegmentMappingToDeltaValuesTable.create(segmentList);
      case _kFormat12:
        return CmapSegmentedCoverageTable.create(segmentList);
      default:
        debugUnsupportedTableFormat(kCmapTag, format);
        return null;
    }
  }

  final int format;
}

class CmapByteEncodingTable extends CmapData {
  CmapByteEncodingTable(
      super.format, this.length, this.language, this.glyphIdArray);

  factory CmapByteEncodingTable.fromByteData(ByteData byteData, int offset) {
    return CmapByteEncodingTable(
        byteData.getUint16(offset),
        byteData.getUint16(offset + 2),
        byteData.getUint16(offset + 4),
        List.generate(256, (i) => byteData.getUint8(offset + 6 + i)));
  }

  factory CmapByteEncodingTable.create() {
    return CmapByteEncodingTable(_kFormat0, _kByteEncodingTableSize, 0,
        List.filled(256, 0) // Not using standard mac glyphs
        );
  }

  final int length;
  final int language;
  final List<int> glyphIdArray;

  @override
  int get size => _kByteEncodingTableSize;

  @override
  void encodeToBinary(ByteData byteData) {
    byteData
      ..setUint16(0, format)
      ..setUint16(2, length)
      ..setUint16(4, language);

    for (var i = 0; i < glyphIdArray.length; i++) {
      byteData.setUint8(6 + i, glyphIdArray[i]);
    }
  }
}

class CmapSegmentMappingToDeltaValuesTable extends CmapData {
  CmapSegmentMappingToDeltaValuesTable(
      super.format,
      this.length,
      this.language,
      this.segCount,
      this.searchRange,
      this.entrySelector,
      this.rangeShift,
      this.endCode,
      this.reservedPad,
      this.startCode,
      this.idDelta,
      this.idRangeOffset,
      this.glyphIdArray);

  factory CmapSegmentMappingToDeltaValuesTable.fromByteData(
      ByteData byteData, int startOffset) {
    final length = byteData.getUint16(startOffset + 2);
    final segCount = byteData.getUint16(startOffset + 6) ~/ 2;

    var offset = startOffset + 14;

    final endCode =
        List.generate(segCount, (i) => byteData.getUint16(offset + 2 * i));
    offset += 2 * segCount;

    final reservedPad = byteData.getUint16(offset);
    offset += 2;

    final startCode =
        List.generate(segCount, (i) => byteData.getUint16(offset + 2 * i));
    offset += 2 * segCount;

    final idDelta =
        List.generate(segCount, (i) => byteData.getInt16(offset + 2 * i));
    offset += 2 * segCount;

    final idRangeOffset =
        List.generate(segCount, (i) => byteData.getUint16(offset + 2 * i));
    offset += 2 * segCount;

    final glyphIdArrayLength = ((startOffset + length) - offset) >> 1;
    final glyphIdArray = List.generate(
        glyphIdArrayLength, (i) => byteData.getUint16(offset + 2 * i));

    return CmapSegmentMappingToDeltaValuesTable(
        byteData.getUint16(startOffset),
        length,
        byteData.getUint16(startOffset + 4),
        segCount,
        byteData.getUint16(startOffset + 8),
        byteData.getUint16(startOffset + 10),
        byteData.getUint16(startOffset + 12),
        endCode,
        reservedPad,
        startCode,
        idDelta,
        idRangeOffset,
        glyphIdArray);
  }

  factory CmapSegmentMappingToDeltaValuesTable.create(
      List<Segment> segmentList) {
    final startCode = segmentList.map((e) => e.startCode).toList();
    final endCode = segmentList.map((e) => e.endCode).toList();
    final idDelta = segmentList.map((e) => e.idDelta).toList();

    final segCount = segmentList.length;

    // Ignoring glyphIdArray
    final glyphIdArray = <int>[];
    final idRangeOffset = List.generate(segCount, (_) => 0);

    final entrySelector = (math.log(segCount) / math.ln2).floor();
    final searchRange = 2 * math.pow(2, entrySelector).toInt();
    final rangeShift = 2 * segCount - searchRange;

    /// Eight 2-byte variable
    /// Four 2-byte arrays of [segCount] length
    /// glyphIdArray is zero length
    final length = 16 + 4 * 2 * segCount;

    return CmapSegmentMappingToDeltaValuesTable(
        _kFormat4,
        length,
        0, // Roman language
        segCount,
        searchRange,
        entrySelector,
        rangeShift,
        endCode,
        0, // Reserved
        startCode,
        idDelta,
        idRangeOffset,
        glyphIdArray);
  }

  final int length;
  final int language;
  final int segCount;
  final int searchRange;
  final int entrySelector;
  final int rangeShift;
  final List<int> endCode;
  final int reservedPad;
  final List<int> startCode;
  final List<int> idDelta;
  final List<int> idRangeOffset;
  final List<int> glyphIdArray;

  @override
  int get size => length;

  @override
  void encodeToBinary(ByteData byteData) {
    byteData
      ..setUint16(0, format)
      ..setUint16(2, length)
      ..setUint16(4, language)
      ..setUint16(6, segCount * 2)
      ..setUint16(8, searchRange)
      ..setUint16(10, entrySelector)
      ..setUint16(12, rangeShift);

    var offset = 14;

    for (final code in endCode) {
      byteData.setUint16(offset, code);
      offset += 2;
    }

    byteData.setUint16(offset, reservedPad);
    offset += 2;

    for (final code in startCode) {
      byteData.setUint16(offset, code);
      offset += 2;
    }

    for (final delta in idDelta) {
      byteData.setUint16(offset, delta);
      offset += 2;
    }

    for (final rangeOffset in idRangeOffset) {
      byteData.setUint16(offset, rangeOffset);
      offset += 2;
    }

    for (final glyphId in glyphIdArray) {
      byteData.setUint16(offset, glyphId);
      offset += 2;
    }
  }
}

class CmapSegmentedCoverageTable extends CmapData {
  CmapSegmentedCoverageTable(
    super.format,
    this.reserved,
    this.length,
    this.language,
    this.numGroups,
    this.groups,
  );

  factory CmapSegmentedCoverageTable.fromByteData(
      ByteData byteData, int offset) {
    final numGroups = byteData.getUint32(offset + 12);

    return CmapSegmentedCoverageTable(
        byteData.getUint16(offset),
        byteData.getUint16(offset + 2),
        byteData.getUint32(offset + 4),
        byteData.getUint32(offset + 8),
        numGroups,
        List.generate(
            numGroups,
            (i) => SequentialMapGroup.fromByteData(
                byteData, offset + 16 + _kSequentialMapGroupSize * i)));
  }

  factory CmapSegmentedCoverageTable.create(List<Segment> segmentList) {
    final groups = segmentList
        .map((e) => SequentialMapGroup(e.startCode, e.endCode, e.startGlyphID))
        .toList();

    final numGroups = groups.length;
    final groupsSize = numGroups * _kSequentialMapGroupSize;

    /// Two 2-byte variables
    /// Three 4-byte variables
    /// SequentialMapGroup (12-byte) array of [numGroups] length
    final length = 16 + groupsSize;

    return CmapSegmentedCoverageTable(
        _kFormat12,
        0,
        length,
        0, // Roman language
        numGroups,
        groups);
  }

  final int reserved;
  final int length;
  final int language;
  final int numGroups;
  final List<SequentialMapGroup> groups;

  @override
  int get size => length;

  @override
  void encodeToBinary(ByteData byteData) {
    byteData
      ..setUint16(0, format)
      ..setUint16(2, reserved)
      ..setUint32(4, length)
      ..setUint32(8, language)
      ..setUint32(12, numGroups);

    var offset = 16;

    for (final group in groups) {
      group.encodeToBinary(byteData.sublistView(offset, group.size));
      offset += group.size;
    }
  }
}

class CharacterToGlyphTable extends FontTable {
  CharacterToGlyphTable(
    super.entry,
    this.header,
    this.data,
  ) : super.fromTableRecordEntry();

  factory CharacterToGlyphTable.fromByteData(
    ByteData byteData,
    TableRecordEntry entry,
  ) {
    final header = CharacterToGlyphTableHeader.fromByteData(byteData, entry);
    final data = List.generate(
            header.numTables,
            (i) => CmapData.fromByteData(
                byteData, entry.offset + header.encodingRecords[i].offset!))
        .whereType<CmapData>()
        .toList();

    return CharacterToGlyphTable(entry, header, data);
  }

  factory CharacterToGlyphTable.create(List<GenericGlyph> fullGlyphList) {
    final fullCharCodeList = fullGlyphList
        .map((e) => e.metadata.charCode)
        .toList()
          ..removeAt(0); // removing .notdef
    final charCodeList = fullCharCodeList.whereType<int>().toList();

    final segmentList = _generateSegments(charCodeList);
    final segmentListFormat4 = [
      ...segmentList,
      Segment(
          0xFFFF, 0xFFFF, 1) // Format 4 table must end with 0xFFFF char code
    ];

    final subtableByFormat = _kDefaultEncodingRecordFormatList
        .toSet()
        .fold<Map<int, CmapData?>>({}, (p, format) {
      p[format] = CmapData.create(
          format == _kFormat4 ? segmentListFormat4 : segmentList, format);
      return p;
    });

    final subtables = [
      for (final format in _kDefaultEncodingRecordFormatList)
        if (subtableByFormat[format] != null) subtableByFormat[format]!,
    ];

    final header = CharacterToGlyphTableHeader(
        0, subtables.length, _getDefaultEncodingRecordList());

    return CharacterToGlyphTable(
      null,
      header,
      subtables,
    );
  }

  final CharacterToGlyphTableHeader header;
  final List<CmapData> data;

  static List<Segment> _generateSegments(List<int> charCodeList) {
    var startCharCode = -1, prevCharCode = -1, startGlyphId = -1;

    final segmentList = <Segment>[];

    void saveSegment() {
      segmentList.add(Segment(
          startCharCode, prevCharCode, startGlyphId + 1 // +1 because of .notdef
          ));
    }

    for (var glyphId = 0; glyphId < charCodeList.length; glyphId++) {
      final charCode = charCodeList[glyphId];

      if (prevCharCode + 1 != charCode && startCharCode != -1) {
        // Save a segment, if there's a gap between previous and current codes
        saveSegment();

        // Next segment starts with new code
        startCharCode = charCode;
        startGlyphId = glyphId;
      } else if (startCharCode == -1) {
        // Start a new segment
        startCharCode = charCode;
        startGlyphId = glyphId;
      }

      prevCharCode = charCode;
    }

    // Closing the last segment
    if (startCharCode != -1 && prevCharCode != -1) {
      saveSegment();
    }

    return segmentList;
  }

  @override
  void encodeToBinary(ByteData byteData) {
    var subtableIndex = 0;
    var offset = header.size;

    for (final subtable in data) {
      subtable.encodeToBinary(byteData.sublistView(offset, subtable.size));
      header.encodingRecords[subtableIndex++].offset = offset;
      offset += subtable.size;
    }

    header.encodeToBinary(byteData.sublistView(0, header.size));
  }

  @override
  int get size => header.size + data.fold<int>(0, (p, d) => p + d.size);
}
