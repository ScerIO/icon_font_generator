import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:icon_font_generator/src/common/generic_glyph.dart';
import 'package:icon_font_generator/src/otf/io.dart';
import 'package:icon_font_generator/src/otf/otf.dart';
import 'package:icon_font_generator/src/otf/reader.dart';
import 'package:icon_font_generator/src/otf/table/all.dart';
import 'package:icon_font_generator/src/utils/misc.dart';
import 'package:icon_font_generator/src/utils/otf.dart';
import 'package:test/test.dart';

import 'constant.dart';

const _kTestFontAssetPath = '$kTestAssetsDir/test_font.ttf';
const _kTestCFF2fontAssetPath = '$kTestAssetsDir/test_cff2_font.otf';

void main() {
  late OpenTypeFont font;

  group('Reader', () {
    setUpAll(() {
      font = readFromFile(_kTestFontAssetPath);
    });

    test('Offset table', () {
      final table = font.offsetTable;

      expect(table.entrySelector, 3);
      expect(table.numTables, 11);
      expect(table.rangeShift, 48);
      expect(table.searchRange, 128);
      expect(table.sfntVersion, 0x10000);
      expect(table.isOpenType, false);
    });

    test('Maximum Profile table', () {
      final table = font.tableMap[kMaxpTag] as MaximumProfileTable;
      expect(table, isNotNull);

      expect(table.version, 0x00010000);
      expect(table.numGlyphs, 166);
      expect(table.maxPoints, 333);
      expect(table.maxContours, 22);
      expect(table.maxCompositePoints, 0);
      expect(table.maxCompositeContours, 0);
      expect(table.maxZones, 2);
      expect(table.maxTwilightPoints, 0);
      expect(table.maxStorage, 10);
      expect(table.maxFunctionDefs, 10);
      expect(table.maxInstructionDefs, 0);
      expect(table.maxStackElements, 255);
      expect(table.maxSizeOfInstructions, 0);
      expect(table.maxComponentElements, 0);
      expect(table.maxComponentDepth, 0);
    });

    test('Header table', () {
      final table = font.tableMap[kHeadTag] as HeaderTable;
      expect(table, isNotNull);

      expect(table.majorVersion, 1);
      expect(table.minorVersion, 0);
      expect(table.fontRevision.major, 1);
      expect(table.fontRevision.minor, 0);
      expect(table.checkSumAdjustment, 3043242535);
      expect(table.magicNumber, 1594834165);
      expect(table.flags, 11);
      expect(table.unitsPerEm, 1000);
      expect(table.created, DateTime.parse('2020-06-09T08:21:53.000Z'));
      expect(table.modified, DateTime.parse('2020-06-09T08:21:53.000Z'));
      expect(table.xMin, -11);
      expect(table.yMin, -153);
      expect(table.xMax, 1636);
      expect(table.yMax, 853);
      expect(table.macStyle, 0);
      expect(table.lowestRecPPEM, 8);
      expect(table.fontDirectionHint, 2);
      expect(table.indexToLocFormat, 0);
      expect(table.glyphDataFormat, 0);
    });

    test('Glyph Data table', () {
      final table = font.tableMap[kGlyfTag] as GlyphDataTable;
      expect(table, isNotNull);
      expect(table.glyphList.length, 166);

      final glyphCalendRainbow = table.glyphList[1];
      expect(glyphCalendRainbow.header.numberOfContours, 3);
      expect(glyphCalendRainbow.header.xMin, 0);
      expect(glyphCalendRainbow.header.yMin, 0);
      expect(glyphCalendRainbow.header.xMax, 1000);
      expect(glyphCalendRainbow.header.yMax, 623);
      expect(
          glyphCalendRainbow.flags
              .sublist(0, 7)
              .map((f) => f.onCurvePoint)
              .toList(),
          [true, false, true, false, true, false, false]);
      expect(glyphCalendRainbow.pointList.first.x, 936);
      expect(glyphCalendRainbow.pointList.last.x, 681);
      expect(glyphCalendRainbow.pointList.first.y, 110);
      expect(glyphCalendRainbow.pointList.last.y, 94);

      final glyphReport = table.glyphList[73];
      expect(glyphReport.header.numberOfContours, 4);
      expect(glyphReport.header.xMin, 0);
      expect(glyphReport.header.yMin, -150);
      expect(glyphReport.header.xMax, 1001);
      expect(glyphReport.header.yMax, 788);
      expect(
          glyphReport.flags.sublist(0, 7).map((f) => f.onCurvePoint).toList(),
          [true, false, false, true, true, false, false]);
      expect(glyphReport.pointList.first.x, 63);
      expect(glyphReport.pointList.last.x, 563);
      expect(glyphReport.pointList.first.y, 788);
      expect(glyphReport.pointList.last.y, 350);

      final glyphPdf = table.glyphList[165];
      expect(glyphPdf.header.numberOfContours, 5);
      expect(glyphPdf.header.xMin, 0);
      expect(glyphPdf.header.yMin, -88);
      expect(glyphPdf.header.xMax, 751);
      expect(glyphPdf.header.yMax, 788);
      expect(glyphPdf.flags.sublist(0, 7).map((f) => f.onCurvePoint).toList(),
          [true, false, false, true, true, false, false]);
      expect(glyphPdf.pointList.first.x, 63);
      expect(glyphPdf.pointList.last.x, 448);
      expect(glyphPdf.pointList.first.y, 788);
      expect(glyphPdf.pointList.last.y, 208);
    });

    test('OS/2 V1 table', () {
      final table = font.tableMap[kOS2Tag] as OS2Table;
      expect(table, isNotNull);

      expect(table.version, 1);
      expect(table.xAvgCharWidth, 862);
      expect(table.usWeightClass, 400);
      expect(table.usWidthClass, 5);
      expect(table.fsType, 0);
      expect(table.ySubscriptXSize, 634);
      expect(table.ySubscriptYSize, 700);
      expect(table.ySubscriptXOffset, 0);
      expect(table.ySubscriptYOffset, 140);
      expect(table.ySuperscriptXSize, 634);
      expect(table.ySuperscriptYSize, 700);
      expect(table.ySuperscriptXOffset, 0);
      expect(table.ySuperscriptYOffset, 480);
      expect(table.yStrikeoutSize, 49);
      expect(table.yStrikeoutPosition, 258);
      expect(table.sFamilyClass, 0);
      expect(table.panose, [2, 0, 5, 3, 0, 0, 0, 0, 0, 0]);
      expect(table.ulUnicodeRange1, 0);
      expect(table.ulUnicodeRange2, 0);
      expect(table.ulUnicodeRange3, 0);
      expect(table.ulUnicodeRange4, 0);
      expect(table.achVendID, 'PfEd');
      expect(table.fsSelection, 64);
      expect(table.usFirstCharIndex, 59414);
      expect(table.usLastCharIndex, 62368);
      expect(table.sTypoAscender, 850);
      expect(table.sTypoDescender, -150);
      expect(table.sTypoLineGap, 90);
      expect(table.usWinAscent, 853);
      expect(table.usWinDescent, 153);
      expect(table.ulCodePageRange1, 1);
      expect(table.ulCodePageRange2, 0);
    });

    test('PostScript table', () {
      final table = font.tableMap[kPostTag] as PostScriptTable;
      expect(table, isNotNull);

      expect(table.header.version, const Revision(2, 0));
      expect(table.header.italicAngle, 0);
      expect(table.header.underlinePosition, 10);
      expect(table.header.underlineThickness, 0);
      expect(table.header.isFixedPitch, 0);
      expect(table.header.minMemType42, 0);
      expect(table.header.maxMemType42, 0);
      expect(table.header.minMemType1, 0);
      expect(table.header.maxMemType1, 0);

      final format20 = table.data as PostScriptVersion20;
      expect(format20.numberOfGlyphs, 166);
      expect(format20.glyphNameIndex, _kPOSTformat20indicies);
      expect(format20.glyphNames.map((ps) => ps.string).toList(),
          _kPOSTformat20names);
    });

    test('Naming table', () {
      final table = font.tableMap[kNameTag] as NamingTableFormat0;
      expect(table, isNotNull);

      expect(table.header.format, 0);
      expect(table.header.count, 18);
      expect(table.stringList.contains('Regular'), isTrue);
      expect(table.stringList.contains('TestFont'), isTrue);
      expect(table.stringList.contains('Version 1.0'), isTrue);
    });

    test('Character To Glyph Index Mapping table', () {
      final table = font.tableMap[kCmapTag] as CharacterToGlyphTable;
      expect(table, isNotNull);

      expect(table.header.version, 0);
      expect(table.header.numTables, 5);

      final format0table = table.data[2] as CmapByteEncodingTable;
      expect(format0table.format, 0);
      expect(format0table.language, 0);
      expect(format0table.length, 262);
      expect(format0table.glyphIdArray, List.generate(256, (_) => 0));

      final format4table =
          table.data[0] as CmapSegmentMappingToDeltaValuesTable;
      expect(format4table.format, 4);
      expect(format4table.length, 410);
      expect(format4table.language, 0);
      expect(format4table.entrySelector, 3);
      expect(format4table.searchRange, 16);
      expect(format4table.rangeShift, 0);
      expect(format4table.segCount, 8);
      expect(format4table.glyphIdArray, List.generate(165, (i) => i + 1));
      expect(format4table.idDelta, [0, 0, 0, 0, 0, 0, 0, 1]);
      expect(format4table.idRangeOffset, [16, 16, 16, 16, 16, 16, 320, 0]);
      expect(format4table.startCode,
          [59414, 59430, 59436, 59444, 59446, 62208, 62362, 65535]);
      expect(format4table.endCode,
          [59414, 59430, 59436, 59444, 59446, 62360, 62368, 65535]);

      final format12table = table.data[1] as CmapSegmentedCoverageTable;
      expect(format12table.format, 12);
      expect(format12table.language, 0);
      expect(format12table.numGroups, 165);
      expect(format12table.length, 1996);
      expect(format12table.groups.map((g) => g.startCharCode).toList(),
          _kCMAPcharCodes);
      expect(format12table.groups.map((g) => g.endCharCode).toList(),
          _kCMAPcharCodes);
      expect(format12table.groups.map((g) => g.startGlyphID).toList(),
          List.generate(165, (i) => i + 1));
    });

    test('Horizontal Header table', () {
      final table = font.tableMap[kHheaTag] as HorizontalHeaderTable;
      expect(table, isNotNull);

      expect(table.majorVersion, 1);
      expect(table.minorVersion, 0);
      expect(table.ascender, 850);
      expect(table.descender, -150);
      expect(table.lineGap, 0);
      expect(table.advanceWidthMax, 1636);
      expect(table.minLeftSideBearing, -11);
      expect(table.minRightSideBearing, -7);
      expect(table.xMaxExtent, 1636);
      expect(table.caretSlopeRise, 1);
      expect(table.caretSlopeRun, 0);
      expect(table.caretOffset, 0);
      expect(table.metricDataFormat, 0);
      expect(table.numberOfHMetrics, 166);
    });

    test('Horizontal Metrics table', () {
      final table = font.tableMap[kHmtxTag] as HorizontalMetricsTable;
      expect(table, isNotNull);

      expect(table.leftSideBearings, isEmpty);
      expect(
          table.hMetrics.map((m) => m.advanceWidth).toList(), _kHMTXadvWidth);
      expect(table.hMetrics.map((m) => m.lsb).toList(), _kHMTXlsb);
    });

    test('Glyph Substitution table', () {
      final table = font.tableMap[kGSUBTag] as GlyphSubstitutionTable;
      expect(table, isNotNull);

      final scriptTable = table.scriptListTable;

      expect(scriptTable.scriptCount, 2);

      expect(scriptTable.scriptRecords[0].scriptTag, 'DFLT');
      expect(scriptTable.scriptTables[0].langSysCount, 0);
      expect(scriptTable.scriptTables[0].defaultLangSys?.featureIndexCount, 1);
      expect(scriptTable.scriptTables[0].defaultLangSys?.featureIndices, [0]);
      expect(scriptTable.scriptTables[0].defaultLangSys?.lookupOrder, 0);
      expect(
          scriptTable.scriptTables[0].defaultLangSys?.requiredFeatureIndex, 0);

      expect(scriptTable.scriptRecords[1].scriptTag, 'latn');
      expect(scriptTable.scriptTables[1].langSysCount, 0);
      expect(scriptTable.scriptTables[1].defaultLangSys?.featureIndexCount, 1);
      expect(scriptTable.scriptTables[1].defaultLangSys?.featureIndices, [0]);
      expect(scriptTable.scriptTables[1].defaultLangSys?.lookupOrder, 0);
      expect(
          scriptTable.scriptTables[1].defaultLangSys?.requiredFeatureIndex, 0);

      final featureTable = table.featureListTable;
      expect(featureTable.featureCount, 1);
      expect(featureTable.featureRecords[0].featureTag, 'liga');
      expect(featureTable.featureTables[0].featureParams, 0);
      expect(featureTable.featureTables[0].lookupIndexCount, 1);
      expect(featureTable.featureTables[0].lookupListIndices, [0]);

      final lookupListTable = table.lookupListTable;
      expect(lookupListTable.lookupCount, 1);

      final lookupTable = lookupListTable.lookupTables.first;
      expect(lookupTable.lookupFlag, 0);
      expect(lookupTable.lookupType, 4);

      final lookupSubtable =
          lookupTable.subtables.first as LigatureSubstitutionSubtable;
      expect(lookupSubtable.ligatureSetCount, 0);
      expect(lookupSubtable.ligatureSetOffsets, isEmpty);
      expect(lookupSubtable.substFormat, 1);

      final coverageTable =
          lookupSubtable.coverageTable as CoverageTableFormat1;
      expect(coverageTable.coverageFormat, 1);
      expect(coverageTable.glyphCount, 0);
      expect(coverageTable.glyphArray, isEmpty);
    });
  });

  group('Creation & Writer', () {
    late ByteData originalByteData, recreatedByteData;
    late OpenTypeFont recreatedFont;

    setUpAll(() {
      MockableDateTime.mockedDate = DateTime.utc(2020, 2, 2, 2, 2);
      originalByteData =
          ByteData.sublistView(File(_kTestFontAssetPath).readAsBytesSync());
      font = OTFReader.fromByteData(originalByteData).read();

      final glyphNameList = (font.post.data as PostScriptVersion20)
          .glyphNames
          .map((s) => s.string)
          .toList();
      final glyphList = font.glyf.glyphList
          .map(GenericGlyph.fromSimpleTrueTypeGlyph)
          .toList();

      for (var i = 0; i < glyphList.length; i++) {
        glyphList[i].metadata.name = glyphNameList[i];
      }

      recreatedFont = OpenTypeFont.createFromGlyphs(
        glyphList: glyphList,
        fontName: 'TestFont',
        useOpenType: false,
        usePostV2: true,
      );

      recreatedByteData = ByteData(recreatedFont.size);
      recreatedFont.encodeToBinary(recreatedByteData);
    });

    tearDownAll(() {
      MockableDateTime.mockedDate = null;
    });

    test('Header table', () {
      const expected =
          'AAEAAAABAADXpqNjXw889QALBAAAAAAA2lveGAAAAADaW94Y//X/ZwZkBAAAAAAIAAIAAAAA';
      final actual = base64Encode(recreatedByteData.buffer.asUint8List(
          recreatedFont.head.entry!.offset, recreatedFont.head.entry!.length));

      expect(actual, expected);
      expect(recreatedFont.head.entry!.checkSum, 439353492);
    }, skip: "Font's checksum is always changing, unskip later");

    test('Glyph Substitution table', () {
      const expected =
          'AAEAAAAKADAAPgACREZMVAAObGF0bgAaAAQAAAAA//8AAQAAAAQAAAAA//8AAQAAAAFsaWdhAAgAAAABAAAAAQAEAAQAAAABAAgAAQAGAAAAAQAA';
      final actual = base64Encode(recreatedByteData.buffer.asUint8List(
          recreatedFont.gsub.entry!.offset, recreatedFont.gsub.entry!.length));

      expect(actual, expected);
      expect(recreatedFont.gsub.entry!.checkSum, 546121080);
    });

    test('OS/2 V5', () {
      final table = recreatedFont.os2;

      expect(table.version, 5);
      expect(table.xAvgCharWidth, 675);
    });
  });

  group('CFF', () {
    late ByteData byteData;

    setUpAll(() {
      byteData =
          ByteData.sublistView(File(_kTestCFF2fontAssetPath).readAsBytesSync());
      font = OTFReader.fromByteData(byteData).read();
    });

    test('CFF2 Read & Write', () {
      final table = font.cff2;

      final originalCFF2byteList =
          byteData.buffer.asUint8List(table.entry!.offset, table.size).toList();
      final encodedCFF2byteData = ByteData(table.size);

      expect(table.size, table.entry!.length);

      table
        ..recalculateOffsets()
        ..encodeToBinary(encodedCFF2byteData);

      final encodedCFF2byteList =
          encodedCFF2byteData.buffer.asUint8List().toList();
      expect(encodedCFF2byteList, originalCFF2byteList);
    });

    test('CFF2 CharString Read & Write', () {
      // final interpreter = CharStringInterpreter();

      // final commands = [
      //   CharStringCommand.rmoveto(0, 0),
      //   CharStringCommand.rlineto([100, 100]),
      //   CharStringCommand.rmoveto(-50, -50),
      //   CharStringCommand.rlineto([100, 100]),
      // ];

      // final encoded = interpreter.writeCommands(commands);
      // final decoded = interpreter.readCommands(encoded);

      // TODO: !!! do some tests
    });
  });

  group('Generic Glyph', () {
    setUpAll(() {
      font = readFromFile(_kTestFontAssetPath);
    });

    test('Conversion from TrueType and back', () {
      final genericList = font.glyf.glyphList
          .map(GenericGlyph.fromSimpleTrueTypeGlyph)
          .toList();
      final simpleList =
          genericList.map((e) => e.toSimpleTrueTypeGlyph()).toList();

      for (var i = 0; i < genericList.length; i++) {
        expect(simpleList[i].pointList, font.glyf.glyphList[i].pointList);
      }
    });

    test('Decompact and compact back', () {
      final genericList = font.glyf.glyphList
          .map(GenericGlyph.fromSimpleTrueTypeGlyph)
          .toList();

      for (final g in genericList) {
        for (final o in g.outlines) {
          o
            ..decompactImplicitPoints()
            ..compactImplicitPoints();
        }
      }

      final simpleList =
          genericList.map((e) => e.toSimpleTrueTypeGlyph()).toList();

      // Those were compacted more than they were originally. Expecting just new size.
      final changedForReason = {
        1: 87,
        34: 66,
        53: 121,
        70: 90,
        115: 60,
        138: 90,
      };

      for (var i = 0; i < genericList.length; i++) {
        final newLength = simpleList[i].pointList.length;
        final expectedLength =
            changedForReason[i] ?? font.glyf.glyphList[i].pointList.length;
        expect(newLength, expectedLength);
      }
    });

    // TODO: !!! quad->cubic outline test
    // TODO: !!! generic->charstring test
    // TODO: !!! generic->simpleglyph test
  });

  group('Utils', () {
    const testString = '[INFO] :谷���新道, ひば���ヶ丘２丁���,'
        ' ひばりヶ���, 東久留米市 (Higashikurume)';

    test('Printable ASCII string', () {
      const expectedString = 'INFO :, , ,  Higashikurume';
      expect(testString.getAsciiPrintable(), expectedString);
    });

    test('PostScript ASCII string', () {
      const expectedString = 'INFO:,,,Higashikurume';
      expect(testString.getPostScriptString(), expectedString);
    });
  });
}

const _kPOSTformat20indicies = [
  258,
  259,
  260,
  261,
  262,
  263,
  264,
  265,
  266,
  267,
  268,
  269,
  270,
  271,
  272,
  273,
  274,
  275,
  276,
  277,
  278,
  279,
  280,
  281,
  282,
  283,
  284,
  285,
  286,
  287,
  288,
  289,
  290,
  291,
  292,
  293,
  294,
  295,
  296,
  297,
  298,
  299,
  300,
  301,
  302,
  303,
  304,
  305,
  306,
  307,
  308,
  309,
  310,
  311,
  312,
  313,
  314,
  315,
  316,
  317,
  318,
  319,
  320,
  321,
  322,
  323,
  324,
  325,
  326,
  327,
  328,
  329,
  330,
  331,
  332,
  333,
  334,
  335,
  336,
  337,
  338,
  339,
  340,
  341,
  342,
  343,
  344,
  345,
  346,
  347,
  348,
  349,
  350,
  351,
  352,
  353,
  354,
  355,
  356,
  357,
  358,
  359,
  360,
  361,
  362,
  363,
  364,
  365,
  366,
  367,
  368,
  369,
  370,
  371,
  372,
  373,
  374,
  375,
  376,
  377,
  378,
  379,
  380,
  381,
  382,
  383,
  384,
  385,
  386,
  387,
  388,
  389,
  390,
  391,
  392,
  393,
  394,
  395,
  396,
  397,
  398,
  399,
  400,
  401,
  402,
  403,
  404,
  405,
  406,
  407,
  408,
  409,
  410,
  411,
  412,
  413,
  414,
  415,
  416,
  417,
  418,
  419,
  420,
  421,
  422,
  423
];
const _kPOSTformat20names = [
  '',
  'calend_rainbow',
  'fav_group',
  'hamburger',
  'menu_notif',
  'note-1',
  'arrow-small-left',
  'checklist',
  'diff-modified',
  'plus',
  'pin',
  'database',
  'markdown',
  'unverified',
  'mark-github',
  'globe',
  'light-bulb',
  'watch',
  'primitive-dot',
  'bookmark',
  'gift',
  'file-directory',
  'versions',
  'triangle-up',
  'issue-closed',
  'tag',
  'book',
  'git-commit',
  'mail-read',
  'repo-push',
  'ellipsis',
  'lock',
  'terminal',
  'key',
  'tasklist',
  'repo',
  'shield-lock',
  'pulse',
  'triangle-down',
  'credit-card',
  'diff-ignored',
  'file-submodule',
  'primitive-square',
  'mute',
  'unmute',
  'heart-outline',
  'sync',
  'beaker',
  'reply',
  'italic',
  'diff-renamed',
  'plus-small',
  'dash',
  'list-unordered',
  'pencil',
  'question',
  'primitive-dot-stroke',
  'saved',
  'unfold',
  'rss',
  'arrow-small-down',
  'line-arrow-down',
  'fold',
  'sign-out',
  'issue-opened',
  'file-code',
  'trashcan',
  'star',
  'shield-check',
  'repo-template',
  'thumbsup',
  'shield-x',
  'logo-gist',
  'report',
  'mention',
  'cloud-download',
  'git-branch',
  'squirrel',
  'desktop-download',
  'kebab-vertical',
  'line-arrow-left',
  'clippy',
  'megaphone',
  'repo-clone',
  'workflow',
  'arrow-up',
  'chevron-up',
  'plug',
  'comment',
  'location',
  'kebab-horizontal',
  'link-external',
  'link',
  'code',
  'history',
  'stop',
  'graph',
  'file-media',
  'text-size',
  'no-newline',
  'gear',
  'home',
  'device-camera-video',
  'diff-added',
  'arrow-both',
  'circuit-board',
  'repo-pull',
  'sign-in',
  'eye-closed',
  'north-star',
  'internal-repo',
  'check',
  'law',
  'cloud-upload',
  'settings',
  'three-bars',
  'flame',
  'horizontal-rule',
  'chevron-right',
  'chevron-left',
  'repo-template-private',
  'github-action',
  'broadcast',
  'archive',
  'note',
  'milestone',
  'project',
  'device-mobile',
  'line-arrow-right',
  'arrow-small-right',
  'arrow-right',
  'inbox',
  'repo-forked',
  'line-arrow-up',
  'tools',
  'jersey',
  'device-desktop',
  'package',
  'thumbsdown',
  'dashboard',
  'play',
  'dependent',
  'rocket',
  'calendar',
  'smiley',
  'issue-reopened',
  'clock',
  'mirror',
  'shield',
  'file-symlink-directory',
  'browser',
  'server',
  'triangle-right',
  'radio-tower',
  'mail',
  'arrow-down',
  'diff-removed',
  'hubot',
  'file',
  'gist-secret',
  'x',
  'screen-normal',
  'infinity',
  'mortar-board',
  'alert',
  'file-pdf'
];
const _kCMAPcharCodes = [
  59414,
  59430,
  59436,
  59444,
  59446,
  62208,
  62209,
  62210,
  62211,
  62212,
  62213,
  62214,
  62215,
  62216,
  62217,
  62218,
  62219,
  62220,
  62221,
  62222,
  62223,
  62224,
  62225,
  62226,
  62227,
  62228,
  62229,
  62230,
  62231,
  62232,
  62233,
  62234,
  62235,
  62236,
  62237,
  62238,
  62239,
  62240,
  62241,
  62242,
  62243,
  62244,
  62245,
  62246,
  62247,
  62248,
  62249,
  62250,
  62251,
  62252,
  62253,
  62254,
  62255,
  62256,
  62257,
  62258,
  62259,
  62260,
  62261,
  62262,
  62263,
  62264,
  62265,
  62266,
  62267,
  62268,
  62269,
  62270,
  62271,
  62272,
  62273,
  62274,
  62275,
  62276,
  62277,
  62278,
  62279,
  62280,
  62281,
  62282,
  62283,
  62284,
  62285,
  62286,
  62287,
  62288,
  62289,
  62290,
  62291,
  62292,
  62293,
  62294,
  62295,
  62296,
  62297,
  62298,
  62299,
  62300,
  62301,
  62302,
  62303,
  62304,
  62305,
  62306,
  62307,
  62308,
  62309,
  62310,
  62311,
  62312,
  62313,
  62314,
  62315,
  62316,
  62317,
  62318,
  62319,
  62320,
  62321,
  62322,
  62323,
  62324,
  62325,
  62326,
  62327,
  62328,
  62329,
  62330,
  62331,
  62332,
  62333,
  62334,
  62335,
  62336,
  62337,
  62338,
  62339,
  62340,
  62341,
  62342,
  62343,
  62344,
  62345,
  62346,
  62347,
  62348,
  62349,
  62350,
  62351,
  62352,
  62353,
  62354,
  62355,
  62356,
  62357,
  62358,
  62359,
  62360,
  62362,
  62363,
  62364,
  62365,
  62366,
  62367,
  62368
];
const _kHMTXadvWidth = [
  1000,
  1000,
  1636,
  818,
  1000,
  1000,
  375,
  1000,
  875,
  750,
  1000,
  750,
  1000,
  1000,
  1000,
  875,
  750,
  750,
  500,
  625,
  875,
  875,
  875,
  750,
  1000,
  937,
  1000,
  875,
  875,
  750,
  750,
  750,
  875,
  875,
  1000,
  750,
  875,
  875,
  750,
  1000,
  875,
  875,
  500,
  1000,
  1000,
  750,
  750,
  1000,
  875,
  375,
  875,
  437,
  500,
  750,
  875,
  875,
  500,
  1000,
  875,
  625,
  375,
  1000,
  875,
  941,
  875,
  750,
  750,
  875,
  1000,
  875,
  1000,
  1000,
  1562,
  1000,
  875,
  1000,
  625,
  1000,
  1000,
  187,
  1000,
  875,
  1000,
  1000,
  1000,
  625,
  625,
  875,
  1000,
  750,
  812,
  750,
  1000,
  875,
  875,
  875,
  1000,
  750,
  1125,
  1000,
  875,
  1000,
  1000,
  875,
  1250,
  875,
  1000,
  875,
  1142,
  1000,
  812,
  750,
  875,
  1000,
  1000,
  750,
  750,
  625,
  500,
  500,
  875,
  1000,
  1000,
  875,
  875,
  875,
  937,
  625,
  1000,
  375,
  625,
  875,
  625,
  1000,
  1000,
  875,
  1000,
  1000,
  1000,
  1000,
  875,
  1000,
  1000,
  875,
  1000,
  875,
  875,
  1000,
  875,
  875,
  875,
  750,
  375,
  1000,
  875,
  625,
  875,
  875,
  750,
  875,
  750,
  875,
  1000,
  1000,
  1000,
  750
];
const _kHMTXlsb = [
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  -3,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  -1,
  0,
  0,
  0,
  0,
  -6,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  -9,
  0,
  0,
  0,
  0,
  0,
  -11,
  0,
  0,
  0,
  -1,
  0,
  0,
  0,
  0,
  0,
  -6,
  0,
  -8,
  0,
  0,
  0,
  0,
  0,
  -6,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0
];
