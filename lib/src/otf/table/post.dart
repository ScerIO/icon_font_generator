import 'dart:typed_data';

import '../../common/codable/binary.dart';
import '../../common/generic_glyph.dart';
import '../../utils/otf.dart';
import '../../utils/pascal_string.dart';
import '../debugger.dart';
import '../defaults.dart';
import 'abstract.dart';
import 'table_record_entry.dart';

const _kVersion20 = 0x00020000;
const _kVersion30 = 0x00030000;

const _kHeaderSize = 32;

class PostScriptTableHeader implements BinaryCodable {
  PostScriptTableHeader(
    this.version,
    this.italicAngle,
    this.underlinePosition,
    this.underlineThickness,
    this.isFixedPitch,
    this.minMemType42,
    this.maxMemType42,
    this.minMemType1,
    this.maxMemType1,
  );

  factory PostScriptTableHeader.fromByteData(
      ByteData byteData, TableRecordEntry entry) {
    final version = Revision.fromInt32(byteData.getInt32(entry.offset));

    return PostScriptTableHeader(
      version,
      byteData.getFixed(entry.offset + 4),
      byteData.getFWord(entry.offset + 8),
      byteData.getFWord(entry.offset + 10),
      byteData.getUint32(entry.offset + 12),
      byteData.getUint32(entry.offset + 16),
      byteData.getUint32(entry.offset + 20),
      byteData.getUint32(entry.offset + 24),
      byteData.getUint32(entry.offset + 28),
    );
  }

  factory PostScriptTableHeader.create(Revision version) {
    return PostScriptTableHeader(
      version,
      0, // italicAngle - upright text
      0, // underlinePosition
      0, // underlineThickness
      0, // isFixedPitch - proportionally spaced
      0,
      0,
      0,
      0,
    );
  }

  final Revision version;
  final int italicAngle;
  final int underlinePosition;
  final int underlineThickness;
  final int isFixedPitch;
  final int minMemType42;
  final int maxMemType42;
  final int minMemType1;
  final int maxMemType1;

  @override
  int get size => _kHeaderSize;

  @override
  void encodeToBinary(ByteData byteData) {
    byteData
      ..setInt32(0, version.int32value)
      ..setFixed(4, italicAngle)
      ..setFWord(8, underlinePosition)
      ..setFWord(10, underlineThickness)
      ..setUint32(12, isFixedPitch)
      ..setUint32(16, minMemType42)
      ..setUint32(20, maxMemType42)
      ..setUint32(24, minMemType1)
      ..setUint32(28, maxMemType1);
  }
}

abstract class PostScriptData implements BinaryCodable {
  PostScriptData();

  static PostScriptData? fromByteData(
      ByteData byteData, int offset, PostScriptTableHeader header) {
    final version = header.version.int32value;

    switch (version) {
      case _kVersion20:
        return PostScriptVersion20.fromByteData(byteData, offset);
      case _kVersion30:
        return PostScriptVersion30();
      default:
        debugUnsupportedTableVersion(kPostTag, version);
        return null;
    }
  }

  Revision get version;
}

class PostScriptVersion30 extends PostScriptData {
  PostScriptVersion30();

  @override
  int get size => 0;

  @override
  Revision get version => const Revision.fromInt32(_kVersion30);

  @override
  void encodeToBinary(_) {}
}

class PostScriptVersion20 extends PostScriptData {
  PostScriptVersion20(
      this.numberOfGlyphs, this.glyphNameIndex, this.glyphNames);

  factory PostScriptVersion20.fromByteData(ByteData byteData, int offset) {
    final numberOfGlyphs = byteData.getUint16(offset);
    offset += 2;

    final glyphNameIndex = List.generate(
        numberOfGlyphs, (i) => byteData.getUint16(offset + i * 2));
    offset += numberOfGlyphs * 2;

    final glyphNames = <PascalString>[];

    for (final glyphIndex in glyphNameIndex) {
      if (_isGlyphNameStandard(glyphIndex)) {
        continue;
      }

      final string = PascalString.fromByteData(byteData, offset);
      offset += string.size;

      glyphNames.add(string);
    }

    return PostScriptVersion20(numberOfGlyphs, glyphNameIndex, glyphNames);
  }

  factory PostScriptVersion20.create(List<String> glyphNameList) {
    final glyphNameIndex = [
      ...kDefaultGlyphIndex,
      for (var i = 0; i < glyphNameList.length; i++)
        _kMacStandardGlyphNames.length + i,
    ];

    final numberOfGlyphs = glyphNameIndex.length;

    final glyphNames =
        glyphNameList.map(PascalString.fromString).toList();

    return PostScriptVersion20(
      numberOfGlyphs,
      glyphNameIndex,
      glyphNames,
    );
  }

  final int numberOfGlyphs;
  final List<int> glyphNameIndex;
  final List<PascalString> glyphNames;

  @override
  int get size {
    var glyphNamesSize = 0, currentNameIndex = 0;

    for (var i = 0; i < numberOfGlyphs; i++) {
      if (_isGlyphNameStandard(glyphNameIndex[i])) {
        continue;
      }

      glyphNamesSize += glyphNames[currentNameIndex++].size;
    }

    return 2 + numberOfGlyphs * 2 + glyphNamesSize;
  }

  @override
  Revision get version => const Revision.fromInt32(_kVersion20);

  @override
  void encodeToBinary(ByteData byteData) {
    byteData.setUint16(0, numberOfGlyphs);

    var offset = 2;

    for (final glyphIndex in glyphNameIndex) {
      byteData.setUint16(offset, glyphIndex);
      offset += 2;
    }

    var currentNameIndex = 0;

    for (var i = 0; i < numberOfGlyphs; i++) {
      final glyphIndex = glyphNameIndex[i];

      if (_isGlyphNameStandard(glyphIndex)) {
        continue;
      }

      final glyphName = glyphNames[currentNameIndex++];
      glyphName.encodeToBinary(byteData.sublistView(offset, glyphName.size));
      offset += glyphName.size;
    }
  }
}

class PostScriptTable extends FontTable {
  PostScriptTable(super.entry, this.header, this.data)
      : super.fromTableRecordEntry();

  factory PostScriptTable.fromByteData(
      ByteData byteData, TableRecordEntry entry) {
    final header = PostScriptTableHeader.fromByteData(byteData, entry);

    return PostScriptTable(
        entry,
        header,
        PostScriptData.fromByteData(
            byteData, entry.offset + _kHeaderSize, header));
  }

  /// Creates post table.
  ///
  /// [glyphList] contains non-default characters.
  /// If [usePostV2] is true, version 2 table is generated.
  factory PostScriptTable.create(List<GenericGlyph> glyphList, bool usePostV2) {
    final glyphNameList = glyphList.map((e) => e.metadata.name ?? '').toList();

    final data = usePostV2
        ? PostScriptVersion20.create(glyphNameList)
        : PostScriptVersion30();

    return PostScriptTable(
        null, PostScriptTableHeader.create(data.version), data);
  }

  final PostScriptTableHeader header;
  final PostScriptData? data;

  @override
  int get size => header.size + (data?.size ?? 0);

  @override
  void encodeToBinary(ByteData byteData) {
    header.encodeToBinary(byteData);
    data?.encodeToBinary(byteData.sublistView(header.size, data!.size));
  }
}

bool _isGlyphNameStandard(int glyphIndex) =>
    glyphIndex < _kMacStandardGlyphNames.length;

const _kMacStandardGlyphNames = [
  '.notdef',
  '.null',
  'nonmarkingreturn',
  'space',
  'exclam',
  'quotedbl',
  'numbersign',
  'dollar',
  'percent',
  'ampersand',
  'quotesingle',
  'parenleft',
  'parenright',
  'asterisk',
  'plus',
  'comma',
  'hyphen',
  'period',
  'slash',
  'zero',
  'one',
  'two',
  'three',
  'four',
  'five',
  'six',
  'seven',
  'eight',
  'nine',
  'colon',
  'semicolon',
  'less',
  'equal',
  'greater',
  'question',
  'at',
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
  'K',
  'L',
  'M',
  'N',
  'O',
  'P',
  'Q',
  'R',
  'S',
  'T',
  'U',
  'V',
  'W',
  'X',
  'Y',
  'Z',
  'bracketleft',
  'backslash',
  'bracketright',
  'asciicircum',
  'underscore',
  'grave',
  'a',
  'b',
  'c',
  'd',
  'e',
  'f',
  'g',
  'h',
  'i',
  'j',
  'k',
  'l',
  'm',
  'n',
  'o',
  'p',
  'q',
  'r',
  's',
  't',
  'u',
  'v',
  'w',
  'x',
  'y',
  'z',
  'braceleft',
  'bar',
  'braceright',
  'asciitilde',
  'Adieresis',
  'Aring',
  'Ccedilla',
  'Eacute',
  'Ntilde',
  'Odieresis',
  'Udieresis',
  'aacute',
  'agrave',
  'acircumflex',
  'adieresis',
  'atilde',
  'aring',
  'ccedilla',
  'eacute',
  'egrave',
  'ecircumflex',
  'edieresis',
  'iacute',
  'igrave',
  'icircumflex',
  'idieresis',
  'ntilde',
  'oacute',
  'ograve',
  'ocircumflex',
  'odieresis',
  'otilde',
  'uacute',
  'ugrave',
  'ucircumflex',
  'udieresis',
  'dagger',
  'degree',
  'cent',
  'sterling',
  'section',
  'bullet',
  'paragraph',
  'germandbls',
  'registered',
  'copyright',
  'trademark',
  'acute',
  'dieresis',
  'notequal',
  'AE',
  'Oslash',
  'infinity',
  'plusminus',
  'lessequal',
  'greaterequal',
  'yen',
  'mu',
  'partialdiff',
  'summation',
  'product',
  'pi',
  'integral',
  'ordfeminine',
  'ordmasculine',
  'Omega',
  'ae',
  'oslash',
  'questiondown',
  'exclamdown',
  'logicalnot',
  'radical',
  'florin',
  'approxequal',
  'Delta',
  'guillemotleft',
  'guillemotright',
  'ellipsis',
  'nonbreakingspace',
  'Agrave',
  'Atilde',
  'Otilde',
  'OE',
  'oe',
  'endash',
  'emdash',
  'quotedblleft',
  'quotedblright',
  'quoteleft',
  'quoteright',
  'divide',
  'lozenge',
  'ydieresis',
  'Ydieresis',
  'fraction',
  'currency',
  'guilsinglleft',
  'guilsinglright',
  'fi',
  'fl',
  'daggerdbl',
  'periodcentered',
  'quotesinglbase',
  'quotedblbase',
  'perthousand',
  'Acircumflex',
  'Ecircumflex',
  'Aacute',
  'Edieresis',
  'Egrave',
  'Iacute',
  'Icircumflex',
  'Idieresis',
  'Igrave',
  'Oacute',
  'Ocircumflex',
  'apple',
  'Ograve',
  'Uacute',
  'Ucircumflex',
  'Ugrave',
  'dotlessi',
  'circumflex',
  'tilde',
  'macron',
  'breve',
  'dotaccent',
  'ring',
  'cedilla',
  'hungarumlaut',
  'ogonek',
  'caron',
  'Lslash',
  'lslash',
  'Scaron',
  'scaron',
  'Zcaron',
  'zcaron',
  'brokenbar',
  'Eth',
  'eth',
  'Yacute',
  'yacute',
  'Thorn',
  'thorn',
  'minus',
  'multiply',
  'onesuperior',
  'twosuperior',
  'threesuperior',
  'onehalf',
  'onequarter',
  'threequarters',
  'franc',
  'Gbreve',
  'gbreve',
  'Idotaccent',
  'Scedilla',
  'scedilla',
  'Cacute',
  'cacute',
  'Ccaron',
  'ccaron',
  'dcroat'
];
