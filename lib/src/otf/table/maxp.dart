import 'dart:typed_data';

import '../../utils/otf.dart';
import '../debugger.dart';

import 'abstract.dart';
import 'glyf.dart';
import 'table_record_entry.dart';

const _kVersion0 = 0x00005000;
const _kVersion1 = 0x00010000;

const _kTableSizeForVersion = {
  _kVersion0: 6,
  _kVersion1: 32,
};

class MaximumProfileTable extends FontTable {
  MaximumProfileTable.v0(super.entry, this.numGlyphs)
      : version = _kVersion0,
        maxPoints = null,
        maxContours = null,
        maxCompositePoints = null,
        maxCompositeContours = null,
        maxZones = null,
        maxTwilightPoints = null,
        maxStorage = null,
        maxFunctionDefs = null,
        maxInstructionDefs = null,
        maxStackElements = null,
        maxSizeOfInstructions = null,
        maxComponentElements = null,
        maxComponentDepth = null,
        super.fromTableRecordEntry();

  MaximumProfileTable.v1(
      super.entry,
      this.numGlyphs,
      this.maxPoints,
      this.maxContours,
      this.maxCompositePoints,
      this.maxCompositeContours,
      this.maxZones,
      this.maxTwilightPoints,
      this.maxStorage,
      this.maxFunctionDefs,
      this.maxInstructionDefs,
      this.maxStackElements,
      this.maxSizeOfInstructions,
      this.maxComponentElements,
      this.maxComponentDepth)
      : version = _kVersion1,
        super.fromTableRecordEntry();

  factory MaximumProfileTable.create(int numGlyphs, GlyphDataTable? glyf) {
    final isOpenType = glyf == null;

    if (isOpenType) {
      return MaximumProfileTable.v0(null, numGlyphs);
    }

    return MaximumProfileTable.v1(
        null,
        numGlyphs,
        glyf.maxPoints,
        glyf.maxContours,
        0, // Composite glyphs are not supported
        0, // Composite glyphs are not supported
        2, // The twilight zone is used
        0, // 0 max points for the twilight zone

        /// Constants taken from FontForge
        1,
        1,
        0,
        64,
        glyf.maxSizeOfInstructions,
        0,
        0);
  }

  static MaximumProfileTable? fromByteData(
      ByteData data, TableRecordEntry entry) {
    final version = data.getInt32(entry.offset);

    if (version == _kVersion0) {
      return MaximumProfileTable.v0(entry, data.getUint16(entry.offset + 4));
    }
    if (version == _kVersion1) {
      return MaximumProfileTable.v1(
        entry,
        data.getUint16(entry.offset + 4),
        data.getUint16(entry.offset + 6),
        data.getUint16(entry.offset + 8),
        data.getUint16(entry.offset + 10),
        data.getUint16(entry.offset + 12),
        data.getUint16(entry.offset + 14),
        data.getUint16(entry.offset + 16),
        data.getUint16(entry.offset + 18),
        data.getUint16(entry.offset + 20),
        data.getUint16(entry.offset + 22),
        data.getUint16(entry.offset + 24),
        data.getUint16(entry.offset + 26),
        data.getUint16(entry.offset + 28),
        data.getUint16(entry.offset + 30),
      );
    } else {
      debugUnsupportedTableVersion(entry.tag, version);
      return null;
    }
  }

  // Version 0.5
  final int version;
  final int numGlyphs;

  // Version 1.0
  final int? maxPoints;
  final int? maxContours;
  final int? maxCompositePoints;
  final int? maxCompositeContours;
  final int? maxZones;
  final int? maxTwilightPoints;
  final int? maxStorage;
  final int? maxFunctionDefs;
  final int? maxInstructionDefs;
  final int? maxStackElements;
  final int? maxSizeOfInstructions;
  final int? maxComponentElements;
  final int? maxComponentDepth;

  @override
  void encodeToBinary(ByteData byteData) {
    byteData
      ..setInt32(0, version)
      ..setUint16(4, numGlyphs);

    if (version == _kVersion1) {
      byteData
        ..setUint16(6, maxPoints!)
        ..setUint16(8, maxContours!)
        ..setUint16(10, maxCompositePoints!)
        ..setUint16(12, maxCompositeContours!)
        ..setUint16(14, maxZones!)
        ..setUint16(16, maxTwilightPoints!)
        ..setUint16(18, maxStorage!)
        ..setUint16(20, maxFunctionDefs!)
        ..setUint16(22, maxInstructionDefs!)
        ..setUint16(24, maxStackElements!)
        ..setUint16(26, maxSizeOfInstructions!)
        ..setUint16(28, maxComponentElements!)
        ..setUint16(30, maxComponentDepth!);
    } else if (version != _kVersion0) {
      debugUnsupportedTableVersion(kMaxpTag, version);
    }
  }

  @override
  int get size => _kTableSizeForVersion[version]!;
}
