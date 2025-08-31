import 'dart:math' as math;
import 'dart:typed_data';

import '../../common/generic_glyph.dart';
import '../../utils/misc.dart';
import '../../utils/otf.dart';

import 'all.dart';

const kChecksumMagicNumber = 0xB1B0AFBA;

const _kMagicNumber = 0x5F0F3CF5;
const _kMacStyleRegular = 0;
const _kIndexToLocFormatShort = 0;
const _kIndexToLocFormatLong = 1;

const _kLowestRecPPEMdefault = 8;

const _kHeaderTableSize = 54;

class HeaderTable extends FontTable {
  HeaderTable(
      super.entry,
      this.fontRevision,
      this.checkSumAdjustment,
      this.flags,
      this.unitsPerEm,
      this.created,
      this.modified,
      this.xMin,
      this.yMin,
      this.xMax,
      this.yMax,
      this.macStyle,
      this.lowestRecPPEM,
      this.indexToLocFormat)
      : majorVersion = 1,
        minorVersion = 0,
        fontDirectionHint = 2,
        glyphDataFormat = 0,
        magicNumber = _kMagicNumber,
        super.fromTableRecordEntry();

  HeaderTable._(
      TableRecordEntry super.entry,
      this.majorVersion,
      this.minorVersion,
      this.fontRevision,
      this.checkSumAdjustment,
      this.magicNumber,
      this.flags,
      this.unitsPerEm,
      this.created,
      this.modified,
      this.xMin,
      this.yMin,
      this.xMax,
      this.yMax,
      this.macStyle,
      this.lowestRecPPEM,
      this.fontDirectionHint,
      this.indexToLocFormat,
      this.glyphDataFormat)
      : super.fromTableRecordEntry();

  factory HeaderTable.fromByteData(ByteData data, TableRecordEntry entry) =>
      HeaderTable._(
          entry,
          data.getUint16(entry.offset),
          data.getUint16(entry.offset + 2),
          Revision.fromInt32(data.getInt32(entry.offset + 4)),
          data.getUint32(entry.offset + 8),
          data.getUint32(entry.offset + 12),
          data.getUint16(entry.offset + 16),
          data.getUint16(entry.offset + 18),
          data.getDateTime(entry.offset + 20),
          data.getDateTime(entry.offset + 28),
          data.getInt16(entry.offset + 36),
          data.getInt16(entry.offset + 38),
          data.getInt16(entry.offset + 40),
          data.getInt16(entry.offset + 42),
          data.getUint16(entry.offset + 44),
          data.getUint16(entry.offset + 46),
          data.getInt16(entry.offset + 48),
          data.getInt16(entry.offset + 50),
          data.getInt16(entry.offset + 52));

  factory HeaderTable.create(
    List<GenericGlyphMetrics> glyphMetricsList,
    GlyphDataTable? glyf,
    Revision revision,
    int unitsPerEm,
  ) {
    final now = MockableDateTime.now();

    final xMin = glyphMetricsList.fold<int>(
        kInt32Max, (prev, m) => math.min(prev, m.xMin));
    final yMin = glyphMetricsList.fold<int>(
        kInt32Max, (prev, m) => math.min(prev, m.yMin));
    final xMax = glyphMetricsList.fold<int>(
        kInt32Min, (prev, m) => math.max(prev, m.xMax));
    final yMax = glyphMetricsList.fold<int>(
        kInt32Min, (prev, m) => math.max(prev, m.yMax));

    return HeaderTable(
        null,
        revision,
        0, // Setting checkSum to zero first, calculating it at last for the entire font
        0x000B,
        unitsPerEm,
        now,
        now,
        xMin,
        yMin,
        xMax,
        yMax,
        _kMacStyleRegular,
        _kLowestRecPPEMdefault,
        glyf == null || glyf.size < 0x20000
            ? _kIndexToLocFormatShort
            : _kIndexToLocFormatLong);
  }

  final int majorVersion;
  final int minorVersion;
  final Revision fontRevision;
  final int checkSumAdjustment;
  final int magicNumber;
  final int flags;
  final int unitsPerEm;
  final DateTime created;
  final DateTime modified;
  final int xMin;
  final int yMin;
  final int xMax;
  final int yMax;
  final int macStyle;
  final int lowestRecPPEM;
  final int fontDirectionHint;
  final int indexToLocFormat;
  final int glyphDataFormat;

  @override
  int get size => _kHeaderTableSize;

  @override
  void encodeToBinary(ByteData byteData) {
    byteData
      ..setUint16(0, majorVersion)
      ..setUint16(2, minorVersion)
      ..setInt32(4, fontRevision.int32value)
      ..setUint32(8, checkSumAdjustment)
      ..setUint32(12, magicNumber)
      ..setUint16(16, flags)
      ..setUint16(18, unitsPerEm)
      ..setDateTime(20, created)
      ..setDateTime(28, modified)
      ..setInt16(36, xMin)
      ..setInt16(38, yMin)
      ..setInt16(40, xMax)
      ..setInt16(42, yMax)
      ..setUint16(44, macStyle)
      ..setUint16(46, lowestRecPPEM)
      ..setInt16(48, fontDirectionHint)
      ..setInt16(50, indexToLocFormat)
      ..setInt16(52, glyphDataFormat);
  }
}
