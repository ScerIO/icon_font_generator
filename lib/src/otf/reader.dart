import 'dart:typed_data';

import '../utils/exception.dart';
import '../utils/otf.dart';

import 'debugger.dart';
import 'otf.dart';
import 'table/all.dart';

/// A helper for reading an OpenType font from a binary data.
class OTFReader {
  OTFReader.fromByteData(this._byteData);

  final ByteData _byteData;

  late OffsetTable _offsetTable;
  late OpenTypeFont _font;

  /// Tables by tags
  final _tableMap = <String, FontTable>{};

  /// Ordered set of table tags to parse first
  final _tagsParseOrder = <String>{kHeadTag, kMaxpTag, kLocaTag, kHheaTag};

  int get _indexToLocFormat => _font.head.indexToLocFormat;
  int get numGlyphs => _font.maxp.numGlyphs;

  /// Reads an OpenType font file and returns [OpenTypeFont] instance
  ///
  /// Throws [ChecksumException] if calculated checksum is different than expected
  OpenTypeFont read() {
    _tableMap.clear();

    final entryMap = <String, TableRecordEntry>{};

    _offsetTable = OffsetTable.fromByteData(_byteData);
    _font = OpenTypeFont(_offsetTable, _tableMap);

    _readTableRecordEntries(entryMap);
    _readTables(entryMap);

    _validateChecksums();

    return _font;
  }

  int _readTableRecordEntries(Map<String, TableRecordEntry> outputMap) {
    var offset = kOffsetTableLength;

    for (var i = 0; i < _offsetTable.numTables; i++) {
      final entry = TableRecordEntry.fromByteData(_byteData, offset);
      outputMap[entry.tag] = entry;
      _tagsParseOrder.add(entry.tag);

      offset += kTableRecordEntryLength;
    }

    return offset;
  }

  void _readTables(Map<String, TableRecordEntry> entryMap) {
    for (final tag in _tagsParseOrder) {
      final entry = entryMap[tag];

      if (entry == null) {
        continue;
      }

      final table = _createTableFromEntry(entry);

      if (table == null) {
        continue;
      }

      _tableMap[tag] = table;
    }
  }

  FontTable? _createTableFromEntry(TableRecordEntry entry) {
    switch (entry.tag) {
      case kHeadTag:
        return HeaderTable.fromByteData(_byteData, entry);
      case kMaxpTag:
        return MaximumProfileTable.fromByteData(_byteData, entry);
      case kLocaTag:
        return IndexToLocationTable.fromByteData(
            _byteData, entry, _indexToLocFormat, numGlyphs);
      case kGlyfTag:
        return GlyphDataTable.fromByteData(
            _byteData, entry, _font.loca, numGlyphs);
      case kGSUBTag:
        return GlyphSubstitutionTable.fromByteData(_byteData, entry);
      case kOS2Tag:
        return OS2Table.fromByteData(_byteData, entry);
      case kPostTag:
        return PostScriptTable.fromByteData(_byteData, entry);
      case kNameTag:
        return NamingTable.fromByteData(_byteData, entry);
      case kCmapTag:
        return CharacterToGlyphTable.fromByteData(_byteData, entry);
      case kHheaTag:
        return HorizontalHeaderTable.fromByteData(_byteData, entry);
      case kHmtxTag:
        return HorizontalMetricsTable.fromByteData(
            _byteData, entry, _font.hhea, numGlyphs);
      case kCFFTag:
      case kCFF2Tag:
        return CFFTable.fromByteData(_byteData, entry);
      default:
        debugUnsupportedTable(entry.tag);
        return null;
    }
  }

  /// Validates tables' and font's checksum
  ///
  /// Throws [ChecksumException] if calculated checksum is different than expected
  void _validateChecksums() {
    final byteDataCopy = ByteData.sublistView(
        Uint8List.fromList([..._byteData.buffer.asUint8List()]))
      ..setUint32(_font.head.entry!.offset + 8,
          0); // Setting head table's checkSumAdjustment to 0

    for (final table in _font.tableMap.values) {
      final entry = table.entry!;

      final tableOffset = entry.offset;
      final tableLength = entry.length;

      final tableByteData = ByteData.sublistView(
          byteDataCopy, tableOffset, tableOffset + tableLength);
      final actualChecksum = calculateTableChecksum(tableByteData);
      final expectedChecksum = entry.checkSum;

      if (actualChecksum != expectedChecksum) {
        throw ChecksumException.table(entry.tag);
      }
    }

    final actualFontChecksum = calculateFontChecksum(byteDataCopy);

    if (_font.head.checkSumAdjustment != actualFontChecksum) {
      throw ChecksumException.font();
    }
  }
}
