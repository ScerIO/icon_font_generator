part of 'cff.dart';

const _kCFF2HeaderSize = 5;

class CFF2TableHeader implements BinaryCodable {
  CFF2TableHeader(this.majorVersion, this.minorVersion, this.headerSize,
      this.topDictLength);

  factory CFF2TableHeader.fromByteData(ByteData byteData) {
    return CFF2TableHeader(
      byteData.getUint8(0),
      byteData.getUint8(1),
      byteData.getUint8(2),
      byteData.getUint16(3),
    );
  }

  factory CFF2TableHeader.create() =>
      CFF2TableHeader(_kMajorVersion2, 0, _kCFF2HeaderSize, null);

  final int majorVersion;
  final int minorVersion;
  final int headerSize;
  int? topDictLength;

  @override
  void encodeToBinary(ByteData byteData) {
    byteData
      ..setUint8(0, majorVersion)
      ..setUint8(1, minorVersion)
      ..setUint8(2, headerSize)
      ..setUint16(3, topDictLength!);
  }

  @override
  int get size => _kCFF2HeaderSize;
}

class CFF2Table extends CFFTable implements CalculatableOffsets {
  CFF2Table(
    super.entry,
    this.header,
    this.topDict,
    this.globalSubrsData,
    this.charStringsData,
    this.vstoreData,
    this.fontDictList,
    this.privateDictList,
    this.localSubrsDataList,
  ) : super.fromTableRecordEntry();

  factory CFF2Table.fromByteData(
    ByteData byteData,
    TableRecordEntry entry,
  ) {
    /// 3 entries with fixed location
    var fixedOffset = entry.offset;

    final header = CFF2TableHeader.fromByteData(
        byteData.sublistView(fixedOffset, _kCFF2HeaderSize));
    fixedOffset += _kCFF2HeaderSize;

    final topDict = CFFDict.fromByteData(
        byteData.sublistView(fixedOffset, header.topDictLength!));
    fixedOffset += header.topDictLength!;

    final globalSubrsData = CFFIndexWithData<Uint8List>.fromByteData(
        byteData.sublistView(fixedOffset), false);
    fixedOffset += globalSubrsData.index!.size;

    /// CharStrings INDEX
    final charStringsIndexEntry = topDict.getEntryForOperator(op.charStrings)!;
    final charStringsIndexOffset =
        charStringsIndexEntry.operandList.first.value as int;
    final charStringsIndexByteData =
        byteData.sublistView(entry.offset + charStringsIndexOffset);

    final charStringsData = CFFIndexWithData<Uint8List>.fromByteData(
        charStringsIndexByteData, false);

    /// VariationStore
    final vstoreEntry = topDict.getEntryForOperator(op.vstore);
    VariationStoreData? vstoreData;

    if (vstoreEntry != null) {
      final vstoreOffset = vstoreEntry.operandList.first.value as int;
      final vstoreByteData = byteData.sublistView(entry.offset + vstoreOffset);
      vstoreData = VariationStoreData.fromByteData(vstoreByteData);
    }

    // NOTE: not decoding FDSelect - using single Font DICT only

    /// Font DICT INDEX
    final fdArrayEntry = topDict.getEntryForOperator(op.fdArray)!;
    final fdArrayOffset = fdArrayEntry.operandList.first.value as int;

    final fontIndexByteData =
        byteData.sublistView(entry.offset + fdArrayOffset);

    /// List of Font DICT
    final fontDictList =
        CFFIndexWithData<CFFDict>.fromByteData(fontIndexByteData, false);

    /// Private DICT list
    final privateDictList = <CFFDict>[];

    /// Local subroutines for each Private DICT
    final localSubrsDataList = <CFFIndexWithData<Uint8List>>[];

    for (var i = 0; i < fontDictList.index!.count; i++) {
      final privateEntry =
          fontDictList.data[i].getEntryForOperator(op.private)!;
      final dictOffset =
          entry.offset + (privateEntry.operandList.last.value as int);
      final dictLength = privateEntry.operandList.first.value as int;
      final dictByteData = byteData.sublistView(dictOffset, dictLength);

      final dict = CFFDict.fromByteData(dictByteData);
      privateDictList.add(dict);

      final localSubrEntry = dict.getEntryForOperator(op.subrs);

      if (localSubrEntry != null) {
        /// Offset from the start of the Private DICT
        final localSubrOffset = localSubrEntry.operandList.first.value as int;

        final localSubrByteData =
            byteData.sublistView(dictOffset + localSubrOffset);
        final localSubrsData =
            CFFIndexWithData<Uint8List>.fromByteData(localSubrByteData, false);

        localSubrsDataList.add(localSubrsData);
      }
    }

    return CFF2Table(entry, header, topDict, globalSubrsData, charStringsData,
        vstoreData, fontDictList, privateDictList, localSubrsDataList);
  }

  factory CFF2Table.create(List<GenericGlyph> glyphList) {
    final header = CFF2TableHeader.create();
    final topDict = CFFDict.empty();
    final globalSubrsData = CFFIndexWithData<Uint8List>.create([], false);
    const VariationStoreData? vstoreData = null; // omitted - no variations

    final charStringInterpreter = CharStringInterpreter(false);

    final charStringRawList = glyphList.map((g) {
      final glyph = g.copy();

      for (final o in glyph.outlines) {
        o
          ..decompactImplicitPoints()
          ..quadToCubic();
      }

      final commandList =
          glyph.toCharStringCommands(CharStringOptimizer(false));
      final byteData = charStringInterpreter.writeCommands(commandList);

      return byteData.buffer.asUint8List();
    }).toList();

    final charStringsData =
        CFFIndexWithData<Uint8List>.create(charStringRawList, false);

    final fontDict = CFFDict([CFFDictEntry([], op.private)]);
    final privateDict =
        CFFDict([]); // A Private DICT is required, but can be empty

    final fontDictList = CFFIndexWithData<CFFDict>.create([fontDict], false);
    final privateDictList = [privateDict];
    final localSubrsDataList = <CFFIndexWithData<Uint8List>>[];

    final table = CFF2Table(
        null,
        header,
        topDict,
        globalSubrsData,
        charStringsData,
        vstoreData,
        fontDictList,
        privateDictList,
        localSubrsDataList)
      ..recalculateOffsets();

    return table;
  }

  final CFF2TableHeader header;
  final CFFDict topDict;
  final CFFIndexWithData<Uint8List> globalSubrsData;
  final CFFIndexWithData<Uint8List> charStringsData;
  final VariationStoreData? vstoreData;
  final CFFIndexWithData<CFFDict> fontDictList;
  final List<CFFDict> privateDictList;
  final List<CFFIndexWithData<Uint8List>> localSubrsDataList;

  void _generateTopDictEntries() {
    final entryList = <CFFDictEntry>[
      CFFDictEntry([CFFOperand.fromValue(0)], op.charStrings),
      if (vstoreData != null)
        CFFDictEntry([CFFOperand.fromValue(0)], op.vstore),
      CFFDictEntry([CFFOperand.fromValue(0)], op.fdArray),
      // NOTE: not encoding FDSelect - using single Font DICT only
    ];

    topDict.entryList = entryList;
  }

  void _recalculateTopDictOffsets() {
    // Generating entries with zero-values
    _generateTopDictEntries();

    var offset = header.size + globalSubrsData.size + topDict.size;

    int? vstoreOffset;
    if (vstoreData != null) {
      vstoreOffset = offset;
      offset += vstoreData!.size;
    }

    final charStringsOffset = offset;
    offset += charStringsData.size;

    final fdArrayOffset = offset;
    offset += fontDictList.size;

    final vstoreEntry = topDict.getEntryForOperator(op.vstore);
    final charStringsEntry = topDict.getEntryForOperator(op.charStrings)!;
    final fdArrayEntry = topDict.getEntryForOperator(op.fdArray)!;

    final offsetList = [
      if (vstoreData != null) vstoreOffset!,
      charStringsOffset,
      fdArrayOffset,
    ];

    final entryList = [
      if (vstoreEntry != null) vstoreEntry,
      charStringsEntry,
      fdArrayEntry,
    ];

    _calculateEntryOffsets(entryList, offsetList, operandIndex: 0);
  }

  @override
  void recalculateOffsets() {
    _recalculateTopDictOffsets();

    header.topDictLength = topDict.size;

    globalSubrsData.recalculateOffsets();
    fontDictList.recalculateOffsets();
    charStringsData.recalculateOffsets();

    // Recalculating font DICTs private offsets and SUBRS entries offsets
    final fdArrayEntry = topDict.getEntryForOperator(op.fdArray)!;
    final fdArrayOffset = fdArrayEntry.operandList.first.value as int;

    var fontDictOffset = fdArrayOffset + fontDictList.index!.size;

    for (var i = 0; i < fontDictList.data.length; i++) {
      final fontDict = fontDictList.data[i];
      final privateDict = privateDictList[i];
      final privateEntry = fontDict.getEntryForOperator(op.private)!;

      final newOperands = [
        CFFOperand.fromValue(privateDict.size),
        CFFOperand.fromValue(0)
      ];
      privateEntry.operandList
        ..clear()
        ..addAll(newOperands);
      fontDictOffset += fontDict.size;

      final subrsEntry = privateDict.getEntryForOperator(op.subrs);
      if (subrsEntry != null) {
        subrsEntry.operandList
          ..clear()
          ..add(CFFOperand.fromValue(0));
        subrsEntry.recalculatePointers(0, () => privateDict.size);
      }

      _calculateEntryOffsets([privateEntry], [fontDictOffset], operandIndex: 1);
    }

    // Recalculating local subrs
    for (final localSubrs in localSubrsDataList) {
      localSubrs.recalculateOffsets();
    }
  }

  @override
  void encodeToBinary(ByteData byteData) {
    var offset = 0;

    header.encodeToBinary(byteData.sublistView(offset, header.size));
    offset += header.size;

    final topDictSize = topDict.size;
    topDict.encodeToBinary(byteData.sublistView(offset, topDictSize));
    offset += topDictSize;

    final globalSubrsSize = globalSubrsData.size;
    globalSubrsData
        .encodeToBinary(byteData.sublistView(offset, globalSubrsSize));
    offset += globalSubrsSize;

    if (vstoreData != null) {
      final vstoreSize = vstoreData!.size;
      vstoreData!.encodeToBinary(byteData.sublistView(offset, vstoreSize));
      offset += vstoreSize;
    }

    final charStringsSize = charStringsData.size;
    charStringsData
        .encodeToBinary(byteData.sublistView(offset, charStringsSize));
    offset += charStringsSize;

    final fontDictListSize = fontDictList.size;
    fontDictList.encodeToBinary(byteData.sublistView(offset, fontDictListSize));
    offset += fontDictListSize;

    for (var i = 0; i < fontDictList.data.length; i++) {
      final privateDict = privateDictList[i];
      final privateDictSize = privateDict.size;

      privateDict.encodeToBinary(byteData.sublistView(offset, privateDictSize));
      offset += privateDictSize;
    }

    for (final localSubrs in localSubrsDataList) {
      final localSubrsSize = localSubrs.size;
      localSubrs.encodeToBinary(byteData.sublistView(offset, localSubrsSize));
      offset += localSubrsSize;
    }
  }

  int get _privateDictListSize => privateDictList.fold(0, (p, d) => p + d.size);

  int get _localSubrsListSize =>
      localSubrsDataList.fold(0, (p, d) => p + d.size);

  @override
  int get size =>
      header.size +
      topDict.size +
      globalSubrsData.size +
      (vstoreData?.size ?? 0) +
      charStringsData.size +
      fontDictList.size +
      _privateDictListSize +
      _localSubrsListSize;
}
