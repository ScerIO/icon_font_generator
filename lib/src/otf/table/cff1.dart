part of 'cff.dart';

const _kCFF1HeaderSize = 4;

// NOTE: local subrs, encodings are omitted

class CFF1TableHeader implements BinaryCodable {
  CFF1TableHeader(
    this.majorVersion,
    this.minorVersion,
    this.headerSize,
    this.offSize,
  );

  factory CFF1TableHeader.fromByteData(ByteData byteData) {
    return CFF1TableHeader(
      byteData.getUint8(0),
      byteData.getUint8(1),
      byteData.getUint8(2),
      byteData.getUint8(3),
    );
  }

  factory CFF1TableHeader.create() =>
      CFF1TableHeader(1, 0, _kCFF1HeaderSize, null);

  final int majorVersion;
  final int minorVersion;
  final int headerSize;
  int? offSize;

  @override
  void encodeToBinary(ByteData byteData) {
    byteData
      ..setUint8(0, majorVersion)
      ..setUint8(1, minorVersion)
      ..setUint8(2, headerSize)
      ..setUint8(3, offSize!);
  }

  @override
  int get size => _kCFF1HeaderSize;
}

class CFF1Table extends CFFTable implements CalculatableOffsets {
  CFF1Table(
    super.entry,
    this.header,
    this.nameIndex,
    this.topDicts,
    this.stringIndex,
    this.globalSubrsData,
    this.charsets,
    this.charStringsData,
    this.fontDictList,
    this.privateDictList,
    this.localSubrsDataList,
  ) : super.fromTableRecordEntry();

  factory CFF1Table.fromByteData(
    ByteData byteData,
    TableRecordEntry entry,
  ) {
    /// 3 entries with fixed location
    var fixedOffset = entry.offset;

    final header = CFF1TableHeader.fromByteData(
        byteData.sublistView(fixedOffset, _kCFF2HeaderSize));
    fixedOffset += header.size;

    final nameIndex = CFFIndexWithData<Uint8List>.fromByteData(
      byteData.sublistView(fixedOffset),
      true,
    );
    fixedOffset += nameIndex.size;

    final topDicts = CFFIndexWithData<CFFDict>.fromByteData(
      byteData.sublistView(fixedOffset),
      true,
    );
    fixedOffset += topDicts.size;

    // NOTE: Using only first Top DICT
    final topDict = topDicts.data.first;

    /// String INDEX
    final stringIndex = CFFIndexWithData<Uint8List>.fromByteData(
      byteData.sublistView(fixedOffset),
      true,
    );
    fixedOffset += stringIndex.size;

    final globalSubrsData = CFFIndexWithData<Uint8List>.fromByteData(
      byteData.sublistView(fixedOffset),
      true,
    );
    fixedOffset += globalSubrsData.index!.size;

    /// CharStrings INDEX
    final charStringsIndexEntry = topDict.getEntryForOperator(op.charStrings)!;
    final charStringsIndexOffset =
        charStringsIndexEntry.operandList.first.value as int;
    final charStringsIndexByteData =
        byteData.sublistView(entry.offset + charStringsIndexOffset);

    final charStringsData = CFFIndexWithData<Uint8List>.fromByteData(
      charStringsIndexByteData,
      true,
    );

    /// Charsets
    final charsetsOffset =
        topDict.getEntryForOperator(op.charset)!.operandList.first.value as int;
    final charsetsByteData =
        byteData.sublistView(entry.offset + charsetsOffset);

    final charsetEntry = CharsetEntry.fromByteData(
      charsetsByteData,
      charStringsData.index!.count,
    )!;

    final privateEntry = topDict.getEntryForOperator(op.private)!;
    final dictOffset =
        entry.offset + (privateEntry.operandList.last.value as int);
    final dictLength = privateEntry.operandList.first.value as int;
    final dictByteData = byteData.sublistView(dictOffset, dictLength);
    final privateDict = CFFDict.fromByteData(dictByteData);

    /// Private DICT list
    final privateDictList = <CFFDict>[privateDict];

    /// Local subroutines for each Private DICT
    final localSubrsDataList = <CFFIndexWithData<Uint8List>>[];

    // NOTE: reading only first local subrs
    final localSubrEntry = privateDict.getEntryForOperator(op.subrs);
    if (localSubrEntry != null) {
      /// Offset from the start of the Private DICT
      final localSubrOffset = localSubrEntry.operandList.first.value as int;

      final localSubrByteData =
          byteData.sublistView(dictOffset + localSubrOffset);
      final localSubrsData =
          CFFIndexWithData<Uint8List>.fromByteData(localSubrByteData, true);

      localSubrsDataList.add(localSubrsData);
    }

    return CFF1Table(
      entry,
      header,
      nameIndex,
      topDicts,
      stringIndex,
      globalSubrsData,
      charsetEntry,
      charStringsData,
      CFFIndexWithData<CFFDict>.create([], true),
      privateDictList,
      localSubrsDataList,
    );
  }

  factory CFF1Table.create(
    List<GenericGlyph> glyphList,
    HeaderTable head,
    HorizontalMetricsTable hmtx,
    NamingTable name,
  ) {
    final header = CFF1TableHeader.create();

    var sidIndex = _cffStandardStringCount;
    final sidList = <int>[];
    final stringIndexDataList = <Uint8List>[];
    final RegExp ascii = RegExp(r'^[\x00-\x7F]+$');

    int putStringInIndex(String string) {
      String finalString = string;
      if (!ascii.hasMatch(finalString)) {
        finalString = 'Non-ascii character';
      }
      stringIndexDataList.add(Uint8List.fromList(finalString.codeUnits));
      sidList.add(sidIndex);
      return sidIndex++;
    }

    // excluding .notdef
    for (final g in glyphList.sublist(1)) {
      final standardSid = _kCharcodeToSidMap[g.metadata.charCode];

      if (standardSid != null) {
        sidList.add(standardSid);
      } else {
        putStringInIndex(g.metadata.name!);
      }
    }

    final glyphSidList = [...sidList];

    final fontName = name.getStringByNameId(NameID.fullFontName)!;
    final copyrightString = '${name.getStringByNameId(NameID.copyright)} '
        '${name.getStringByNameId(NameID.urlVendor)}';

    final topDictStringEntryMap = {
      op.version: name.getStringByNameId(NameID.version),
      op.notice: copyrightString,
      op.fullName: fontName,
      op.weight: name.getStringByNameId(NameID.fontSubfamily),
    };

    final topDicts = CFFIndexWithData.create([
      CFFDict([
        for (final e in topDictStringEntryMap.entries)
          if (e.value != null)
            CFFDictEntry(
              [CFFOperand.fromValue(putStringInIndex(e.value!))],
              e.key,
            ),
        CFFDictEntry([
          CFFOperand.fromValue(head.xMin),
          CFFOperand.fromValue(head.yMin),
          CFFOperand.fromValue(head.xMax),
          CFFOperand.fromValue(head.yMax)
        ], op.fontBBox),
      ])
    ], true);
    final globalSubrsData = CFFIndexWithData<Uint8List>.create([], true);

    final charStringRawList = <Uint8List>[];

    for (var i = 0; i < glyphList.length; i++) {
      final glyph = glyphList[i].copy();

      for (final o in glyph.outlines) {
        o
          ..decompactImplicitPoints()
          ..quadToCubic();
      }

      final commandList = [
        ...glyph.toCharStringCommands(CharStringOptimizer(true)),
        CharStringCommand(cs_op.endchar, [])
      ];
      final byteData = CharStringInterpreter(true).writeCommands(
        commandList,
        glyphWidth: hmtx.hMetrics[i].advanceWidth,
      );

      charStringRawList.add(byteData.buffer.asUint8List());
    }

    final charStringsData =
        CFFIndexWithData<Uint8List>.create(charStringRawList, true);

    final fontDict = CFFDict.empty();

    final privateDict = CFFDict([
      CFFDictEntry([CFFOperand.fromValue(0)], op.nominalWidthX),
    ]);

    final fontDictList = CFFIndexWithData<CFFDict>.create([fontDict], true);
    final privateDictList = [privateDict];
    final localSubrsDataList = <CFFIndexWithData<Uint8List>>[];

    final nameIndex = CFFIndexWithData<Uint8List>.create([
      Uint8List.fromList(fontName.getPostScriptString().codeUnits),
    ], true);
    final stringIndex = CFFIndexWithData<Uint8List>.create(
      stringIndexDataList,
      true,
    );

    final charsets = CharsetEntryFormat1.create(glyphSidList);

    final table = CFF1Table(
      null,
      header,
      nameIndex,
      topDicts,
      stringIndex,
      globalSubrsData,
      charsets,
      charStringsData,
      fontDictList,
      privateDictList,
      localSubrsDataList,
    )..recalculateOffsets();

    return table;
  }

  final CFF1TableHeader header;
  final CFFIndexWithData<Uint8List> nameIndex;
  final CFFIndexWithData<CFFDict> topDicts;
  final CFFIndexWithData<Uint8List> stringIndex;
  final CFFIndexWithData<Uint8List> globalSubrsData;
  final CharsetEntry charsets;
  final CFFIndexWithData<Uint8List> charStringsData;
  final CFFIndexWithData<CFFDict> fontDictList;
  final List<CFFDict> privateDictList;
  final List<CFFIndexWithData<Uint8List>> localSubrsDataList;

  CFFDict get topDict => topDicts.data.first;

  void _generateTopDictEntries() {
    final entryList = <CFFDictEntry>[
      CFFDictEntry([CFFOperand.fromValue(0)], op.charset),
      CFFDictEntry([CFFOperand.fromValue(0)], op.charStrings),
      CFFDictEntry([
        CFFOperand.fromValue(privateDictList.first.size),
        CFFOperand.fromValue(0)
      ], op.private),
    ];

    final operatorList = entryList.map((e) => e.operator).toList();

    topDict.entryList
      ..removeWhere((e) => operatorList.contains(e.operator))
      ..addAll(entryList);
  }

  void _recalculateTopDictOffsets() {
    // Generating entries with zero-values
    _generateTopDictEntries();

    var offset = _fixedSize;

    final charsetOffset = offset;
    offset += charsets.size;

    final charStringsOffset = offset;
    offset += charStringsData.size;

    // NOTE: Using only first private dict
    final privateDict = privateDictList.first;
    final privateDictOffset = offset;
    offset += privateDict.size;

    final charsetEntry = topDict.getEntryForOperator(op.charset)!;
    final charStringsEntry = topDict.getEntryForOperator(op.charStrings)!;
    final privateEntry = topDict.getEntryForOperator(op.private)!;

    final offsetList = [
      charsetOffset,
      charStringsOffset,
      privateDictOffset,
    ];

    final entryList = [
      charsetEntry,
      charStringsEntry,
      privateEntry,
    ];

    _calculateEntryOffsets(entryList, offsetList, operandIndexList: [0, 0, 1]);
  }

  @override
  void recalculateOffsets() {
    _recalculateTopDictOffsets();

    // Recalculating INDEXex
    nameIndex.recalculateOffsets();
    topDicts.recalculateOffsets();
    stringIndex.recalculateOffsets();
    globalSubrsData.recalculateOffsets();
    charStringsData.recalculateOffsets();
    fontDictList.recalculateOffsets();
    for (final e in localSubrsDataList) {
      e.recalculateOffsets();
    }

    // Last data offset
    final lastDataEntry = topDict.getEntryForOperator(op.private)!;
    final lastDataOffset = lastDataEntry.operandList.last.value as int;
    header.offSize = (lastDataOffset.bitLength / 8).ceil();
  }

  @override
  void encodeToBinary(ByteData byteData) {
    var offset = 0;

    header.encodeToBinary(byteData.sublistView(offset, header.size));
    offset += header.size;

    final nameIndexSize = nameIndex.size;
    nameIndex.encodeToBinary(byteData.sublistView(offset, nameIndexSize));
    offset += nameIndexSize;

    final topDictsSize = topDicts.size;
    topDicts.encodeToBinary(byteData.sublistView(offset, topDictsSize));
    offset += topDictsSize;

    final stringIndexSize = stringIndex.size;
    stringIndex.encodeToBinary(byteData.sublistView(offset, stringIndexSize));
    offset += stringIndexSize;

    final globalSubrsSize = globalSubrsData.size;
    globalSubrsData
        .encodeToBinary(byteData.sublistView(offset, globalSubrsSize));
    offset += globalSubrsSize;

    final charsetsSize = charsets.size;
    charsets.encodeToBinary(byteData.sublistView(offset, charsetsSize));
    offset += charsetsSize;

    final charStringsSize = charStringsData.size;
    charStringsData
        .encodeToBinary(byteData.sublistView(offset, charStringsSize));
    offset += charStringsSize;

    // NOTE: Using only first private dict
    final privateDict = privateDictList.first;
    final privateDictSize = privateDict.size;

    privateDict.encodeToBinary(byteData.sublistView(offset, privateDictSize));
    offset += privateDictSize;
  }

  int get _privateDictListSize => privateDictList.fold(0, (p, d) => p + d.size);

  int get _fixedSize =>
      header.size +
      nameIndex.size +
      topDicts.size +
      stringIndex.size +
      globalSubrsData.size;

  @override
  int get size =>
      _fixedSize + charsets.size + charStringsData.size + _privateDictListSize;
}
