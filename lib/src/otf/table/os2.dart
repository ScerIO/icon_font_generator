import 'dart:math' as math;
import 'dart:typed_data';

import '../../utils/exception.dart';
import '../../utils/misc.dart';
import '../../utils/otf.dart';
import '../debugger.dart';
import 'abstract.dart';
import 'cmap.dart';
import 'gsub.dart';
import 'head.dart';
import 'hhea.dart';
import 'hmtx.dart';
import 'table_record_entry.dart';

const _kVersion0 = 0x0000;
const _kVersion1 = 0x0001;
const _kVersion4 = 0x0004;
const _kVersion5 = 0x0005;

/// Byte size for fields added with specific version
const _kVersionDataSize = {
  _kVersion0: 78,
  _kVersion1: 8,
  _kVersion4: 10,
  _kVersion5: 4,
};

const _kDefaultSubscriptRelativeXsize = .65;
const _kDefaultSubscriptRelativeYsize = .7;
const _kDefaultSubscriptRelativeYoffset = .14;
const _kDefaultSuperscriptRelativeYoffset = .48;
const _kDefaultStrikeoutRelativeSize = .1;
const _kDefaultStrikeoutRelativeOffset = .26;

/// Default values for PANOSE classification:
///
/// * Family type: Latin Text
/// * Serif style: Any
/// * Font weight: Book
/// * Proportion: Modern
/// * Anything else: Any
const _kDefaultPANOSE = [2, 0, 5, 3, 0, 0, 0, 0, 0, 0];

class OS2Table extends FontTable {
  OS2Table._(
    super.entry,
    this.version,
    this.xAvgCharWidth,
    this.usWeightClass,
    this.usWidthClass,
    this.fsType,
    this.ySubscriptXSize,
    this.ySubscriptYSize,
    this.ySubscriptXOffset,
    this.ySubscriptYOffset,
    this.ySuperscriptXSize,
    this.ySuperscriptYSize,
    this.ySuperscriptXOffset,
    this.ySuperscriptYOffset,
    this.yStrikeoutSize,
    this.yStrikeoutPosition,
    this.sFamilyClass,
    this.panose,
    this.ulUnicodeRange1,
    this.ulUnicodeRange2,
    this.ulUnicodeRange3,
    this.ulUnicodeRange4,
    this.achVendID,
    this.fsSelection,
    this.usFirstCharIndex,
    this.usLastCharIndex,
    this.sTypoAscender,
    this.sTypoDescender,
    this.sTypoLineGap,
    this.usWinAscent,
    this.usWinDescent,
    this.ulCodePageRange1,
    this.ulCodePageRange2,
    this.sxHeight,
    this.sCapHeight,
    this.usDefaultChar,
    this.usBreakChar,
    this.usMaxContext,
    this.usLowerOpticalPointSize,
    this.usUpperOpticalPointSize,
  ) : super.fromTableRecordEntry();

  factory OS2Table.fromByteData(ByteData byteData, TableRecordEntry entry) {
    final version = byteData.getInt16(entry.offset);

    final isV1 = version >= _kVersion1;
    final isV4 = version >= _kVersion4;
    final isV5 = version >= _kVersion5;

    if (version > _kVersion5) {
      debugUnsupportedTableVersion(kOS2Tag, version);
    }

    return OS2Table._(
      entry,
      version,
      byteData.getInt16(entry.offset + 2),
      byteData.getUint16(entry.offset + 4),
      byteData.getUint16(entry.offset + 6),
      byteData.getUint16(entry.offset + 8),
      byteData.getInt16(entry.offset + 10),
      byteData.getInt16(entry.offset + 12),
      byteData.getInt16(entry.offset + 14),
      byteData.getInt16(entry.offset + 16),
      byteData.getInt16(entry.offset + 18),
      byteData.getInt16(entry.offset + 20),
      byteData.getInt16(entry.offset + 22),
      byteData.getInt16(entry.offset + 24),
      byteData.getInt16(entry.offset + 26),
      byteData.getInt16(entry.offset + 28),
      byteData.getInt16(entry.offset + 30),
      List.generate(10, (i) => byteData.getUint8(entry.offset + 32 + i)),
      byteData.getUint32(entry.offset + 42),
      byteData.getUint32(entry.offset + 46),
      byteData.getUint32(entry.offset + 50),
      byteData.getUint32(entry.offset + 54),
      byteData.getTag(entry.offset + 58),
      byteData.getUint16(entry.offset + 62),
      byteData.getUint16(entry.offset + 64),
      byteData.getUint16(entry.offset + 66),
      byteData.getInt16(entry.offset + 68),
      byteData.getInt16(entry.offset + 70),
      byteData.getInt16(entry.offset + 72),
      byteData.getUint16(entry.offset + 74),
      byteData.getUint16(entry.offset + 76),
      !isV1 ? null : byteData.getUint32(entry.offset + 78),
      !isV1 ? null : byteData.getUint32(entry.offset + 82),
      !isV4 ? null : byteData.getInt16(entry.offset + 86),
      !isV4 ? null : byteData.getInt16(entry.offset + 88),
      !isV4 ? null : byteData.getUint16(entry.offset + 90),
      !isV4 ? null : byteData.getUint16(entry.offset + 92),
      !isV4 ? null : byteData.getUint16(entry.offset + 94),
      !isV5 ? null : byteData.getUint16(entry.offset + 96),
      !isV5 ? null : byteData.getUint16(entry.offset + 98),
    );
  }

  factory OS2Table.create(
    HorizontalMetricsTable hmtx,
    HeaderTable head,
    HorizontalHeaderTable hhea,
    CharacterToGlyphTable cmap,
    GlyphSubstitutionTable gsub,
    String achVendID, {
    int version = _kVersion5,
  }) {
    final asciiAchVendID = achVendID.getAsciiPrintable();

    if (asciiAchVendID.length != 4) {
      throw TableDataFormatException(
          'Incorrect achVendID tag format in OS/2 table');
    }

    final emSize = head.unitsPerEm;
    final height = hhea.ascender - hhea.descender;

    final isV1 = version >= _kVersion1;
    final isV4 = version >= _kVersion4;
    final isV5 = version >= _kVersion5;

    final scriptXsize = (emSize * _kDefaultSubscriptRelativeXsize).round();
    final scriptYsize = (height * _kDefaultSubscriptRelativeYsize).round();
    final subscriptYoffset =
        (height * _kDefaultSubscriptRelativeYoffset).round();
    final superscriptYoffset =
        (height * _kDefaultSuperscriptRelativeYoffset).round();
    final strikeoutSize = (height * _kDefaultStrikeoutRelativeSize).round();
    final strikeoutOffset = (height * _kDefaultStrikeoutRelativeOffset).round();

    final cmapFormat4subtable =
        cmap.data.whereType<CmapSegmentMappingToDeltaValuesTable>().first;

    return OS2Table._(
        null,
        version,
        _getAverageWidth(hmtx),
        400, // Regular weight
        5, // Normal width
        0, // Installable embedding
        scriptXsize,
        scriptYsize,
        0, // zero X offset
        subscriptYoffset,
        scriptXsize,
        scriptYsize,
        0, // zero X offset
        superscriptYoffset,
        strikeoutSize,
        strikeoutOffset,
        0, // No Classification
        _kDefaultPANOSE,

        /// NOTE: Only 2 unicode ranges are used now.
        ///
        /// Should be made calculated, in case of using other ranges.

        1, // Bit 1: Basic Latin. Includes space
        (1 << 28) | (1 << 25), // Bits 57 & 60: Non-Plane 0 and Private Use Area
        // 1 << 25, // Bits 57 & 60: Non-Plane 0 and Private Use Area
        0,
        0,
        asciiAchVendID,
        0x40 | 0x80, // REGULAR and USE_TYPO_METRICS
        cmapFormat4subtable.startCode.first,
        cmapFormat4subtable.endCode.last,
        hhea.ascender,
        hhea.descender,
        hhea.lineGap,
        math.max(head.yMax, hhea.ascender),
        -math.min(head.yMin, hhea.descender),
        !isV1 ? null : 0, // The code page is not functional
        !isV1 ? null : 0,
        !isV4 ? null : 0,
        !isV4 ? null : 0,
        !isV4 ? null : 0,
        !isV4 ? null : kUnicodeSpaceCharCode,
        !isV4 ? null : _getMaxContext(gsub),

        /// For fonts that were not designed for multiple optical-size variants,
        /// usLowerOpticalPointSize should be set to 0 (zero),
        /// and usUpperOpticalPointSize should be set to 0xFFFF.
        !isV5 ? null : 0,
        !isV5 ? null : 0xFFFE);
  }

  final int version;

  // Version 0
  final int xAvgCharWidth;
  final int usWeightClass;
  final int usWidthClass;
  final int fsType;
  final int ySubscriptXSize;
  final int ySubscriptYSize;
  final int ySubscriptXOffset;
  final int ySubscriptYOffset;
  final int ySuperscriptXSize;
  final int ySuperscriptYSize;
  final int ySuperscriptXOffset;
  final int ySuperscriptYOffset;
  final int yStrikeoutSize;
  final int yStrikeoutPosition;
  final int sFamilyClass;
  final List<int> panose;
  final int ulUnicodeRange1;
  final int ulUnicodeRange2;
  final int ulUnicodeRange3;
  final int ulUnicodeRange4;
  final String achVendID;
  final int fsSelection;
  final int usFirstCharIndex;
  final int usLastCharIndex;
  final int sTypoAscender;
  final int sTypoDescender;
  final int sTypoLineGap;
  final int usWinAscent;
  final int usWinDescent;

  // Version 1
  final int? ulCodePageRange1;
  final int? ulCodePageRange2;

  // Version 4
  final int? sxHeight;
  final int? sCapHeight;
  final int? usDefaultChar;
  final int? usBreakChar;
  final int? usMaxContext;

  // Version 5
  final int? usLowerOpticalPointSize;
  final int? usUpperOpticalPointSize;

  @override
  int get size {
    var size = 0;

    for (final e in _kVersionDataSize.entries) {
      if (e.key > version) {
        break;
      }

      size += e.value;
    }

    return size;
  }

  static int _getAverageWidth(HorizontalMetricsTable hmtx) {
    if (hmtx.hMetrics.isEmpty) {
      return 0;
    }

    final nonEmptyWidths = hmtx.hMetrics.where((m) => m.advanceWidth > 0);

    final widthSum = nonEmptyWidths.fold<int>(0, (p, m) => p + m.advanceWidth);
    return (widthSum / nonEmptyWidths.length).round();
  }

  // NOTE: GPOS is also used in calculation, not supported yet
  static int _getMaxContext(GlyphSubstitutionTable gsub) {
    if (gsub.lookupListTable.lookupTables.isEmpty) {
      return 0;
    }

    var maxContext = 0;

    for (final lookup in gsub.lookupListTable.lookupTables) {
      for (final subtable in lookup.subtables) {
        maxContext = math.max(maxContext, subtable.maxContext);
      }
    }

    return maxContext;
  }

  @override
  void encodeToBinary(ByteData byteData) {
    final isV1 = version >= _kVersion1;
    final isV4 = version >= _kVersion4;
    final isV5 = version >= _kVersion5;

    if (version > _kVersion5) {
      debugUnsupportedTableVersion(kOS2Tag, version);
    }

    byteData
      ..setInt16(0, version)
      ..setInt16(2, xAvgCharWidth)
      ..setUint16(4, usWeightClass)
      ..setUint16(6, usWidthClass)
      ..setUint16(8, fsType)
      ..setInt16(10, ySubscriptXSize)
      ..setInt16(12, ySubscriptYSize)
      ..setInt16(14, ySubscriptXOffset)
      ..setInt16(16, ySubscriptYOffset)
      ..setInt16(18, ySuperscriptXSize)
      ..setInt16(20, ySuperscriptYSize)
      ..setInt16(22, ySuperscriptXOffset)
      ..setInt16(24, ySuperscriptYOffset)
      ..setInt16(26, yStrikeoutSize)
      ..setInt16(28, yStrikeoutPosition)
      ..setInt16(30, sFamilyClass)
      ..setUint32(42, ulUnicodeRange1)
      ..setUint32(46, ulUnicodeRange2)
      ..setUint32(50, ulUnicodeRange3)
      ..setUint32(54, ulUnicodeRange4)
      ..setTag(58, achVendID)
      ..setUint16(62, fsSelection)
      ..setUint16(64, usFirstCharIndex)
      ..setUint16(66, usLastCharIndex)
      ..setInt16(68, sTypoAscender)
      ..setInt16(70, sTypoDescender)
      ..setInt16(72, sTypoLineGap)
      ..setUint16(74, usWinAscent)
      ..setUint16(76, usWinDescent);

    for (var i = 0; i < panose.length; i++) {
      byteData.setUint8(32 + i, panose[i]);
    }

    if (isV1) {
      byteData
        ..setUint32(78, ulCodePageRange1!)
        ..setUint32(82, ulCodePageRange2!);
    }

    if (isV4) {
      byteData
        ..setInt16(86, sxHeight!)
        ..setInt16(88, sCapHeight!)
        ..setUint16(90, usDefaultChar!)
        ..setUint16(92, usBreakChar!)
        ..setUint16(94, usMaxContext!);
    }

    if (isV5) {
      byteData
        ..setUint16(96, usLowerOpticalPointSize!)
        ..setUint16(98, usUpperOpticalPointSize!);
    }
  }
}
