import 'dart:typed_data';

import '../common/calculatable_offsets.dart';
import '../common/codable/binary.dart';
import '../common/generic_glyph.dart';
import '../utils.dart';
import '../utils/misc.dart';
import '../utils/otf.dart';
import 'defaults.dart';
import 'reader.dart';
import 'table/all.dart';

/// Ordered list of table tags for encoding (Optimized Table Ordering)
const _kTableTagsToEncode = {
  kHeadTag,
  kHheaTag,
  kMaxpTag,
  kOS2Tag,
  kHmtxTag,
  kNameTag, // NOTE: 'name' should be after 'cmap' for TTF
  kCmapTag,
  kLocaTag,
  kGlyfTag,
  kPostTag,
  kCFFTag,
  kCFF2Tag,
  kGSUBTag
};

/// An OpenType font.
/// Contains either TrueType (glyf table) or OpenType (CFF2 table) outlines
class OpenTypeFont implements BinaryCodable {
  OpenTypeFont(this.offsetTable, this.tableMap);

  factory OpenTypeFont.fromByteData(ByteData byteData) {
    final reader = OTFReader.fromByteData(byteData);
    return reader.read();
  }

  /// Generates new OpenType font.
  ///
  /// Mutates every glyph's metadata,
  /// so that it contains newly generated charcode.
  ///
  /// * [glyphList] is a list of generic glyphs. Required.
  /// * [fontName] is a font name.
  ///   If null, glyph names are omitted (PostScriptV3 table is generated).
  /// * [description] is a font description for naming table.
  /// * [revision] is a font revision. Defaults to 1.0.
  /// * [achVendID] is a vendor ID in OS/2 table. Defaults to 4 spaces.
  /// * If [useOpenType] is set to true, OpenType outlines
  /// in CFF table format are generated.
  /// Otherwise, a font with TrueType outlines (TTF) is generated.
  /// Defaults to true.
  /// * If [usePostV2] is set to true, post table of version 2 is generated
  /// (containing a name for each glyph).
  /// Otherwise, version 3 table (without glyph names) is generated.
  /// Defaults to false.
  /// * If [normalize] is set to true,
  /// glyphs are resized and centered to fit in coordinates grid (unitsPerEm).
  /// Defaults to true.
  factory OpenTypeFont.createFromGlyphs({
    required List<GenericGlyph> glyphList,
    String? fontName,
    String? description,
    Revision? revision,
    String? achVendID,
    bool? useOpenType,
    bool? usePostV2,
    bool? normalize,
  }) {
    if (fontName?.isEmpty ?? false) {
      fontName = null;
    }

    revision ??= kDefaultFontRevision;
    achVendID ??= kDefaultAchVendID;
    fontName ??= kDefaultFontFamily;
    useOpenType ??= true;
    normalize ??= true;
    usePostV2 ??= false;

    glyphList = _generateCharCodes(glyphList);

    // A power of two is recommended only for TrueType outlines
    final unitsPerEm =
        useOpenType ? kDefaultOpenTypeUnitsPerEm : kDefaultTrueTypeUnitsPerEm;

    final baselineExtension = normalize ? kDefaultBaselineExtension : 0;
    final ascender = unitsPerEm - baselineExtension;
    final descender = -baselineExtension;

    final resizedGlyphList = _resizeAndCenter(
      glyphList,
      ascender: normalize ? ascender : null,
      descender: normalize ? descender : null,
      fontHeight: normalize ? null : unitsPerEm,
    );

    final defaultGlyphList = generateDefaultGlyphList(ascender);
    final fullGlyphList = [
      ...defaultGlyphList,
      ...resizedGlyphList,
    ];

    final defaultGlyphMetricsList =
        defaultGlyphList.map((g) => g.metrics).toList();

    // If normalization is off every custom glyph's size equals unitsPerEm
    final customGlyphMetricsList = normalize
        ? resizedGlyphList.map((g) => g.metrics).toList()
        : List.filled(
            resizedGlyphList.length, GenericGlyphMetrics.square(unitsPerEm));

    final glyphMetricsList = [
      ...defaultGlyphMetricsList,
      ...customGlyphMetricsList,
    ];

    final glyf = useOpenType ? null : GlyphDataTable.fromGlyphs(fullGlyphList);
    final head =
        HeaderTable.create(glyphMetricsList, glyf, revision, unitsPerEm);
    final loca = useOpenType
        ? null
        : IndexToLocationTable.create(head.indexToLocFormat, glyf!);
    final hmtx = HorizontalMetricsTable.create(glyphMetricsList, unitsPerEm);
    final hhea = HorizontalHeaderTable.create(
        glyphMetricsList, hmtx, ascender, descender);
    final post = PostScriptTable.create(resizedGlyphList, usePostV2);
    final name = NamingTable.create(fontName, description, revision);

    if (name == null) {
      throw TableDataFormatException('Unknown "name" table format');
    }

    final maxp = MaximumProfileTable.create(fullGlyphList.length, glyf);
    final cmap = CharacterToGlyphTable.create(fullGlyphList);
    final gsub = GlyphSubstitutionTable.create();
    final os2 = OS2Table.create(hmtx, head, hhea, cmap, gsub, achVendID);

    final cff =
        useOpenType ? CFF1Table.create(fullGlyphList, head, hmtx, name) : null;

    final tables = <String, FontTable>{
      if (!useOpenType) ...{
        kGlyfTag: glyf!,
        kLocaTag: loca!,
      },
      if (useOpenType) ...{
        kCFFTag: cff!,
      },
      kCmapTag: cmap,
      kMaxpTag: maxp,
      kHeadTag: head,
      kHmtxTag: hmtx,
      kHheaTag: hhea,
      kPostTag: post,
      kNameTag: name,
      kGSUBTag: gsub,
      kOS2Tag: os2,
    };

    final offsetTable = OffsetTable.create(tables.length, useOpenType);

    return OpenTypeFont(offsetTable, tables);
  }

  final OffsetTable offsetTable;
  final Map<String, FontTable> tableMap;

  HeaderTable get head => tableMap[kHeadTag] as HeaderTable;

  MaximumProfileTable get maxp => tableMap[kMaxpTag] as MaximumProfileTable;

  IndexToLocationTable get loca => tableMap[kLocaTag] as IndexToLocationTable;

  GlyphDataTable get glyf => tableMap[kGlyfTag] as GlyphDataTable;

  GlyphSubstitutionTable get gsub =>
      tableMap[kGSUBTag] as GlyphSubstitutionTable;

  OS2Table get os2 => tableMap[kOS2Tag] as OS2Table;

  PostScriptTable get post => tableMap[kPostTag] as PostScriptTable;

  NamingTable get name => tableMap[kNameTag] as NamingTable;

  CharacterToGlyphTable get cmap => tableMap[kCmapTag] as CharacterToGlyphTable;

  HorizontalHeaderTable get hhea => tableMap[kHheaTag] as HorizontalHeaderTable;

  HorizontalMetricsTable get hmtx =>
      tableMap[kHmtxTag] as HorizontalMetricsTable;

  CFF1Table get cff => tableMap[kCFFTag] as CFF1Table;

  CFF2Table get cff2 => tableMap[kCFF2Tag] as CFF2Table;

  bool get isOpenType => offsetTable.isOpenType;

  String get familyName => name.familyName;

  @override
  void encodeToBinary(ByteData byteData) {
    var currentTableOffset = kOffsetTableLength + entryListSize;

    final entryList = <TableRecordEntry>[];

    for (final tag in _kTableTagsToEncode) {
      final table = tableMap[tag];

      if (table == null) {
        continue;
      }

      if (table is CalculatableOffsets) {
        (table as CalculatableOffsets).recalculateOffsets();
      }

      final tableSize = table.size;

      table.encodeToBinary(byteData.sublistView(currentTableOffset, tableSize));
      final encodedTable = ByteData.sublistView(
          byteData, currentTableOffset, currentTableOffset + tableSize);

      table.entry = TableRecordEntry(tag, calculateTableChecksum(encodedTable),
          currentTableOffset, tableSize);
      entryList.add(table.entry!);

      currentTableOffset += getPaddedTableSize(tableSize);
    }

    // The directory entry tags must be in ascending order
    entryList.sort((e1, e2) => e1.tag.compareTo(e2.tag));

    for (var i = 0; i < entryList.length; i++) {
      final entryOffset = kOffsetTableLength + i * kTableRecordEntryLength;
      final entryByteData =
          byteData.sublistView(entryOffset, kTableRecordEntryLength);
      entryList[i].encodeToBinary(entryByteData);
    }

    offsetTable.encodeToBinary(byteData.sublistView(0, kOffsetTableLength));

    // Setting checksum for whole font in the head table
    final fontChecksum = calculateFontChecksum(byteData);
    byteData.setUint32(head.entry!.offset + 8, fontChecksum);
  }

  int get entryListSize => kTableRecordEntryLength * tableMap.length;

  int get tableListSize =>
      tableMap.values.fold<int>(0, (p, t) => p + getPaddedTableSize(t.size));

  @override
  int get size => kOffsetTableLength + entryListSize + tableListSize;

  // TODO: I don't like this. Refactor it later. Use "strategy" or something.
  static List<GenericGlyph> _resizeAndCenter(
    List<GenericGlyph> glyphList, {
    int? ascender,
    int? descender,
    int? fontHeight,
  }) {
    return glyphList.map((g) {
      if (fontHeight != null) {
        // Not normalizing glyphs, just resizing them according to unitsPerEm
        return g.resize(
            fontHeight: fontHeight,
            ratioX: g.metadata.ratioX,
            ratioY: g.metadata.ratioY);
      }

      if (ascender != null && descender != null) {
        return g
            .resize(
              ascender: ascender,
              descender: descender,
              ratioX: g.metadata.ratioX,
              ratioY: g.metadata.ratioY,
            )
            .center(ascender, descender, g.metadata.offset ?? 0);
      }

      throw ArgumentError('ascender/descender or fontHeight must not be null');
    }).toList();
  }

  static List<GenericGlyph> _generateCharCodes(List<GenericGlyph> glyphList) {
    for (var i = 0; i < glyphList.length; i++) {
      glyphList[i].metadata.charCode = kUnicodePrivateUseAreaStart + i;
    }
    return glyphList;
  }

  // static List<GenericGlyph> _generateCharCodes(List<GenericGlyph> glyphList) {
  //   final definedCodes = <int>{};
  //   for (var i = 0; i < glyphList.length; i++) {
  //     int codeUnit = kUnicodePrivateUseAreaStart;

  //     final name = glyphList[i].metadata.name;
  //     if (name?.isNotEmpty ?? false) {
  //       int codeUnitsWhere(int start, int count) => name!
  //           .substring(start, min(start + count, name.length))
  //           .codeUnits
  //           .fold(0, (acc, next) => acc += next);

  //       codeUnit += codeUnitsWhere(0, 2);
  //       final chunks = name!.length ~/ 3;
  //       for (var startIndex = 0; startIndex < chunks; startIndex++) {
  //         codeUnit += codeUnitsWhere(startIndex * 3, 1);
  //       }
  //       if (chunks <= 2) {
  //         codeUnit += name.length;
  //       }
  //       codeUnit += codeUnitsWhere(name.length - 3, 2);

  //       while (!definedCodes.add(codeUnit)) {
  //         logger.w('Code unit already used. Changed with multiplier');
  //         codeUnit += name.length;
  //       }

  //       logger.w('For icon named: $name, generated char code: $codeUnit');
  //     } else {
  //       codeUnit += i;
  //     }

  //     glyphList[i].metadata.charCode = codeUnit;
  //   }
  //   return glyphList.sorted(
  //     (a, b) => a.metadata.charCode!.compareTo(b.metadata.charCode!),
  //   );
  // }
}
